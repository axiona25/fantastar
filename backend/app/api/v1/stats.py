"""API Statistiche aggregate: top marcatori, top fantasy, top assist, best value, classifica Serie A."""
from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select, func, desc
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.player import Player
from app.models.real_team import RealTeam
from app.models.player_stats import PlayerStats
from app.models.match import Match
from app.models.fantasy_player_score import FantasyPlayerScore
from app.utils.cache import cache_get
from app.tasks.sync_standings import CACHE_KEY_STANDINGS, sync_standings

router = APIRouter(prefix="/stats", tags=["stats"])


@router.get("/standings")
async def get_standings():
    """
    Classifica Serie A reale (da cache Redis, popolata da sync_standings).
    Ritorna: position, crest, team_name, points, won, draw, lost, goals_for, goals_against.
    """
    data = await cache_get(CACHE_KEY_STANDINGS)
    if not data:
        await sync_standings()
        data = await cache_get(CACHE_KEY_STANDINGS)
    if not data or "standings" not in data:
        return []
    tables = data.get("standings") or []
    for t in tables:
        if t.get("type") == "TOTAL" and "table" in t:
            return [
                {
                    "position": row.get("position"),
                    "crest": (row.get("team") or {}).get("crest"),
                    "team_name": (row.get("team") or {}).get("name") or "",
                    "points": row.get("points", 0),
                    "won": row.get("won", 0),
                    "draw": row.get("draw", 0),
                    "lost": row.get("lost", 0),
                    "goals_for": row.get("goalsFor", 0),
                    "goals_against": row.get("goalsAgainst", 0),
                }
                for row in t["table"]
            ]
    return []


@router.get("/top-scorers")
async def top_scorers(
    limit: int = Query(20, ge=1, le=100),
    position: str | None = Query(None),
    season: str = Query("2025"),
    db: Annotated[AsyncSession, Depends(get_db)] = None,
):
    """Top marcatori Serie A (aggregato da player_stats)."""
    goals_sum = func.coalesce(func.sum(PlayerStats.goals), 0)
    q = (
        select(Player.id, Player.name, Player.position, RealTeam.name.label("team_name"), goals_sum.label("goals"))
        .join(PlayerStats, PlayerStats.player_id == Player.id)
        .join(Match, PlayerStats.match_id == Match.id)
        .join(RealTeam, Player.real_team_id == RealTeam.id)
        .where(Match.season == season)
        .group_by(Player.id, Player.name, Player.position, RealTeam.name)
        .order_by(desc(goals_sum))
        .limit(limit)
    )
    if position:
        q = q.where(Player.position == position.upper()[:3])
    r = await db.execute(q)
    rows = r.all()
    return [{"player_id": row.id, "name": row.name, "position": row.position, "team_name": row.team_name, "goals": row.goals} for row in rows]


@router.get("/top-fantasy")
async def top_fantasy(
    limit: int = Query(20, ge=1, le=100),
    position: str | None = Query(None),
    min_appearances: int = Query(1, ge=0),
    db: Annotated[AsyncSession, Depends(get_db)] = None,
):
    """Top giocatori per punteggio fantasy medio (da fantasy_player_scores)."""
    sub = (
        select(
            FantasyPlayerScore.player_id,
            func.count(FantasyPlayerScore.matchday).label("appearances"),
            func.avg(FantasyPlayerScore.total_score).label("avg_score"),
        )
        .group_by(FantasyPlayerScore.player_id)
    )
    q = (
        select(Player.id, Player.name, Player.position, RealTeam.name.label("team_name"), sub.c.appearances, sub.c.avg_score)
        .join(sub, sub.c.player_id == Player.id)
        .join(RealTeam, Player.real_team_id == RealTeam.id)
        .where(sub.c.appearances >= min_appearances)
        .order_by(desc(sub.c.avg_score))
        .limit(limit)
    )
    if position:
        q = q.where(Player.position == position.upper()[:3])
    r = await db.execute(q)
    rows = r.all()
    return [{"player_id": row.id, "name": row.name, "position": row.position, "team_name": row.team_name, "appearances": row.appearances, "avg_fantasy_score": float(row.avg_score) if row.avg_score else 0} for row in rows]


@router.get("/top-assists")
async def top_assists(
    limit: int = Query(20, ge=1, le=100),
    position: str | None = Query(None),
    season: str = Query("2025"),
    db: Annotated[AsyncSession, Depends(get_db)] = None,
):
    """Top assistman (aggregato da player_stats)."""
    assists_sum = func.coalesce(func.sum(PlayerStats.assists), 0)
    q = (
        select(Player.id, Player.name, Player.position, RealTeam.name.label("team_name"), assists_sum.label("assists"))
        .join(PlayerStats, PlayerStats.player_id == Player.id)
        .join(Match, PlayerStats.match_id == Match.id)
        .join(RealTeam, Player.real_team_id == RealTeam.id)
        .where(Match.season == season)
        .group_by(Player.id, Player.name, Player.position, RealTeam.name)
        .order_by(desc(assists_sum))
        .limit(limit)
    )
    if position:
        q = q.where(Player.position == position.upper()[:3])
    r = await db.execute(q)
    rows = r.all()
    return [{"player_id": row.id, "name": row.name, "position": row.position, "team_name": row.team_name, "assists": row.assists} for row in rows]


@router.get("/best-value")
async def best_value(
    limit: int = Query(20, ge=1, le=100),
    position: str | None = Query(None),
    min_appearances: int = Query(1, ge=0),
    db: Annotated[AsyncSession, Depends(get_db)] = None,
):
    """Miglior rapporto punteggio fantasy / prezzo (avg_fantasy_score / initial_price * 100)."""
    sub = (
        select(
            FantasyPlayerScore.player_id,
            func.count(FantasyPlayerScore.matchday).label("appearances"),
            func.avg(FantasyPlayerScore.total_score).label("avg_score"),
        )
        .group_by(FantasyPlayerScore.player_id)
    )
    value_ratio_expr = sub.c.avg_score / func.nullif(Player.initial_price, 0) * 100
    q = (
        select(
            Player.id,
            Player.name,
            Player.position,
            RealTeam.name.label("team_name"),
            Player.initial_price,
            sub.c.avg_score,
            value_ratio_expr.label("value_ratio"),
        )
        .join(sub, sub.c.player_id == Player.id)
        .join(RealTeam, Player.real_team_id == RealTeam.id)
        .where(sub.c.appearances >= min_appearances, Player.initial_price > 0)
        .order_by(desc(value_ratio_expr))
        .limit(limit)
    )
    if position:
        q = q.where(Player.position == position.upper()[:3])
    r = await db.execute(q)
    rows = r.all()
    return [{"player_id": row.id, "name": row.name, "position": row.position, "team_name": row.team_name, "initial_price": float(row.initial_price), "avg_fantasy_score": float(row.avg_score) if row.avg_score else 0, "value_ratio": float(row.value_ratio) if row.value_ratio else 0} for row in rows]
