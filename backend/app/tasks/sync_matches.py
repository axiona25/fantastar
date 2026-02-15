"""
Sync partite da Football-Data.org: tutte le partite, live, eventi singola partita.
Include sync_real_teams per popolare external_id sulle squadre.
Dopo aggiornamento partite live: broadcast WebSocket a ws/match/{id} e ws/live/{league_id}.
"""
import logging
from collections import defaultdict
from datetime import datetime
from typing import Optional

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import AsyncSessionLocal
from app.data_providers.football_data_org import FootballDataOrgProvider
from app.models.real_team import RealTeam
from app.models.match import Match
from app.models.match_event import MatchEvent
from app.models.fantasy_calendar import FantasyCalendar
from app.models.fantasy_team import FantasyTeam
from app.utils.cache import cache_set, TTL_LIVE_MATCHES
from app.services.push_service import send_push_to_users

logger = logging.getLogger(__name__)

CACHE_KEY_LIVE = "live:matches"


async def sync_real_teams() -> dict:
    """Scarica squadre Serie A da API e aggiorna real_teams (external_id, crest_url, ecc.)."""
    provider = FootballDataOrgProvider(rate_limit=0)
    stats = {"updated": 0, "created": 0}
    try:
        data = await provider.get_teams()
        teams_data = data.get("teams") or []
        async with AsyncSessionLocal() as session:
            for t in teams_data:
                ext_id = t.get("id")
                name = (t.get("name") or "").strip()
                if not name:
                    continue
                short_name = t.get("shortName") or t.get("tla")
                tla = t.get("tla")
                crest = t.get("crest")
                existing = await session.execute(
                    select(RealTeam).where(
                        (RealTeam.external_id == ext_id) | (RealTeam.name == name)
                    )
                )
                row = existing.scalar_one_or_none()
                if row:
                    row.external_id = ext_id
                    row.short_name = short_name or row.short_name
                    row.tla = tla or row.tla
                    row.crest_url = crest or row.crest_url
                    stats["updated"] += 1
                else:
                    session.add(RealTeam(
                        external_id=ext_id,
                        name=name,
                        short_name=short_name,
                        tla=tla,
                        crest_url=crest,
                    ))
                    stats["created"] += 1
            await session.commit()
        logger.info("sync_real_teams: %s", stats)
        return stats
    except Exception as e:
        logger.exception("sync_real_teams failed: %s", e)
        return stats
    finally:
        await provider.close()


def _parse_utc(s: str | None) -> datetime | None:
    if not s:
        return None
    try:
        from dateutil import parser
        return parser.isoparse(s)
    except Exception:
        return None


async def _team_id_by_external(session: AsyncSession, external_id: int) -> Optional[int]:
    r = await session.execute(select(RealTeam.id).where(RealTeam.external_id == external_id))
    row = r.scalar_one_or_none()
    return row


async def sync_all_matches() -> dict:
    """
    Scarica TUTTE le partite della stagione da Football-Data.org (get_matches senza filtri)
    e le salva/aggiorna nel DB. Include partite non ancora giocate (es. Inter-Juventus 20:45)
    non appena compaiono nell'API, così non restano partite mancanti.
    Assume che real_teams abbiano external_id già popolato (da sync squadre/init).
    """
    provider = FootballDataOrgProvider(rate_limit=0)
    stats = {"created": 0, "updated": 0, "errors": 0}
    try:
        data = await provider.get_matches()  # nessun matchday/status: tutte le partite stagione
        matches_data = data.get("matches") or []
        async with AsyncSessionLocal() as session:
            for m in matches_data:
                ext_id = m.get("id")
                if not ext_id:
                    continue
                home_team_ext = m.get("homeTeam", {}).get("id") if isinstance(m.get("homeTeam"), dict) else None
                away_team_ext = m.get("awayTeam", {}).get("id") if isinstance(m.get("awayTeam"), dict) else None
                home_team_id = await _team_id_by_external(session, home_team_ext) if home_team_ext else None
                away_team_id = await _team_id_by_external(session, away_team_ext) if away_team_ext else None

                score = m.get("score") or {}
                ft = score.get("fullTime") or {}
                home_score = ft.get("home")
                away_score = ft.get("away")
                status = m.get("status", "SCHEDULED")
                utc_date = _parse_utc(m.get("utcDate"))
                # DB column is TIMESTAMP WITHOUT TIME ZONE: strip tz to avoid offset-naive/aware mismatch
                utc_date = utc_date.replace(tzinfo=None) if utc_date and getattr(utc_date, "tzinfo", None) else utc_date
                matchday = m.get("matchday") or 0

                existing = await session.execute(select(Match).where(Match.external_id == ext_id))
                match_row = existing.scalar_one_or_none()
                if match_row:
                    match_row.home_team_id = home_team_id
                    match_row.away_team_id = away_team_id
                    match_row.home_score = home_score
                    match_row.away_score = away_score
                    match_row.status = status
                    match_row.kick_off = utc_date
                    match_row.matchday = matchday
                    match_row.last_synced = datetime.utcnow()
                    stats["updated"] += 1
                else:
                    session.add(Match(
                        external_id=ext_id,
                        matchday=matchday,
                        home_team_id=home_team_id,
                        away_team_id=away_team_id,
                        home_score=home_score,
                        away_score=away_score,
                        status=status,
                        kick_off=utc_date,
                        last_synced=datetime.utcnow(),
                    ))
                    stats["created"] += 1
            await session.commit()
        logger.info("sync_all_matches: %s", stats)
        return stats
    except Exception as e:
        logger.exception("sync_all_matches failed: %s", e)
        stats["errors"] += 1
        return stats
    finally:
        await provider.close()


async def sync_live_matches() -> dict:
    """Polling partite IN_PLAY: aggiorna score e eventi, salva in Redis, broadcast WebSocket."""
    provider = FootballDataOrgProvider(rate_limit=0)
    try:
        data = await provider.get_live_matches()
        matches = data.get("matches") or []
        await cache_set(CACHE_KEY_LIVE, data, ttl_seconds=TTL_LIVE_MATCHES)

        updated_ext_ids: list[int] = []
        async with AsyncSessionLocal() as session:
            for m in matches:
                ext_id = m.get("id")
                if not ext_id:
                    continue
                updated_ext_ids.append(ext_id)
                score = m.get("score") or {}
                ft = score.get("fullTime") or {}
                home_score = ft.get("home")
                away_score = ft.get("away")
                status = m.get("status", "IN_PLAY")
                minute = m.get("minute")

                await session.execute(
                    update(Match)
                    .where(Match.external_id == ext_id)
                    .values(
                        home_score=home_score,
                        away_score=away_score,
                        status=status,
                        minute=minute,
                        last_synced=datetime.utcnow(),
                    )
                )
                try:
                    detail = await provider.get_match_detail(ext_id)
                    await _save_match_events(session, detail, ext_id)
                except Exception as e:
                    logger.debug("get_match_detail %s: %s", ext_id, e)
            await session.commit()

            if updated_ext_ids:
                await _broadcast_live_updates(session, updated_ext_ids)

        return {"live_count": len(matches), "cached": True}
    except Exception as e:
        logger.exception("sync_live_matches failed: %s", e)
        return {"live_count": 0, "error": str(e)}
    finally:
        await provider.close()


async def _broadcast_live_updates(session: AsyncSession, updated_ext_ids: list[int]) -> None:
    """
    Dopo commit: broadcast a ws/match/{id} (eventi partita) e ws/live/{league_id} (punteggi fantasy).
    """
    from app.api.websocket import broadcast_match_update, broadcast_live_update
    from app.services.scoring_engine import ScoringEngine

    r = await session.execute(
        select(Match.id, Match.matchday, Match.home_score, Match.away_score, Match.minute, Match.status).where(
            Match.external_id.in_(updated_ext_ids)
        )
    )
    updated_matches = r.all()
    if not updated_matches:
        return

    for row in updated_matches:
        match_id, matchday, home_score, away_score, minute, status = row
        events_r = await session.execute(
            select(MatchEvent.event_type, MatchEvent.minute).where(MatchEvent.match_id == match_id).order_by(MatchEvent.id)
        )
        events = [{"type": e, "minute": m} for e, m in events_r.all()]
        try:
            await broadcast_match_update(
                match_id,
                {
                    "type": "match_update",
                    "match_id": match_id,
                    "matchday": matchday,
                    "home_score": home_score,
                    "away_score": away_score,
                    "minute": minute,
                    "status": status or "IN_PLAY",
                    "events": events,
                },
            )
        except Exception as e:
            logger.debug("broadcast_match_update %s: %s", match_id, e)

    matchdays = {md for (_, md, *_) in updated_matches}
    cal_r = await session.execute(
        select(FantasyCalendar.league_id, FantasyCalendar.matchday).where(
            FantasyCalendar.matchday.in_(matchdays)
        ).distinct()
    )
    league_matchdays = cal_r.all()
    if not league_matchdays:
        return

    by_league: dict = defaultdict(list)
    for lid, md in league_matchdays:
        by_league[lid].append(md)

    engine = ScoringEngine(session)
    for league_id, mds in by_league.items():
        updates = []
        for md in mds:
            try:
                results = await engine.calculate_matchday_results(league_id, md)
                updates.append({
                    "matchday": md,
                    "results": [
                        {
                            "home_team_id": str(r.home_team_id),
                            "away_team_id": str(r.away_team_id),
                            "home_score": float(r.home_score),
                            "away_score": float(r.away_score),
                            "home_goals": r.home_goals,
                            "away_goals": r.away_goals,
                            "home_result": r.home_result,
                            "away_result": r.away_result,
                        }
                        for r in results
                    ],
                })
            except Exception as e:
                logger.debug("calculate_matchday_results league=%s matchday=%s: %s", league_id, md, e)
        if updates:
            try:
                await broadcast_live_update(
                    league_id,
                    {"type": "live_scores", "updates": updates},
                )
            except Exception as e:
                logger.debug("broadcast_live_update %s: %s", league_id, e)

    # Push: notifica utenti delle leghe con giornate aggiornate
    try:
        league_ids = list(by_league.keys())
        if league_ids:
            user_r = await session.execute(
                select(FantasyTeam.user_id).where(FantasyTeam.league_id.in_(league_ids)).distinct()
            )
            user_ids = [row[0] for row in user_r.all()]
            if user_ids:
                await send_push_to_users(session, user_ids, "Risultato aggiornato", "Controlla i punteggi della tua giornata!")
    except Exception as e:
        logger.debug("push live_scores: %s", e)


async def _save_match_events(session: AsyncSession, match_detail: dict, external_match_id: int) -> None:
    """Salva goal e altri eventi da get_match_detail. Trova match_id da external_id."""
    r = await session.execute(select(Match.id).where(Match.external_id == external_match_id))
    match_id = r.scalar_one_or_none()
    if not match_id:
        return

    goals = match_detail.get("goals") or []
    bookings = match_detail.get("bookings") or []
    for g in goals:
        minute = g.get("minute") or 0
        gtype = (g.get("type") or "REGULAR").upper()
        event_type = "OWN_GOAL" if "OWN" in gtype else ("PENALTY_SCORED" if "PENALTY" in gtype else "GOAL")
        session.add(MatchEvent(
            match_id=match_id,
            player_id=None,
            team_id=None,
            event_type=event_type,
            minute=minute,
            detail=g.get("type"),
        ))
    for b in bookings:
        minute = b.get("minute") or 0
        card = (b.get("card") or "YELLOW").upper()
        event_type = "RED_CARD" if card == "RED" else ("SECOND_YELLOW" if "YELLOW_RED" in card else "YELLOW_CARD")
        session.add(MatchEvent(
            match_id=match_id,
            player_id=None,
            team_id=None,
            event_type=event_type,
            minute=minute,
        ))


async def sync_match_events(match_id: int) -> int:
    """Scarica eventi (gol, cartellini) di una partita (match_id = nostro ID DB)."""
    from sqlalchemy import select
    async with AsyncSessionLocal() as session:
        r = await session.execute(select(Match.external_id).where(Match.id == match_id))
        ext_id = r.scalar_one_or_none()
    if not ext_id:
        logger.warning("sync_match_events: match_id %s not found", match_id)
        return 0
    provider = FootballDataOrgProvider(rate_limit=0)
    try:
        detail = await provider.get_match_detail(ext_id)
        async with AsyncSessionLocal() as session:
            await _save_match_events(session, detail, ext_id)
            await session.commit()
        return len(detail.get("goals") or []) + len(detail.get("bookings") or [])
    finally:
        await provider.close()
