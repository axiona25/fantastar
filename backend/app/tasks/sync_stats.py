"""
Sync statistiche avanzate giocatori da BZZoiro dopo una partita.
"""
import logging
from decimal import Decimal
from typing import Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import AsyncSessionLocal
from app.data_providers.bzzoiro import BZZoiroProvider
from app.models.player_stats import PlayerStats
from app.models.match import Match
from app.models.player import Player

logger = logging.getLogger(__name__)


def _decimal(v) -> Optional[Decimal]:
    if v is None:
        return None
    try:
        return Decimal(str(v))
    except Exception:
        return None


async def sync_player_stats(match_id: Optional[int] = None, event_id: Optional[str] = None) -> dict:
    """
    Dopo una partita, scarica stat avanzate da BZZoiro e salva in player_stats.
    match_id = nostro ID DB; event_id = ID evento BZZoiro (se diverso).
    """
    provider = BZZoiroProvider(rate_limit=0)
    stats = {"upserted": 0, "errors": 0}
    try:
        data = await provider.get_player_stats(event_id=event_id)
        if not data or not isinstance(data, dict):
            return stats
        # Struttura API BZZoiro può variare: lista di stat per giocatore o per event
        records = data.get("player_stats") or data.get("stats") or data.get("results") or []
        if isinstance(data, list):
            records = data
        if not records:
            return stats

        async with AsyncSessionLocal() as session:
            for rec in records:
                try:
                    ext_player_id = rec.get("player_id") or rec.get("player") or rec.get("id")
                    ext_match_id = rec.get("event_id") or rec.get("match_id") or event_id
                    if not ext_player_id or not ext_match_id:
                        continue
                    # Risolvi player_id e match_id nostri
                    rp = await session.execute(select(Player.id).where(Player.external_id == int(ext_player_id)))
                    player_id = rp.scalar_one_or_none()
                    rm = await session.execute(select(Match.id).where(Match.external_id == int(ext_match_id)))
                    match_id_db = rm.scalar_one_or_none()
                    if not player_id or not match_id_db:
                        continue
                    # Upsert player_stats
                    existing = await session.execute(
                        select(PlayerStats).where(
                            PlayerStats.player_id == player_id,
                            PlayerStats.match_id == match_id_db,
                        )
                    )
                    ps = existing.scalar_one_or_none()
                    if not ps:
                        ps = PlayerStats(player_id=player_id, match_id=match_id_db)
                        session.add(ps)
                    ps.minutes_played = rec.get("minutes_played") or ps.minutes_played or 0
                    ps.rating = _decimal(rec.get("rating"))
                    ps.goals = rec.get("goals") or 0
                    ps.assists = rec.get("goal_assist") or rec.get("assists") or 0
                    ps.expected_goals = _decimal(rec.get("expected_goals"))
                    ps.expected_assists = _decimal(rec.get("expected_assists"))
                    ps.total_passes = rec.get("total_pass") or rec.get("total_passes") or 0
                    ps.accurate_passes = rec.get("accurate_pass") or rec.get("accurate_passes") or 0
                    ps.key_passes = rec.get("key_pass") or rec.get("key_passes") or 0
                    ps.saves = rec.get("saves") or 0
                    ps.clean_sheet = rec.get("clean_sheet") or False
                    stats["upserted"] += 1
                except Exception as e:
                    logger.debug("sync_player_stats row: %s", e)
                    stats["errors"] += 1
            await session.commit()
        logger.info("sync_player_stats: %s", stats)
        return stats
    except Exception as e:
        logger.exception("sync_player_stats failed: %s", e)
        stats["errors"] += 1
        return stats
    finally:
        await provider.close()
