"""
Listone giocatori: filtri, paginazione, statistiche stagione aggregate.
Calcolo valore attuale da performance. Dettaglio giocatore con fallback TheSportsDB.
"""
import logging
from datetime import date, datetime
from decimal import Decimal
from typing import Any
from uuid import UUID

import httpx
from sqlalchemy import select, func, and_, or_, Integer, case
from sqlalchemy.ext.asyncio import AsyncSession

logger = logging.getLogger(__name__)

THESPORTSDB_SEARCH = "https://www.thesportsdb.com/api/v1/json/3/searchplayers.php"


def _team_match(our: str | None, their: str | None) -> bool:
    if not our or not their:
        return False
    a, b = our.strip().lower(), their.strip().lower()
    return a in b or b in a


async def _fetch_thesportsdb_details(player_name: str, team_name: str | None) -> dict[str, Any]:
    """Cerca giocatore su TheSportsDB e ritorna height, weight, description, birth_place, position_detail se trova match per squadra."""
    out = {}
    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            r = await client.get(THESPORTSDB_SEARCH, params={"p": player_name})
            r.raise_for_status()
            data = r.json()
        players = data.get("player") or []
        if not isinstance(players, list):
            players = []
        for p in players:
            if not _team_match(team_name, p.get("strTeam")):
                continue
            if p.get("strSport") != "Soccer":
                continue
            out["height"] = (p.get("strHeight") or "").strip() or None
            out["weight"] = (p.get("strWeight") or "").strip() or None
            out["birth_place"] = (p.get("strBirthLocation") or "").strip() or None
            out["position_detail"] = (p.get("strPosition") or "").strip() or None
            desc = (p.get("strDescriptionEN") or p.get("strDescriptionIT") or p.get("strDescriptionDE") or "").strip()
            out["description"] = desc or None
            break
    except Exception as e:
        logger.debug("TheSportsDB fetch for %s: %s", player_name, e)
    return out

from app.models.player import Player
from app.models.real_team import RealTeam
from app.models.player_stats import PlayerStats
from app.models.match import Match
from app.models.fantasy_roster import FantasyRoster
from app.models.fantasy_team import FantasyTeam
from app.models.fantasy_player_score import FantasyPlayerScore
from app.schemas.player_list import (
    PlayerSeasonStats,
    PlayerListResponse,
    PlayerDetailResponse,
    PlayerMatchStat,
    PlayerFantasyScore,
    NextMatch,
)


def calculate_current_value(
    initial_price: float,
    goals: int,
    assists: int,
    avg_fantasy: float | None,
    appearances: int,
    total_matches: int,
) -> float:
    """
    Valore attuale = prezzo_base * (1 + bonus_performance).
    Bonus: gol +2%, assist +1%; media fantasy > 7 +10%, > 9 +25%, < 4 -15%;
    presenze < 50% partite -10%.
    """
    base = float(initial_price)
    if base <= 0:
        return base
    bonus = 0.0
    bonus += goals * 0.02
    bonus += assists * 0.01
    if avg_fantasy is not None:
        if avg_fantasy >= 9:
            bonus += 0.25
        elif avg_fantasy >= 7:
            bonus += 0.10
        elif avg_fantasy < 4:
            bonus -= 0.15
    if total_matches and appearances < total_matches * 0.5:
        bonus -= 0.10
    return round(base * (1 + bonus), 2)


async def get_season_stats_for_players(
    db: AsyncSession, player_ids: list[int], season: str = "2025"
) -> dict[int, dict]:
    """Aggrega statistiche stagione da PlayerStats + Match (season)."""
    if not player_ids:
        return {}
    r = await db.execute(
        select(
            PlayerStats.player_id,
            func.count(PlayerStats.id).label("appearances"),
            func.coalesce(func.sum(PlayerStats.goals), 0).label("goals"),
            func.coalesce(func.sum(PlayerStats.assists), 0).label("assists"),
            func.coalesce(func.sum(PlayerStats.minutes_played), 0).label("minutes_played"),
            func.avg(PlayerStats.rating).label("avg_rating"),
            func.coalesce(func.sum(PlayerStats.expected_goals), 0).label("total_xg"),
            func.coalesce(func.sum(PlayerStats.expected_assists), 0).label("total_xa"),
            func.coalesce(func.sum(case((PlayerStats.clean_sheet == True, 1), else_=0)), 0).label("clean_sheets"),
        )
        .join(Match, PlayerStats.match_id == Match.id)
        .where(
            PlayerStats.player_id.in_(player_ids),
            Match.season == season,
        )
        .group_by(PlayerStats.player_id)
    )
    stats = {}
    for row in r.all():
        stats[row.player_id] = {
            "appearances": row.appearances or 0,
            "goals": row.goals or 0,
            "assists": row.assists or 0,
            "yellow_cards": 0,
            "red_cards": 0,
            "clean_sheets": row.clean_sheets or 0,
            "minutes_played": row.minutes_played or 0,
            "avg_rating": float(row.avg_rating) if row.avg_rating is not None else None,
            "total_xg": float(row.total_xg) if row.total_xg is not None else None,
            "total_xa": float(row.total_xa) if row.total_xa is not None else None,
        }
    return stats


async def get_players_paginated(
    db: AsyncSession,
    *,
    position: str | None = None,
    team_id: int | None = None,
    search: str | None = None,
    sort_by: str = "name",
    sort_order: str = "asc",
    min_price: float | None = None,
    max_price: float | None = None,
    available_only: bool = False,
    league_id: UUID | None = None,
    page: int = 1,
    page_size: int = 30,
    season: str = "2025",
) -> tuple[list[PlayerListResponse], int]:
    """Listone con filtri e paginazione. Ritorna (lista, total)."""
    q = select(Player).join(RealTeam, Player.real_team_id == RealTeam.id).where(Player.is_active == True)
    if position:
        q = q.where(Player.position == position.upper()[:3])
    if team_id:
        q = q.where(Player.real_team_id == team_id)
    if search:
        q = q.where(Player.name.ilike(f"%{search}%"))
    if min_price is not None:
        q = q.where(Player.initial_price >= Decimal(str(min_price)))
    if max_price is not None:
        q = q.where(Player.initial_price <= Decimal(str(max_price)))
    if available_only and league_id:
        sub = select(FantasyRoster.player_id).join(FantasyTeam, FantasyTeam.id == FantasyRoster.fantasy_team_id).where(
            FantasyTeam.league_id == league_id, FantasyRoster.is_active == True
        )
        q = q.where(Player.id.not_in(sub))
    count_q = select(func.count()).select_from(q.subquery())
    total = (await db.execute(count_q)).scalar() or 0
    order_col = getattr(Player, sort_by, Player.name)
    if sort_order.lower() == "desc":
        q = q.order_by(order_col.desc())
    else:
        q = q.order_by(order_col.asc())
    q = q.offset((page - 1) * page_size).limit(page_size)
    r = await db.execute(q)
    players = r.scalars().all()
    if not players:
        return [], total
    player_ids = [p.id for p in players]
    season_stats = await get_season_stats_for_players(db, player_ids, season)
    owned_in_league: dict[int, str] = {}
    if league_id:
        r2 = await db.execute(
            select(FantasyRoster.player_id, FantasyTeam.name)
            .join(FantasyTeam, FantasyTeam.id == FantasyRoster.fantasy_team_id)
            .where(
                FantasyTeam.league_id == league_id,
                FantasyRoster.is_active == True,
                FantasyRoster.player_id.in_(player_ids),
            )
        )
        for (pid, tname) in r2.all():
            owned_in_league[pid] = tname
    total_matches = 38
    r3 = await db.execute(select(func.count(func.distinct(Match.matchday))).where(Match.season == season))
    total_matches_val = r3.scalar_one_or_none()
    if total_matches_val is not None:
        total_matches = total_matches_val
    result = []
    for p in players:
        stats = season_stats.get(p.id) or {}
        avg_fantasy = None
        if stats.get("avg_rating") is not None:
            avg_fantasy = float(stats["avg_rating"])
        current_val = calculate_current_value(
            float(p.initial_price or 1),
            stats.get("goals", 0),
            stats.get("assists", 0),
            avg_fantasy,
            stats.get("appearances", 0),
            total_matches,
        )
        owned = owned_in_league.get(p.id)
        rt = await db.execute(select(RealTeam).where(RealTeam.id == p.real_team_id))
        real_team = rt.scalar_one_or_none()
        result.append(PlayerListResponse(
            id=p.id,
            name=p.name,
            first_name=p.first_name,
            last_name=p.last_name,
            position=p.position or "CEN",
            shirt_number=p.shirt_number,
            nationality=p.nationality,
            real_team_id=real_team.id if real_team else 0,
            real_team_name=real_team.name if real_team else "",
            real_team_short=real_team.short_name if real_team else None,
            real_team_badge=real_team.crest_url if real_team else None,
            photo_url=f"/static/{p.photo_local}" if p.photo_local else p.photo_url,
            cutout_url=f"/static/{p.cutout_local}" if p.cutout_local else p.cutout_url,
            initial_price=float(p.initial_price or 1),
            current_value=current_val,
            season_stats=PlayerSeasonStats(**stats) if stats else None,
            is_available=(owned is None),
            owned_by=owned,
        ))
    return result, total


async def get_player_detail(
    db: AsyncSession, player_id: int, league_id: UUID | None = None, season: str = "2025"
) -> PlayerDetailResponse | None:
    """Scheda completa giocatore: base + match_stats (ultime 10) + fantasy_scores + next_matches."""
    r = await db.execute(select(Player).where(Player.id == player_id))
    player = r.scalar_one_or_none()
    if not player:
        return None
    rt = await db.execute(select(RealTeam).where(RealTeam.id == player.real_team_id))
    real_team = rt.scalar_one_or_none()
    # Arricchisci da TheSportsDB se mancano height, weight, description, birth_place, position_detail
    need_fetch = not all([player.height, player.weight, player.description, player.birth_place, player.position_detail])
    if need_fetch and (player.name or "").strip():
        extra = await _fetch_thesportsdb_details(player.name.strip(), real_team.name if real_team else None)
        if extra:
            updated = False
            if extra.get("height") and not player.height:
                player.height = extra["height"][:50]
                updated = True
            if extra.get("weight") and not player.weight:
                player.weight = extra["weight"][:50]
                updated = True
            if extra.get("description") and not player.description:
                player.description = extra["description"][:10000]
                updated = True
            if extra.get("birth_place") and not player.birth_place:
                player.birth_place = extra["birth_place"][:200]
                updated = True
            if extra.get("position_detail") and not player.position_detail:
                player.position_detail = extra["position_detail"][:100]
                updated = True
            if updated:
                await db.commit()
                await db.refresh(player)
    season_stats_map = await get_season_stats_for_players(db, [player_id], season)
    stats = season_stats_map.get(player_id) or {}
    total_matches = 38
    rtm = await db.execute(select(func.count(func.distinct(Match.matchday))).where(Match.season == season))
    total_matches_val = rtm.scalar_one_or_none()
    if total_matches_val is not None:
        total_matches = total_matches_val
    avg_f = float(stats["avg_rating"]) if stats.get("avg_rating") is not None else None
    current_val = calculate_current_value(
        float(player.initial_price or 1), stats.get("goals", 0), stats.get("assists", 0),
        avg_f, stats.get("appearances", 0), total_matches,
    )
    owned_by = None
    if league_id:
        r_owned = await db.execute(
            select(FantasyTeam.name).join(FantasyRoster, FantasyRoster.fantasy_team_id == FantasyTeam.id).where(
                FantasyTeam.league_id == league_id, FantasyRoster.player_id == player_id, FantasyRoster.is_active == True
            )
        )
        owned_by = r_owned.scalar_one_or_none()
    base = PlayerListResponse(
        id=player.id,
        name=player.name,
        first_name=player.first_name,
        last_name=player.last_name,
        position=player.position or "CEN",
        shirt_number=player.shirt_number,
        nationality=player.nationality,
        real_team_id=real_team.id if real_team else 0,
        real_team_name=real_team.name if real_team else "",
        real_team_short=real_team.short_name if real_team else None,
        real_team_badge=real_team.crest_url if real_team else None,
        photo_url=f"/static/{player.photo_local}" if player.photo_local else player.photo_url,
        cutout_url=f"/static/{player.cutout_local}" if player.cutout_local else player.cutout_url,
        initial_price=float(player.initial_price or 1),
        current_value=current_val,
        season_stats=PlayerSeasonStats(**stats) if stats else None,
        is_available=(owned_by is None),
        owned_by=owned_by,
    )
    match_stats: list[PlayerMatchStat] = []
    r_match = await db.execute(
        select(PlayerStats, Match)
        .join(Match, PlayerStats.match_id == Match.id)
        .where(PlayerStats.player_id == player_id, Match.season == season)
        .order_by(Match.matchday.desc())
        .limit(10)
    )
    opponent_ids = set()
    rows_data = []
    for (ps, m) in r_match.all():
        opp_id = m.away_team_id if m.home_team_id == player.real_team_id else m.home_team_id
        opponent_ids.add(opp_id)
        rows_data.append((ps, m, opp_id))
    team_names = {}
    if opponent_ids:
        r_teams = await db.execute(select(RealTeam.id, RealTeam.name).where(RealTeam.id.in_(opponent_ids)))
        team_names = {row[0]: row[1] for row in r_teams.all()}
    for (ps, m, opp_id) in rows_data:
        match_stats.append(PlayerMatchStat(
            match_id=m.id,
            matchday=m.matchday,
            opponent=team_names.get(opp_id) or "",
            date=m.kick_off,
            minutes_played=ps.minutes_played or 0,
            goals=ps.goals or 0,
            assists=ps.assists or 0,
            rating=float(ps.rating) if ps.rating else None,
            xg=float(ps.expected_goals) if ps.expected_goals else None,
            xa=float(ps.expected_assists) if ps.expected_assists else None,
            key_passes=ps.key_passes,
        ))
    fantasy_scores: list[PlayerFantasyScore] = []
    r3 = await db.execute(
        select(FantasyPlayerScore.matchday, FantasyPlayerScore.total_score, FantasyPlayerScore.events_json)
        .where(FantasyPlayerScore.player_id == player_id)
        .order_by(FantasyPlayerScore.matchday.desc())
        .limit(30)
    )
    seen_matchdays = set()
    for row in r3.all():
        if row.matchday in seen_matchdays:
            continue
        seen_matchdays.add(row.matchday)
        events = (row.events_json or []) if isinstance(row.events_json, list) else []
        if isinstance(row.events_json, dict):
            events = list(row.events_json.keys()) if row.events_json else []
        fantasy_scores.append(PlayerFantasyScore(
            matchday=row.matchday,
            score=float(row.total_score or 0),
            events=[str(e) for e in events],
        ))
    next_matches: list[NextMatch] = []
    r4 = await db.execute(
        select(Match).where(
            or_(Match.home_team_id == player.real_team_id, Match.away_team_id == player.real_team_id),
            Match.season == season,
            Match.status.in_(["SCHEDULED", "TIMED"]),
        ).order_by(Match.matchday).limit(5)
    )
    matches_next = r4.scalars().all()
    opp_ids_next = set()
    for m in matches_next:
        oid = m.away_team_id if m.home_team_id == player.real_team_id else m.home_team_id
        opp_ids_next.add(oid)
    opp_teams_next = {}
    if opp_ids_next:
        r5 = await db.execute(select(RealTeam.id, RealTeam.name, RealTeam.crest_url).where(RealTeam.id.in_(opp_ids_next)))
        opp_teams_next = {row[0]: (row[1], row[2]) for row in r5.all()}
    for m in matches_next:
        oid = m.away_team_id if m.home_team_id == player.real_team_id else m.home_team_id
        opp_name, badge = opp_teams_next.get(oid, ("", None))
        home_away = "home" if m.home_team_id == player.real_team_id else "away"
        next_matches.append(NextMatch(
            matchday=m.matchday,
            opponent_name=opp_name or "",
            opponent_badge=badge,
            date=m.kick_off,
            home_away=home_away,
        ))
    # Età da date_of_birth
    age = None
    if player.date_of_birth:
        today = date.today()
        age = today.year - player.date_of_birth.year - ((today.month, today.day) < (player.date_of_birth.month, player.date_of_birth.day))
    date_of_birth_str = player.date_of_birth.isoformat() if player.date_of_birth else None

    return PlayerDetailResponse(
        **base.model_dump(),
        date_of_birth=date_of_birth_str,
        age=age,
        height=player.height,
        weight=player.weight,
        birth_place=player.birth_place,
        description=player.description,
        position_detail=player.position_detail,
        match_stats=match_stats,
        fantasy_scores=fantasy_scores,
        next_matches=next_matches,
    )
