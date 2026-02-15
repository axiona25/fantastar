"""
Sync rose giocatori: scarica tutte le rose delle 20 squadre da Football-Data.org.
Usa POSITION_MAP per mappare i ruoli.
"""
import logging
from datetime import date
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import AsyncSessionLocal
from app.data_providers.football_data_org import FootballDataOrgProvider, POSITION_MAP
from app.models.real_team import RealTeam
from app.models.player import Player

logger = logging.getLogger(__name__)


def _parse_date(s: str | None) -> date | None:
    if not s:
        return None
    try:
        return date.fromisoformat(s[:10])
    except Exception:
        return None


def _map_position(api_position: str) -> str:
    """Mappa posizione API -> POR, DIF, CEN, ATT."""
    return POSITION_MAP.get(api_position, "CEN")


async def sync_all_players() -> dict:
    """Scarica tutte le rose delle 20 squadre (circa 656 giocatori)."""
    provider = FootballDataOrgProvider(rate_limit=0)
    stats = {"created": 0, "updated": 0, "skipped": 0}
    try:
        data = await provider.get_teams()
        teams_data = data.get("teams") or []
        async with AsyncSessionLocal() as session:
            for t in teams_data:
                ext_team_id = t.get("id")
                r = await session.execute(select(RealTeam.id).where(RealTeam.external_id == ext_team_id))
                real_team_id = r.scalar_one_or_none()
                if not real_team_id:
                    logger.warning("Team external_id %s not found in DB, skip squad", ext_team_id)
                    continue
                squad = t.get("squad") or []
                for p in squad:
                    ext_id = p.get("id")
                    if not ext_id:
                        continue
                    name = (p.get("name") or "").strip()
                    if not name:
                        stats["skipped"] += 1
                        continue
                    position = _map_position(p.get("position") or "")
                    shirt = p.get("shirtNumber")
                    dob = _parse_date(p.get("dateOfBirth"))
                    nationality = (p.get("nationality") or "")[:50]
                    existing = await session.execute(select(Player).where(Player.external_id == ext_id))
                    row = existing.scalar_one_or_none()
                    if row:
                        row.real_team_id = real_team_id
                        row.name = name
                        row.position = position
                        row.shirt_number = shirt
                        row.date_of_birth = dob
                        row.nationality = nationality or row.nationality
                        stats["updated"] += 1
                    else:
                        session.add(Player(
                            external_id=ext_id,
                            real_team_id=real_team_id,
                            name=name,
                            position=position,
                            shirt_number=shirt,
                            date_of_birth=dob,
                            nationality=nationality or None,
                            initial_price=Decimal("1"),
                        ))
                        stats["created"] += 1
            await session.commit()
        logger.info("sync_all_players: %s", stats)
        return stats
    except Exception as e:
        logger.exception("sync_all_players failed: %s", e)
        return stats
    finally:
        await provider.close()
