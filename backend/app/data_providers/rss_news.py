"""
Provider RSS News - Feed calcio italiano.
Usa feedparser. Feed testati e funzionanti.
Estrae image_url da media_content, media_thumbnail, enclosure, o prima <img> in summary/content.
Pulizia title/summary: rimozione tag HTML e HTML entities (clean_html).
"""
import asyncio
import logging
import re
from datetime import datetime
from typing import List, Dict, Any

import feedparser
from bs4 import BeautifulSoup

from app.utils.html_utils import clean_html

logger = logging.getLogger(__name__)

RSS_FEEDS = {
    "Gazzetta dello Sport": "https://www.gazzetta.it/rss/calcio.xml",
    "Corriere dello Sport": "https://www.corrieredellosport.it/rss/calcio",
    "Tuttosport": "https://www.tuttosport.com/rss/calcio",
    "Calciomercato.com": "https://www.calciomercato.com/feed",
    "Fantacalcio.it": "https://www.fantacalcio.it/rss",
    "Sky Sport Calcio": "https://sport.sky.it/rss/sport/calcio.xml",
}


def _image_from_html(html: str) -> str | None:
    """Estrae URL della prima <img> dal testo HTML (summary/content)."""
    if not html or not html.strip():
        return None
    try:
        soup = BeautifulSoup(html, "lxml")
        img = soup.find("img", src=True)
        if img and img.get("src"):
            return (img["src"] or "").strip() or None
    except Exception:
        pass
    # Fallback regex
    m = re.search(r'<img[^>]+src=["\']([^"\']+)["\']', html, re.I)
    return m.group(1).strip() if m else None


def _extract_image_url(entry) -> str | None:
    """
    Cerca immagine nell'entry in ordine:
    - media_content[0]['url'] (media:content)
    - media_thumbnail[0]['url'] (media:thumbnail)
    - enclosures[0]['href'] (enclosure)
    - prima <img> in summary o content
    """
    # media:content
    media_content = getattr(entry, "media_content", None)
    if media_content and len(media_content):
        first = media_content[0]
        url = first.get("url") if isinstance(first, dict) else getattr(first, "url", None) or getattr(first, "href", None)
        if url and str(url).strip().startswith("http"):
            return str(url).strip()

    # media:thumbnail
    media_thumbnail = getattr(entry, "media_thumbnail", None)
    if media_thumbnail and len(media_thumbnail):
        first = media_thumbnail[0]
        url = first.get("url") if isinstance(first, dict) else getattr(first, "url", None)
        if url and str(url).strip().startswith("http"):
            return str(url).strip()

    # enclosure
    enclosures = getattr(entry, "enclosures", None)
    if enclosures and len(enclosures):
        first = enclosures[0]
        href = first.get("href") if isinstance(first, dict) else getattr(first, "href", None)
        if href and str(href).strip().startswith("http"):
            return str(href).strip()

    # prima <img> in summary o content
    summary = getattr(entry, "summary", "") or getattr(entry, "description", "") or ""
    if summary:
        url = _image_from_html(summary)
        if url and url.strip():
            return url.strip()
    content = getattr(entry, "content", None)
    if content and len(content):
        val = content[0].get("value") if isinstance(content[0], dict) else getattr(content[0], "value", "")
        if val:
            url = _image_from_html(val)
            if url and url.startswith("http"):
                return url

    return None


def _parse_entry(entry, source: str) -> Dict[str, Any]:
    """Normalizza una entry feed in formato comune. Pulisce title e summary da tag HTML."""
    published = None
    if hasattr(entry, "published_parsed") and entry.published_parsed:
        try:
            published = datetime(*entry.published_parsed[:6])
        except Exception:
            pass
    image_url = _extract_image_url(entry)
    raw_title = getattr(entry, "title", "") or ""
    raw_summary = getattr(entry, "summary", "") or getattr(entry, "description", "") or ""
    return {
        "title": clean_html(raw_title),
        "summary": clean_html(raw_summary),
        "url": getattr(entry, "link", "") or "",
        "source": source,
        "image_url": image_url,
        "published_at": published,
    }


async def fetch_feed(url: str, source: str = "") -> List[Dict[str, Any]]:
    """Scarica e parsa un singolo feed RSS."""
    loop = asyncio.get_event_loop()
    try:
        parsed = await loop.run_in_executor(None, lambda: feedparser.parse(url))
        if parsed.bozo and not getattr(parsed, "entries", None):
            logger.warning(f"RSS feed parse error or empty: {url}")
            return []
        return [_parse_entry(e, source or url) for e in parsed.get("entries", [])]
    except Exception as e:
        logger.warning(f"RSS fetch failed {url}: {e}")
        return []


async def fetch_all_feeds() -> List[Dict[str, Any]]:
    """Scarica tutti i feed configurati e ritorna articoli normalizzati."""
    tasks = [fetch_feed(url, name) for name, url in RSS_FEEDS.items()]
    results = await asyncio.gather(*tasks, return_exceptions=True)
    articles = []
    for i, r in enumerate(results):
        if isinstance(r, Exception):
            logger.warning(f"Feed {list(RSS_FEEDS.keys())[i]} failed: {r}")
            continue
        articles.extend(r)
    # Ordina per data pubblicazione (più recenti prima)
    articles.sort(key=lambda a: a.get("published_at") or datetime.min, reverse=True)
    return articles
