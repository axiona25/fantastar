#!/usr/bin/env python3
"""
Scarica le foto per i 31 giocatori senza foto locale.
Prova in ordine: 1) ESPN headshot (external_id), 2) TheSportsDB (search per nome).
Salva in static/photos/{id}.png e aggiorna il DB.

Eseguire: docker-compose exec backend python3 scripts/download_missing_photos.py
"""
from __future__ import annotations

import sys
import time
from pathlib import Path

backend_dir = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(backend_dir))

_root = backend_dir.parent
_env = _root / ".env"
if _env.exists():
    from dotenv import load_dotenv
    load_dotenv(_env)

import httpx

PHOTOS_DIR = backend_dir / "static" / "photos"
REQUEST_TIMEOUT = 10.0
SLEEP_BETWEEN_REQUESTS = 0.5
MIN_PHOTO_BYTES = 5000  # sotto questa soglia consideriamo placeholder

# ESPN headshot (external_id = espn_id)
ESPN_URL = "https://a.espn.com/combiner/i?img=/i/headshots/soccer/players/full/{espn_id}.png&w=350&h=254"
THESPORTSDB_SEARCH = "https://www.thesportsdb.com/api/v1/json/3/searchplayers.php"

# 31 giocatori senza foto (id, name, external_id)
MISSING_PLAYERS = [
    (10, "Cheveyo Balentien", 282945),
    (40, "Piergiorgio Bonanno", 291721),
    (93, "Evan N'Dicka", 526),
    (102, "Relja Obrić", 246518),
    (131, "Eivind Helland", 210842),
    (165, "Juan Martín Rodriguez", 260246),
    (167, "Othniel Raterink", 192169),
    (173, "Agustín Albarracín", 259979),
    (176, "Yael Trepy", 289719),
    (199, "Rendijs Mihelsons", 290183),
    (205, "Xheto Nuredini", 276932),
    (236, "Thomas Berenbruch", 271989),
    (259, "Issiaka Kamate", 190998),
    (270, "Stefano Turco", 261736),
    (329, "Gianluca Astaldi", 290120),
    (362, "Vanja Milinković-Savić", 2275),
    (401, "Juan Arizala", 202427),
    (407, "Thomas Kristensen", 151299),
    (437, "Ioan Vermeșan", 285610),
    (438, "Mel Akalé", 286779),
    (455, "Luca Monticelli", 228738),
    (492, "Gioele Zacchi", 176750),
    (493, "Lorenzo Nyarko", 288538),
    (496, "Pedro Felipe", 246656),
    (537, "Marius Mihai Marin", 56647),
    (540, "Brando Bettazzi", 286825),
    (546, "Rafiu Durosinmi", 216210),
    (567, "Zalán Kugyela", 290877),
    (573, "Adrien Tameze", 8438),
    (598, "Cristian Pehlivanov", 274043),
    (631, "Cristiano De Paoli", 284110),
]


def try_espn(client: httpx.Client, external_id: int) -> bytes | None:
    """Ritorna il contenuto dell'immagine se valida (200 e > MIN_PHOTO_BYTES), altrimenti None."""
    url = ESPN_URL.format(espn_id=external_id)
    try:
        r = client.get(url, timeout=REQUEST_TIMEOUT)
        if r.status_code != 200:
            return None
        if len(r.content) < MIN_PHOTO_BYTES:
            return None
        return r.content
    except Exception:
        return None


def try_thesportsdb(client: httpx.Client, player_name: str) -> tuple[bytes | None, bytes | None]:
    """
    Cerca il giocatore per nome. Ritorna (photo_bytes, cutout_bytes).
    photo da strThumb, cutout da strCutout; uno o entrambi possono essere None.
    """
    try:
        r = client.get(THESPORTSDB_SEARCH, params={"p": player_name}, timeout=REQUEST_TIMEOUT)
        if r.status_code != 200:
            return None, None
        data = r.json()
        players = data.get("player")
        if not players or not isinstance(players, list):
            return None, None
        p = players[0]
        if not isinstance(p, dict):
            return None, None
        thumb = (p.get("strThumb") or "").strip()
        cutout = (p.get("strCutout") or "").strip()
        photo_bytes = None
        cutout_bytes = None
        if thumb:
            time.sleep(SLEEP_BETWEEN_REQUESTS)
            r2 = client.get(thumb, timeout=REQUEST_TIMEOUT)
            if r2.status_code == 200 and len(r2.content) >= MIN_PHOTO_BYTES:
                photo_bytes = r2.content
        if cutout:
            time.sleep(SLEEP_BETWEEN_REQUESTS)
            r3 = client.get(cutout, timeout=REQUEST_TIMEOUT)
            if r3.status_code == 200 and len(r3.content) >= MIN_PHOTO_BYTES:
                cutout_bytes = r3.content
        return photo_bytes, cutout_bytes
    except Exception:
        return None, None


def main() -> None:
    PHOTOS_DIR.mkdir(parents=True, exist_ok=True)

    from app.config import settings
    from app.models.player import Player
    from sqlalchemy import create_engine, update
    from sqlalchemy.orm import Session

    sync_url = settings.DATABASE_URL
    if "+asyncpg" in sync_url:
        sync_url = sync_url.replace("postgresql+asyncpg://", "postgresql://")
    engine = create_engine(sync_url)

    downloaded = 0
    not_found: list[str] = []

    with httpx.Client(timeout=REQUEST_TIMEOUT) as client:
        for i, (pid, name, external_id) in enumerate(MISSING_PLAYERS):
            if i > 0:
                time.sleep(SLEEP_BETWEEN_REQUESTS)

            photo_path = PHOTOS_DIR / f"{pid}.png"
            cutout_path = PHOTOS_DIR / f"{pid}_cutout.png"
            photo_bytes: bytes | None = None
            cutout_bytes: bytes | None = None
            source = ""

            # FONTE 1 - ESPN
            photo_bytes = try_espn(client, external_id)
            if photo_bytes:
                source = "ESPN"
            else:
                time.sleep(SLEEP_BETWEEN_REQUESTS)
                # FONTE 2 - TheSportsDB
                photo_bytes, cutout_bytes = try_thesportsdb(client, name)
                if photo_bytes or cutout_bytes:
                    source = "TheSportsDB"

            if not photo_bytes and not cutout_bytes:
                print(f"❌ {name}: nessuna foto trovata")
                not_found.append(name)
                continue

            # Se abbiamo solo cutout, usalo anche come foto principale
            if not photo_bytes and cutout_bytes:
                photo_bytes = cutout_bytes
            if photo_bytes:
                photo_path.write_bytes(photo_bytes)
            if cutout_bytes:
                cutout_path.write_bytes(cutout_bytes)

            print(f"✅ {name}: scaricata da {source}")
            downloaded += 1

            # Aggiorna DB
            with Session(engine) as session:
                values = {
                    "photo_url": f"/static/photos/{pid}.png",
                    "photo_local": f"photos/{pid}.png",
                }
                if cutout_bytes:
                    values["cutout_url"] = f"/static/photos/{pid}_cutout.png"
                    values["cutout_local"] = f"photos/{pid}_cutout.png"
                session.execute(update(Player).where(Player.id == pid).values(**values))
                session.commit()

    print("\n--- Report ---")
    print(f"Scaricate: {downloaded}/31")
    print(f"Mancanti: {len(not_found)}/31")
    if not_found:
        for n in not_found:
            print(f"  - {n}")


if __name__ == "__main__":
    main()
