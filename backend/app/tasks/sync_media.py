"""
Download stemmi, foto giocatori, e generazione avatar per mancanti.
Salva in /media/ e aggiorna path locale nel DB.
"""
import logging
import os
from pathlib import Path
from typing import Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import AsyncSessionLocal
from app.data_providers.football_data_org import FootballDataOrgProvider
from app.data_providers.thesportsdb import TheSportsDBProvider
from app.models.real_team import RealTeam
from app.models.player import Player
from app.config import settings

logger = logging.getLogger(__name__)

MEDIA_ROOT = Path(settings.MEDIA_ROOT).resolve() if (getattr(settings, "MEDIA_ROOT", None) and settings.MEDIA_ROOT) else (Path(__file__).resolve().parent.parent.parent.parent / "media")
BADGES_DIR = MEDIA_ROOT / "team_badges"
PHOTOS_DIR = MEDIA_ROOT / "player_photos"
AVATARS_DIR = MEDIA_ROOT / "avatars"


def _ensure_dirs():
    BADGES_DIR.mkdir(parents=True, exist_ok=True)
    PHOTOS_DIR.mkdir(parents=True, exist_ok=True)
    AVATARS_DIR.mkdir(parents=True, exist_ok=True)


async def download_all_badges() -> dict:
    """Scarica stemmi da Football-Data.org (crest) e opzionale TheSportsDB."""
    _ensure_dirs()
    provider_fd = FootballDataOrgProvider(rate_limit=0)
    provider_ts = TheSportsDBProvider(rate_limit=0.5)
    stats = {"downloaded": 0, "updated": 0, "errors": 0}
    try:
        data = await provider_fd.get_teams()
        teams = data.get("teams") or []
        async with AsyncSessionLocal() as session:
            for t in teams:
                ext_id = t.get("id")
                crest_url = t.get("crest")
                r = await session.execute(select(RealTeam).where(RealTeam.external_id == ext_id))
                row = r.scalar_one_or_none()
                if not row:
                    continue
                local_path = None
                if crest_url:
                    ext = "png" if "png" in crest_url.lower() else "jpg"
                    local_path = f"team_badges/{row.id}.{ext}"
                    full_path = MEDIA_ROOT / local_path
                    try:
                        async with provider_fd.client.stream("GET", crest_url) as resp:
                            resp.raise_for_status()
                            full_path.parent.mkdir(parents=True, exist_ok=True)
                            with open(full_path, "wb") as f:
                                async for chunk in resp.aiter_bytes():
                                    f.write(chunk)
                        row.crest_local = local_path
                        await session.flush()
                        stats["downloaded"] += 1
                    except Exception as e:
                        logger.debug("download badge %s: %s", crest_url, e)
                        stats["errors"] += 1
            await session.commit()
        logger.info("download_all_badges: %s", stats)
        return stats
    finally:
        await provider_fd.close()
        await provider_ts.close()


async def download_all_player_photos() -> dict:
    """Scarica foto cutout da TheSportsDB (dove disponibili)."""
    _ensure_dirs()
    provider_ts = TheSportsDBProvider(rate_limit=0.5)
    stats = {"downloaded": 0, "errors": 0}
    try:
        async with AsyncSessionLocal() as session:
            r = await session.execute(select(Player).where(Player.cutout_url.isnot(None)))
            players = r.scalars().all()
            for row in players:
                if not row.cutout_url or row.cutout_local:
                    continue
                local_path = f"player_photos/{row.id}.png"
                full_path = MEDIA_ROOT / local_path
                ok = await provider_ts.download_image(row.cutout_url, str(full_path))
                if ok:
                    row.cutout_local = local_path
                    stats["downloaded"] += 1
                else:
                    stats["errors"] += 1
            await session.commit()
        logger.info("download_all_player_photos: %s", stats)
        return stats
    finally:
        await provider_ts.close()


def _generate_avatar_image(name: str, path: str) -> bool:
    """Genera immagine con iniziali (PIL)."""
    try:
        from PIL import Image, ImageDraw, ImageFont
        initials = "".join((c[0] for c in name.split()[:2] if c)).upper()[:2] or "?"
        w, h = 64, 64
        img = Image.new("RGB", (w, h), color=(70, 70, 70))
        draw = ImageDraw.Draw(img)
        try:
            font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 24)
        except Exception:
            font = ImageFont.load_default()
        bbox = draw.textbbox((0, 0), initials, font=font)
        tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
        draw.text(((w - tw) / 2, (h - th) / 2 - 2), initials, fill=(220, 220, 220), font=font)
        Path(path).parent.mkdir(parents=True, exist_ok=True)
        img.save(path)
        return True
    except Exception as e:
        logger.debug("generate_avatar %s: %s", name, e)
        return False


async def generate_missing_avatars() -> dict:
    """Genera avatar con iniziali per giocatori senza foto."""
    _ensure_dirs()
    stats = {"generated": 0, "skipped": 0}
    async with AsyncSessionLocal() as session:
        r = await session.execute(select(Player))
        for row in r.scalars().all():
            if row.cutout_local or row.photo_local:
                stats["skipped"] += 1
                continue
            path = AVATARS_DIR / f"player_{row.id}.png"
            if path.exists():
                stats["skipped"] += 1
                continue
            if _generate_avatar_image(row.name, str(path)):
                row.photo_local = f"avatars/player_{row.id}.png"
                stats["generated"] += 1
        await session.commit()
    logger.info("generate_missing_avatars: %s", stats)
    return stats
