"""
Highlights video da YouTube Data API v3.
Cerca video "home_team away_team highlights Serie A" con publishedAfter = kick_off, duration medium (4-20 min).
"""
import logging
import os
from datetime import datetime
from typing import Any

import httpx

logger = logging.getLogger(__name__)

YOUTUBE_API_KEY = os.getenv("YOUTUBE_API_KEY")
YOUTUBE_SEARCH_URL = "https://www.googleapis.com/youtube/v3/search"


def _rfc3339(d: datetime) -> str:
    """Formato RFC 3339 per publishedAfter (YouTube richiede Z/UTC)."""
    return d.strftime("%Y-%m-%dT%H:%M:%SZ")


async def search_highlights(
    home_team: str,
    away_team: str,
    kick_off: datetime | None = None,
) -> list[dict[str, Any]]:
    """
    Cerca highlights su YouTube per la partita.
    Ritorna lista con: title, thumbnail, video_id, embed_url, channel, published_at.
    """
    if not YOUTUBE_API_KEY or not YOUTUBE_API_KEY.strip():
        return []

    query = f"{home_team} {away_team} highlights Serie A"
    params: dict[str, Any] = {
        "part": "snippet",
        "q": query,
        "type": "video",
        "maxResults": 5,
        "order": "date",
        "key": YOUTUBE_API_KEY.strip(),
        "videoDuration": "medium",  # 4-20 min (highlights tipici)
    }
    if kick_off is not None:
        params["publishedAfter"] = _rfc3339(kick_off)

    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            r = await client.get(YOUTUBE_SEARCH_URL, params=params)
            r.raise_for_status()
            data = r.json()
    except Exception as e:
        logger.warning("YouTube search highlights %s: %s", query[:50], e)
        return []

    results: list[dict[str, Any]] = []
    for item in data.get("items", []):
        vid = item.get("id")
        if not isinstance(vid, dict) or vid.get("kind") != "youtube#video":
            continue
        video_id = vid.get("videoId")
        if not video_id:
            continue
        snippet = item.get("snippet") or {}
        thumbnails = snippet.get("thumbnails") or {}
        thumb = thumbnails.get("high") or thumbnails.get("medium") or thumbnails.get("default") or {}
        thumbnail_url = thumb.get("url") if isinstance(thumb, dict) else ""
        channel = (snippet.get("channelTitle") or "").strip()
        results.append({
            "title": (snippet.get("title") or "Highlights").strip(),
            "thumbnail": thumbnail_url or "",
            "video_id": video_id,
            "embed_url": f"https://www.youtube.com/embed/{video_id}",
            "channel": channel,
            "published_at": (snippet.get("publishedAt") or "").strip(),
            "embed": "",
            "competition": "",
            "matchviewUrl": "",
        })
    return results
