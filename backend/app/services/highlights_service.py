"""
Highlights video: prima ScoreBat (gratuito), se vuoto e YOUTUBE_API_KEY impostata → YouTube Data API v3.
Cache risultati per match: 2 ore.
"""
import logging
import time
from typing import Any

import httpx
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.match import Match
from app.models.real_team import RealTeam

logger = logging.getLogger(__name__)

SCOREBAT_FEED_URL = "https://www.scorebat.com/video-api/v1/"
FEED_CACHE_TTL_SECONDS = 30 * 60  # 30 minuti
_feed_cache: tuple[float, list[dict[str, Any]]] | None = None

# Cache risultati combinati (ScoreBat + eventuale YouTube) per match_id, TTL 2 ore
_HIGHLIGHTS_CACHE_TTL_SECONDS = 2 * 60 * 60
_highlights_cache: dict[int, tuple[float, list[dict[str, Any]]]] = {}


def _normalize_team(name: str | None) -> str:
    """Stessa logica di ESPN: rimuove prefissi/suffissi per matching."""
    if name is None or not isinstance(name, str):
        return ""
    name = name.lower().strip()
    for prefix in (
        "ac ",
        "fc ",
        "us ",
        "ss ",
        "ssc ",
        "afc ",
        "as ",
        "acf ",
        "ssd ",
        "usc ",
    ):
        if name.startswith(prefix):
            name = name[len(prefix) :]
    for suffix in (
        " fc",
        " ac",
        " calcio",
        " 1909",
        " 1907",
        " 1913",
        " 1899",
        " bc",
    ):
        if name.endswith(suffix):
            name = name[: -len(suffix)]
    return name.strip()


def _names_match(name_a: str, name_b: str) -> bool:
    """True se i due nomi squadra coincidono dopo normalizzazione (come ESPN)."""
    a = _normalize_team(name_a)
    b = _normalize_team(name_b)
    if not a or not b:
        return False
    if a == b:
        return True
    if a in b or b in a:
        return True
    a_first = (a.split() or [""])[0]
    b_first = (b.split() or [""])[0]
    if a_first and b_first and a_first == b_first:
        return True
    return False


def _competition_is_serie_a_or_italy(competition: Any) -> bool:
    """True se competition.name contiene 'Serie A' o 'Italy' (case-insensitive)."""
    if competition is None:
        return False
    if isinstance(competition, dict):
        name = (competition.get("name") or competition.get("label") or "") or ""
    else:
        name = str(competition)
    name = name.lower()
    return "serie a" in name or "italy" in name or "italia" in name


def _teams_match_item(
    item: dict[str, Any],
    home_name: str,
    away_name: str,
) -> bool:
    """True se side1/side2 (in qualsiasi ordine) corrispondono a home_name e away_name."""
    side1 = item.get("side1") or {}
    side2 = item.get("side2") or {}
    if isinstance(side1, dict):
        side1_name = (side1.get("name") or "") or ""
    else:
        side1_name = str(side1)
    if isinstance(side2, dict):
        side2_name = (side2.get("name") or "") or ""
    else:
        side2_name = str(side2)
    # (home, away) vs (side1, side2) oppure (side1, side2) vs (away, home)
    if _names_match(home_name, side1_name) and _names_match(away_name, side2_name):
        return True
    if _names_match(home_name, side2_name) and _names_match(away_name, side1_name):
        return True
    return False


async def _get_cached_feed() -> list[dict[str, Any]]:
    """Scarica il feed ScoreBat v1 e lo mette in cache per 30 minuti."""
    global _feed_cache
    now = time.time()
    if _feed_cache is not None:
        ts, data = _feed_cache
        if now - ts < FEED_CACHE_TTL_SECONDS:
            return data
    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            resp = await client.get(SCOREBAT_FEED_URL)
            resp.raise_for_status()
            data = resp.json()
    except Exception as e:
        logger.warning("ScoreBat feed %s: %s", SCOREBAT_FEED_URL, e)
        if _feed_cache is not None:
            _, data = _feed_cache
            return data
        return []
    if not isinstance(data, list):
        data = data.get("response", data.get("data", [])) if isinstance(data, dict) else []
    _feed_cache = (now, data)
    return data


async def _get_scorebat_highlights(
    home_name: str,
    away_name: str,
) -> list[dict[str, Any]]:
    """Ritorna highlight da ScoreBat per le squadre date."""
    feed = await _get_cached_feed()
    out: list[dict[str, Any]] = []
    for item in feed:
        if not isinstance(item, dict):
            continue
        if not _competition_is_serie_a_or_italy(item.get("competition")):
            continue
        if not _teams_match_item(item, home_name, away_name):
            continue
        thumbnail = item.get("thumbnail") or ""
        if isinstance(thumbnail, dict):
            thumbnail = thumbnail.get("url") or thumbnail.get("src") or ""
        thumbnail = (thumbnail or "").strip()
        videos = item.get("videos") or []
        if not isinstance(videos, list):
            continue
        # URL pagina ScoreBat (item o video)
        item_url = (item.get("url") or item.get("matchviewUrl") or "").strip()
        for v in videos:
            if not isinstance(v, dict):
                continue
            embed = v.get("embed") or v.get("embedHtml") or ""
            title = (v.get("title") or "Highlights").strip()
            if not embed and not title:
                continue
            watch_url = (v.get("url") or item_url or "").strip()
            out.append({
                "title": title,
                "embed": (embed or "").strip(),
                "thumbnail": thumbnail,
                "competition": "",
                "matchviewUrl": item_url,
                "video_id": None,
                "embed_url": None,
                "watch_url": watch_url or item_url,
                "source": "ScoreBat",
            })
    return out


async def get_highlights_for_match(match_id: int, db: AsyncSession) -> list[dict[str, Any]]:
    """
    Ritorna lista di highlight per la partita.
    1) Cerca in ScoreBat (gratuito).
    2) Se ScoreBat vuoto e YOUTUBE_API_KEY configurata, cerca su YouTube.
    3) Cache risultati per 2 ore.
    """
    now = time.time()
    if match_id in _highlights_cache:
        ts, cached = _highlights_cache[match_id]
        if now - ts < _HIGHLIGHTS_CACHE_TTL_SECONDS:
            return cached

    row = (
        await db.execute(
            select(
                Match.home_team_id,
                Match.away_team_id,
                Match.kick_off,
            ).where(Match.id == match_id)
        )
    ).one_or_none()
    if not row:
        return []

    home_team_id, away_team_id, kick_off = row.home_team_id, row.away_team_id, row.kick_off
    home_name = ""
    away_name = ""
    if home_team_id:
        r = await db.execute(select(RealTeam.name).where(RealTeam.id == home_team_id))
        home_name = (r.scalar_one_or_none() or "") or ""
    if away_team_id:
        r = await db.execute(select(RealTeam.name).where(RealTeam.id == away_team_id))
        away_name = (r.scalar_one_or_none() or "") or ""

    out = await _get_scorebat_highlights(home_name, away_name)

    if not out:
        from app.services.youtube_highlights_provider import search_highlights

        yt_list = await search_highlights(home_name, away_name, kick_off)
        for y in yt_list:
            video_id = y.get("video_id")
            out.append({
                "title": y.get("title", ""),
                "embed": y.get("embed", ""),
                "thumbnail": y.get("thumbnail", ""),
                "competition": y.get("competition", ""),
                "matchviewUrl": y.get("matchviewUrl", ""),
                "video_id": video_id,
                "embed_url": y.get("embed_url"),
                "watch_url": f"https://www.youtube.com/watch?v={video_id}" if video_id else "",
                "source": y.get("channel", ""),
            })

    _highlights_cache[match_id] = (now, out)
    return out
