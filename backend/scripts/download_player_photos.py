#!/usr/bin/env python3
"""
Scarica foto giocatori da TheSportsDB (searchplayers): strThumb → photo, strCutout → cutout.
Filtra risultati per SQUADRA (nome squadra nel nostro DB vs strTeam su TheSportsDB) per evitare
foto sbagliate su nomi simili. Salva thesportsdb_id nel DB.

Uso:
  1. Reset foto esistenti (opzionale): python scripts/download_player_photos.py --reset
  2. Download: python scripts/download_player_photos.py

Eseguire: docker-compose exec backend python scripts/download_player_photos.py [--reset]
"""
import argparse
import asyncio
import logging
import re
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

# TheSportsDB free API (no key required, "3" is the public key). ToS: rispettare rate limit.
SEARCH_URL = "https://www.thesportsdb.com/api/v1/json/3/searchplayers.php"
RATE_LIMIT_SEC = 1.0  # 1 richiesta al secondo (ToS)


def _normalize_team_name(s: str | None) -> str:
    if not s:
        return ""
    return re.sub(r"\s+", " ", s.strip().lower())


def _team_match(our_team: str | None, result_team: str | None) -> bool:
    """Confronto fuzzy: 'Juventus' match 'Juventus FC' (partial match, case-insensitive)."""
    if not our_team or not result_team:
        return False
    a = _normalize_team_name(our_team)
    b = _normalize_team_name(result_team)
    if not a or not b:
        return False
    return a in b or b in a or a == b


def _normalize_for_comparison(s: str | None) -> str:
    """Per confronto nazionalità / nome: strip e lower."""
    if not s:
        return ""
    return re.sub(r"\s+", " ", s.strip().lower())


def _date_match(our_date, result_date_str: str | None) -> bool:
    """Confronta data nascita (our_date = date object, result_date_str = 'YYYY-MM-DD' o simile)."""
    if not our_date or not result_date_str:
        return False
    try:
        from datetime import datetime
        parsed = datetime.strptime(result_date_str.strip()[:10], "%Y-%m-%d").date()
        return our_date == parsed
    except Exception:
        return False


async def fetch_player_search(player_name: str) -> dict:
    """GET searchplayers.php?p=name, ritorna il JSON."""
    import httpx
    async with httpx.AsyncClient(timeout=30.0) as client:
        r = await client.get(SEARCH_URL, params={"p": player_name})
        r.raise_for_status()
        return r.json()


async def download_image(url: str, path: Path) -> bool:
    """Scarica URL e salva in path."""
    if not url or not url.strip():
        return False
    try:
        import httpx
        path.parent.mkdir(parents=True, exist_ok=True)
        async with httpx.AsyncClient(timeout=30.0) as client:
            r = await client.get(url)
            r.raise_for_status()
            path.write_bytes(r.content)
        return True
    except Exception as e:
        logger.debug("Download failed %s -> %s: %s", url, path, e)
        return False


def _choose_best_match(candidates: list[dict], player_team: str | None, player_nationality: str | None, player_dob) -> dict | None:
    """
    Tra i risultati che matchano la squadra, scegli il migliore:
    (a) stessa squadra (già filtrati), (b) stessa nazionalità, (c) stessa data di nascita.
    """
    if not candidates:
        return None
    if len(candidates) == 1:
        return candidates[0]

    def score(p: dict) -> int:
        s = 0
        if player_nationality and _normalize_for_comparison(p.get("strNationality")) == _normalize_for_comparison(player_nationality):
            s += 2
        if _date_match(player_dob, p.get("dateBorn")):
            s += 1
        return s

    return max(candidates, key=score)


async def reset_photos(session) -> int:
    """Resetta photo_url, photo_local, cutout_url, cutout_local per tutti i giocatori che hanno photo_local. Ritorna numero di righe aggiornate."""
    from sqlalchemy import update
    from app.models.player import Player
    r = await session.execute(
        update(Player).where(Player.photo_local.isnot(None)).values(
            photo_url=None,
            photo_local=None,
            cutout_url=None,
            cutout_local=None,
        )
    )
    await session.commit()
    return r.rowcount


async def main():
    parser = argparse.ArgumentParser(description="Download player photos from TheSportsDB (with team filter)")
    parser.add_argument("--reset", action="store_true", help="Reset existing photos before downloading")
    args = parser.parse_args()

    from sqlalchemy import select

    from app.database import AsyncSessionLocal
    from app.models.player import Player
    from app.models.real_team import RealTeam

    # Directory backend/static/photos
    static_photos = backend_dir / "static" / "photos"
    static_photos.mkdir(parents=True, exist_ok=True)
    photos_prefix = "photos"

    if args.reset:
        async with AsyncSessionLocal() as session:
            n = await reset_photos(session)
            logger.info("Reset %d players (cleared photo/cutout fields)", n)

    # Carica player con real_team (join) per avere il nome squadra
    async with AsyncSessionLocal() as session:
        r = await session.execute(
            select(Player, RealTeam.name.label("team_name"))
            .select_from(Player)
            .outerjoin(RealTeam, Player.real_team_id == RealTeam.id)
            .where(Player.is_active == True)
            .order_by(Player.id)
        )
        rows = r.all()

    total = len(rows)
    downloaded = 0
    skipped = 0
    not_found = 0
    no_team_match = 0

    for i, (player, team_name) in enumerate(rows):
        # Se ha già thesportsdb_id e foto, skip (già assegnato in modo sicuro)
        if player.thesportsdb_id and player.photo_local and player.cutout_local:
            skipped += 1
            continue
        # Se ha già foto e non stiamo in reset, skip (evitiamo di sovrascrivere)
        if player.photo_local and player.cutout_local and not args.reset:
            skipped += 1
            continue

        player_name = (player.name or "").strip()
        if not player_name:
            skipped += 1
            continue

        try:
            data = await fetch_player_search(player_name)
            await asyncio.sleep(RATE_LIMIT_SEC)
        except Exception as e:
            logger.warning("Player %s (id=%s): request failed: %s", player_name, player.id, e)
            skipped += 1
            continue

        plist = data.get("player")
        if not plist or not isinstance(plist, list):
            logger.warning("Player %s (id=%s): not found on TheSportsDB", player_name, player.id)
            not_found += 1
            continue

        # Filtra per squadra: solo risultati dove strTeam matcha la nostra real_team.name
        team_matches = [p for p in plist if _team_match(team_name, p.get("strTeam"))]
        if not team_matches:
            logger.info(
                "Player %s (id=%s): no result with team match (our team=%s). Skip.",
                player_name,
                player.id,
                team_name or "(none)",
            )
            no_team_match += 1
            continue

        # Preferisci Soccer e con foto
        with_photo = [p for p in team_matches if p.get("strSport") == "Soccer" and (p.get("strThumb") or p.get("strCutout"))]
        candidates = with_photo if with_photo else team_matches
        chosen = _choose_best_match(
            candidates,
            player_team=team_name,
            player_nationality=player.nationality,
            player_dob=player.date_of_birth,
        )
        if not chosen:
            not_found += 1
            continue

        str_thumb = (chosen.get("strThumb") or "").strip() or None
        str_cutout = (chosen.get("strCutout") or "").strip() or None
        if not str_thumb and not str_cutout:
            logger.warning("Player %s (id=%s): chosen result has no strThumb/strCutout", player_name, player.id)
            not_found += 1
            continue

        thesportsdb_id = (chosen.get("idPlayer") or "").strip() or None

        pid = player.id
        photo_path = static_photos / f"{pid}.png"
        cutout_path = static_photos / f"{pid}_cutout.png"

        ok_photo = False
        if str_thumb:
            ok_photo = await download_image(str_thumb, photo_path)
            await asyncio.sleep(RATE_LIMIT_SEC)
        ok_cutout = False
        if str_cutout:
            ok_cutout = await download_image(str_cutout, cutout_path)
            await asyncio.sleep(RATE_LIMIT_SEC)

        if not ok_photo and not ok_cutout:
            skipped += 1
            continue

        async with AsyncSessionLocal() as session:
            r = await session.execute(select(Player).where(Player.id == pid))
            row = r.scalar_one_or_none()
            if not row:
                continue
            if thesportsdb_id:
                row.thesportsdb_id = thesportsdb_id
            if str_thumb:
                row.photo_url = str_thumb
                if ok_photo:
                    row.photo_local = f"{photos_prefix}/{pid}.png"
            if str_cutout:
                row.cutout_url = str_cutout
                if ok_cutout:
                    row.cutout_local = f"{photos_prefix}/{pid}_cutout.png"
            await session.commit()

        downloaded += 1
        print(f"Downloaded {downloaded}/{total} photos... (id={pid} {player_name} team={team_name or '?'})", flush=True)

    print(
        f"Done. Downloaded {downloaded}/{total} photos. "
        f"No team match: {no_team_match}, Not found: {not_found}, Skipped: {skipped}"
    )


if __name__ == "__main__":
    asyncio.run(main())
