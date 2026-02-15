#!/usr/bin/env python3
"""
Aggiorna photo_url e cutout_url (e photo_local, cutout_local) per i giocatori
in base ai file presenti in backend/static/photos/.

Le foto sono già nominate con l'ID del giocatore: {id}.png e {id}_cutout.png.
- Se esiste photos/{id}.png → photo_url = '/static/photos/{id}.png'
- Se esiste photos/{id}_cutout.png → cutout_url = '/static/photos/{id}_cutout.png'
- Se non esiste la foto locale, photo_url resta invariato (URL remoto TheSportsDB come fallback).

Uso: python scripts/map_player_photos.py
      docker-compose exec backend python scripts/map_player_photos.py
"""
from __future__ import annotations

import asyncio
import logging
import sys
from pathlib import Path

backend_dir = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(backend_dir))

_root = backend_dir.parent
_env = _root / ".env"
if _env.exists():
    from dotenv import load_dotenv
    load_dotenv(_env)

logging.basicConfig(level=logging.INFO, format="%(message)s")
logger = logging.getLogger(__name__)

PHOTOS_DIR = backend_dir / "static" / "photos"


async def main() -> None:
    if not PHOTOS_DIR.exists():
        logger.error("Cartella non trovata: %s", PHOTOS_DIR)
        sys.exit(1)

    from app.database import AsyncSessionLocal
    from app.models.player import Player
    from sqlalchemy import select, update

    async with AsyncSessionLocal() as session:
        r = await session.execute(select(Player.id))
        player_ids = [row[0] for row in r.all()]

    total = len(player_ids)
    local_photo_count = 0
    cutout_count = 0
    updates_photo: list[tuple[int, str]] = []
    updates_cutout: list[tuple[int, str]] = []

    for pid in player_ids:
        photo_path = PHOTOS_DIR / f"{pid}.png"
        cutout_path = PHOTOS_DIR / f"{pid}_cutout.png"
        if photo_path.is_file():
            local_photo_count += 1
            updates_photo.append((pid, f"/static/photos/{pid}.png"))
        if cutout_path.is_file():
            cutout_count += 1
            updates_cutout.append((pid, f"/static/photos/{pid}_cutout.png"))

    async with AsyncSessionLocal() as session:
        for pid, url in updates_photo:
            await session.execute(
                update(Player)
                .where(Player.id == pid)
                .values(
                    photo_url=url,
                    photo_local=f"photos/{pid}.png",
                )
            )
        for pid, url in updates_cutout:
            await session.execute(
                update(Player)
                .where(Player.id == pid)
                .values(
                    cutout_url=url,
                    cutout_local=f"photos/{pid}_cutout.png",
                )
            )
        await session.commit()

    without_local = total - local_photo_count
    logger.info("--- Report ---")
    logger.info("Foto locali trovate: %d/%d", local_photo_count, total)
    logger.info("Cutout trovati: %d/%d", cutout_count, total)
    logger.info("Giocatori senza foto locale (useranno URL remoto): %d", without_local)


if __name__ == "__main__":
    asyncio.run(main())
