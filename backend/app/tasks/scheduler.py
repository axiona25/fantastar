"""
Scheduler per sync periodici con APScheduler.
- Ogni 2 min: sync partite (sync_all_matches da football-data.org) — tutte le partite stagione/giornata
- Ogni 5 min: controlla partite live, se IN_PLAY attiva polling 60s
- Ogni 60s (solo durante partite live): sync live
- Ogni 10 min: sync classifica
- Ogni 15 min: sync news
- Ogni settimana: sync rose
"""
import logging
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.interval import IntervalTrigger
from apscheduler.triggers.cron import CronTrigger

from app.tasks.sync_standings import sync_standings
from app.tasks.sync_matches import sync_live_matches, sync_all_matches
from app.tasks.sync_news import sync_news
from app.tasks.sync_players import sync_all_players
from app.tasks.sync_availability import sync_availability_injuries, run_availability_after_matchday
from app.tasks.sync_commentary import sync_live_commentary

logger = logging.getLogger(__name__)

scheduler = AsyncIOScheduler()
_live_polling_job = None
_commentary_polling_job = None


async def _job_check_live():
    """Ogni 5 min: verifica se ci sono partite live; se sì attiva polling 60s."""
    global _live_polling_job
    try:
        from app.data_providers.football_data_org import FootballDataOrgProvider
        provider = FootballDataOrgProvider(rate_limit=0)
        try:
            data = await provider.get_live_matches()
            matches = data.get("matches") or []
            if matches:
                if _live_polling_job is None:
                    _live_polling_job = scheduler.add_job(
                        _job_sync_live,
                        IntervalTrigger(seconds=60),
                        id="sync_live",
                        replace_existing=True,
                    )
                    logger.info("Live matches detected, started 60s polling")
                if _commentary_polling_job is None:
                    _commentary_polling_job = scheduler.add_job(
                        _job_sync_commentary,
                        IntervalTrigger(minutes=2),
                        id="sync_commentary",
                        replace_existing=True,
                    )
                    logger.info("Live matches detected, started 2min commentary sync")
            else:
                if _live_polling_job is not None:
                    _live_polling_job.remove()
                    _live_polling_job = None
                    logger.info("No live matches, stopped 60s polling")
                if _commentary_polling_job is not None:
                    _commentary_polling_job.remove()
                    _commentary_polling_job = None
                    logger.info("No live matches, stopped commentary sync")
        finally:
            await provider.close()
    except Exception as e:
        logger.exception("_job_check_live: %s", e)


async def _job_sync_live():
    """Polling ogni 60s durante partite live."""
    try:
        await sync_live_matches()
    except Exception as e:
        logger.exception("_job_sync_live: %s", e)


async def _job_sync_commentary():
    """Ogni 2 min durante partite live: cronache + voti keyword + WebSocket."""
    try:
        await sync_live_commentary()
    except Exception as e:
        logger.exception("_job_sync_commentary: %s", e)


async def _job_sync_matches():
    """Ogni 2 min: sync tutte le partite da Football-Data.org (stagione/giornata corrente)."""
    try:
        await sync_all_matches()
    except Exception as e:
        logger.exception("_job_sync_matches: %s", e)


async def _job_sync_standings():
    try:
        await sync_standings()
    except Exception as e:
        logger.exception("_job_sync_standings: %s", e)


async def _job_sync_news():
    try:
        await sync_news()
    except Exception as e:
        logger.exception("_job_sync_news: %s", e)


async def _job_sync_rosters():
    try:
        await sync_all_players()
    except Exception as e:
        logger.exception("_job_sync_rosters: %s", e)


async def _job_sync_availability_injuries():
    try:
        await sync_availability_injuries()
    except Exception as e:
        logger.exception("_job_sync_availability_injuries: %s", e)


async def _job_availability_after_matchday():
    """Dopo ogni giornata: squalifiche da cartellini e scadenza squalifiche."""
    try:
        from app.database import AsyncSessionLocal
        from app.models.match import Match
        from sqlalchemy import select, func
        async with AsyncSessionLocal() as db:
            r = await db.execute(
                select(func.max(Match.matchday)).where(Match.status == "FINISHED")
            )
            max_matchday = r.scalar_one_or_none()
        if max_matchday:
            await run_availability_after_matchday(max_matchday)
    except Exception as e:
        logger.exception("_job_availability_after_matchday: %s", e)


async def _job_import_gazzetta_ratings():
    """Ogni 2 ore: importa voti Gazzetta per partite FINISHED da 2+ ore."""
    try:
        from app.database import AsyncSessionLocal
        from app.services.gazzetta_scraper import import_gazzetta_ratings_finished_matches
        async with AsyncSessionLocal() as db:
            result = await import_gazzetta_ratings_finished_matches(db)
        if result.get("updated"):
            logger.info("Gazzetta ratings imported: %s", result)
    except Exception as e:
        logger.exception("_job_import_gazzetta_ratings: %s", e)


def start_scheduler():
    """Avvia lo scheduler. Chiamare dopo startup app (es. lifespan)."""
    scheduler.add_job(_job_sync_matches, IntervalTrigger(minutes=2), id="sync_matches", replace_existing=True)
    scheduler.add_job(_job_check_live, IntervalTrigger(minutes=5), id="check_live", replace_existing=True)
    scheduler.add_job(_job_sync_standings, IntervalTrigger(minutes=10), id="sync_standings", replace_existing=True)
    scheduler.add_job(_job_sync_news, IntervalTrigger(minutes=15), id="sync_news", replace_existing=True)
    scheduler.add_job(_job_sync_rosters, CronTrigger(day_of_week="sun", hour=3, minute=0), id="sync_rosters", replace_existing=True)
    scheduler.add_job(_job_sync_availability_injuries, IntervalTrigger(hours=12), id="sync_availability_injuries", replace_existing=True)
    scheduler.add_job(_job_availability_after_matchday, IntervalTrigger(hours=6), id="availability_after_matchday", replace_existing=True)
    scheduler.add_job(_job_import_gazzetta_ratings, IntervalTrigger(hours=2), id="import_gazzetta_ratings", replace_existing=True)
    scheduler.start()
    logger.info("Scheduler started: sync_matches 2min, check_live 5min, standings 10min, news 15min, rosters weekly, availability 12h, suspensions 6h")


def stop_scheduler():
    scheduler.shutdown(wait=False)
