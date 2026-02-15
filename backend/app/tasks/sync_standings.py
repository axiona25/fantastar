"""
Sync classifica Serie A da Football-Data.org e salvataggio in Redis.
"""
import logging
from app.data_providers.football_data_org import FootballDataOrgProvider
from app.utils.cache import cache_set, TTL_STANDINGS

logger = logging.getLogger(__name__)

CACHE_KEY_STANDINGS = "standings:sa"


async def sync_standings() -> dict | None:
    """Aggiorna classifica Serie A e la salva in Redis (TTL 5 min)."""
    provider = FootballDataOrgProvider(rate_limit=0)
    try:
        data = await provider.get_standings()
        await cache_set(CACHE_KEY_STANDINGS, data, ttl_seconds=TTL_STANDINGS)
        logger.info("Standings synced and cached")
        return data
    except Exception as e:
        logger.exception("sync_standings failed: %s", e)
        return None
    finally:
        await provider.close()
