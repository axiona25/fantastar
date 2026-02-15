"""
Sync disponibilità giocatori: infortuni da TheSportsDB, squalifiche da cartellini.
Chiamato dallo scheduler (ogni 12h infortuni; dopo ogni giornata squalifiche).
"""
import logging
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import AsyncSessionLocal
from app.models.match import Match
from app.services.availability_service import AvailabilityService

logger = logging.getLogger(__name__)


async def sync_availability_injuries() -> int:
    """Sync infortuni da TheSportsDB (strInjured). Ritorna numero giocatori aggiornati."""
    async with AsyncSessionLocal() as db:
        service = AvailabilityService(db)
        try:
            count = await service.sync_injuries_from_api()
            logger.info("sync_availability_injuries: updated %s players", count)
            return count
        except Exception as e:
            logger.exception("sync_availability_injuries failed: %s", e)
            return 0


async def update_suspensions_after_matchday(matchday: int, season: str = "2025") -> int:
    """Calcola squalifiche dopo una giornata (rossi, doppio giallo, accumulo gialli)."""
    async with AsyncSessionLocal() as db:
        service = AvailabilityService(db)
        try:
            count = await service.update_suspensions_after_matchday(matchday, season)
            logger.info("update_suspensions_after_matchday(%s): created %s suspensions", matchday, count)
            return count
        except Exception as e:
            logger.exception("update_suspensions_after_matchday failed: %s", e)
            return 0


async def check_suspension_expiry(matchday: int, season: str = "2025") -> int:
    """Sblocca squalifiche scadute (matchday > matchday_to)."""
    async with AsyncSessionLocal() as db:
        service = AvailabilityService(db)
        try:
            count = await service.check_suspension_expiry(matchday, season)
            logger.info("check_suspension_expiry(%s): expired %s", matchday, count)
            return count
        except Exception as e:
            logger.exception("check_suspension_expiry failed: %s", e)
            return 0


async def run_availability_after_matchday(matchday: int, season: str = "2025") -> dict:
    """
    Esegui dopo che tutte le partite di una giornata sono FINISHED:
    1. Calcola squalifiche da cartellini
    2. Sblocca squalifiche scadute (per la prossima giornata)
    """
    s1 = await update_suspensions_after_matchday(matchday, season)
    s2 = await check_suspension_expiry(matchday + 1, season)
    return {"suspensions_created": s1, "suspensions_expired": s2}
