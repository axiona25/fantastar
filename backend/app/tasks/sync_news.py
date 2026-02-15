"""
Sync news da feed RSS e salvataggio in news_articles.
Pulizia summary: rimuove tag tipo {rsn-live-v2}, decodifica HTML entities.
"""
import html
import logging
import re
from datetime import datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import AsyncSessionLocal
from app.data_providers.rss_news import fetch_all_feeds
from app.models.news_article import NewsArticle
from app.utils.cache import cache_set, TTL_NEWS

logger = logging.getLogger(__name__)

CACHE_KEY_NEWS = "news:list"


def _clean_summary(text: str | None) -> str | None:
    """
    Pulisce il summary: rimuove contenuto tra { }, decodifica HTML entities.
    Se dopo la pulizia è vuoto, ritorna None.
    """
    if not text or not isinstance(text, str):
        return None
    s = text.strip()
    if not s:
        return None
    # Rimuovi tutto ciò che è tra { } (es. {rsn-live-v2})
    s = re.sub(r"\{[^{}]*\}", "", s)
    # Decodifica HTML entities (&#8217; → ', &amp; → &, ecc.)
    s = html.unescape(s)
    s = s.strip()
    return s if s else None


async def sync_news() -> dict:
    """Fetch tutti i feed RSS e salva in news_articles (upsert by url)."""
    stats = {"inserted": 0, "updated": 0, "cached": False}
    try:
        articles = await fetch_all_feeds()
        await cache_set(CACHE_KEY_NEWS, [{"title": a.get("title"), "url": a.get("url"), "source": a.get("source")} for a in articles[:50]], ttl_seconds=TTL_NEWS)
        stats["cached"] = True

        skip_keywords = ["liveblog", "live blog", "rsn-live"]

        async with AsyncSessionLocal() as session:
            for a in articles:
                url = (a.get("url") or "").strip()
                if not url:
                    continue
                title = (a.get("title") or "").strip()
                if any(kw in title.lower() for kw in skip_keywords):
                    continue
                summary_raw = a.get("summary") or ""
                summary_clean = _clean_summary(summary_raw)
                if not summary_clean or not summary_clean.strip():
                    continue
                existing = await session.execute(select(NewsArticle).where(NewsArticle.url == url))
                row = existing.scalar_one_or_none()
                pub = a.get("published_at")
                if isinstance(pub, datetime):
                    pass
                elif pub and hasattr(pub, "isoformat"):
                    pass
                else:
                    pub = None

                if row:
                    row.title = (a.get("title") or row.title)[:500]
                    row.summary = summary_clean
                    row.source = (a.get("source") or row.source)[:100] if a.get("source") else row.source
                    row.image_url = (a.get("image_url") or row.image_url)[:1000] if a.get("image_url") else row.image_url
                    row.published_at = pub or row.published_at
                    stats["updated"] += 1
                else:
                    session.add(NewsArticle(
                        title=(a.get("title") or "")[:500],
                        summary=summary_clean,
                        url=url[:1000],
                        source=(a.get("source") or "")[:100] or None,
                        image_url=(a.get("image_url") or "")[:1000] or None,
                        published_at=pub,
                    ))
                    stats["inserted"] += 1
            await session.commit()
        logger.info("sync_news: %s", stats)
        return stats
    except Exception as e:
        logger.exception("sync_news failed: %s", e)
        return stats
