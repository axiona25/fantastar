"""
Redis cache helper. TTL in secondi.
Chiavi: standings:sa (5 min), live:matches (30 sec), roster:team_{id} (1 ora), news (15 min).
"""
import json
import logging
from typing import Any, Optional

from redis.asyncio import Redis
from app.config import settings

logger = logging.getLogger(__name__)

# TTL in secondi
TTL_STANDINGS = 300   # 5 min
TTL_LIVE_MATCHES = 30  # 30 sec
TTL_ROSTER = 3600      # 1 ora
TTL_NEWS = 900         # 15 min
TTL_MATCH_DETAIL = 120  # 2 min (dettaglio partita, refresh più spesso se IN_PLAY)

_redis: Optional[Redis] = None


async def get_redis() -> Redis:
    global _redis
    if _redis is None:
        _redis = Redis.from_url(settings.REDIS_URL, decode_responses=True)
    return _redis


async def cache_get(key: str) -> Optional[Any]:
    """Legge valore da Redis (stringa JSON decodificata)."""
    try:
        r = await get_redis()
        raw = await r.get(key)
        if raw is None:
            return None
        return json.loads(raw)
    except Exception as e:
        logger.warning("cache_get %s: %s", key, e)
        return None


async def cache_set(key: str, value: Any, ttl_seconds: int = 300) -> bool:
    """Scrive valore in Redis con TTL."""
    try:
        r = await get_redis()
        await r.set(key, json.dumps(value, default=str), ex=ttl_seconds)
        return True
    except Exception as e:
        logger.warning("cache_set %s: %s", key, e)
        return False


async def cache_delete(key: str) -> bool:
    try:
        r = await get_redis()
        await r.delete(key)
        return True
    except Exception as e:
        logger.warning("cache_delete %s: %s", key, e)
        return False


async def close_redis():
    global _redis
    if _redis:
        await _redis.aclose()
        _redis = None
