"""
API Partite: lista partite (filtrando per status) e dettaglio con eventi.
Usato da Flutter Live: GET /matches?status=IN_PLAY, GET /matches/{id}.
"""
from typing import Annotated

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import aliased

from app.database import get_db
from app.models.match import Match
from app.models.match_event import MatchEvent
from app.models.real_team import RealTeam
from app.models.player import Player
from app.models.player_ai_rating import PlayerAIRating
from app.schemas.match_schema import (
    MatchListItem,
    MatchDetailResponse,
    MatchDetailFullResponse,
    MatchEventItem,
    PlayerRatingRow,
    MatchHighlightItem,
    MatchRatingsResponse,
    MatchRatingTeam,
    MatchRatingPlayer,
    MatchRatingPlayerEvents,
    MatchRatingPlayerEventItem,
)
from app.services.match_detail_service import get_match_detail_full
from app.services.highlights_service import get_highlights_for_match
from app.services.player_rating_service import calculate_ratings

router = APIRouter(prefix="/matches", tags=["matches"])

HomeTeam = aliased(RealTeam)
AwayTeam = aliased(RealTeam)


def _normalize_name_for_match(name: str | None) -> str:
    """Normalizza nome per confronto (lowercase, strip, caratteri unificati)."""
    if not name or not isinstance(name, str):
        return ""
    s = " ".join(name.strip().split()).lower()
    for old, new in (("ü", "u"), ("ö", "o"), ("ä", "a"), ("ß", "ss"), ("é", "e"), ("è", "e"), ("í", "i"), ("ó", "o"), ("á", "a"), ("ù", "u")):
        s = s.replace(old, new)
    return s


def _resolve_role_from_db(lineup_name: str, db_players: list[tuple[str, str]]) -> str | None:
    """
    Cerca il giocatore nella lista (name, position) dal nostro DB e restituisce position (POR/DIF/CEN/ATT).
    Fuzzy match: exact, cognome, contiene.
    """
    if not lineup_name or not db_players:
        return None
    nq = _normalize_name_for_match(lineup_name)
    if not nq:
        return None
    q_words = nq.split()
    q_surname = q_words[-1] if q_words else ""
    for db_name, position in db_players:
        nd = _normalize_name_for_match(db_name)
        if not nd:
            continue
        if nq == nd:
            return position
        d_words = nd.split()
        d_surname = d_words[-1] if d_words else ""
        if q_surname and (nd.endswith(q_surname) or d_surname == q_surname):
            return position
        if q_surname in nd or nd in nq or nq in nd:
            return position
    return None


@router.get("", response_model=list[MatchListItem])
async def list_matches(
    status: Annotated[str | None, Query(description="Filtro status (es. IN_PLAY)")] = None,
    matchday: Annotated[int | None, Query(description="Filtro giornata")] = None,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
):
    """Lista partite con nomi squadre, kick_off, stemmi e sigle (TLA); opzionale filtro status e matchday."""
    q = (
        select(
            Match.id,
            Match.matchday,
            Match.home_score,
            Match.away_score,
            Match.minute,
            Match.status,
            Match.kick_off,
            HomeTeam.name.label("home_team_name"),
            AwayTeam.name.label("away_team_name"),
            HomeTeam.crest_url.label("home_crest"),
            AwayTeam.crest_url.label("away_crest"),
            HomeTeam.tla.label("home_tla"),
            AwayTeam.tla.label("away_tla"),
        )
        .select_from(Match)
        .outerjoin(HomeTeam, Match.home_team_id == HomeTeam.id)
        .outerjoin(AwayTeam, Match.away_team_id == AwayTeam.id)
        .order_by(Match.matchday, Match.id)
    )
    if status:
        q = q.where(Match.status == status)
    if matchday is not None:
        q = q.where(Match.matchday == matchday)
    r = await db.execute(q)
    rows = r.all()
    return [
        MatchListItem(
            id=row.id,
            matchday=row.matchday,
            home_team_name=row.home_team_name or "",
            away_team_name=row.away_team_name or "",
            home_score=row.home_score,
            away_score=row.away_score,
            minute=row.minute,
            status=row.status or "SCHEDULED",
            kick_off=row.kick_off,
            home_crest=row.home_crest,
            away_crest=row.away_crest,
            home_tla=row.home_tla,
            away_tla=row.away_tla,
        )
        for row in rows
    ]


@router.get("/current-matchday")
async def get_current_matchday(
    db: Annotated[AsyncSession, Depends(get_db)] = None,
):
    """
    Giornata "corrente": la più alta con almeno un match IN_PLAY o FINISHED.
    Se nessuna (stagione non iniziata): la prossima con match SCHEDULED/TIMED.
    Usato dalla Live screen per mostrare tutte le partite della giornata.
    """
    # Giornata più alta con almeno una partita in corso o terminata
    r = await db.execute(
        select(func.max(Match.matchday)).where(
            Match.status.in_(["IN_PLAY", "PAUSED", "FINISHED"])
        )
    )
    matchday = r.scalar_one_or_none()
    if matchday is not None:
        return {"matchday": matchday}
    # Nessuna partita giocata: prossima giornata con partite in programma
    r2 = await db.execute(
        select(func.min(Match.matchday)).where(
            Match.status.in_(["SCHEDULED", "TIMED"])
        )
    )
    next_md = r2.scalar_one_or_none()
    return {"matchday": next_md if next_md is not None else 1}


@router.get("/{match_id}/detail", response_model=MatchDetailFullResponse)
async def get_match_detail_full_route(
    match_id: int,
    background_tasks: BackgroundTasks,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
):
    """Dettaglio partita completo: eventi, formazioni, statistiche, cronaca. Traduzione EN->IT in background."""
    detail = await get_match_detail_full(match_id, db, background_tasks=background_tasks)
    if not detail:
        raise HTTPException(status_code=404, detail="Match not found")
    return detail


@router.get("/{match_id}", response_model=MatchDetailResponse)
async def get_match_detail(
    match_id: int,
    db: Annotated[AsyncSession, Depends(get_db)] = None,
):
    """Dettaglio partita con eventi (gol, cartellini)."""
    q = (
        select(
            Match.id,
            Match.matchday,
            Match.home_score,
            Match.away_score,
            Match.minute,
            Match.status,
            HomeTeam.name.label("home_team_name"),
            AwayTeam.name.label("away_team_name"),
        )
        .select_from(Match)
        .outerjoin(HomeTeam, Match.home_team_id == HomeTeam.id)
        .outerjoin(AwayTeam, Match.away_team_id == AwayTeam.id)
        .where(Match.id == match_id)
    )
    r = await db.execute(q)
    row = r.one_or_none()
    if not row:
        raise HTTPException(status_code=404, detail="Match not found")
    events_r = await db.execute(
        select(MatchEvent.event_type, MatchEvent.minute)
        .where(MatchEvent.match_id == match_id)
        .order_by(MatchEvent.id)
    )
    events = [MatchEventItem(type=e, minute=m) for e, m in events_r.all()]
    return MatchDetailResponse(
        id=row.id,
        matchday=row.matchday,
        home_team_name=row.home_team_name or "",
        away_team_name=row.away_team_name or "",
        home_score=row.home_score,
        away_score=row.away_score,
        minute=row.minute,
        status=row.status or "SCHEDULED",
        events=events,
    )


@router.get("/{match_id}/highlights", response_model=list[MatchHighlightItem])
async def get_match_highlights(
    match_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Highlights video (ScoreBat): filtra per data e squadre; cache 1h."""
    r = await db.execute(select(Match.id).where(Match.id == match_id))
    if not r.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Match not found")
    items = await get_highlights_for_match(match_id, db)
    return [MatchHighlightItem(**x) for x in items]


@router.get("/{match_id}/ratings", response_model=MatchRatingsResponse)
async def get_match_ratings(
    match_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """
    Voti live da detail: eventi (gol, cartellini, rigori) + assist estratti dalla cronaca ("Assist di [Nome]").
    Calcolo al volo, ordinato per posizione (POR → DIF → CEN → ATT).
    """
    detail = await get_match_detail_full(match_id, db, background_tasks=None)
    if not detail:
        raise HTTPException(status_code=404, detail="Match not found")

    r_match = await db.execute(select(Match.home_team_id, Match.away_team_id).where(Match.id == match_id))
    match_row = r_match.one_or_none()
    home_team_id = match_row.home_team_id if match_row else None
    away_team_id = match_row.away_team_id if match_row else None
    home_db_players: list[tuple[str, str]] = []
    away_db_players: list[tuple[str, str]] = []
    home_name_to_photo: dict[str, str] = {}
    away_name_to_photo: dict[str, str] = {}
    home_name_to_cutout: dict[str, str] = {}
    away_name_to_cutout: dict[str, str] = {}
    home_name_to_id: dict[str, int] = {}
    away_name_to_id: dict[str, int] = {}
    if home_team_id or away_team_id:
        r_players = await db.execute(
            select(
                Player.id,
                Player.name,
                Player.position,
                Player.real_team_id,
                Player.photo_local,
                Player.photo_url,
                Player.cutout_local,
                Player.cutout_url,
            ).where(
                Player.real_team_id.in_([tid for tid in (home_team_id, away_team_id) if tid is not None])
            )
        )
        for row in r_players.all():
            pid, name, position, rtid = row[0], row[1], row[2], row[3]
            photo_local, photo_url = row[4], row[5]
            cutout_local, cutout_url = row[6], row[7]
            photo = f"/static/{photo_local}" if photo_local else (photo_url or "")
            cutout = f"/static/{cutout_local}" if cutout_local else (cutout_url or "")
            nq = _normalize_name_for_match(name) if name else ""
            if name and position:
                if rtid == home_team_id:
                    home_db_players.append((name, (position or "CEN").upper()))
                    if nq:
                        home_name_to_id[nq] = pid
                    if nq and photo:
                        home_name_to_photo[nq] = photo
                    if nq and cutout:
                        home_name_to_cutout[nq] = cutout
                elif rtid == away_team_id:
                    away_db_players.append((name, (position or "CEN").upper()))
                    if nq:
                        away_name_to_id[nq] = pid
                    if nq and photo:
                        away_name_to_photo[nq] = photo
                    if nq and cutout:
                        away_name_to_cutout[nq] = cutout

    lineups_dict: dict = {}
    for side in ("home", "away"):
        lineup = (detail.lineups or {}).get(side)
        if not lineup:
            lineups_dict[side] = {"starting": [], "substitutes": []}
            continue
        starters = getattr(lineup, "starting", None) or getattr(lineup, "starters", None) or []
        subs = getattr(lineup, "substitutes", None) or []
        lineups_dict[side] = {
            "starting": [{"name": getattr(p, "name", ""), "number": getattr(p, "number", None), "position": getattr(p, "position", "CEN")} for p in starters],
            "substitutes": [{"name": getattr(p, "name", ""), "number": getattr(p, "number", None), "position": getattr(p, "position", "RIS")} for p in subs],
        }
    events_list = [
        {
            "type": e.type or "",
            "player": e.player,
            "team": e.team,
            "detail": e.detail,
            "minute": getattr(e, "minute", None),
        }
        for e in (detail.events or [])
    ]
    commentary_list = [{"text": getattr(c, "text", "") or ""} for c in (detail.commentary or [])]

    result = calculate_ratings(
        lineups_dict,
        events_list,
        commentary_list,
        home_score=detail.home_score,
        away_score=detail.away_score,
    )

    for row in result.get("home", {}).get("starters", []) + result.get("home", {}).get("bench", []):
        resolved = _resolve_role_from_db(row.get("name") or "", home_db_players)
        if resolved:
            row["position"] = resolved
        nq = _normalize_name_for_match(row.get("name") or "")
        if nq and nq in home_name_to_id:
            row["player_id"] = home_name_to_id[nq]
    for row in result.get("away", {}).get("starters", []) + result.get("away", {}).get("bench", []):
        resolved = _resolve_role_from_db(row.get("name") or "", away_db_players)
        if resolved:
            row["position"] = resolved
        nq = _normalize_name_for_match(row.get("name") or "")
        if nq and nq in away_name_to_id:
            row["player_id"] = away_name_to_id[nq]

    def to_rating_player(row: dict, photo_url: str | None = None, cutout_url: str | None = None) -> MatchRatingPlayer:
        ev = row.get("events") or {}
        raw_event_list = row.get("event_list") or []
        event_list = [
            MatchRatingPlayerEventItem(type=item.get("type", ""), minute=item.get("minute"))
            for item in raw_event_list
            if isinstance(item, dict)
        ]
        return MatchRatingPlayer(
            name=row.get("name", ""),
            player_id=row.get("player_id"),
            role=(row.get("position") or "CEN").upper(),
            number=row.get("number"),
            live_rating=row.get("rating"),
            fantasy_score=row.get("fantasy_score"),
            is_starter=row.get("is_starter", True),
            played=row.get("played", True),
            subbed_in=row.get("subbed_in", False),
            subbed_out=row.get("subbed_out", False),
            minute_in=row.get("minute_in"),
            minute_out=row.get("minute_out"),
            events=MatchRatingPlayerEvents(
                goals=ev.get("goals", 0),
                assists=ev.get("assists", 0),
                own_goals=ev.get("own_goals", 0),
                yellow_cards=ev.get("yellow_cards", 0),
                red_cards=ev.get("red_cards", 0),
                penalty_saved=ev.get("penalty_saved", 0),
                penalty_missed=ev.get("penalty_missed", 0),
                goals_conceded=ev.get("goals_conceded", 0),
                minutes_played=ev.get("minutes_played", 0),
                subbed_in=ev.get("subbed_in", 0),
                subbed_out=ev.get("subbed_out", 0),
                injury=ev.get("injury", 0),
            ),
            event_list=event_list,
            photo_url=photo_url or None,
            cutout_url=cutout_url or None,
        )

    def media_for(row: dict, side: str) -> tuple[str | None, str | None]:
        name = (row.get("name") or "").strip()
        nq = _normalize_name_for_match(name) if name else ""
        if side == "home":
            return home_name_to_photo.get(nq), home_name_to_cutout.get(nq)
        return away_name_to_photo.get(nq), away_name_to_cutout.get(nq)

    home_starters = [to_rating_player(r, *media_for(r, "home")) for r in result.get("home", {}).get("starters", [])]
    home_bench = [to_rating_player(r, *media_for(r, "home")) for r in result.get("home", {}).get("bench", [])]
    away_starters = [to_rating_player(r, *media_for(r, "away")) for r in result.get("away", {}).get("starters", [])]
    away_bench = [to_rating_player(r, *media_for(r, "away")) for r in result.get("away", {}).get("bench", [])]
    home_name = (detail.home_team.name or "").strip()
    away_name = (detail.away_team.name or "").strip()

    return MatchRatingsResponse(
        match_id=detail.id,
        source="algorithm",
        is_final=False,
        home_team=MatchRatingTeam(name=home_name, starters=home_starters, bench=home_bench),
        away_team=MatchRatingTeam(name=away_name, starters=away_starters, bench=away_bench),
    )


@router.get("/{match_id}/ratings/ai", response_model=list[PlayerRatingRow])
async def get_match_ratings_ai(
    match_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
):
    """Pagelle AI: voti giocatori da player_ai_ratings (sentiment/mentions)."""
    r_match = await db.execute(select(Match.id).where(Match.id == match_id))
    if not r_match.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Match not found")
    r = await db.execute(
        select(PlayerAIRating, Player.name)
        .join(Player, PlayerAIRating.player_id == Player.id)
        .where(PlayerAIRating.match_id == match_id)
        .order_by(PlayerAIRating.player_id, PlayerAIRating.minute.desc())
    )
    rows = r.all()
    seen: set[int] = set()
    out = []
    for (rating_row, player_name) in rows:
        if rating_row.player_id in seen:
            continue
        seen.add(rating_row.player_id)
        out.append(PlayerRatingRow(
            player_id=rating_row.player_id,
            player_name=player_name or "",
            rating=rating_row.rating,
            trend=rating_row.trend or "stable",
            mentions=rating_row.mentions or 0,
            minute=rating_row.minute,
        ))
    return sorted(out, key=lambda x: x.rating, reverse=True)
