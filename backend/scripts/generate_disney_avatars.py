#!/usr/bin/env python3
"""
Genera avatar stile Disney/Pixar con OpenAI gpt-image-1 (image-to-image).
Usa SOLO endpoint /v1/images/edits: client.images.edit oppure HTTP diretto.
Salva in static/avatars/{id}.png.

SETUP: pip install openai

Uso:
  --test      : 10 giocatori (249, 306, 100, 150, 200, 300, 400, 500, 600, 50)
  --all       : tutti i giocatori con foto
  --ids       : ID specifici (es. --ids 249,306)
  --api-key   : API key OpenAI (altrimenti env o backend/secrets/openai_api_key.txt)

"""
from __future__ import annotations

import argparse
import base64
import logging
import os
import sys
import time
from pathlib import Path

backend_dir = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(backend_dir))

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

PHOTOS_DIR = backend_dir / "static" / "photos"
CROPPED_DIR = PHOTOS_DIR / "cropped"
AVATARS_DIR = backend_dir / "static" / "avatars"
SECRETS_DIR = backend_dir / "secrets"
OPENAI_KEY_FILE = SECRETS_DIR / "openai_api_key.txt"
SLEEP_BETWEEN = 3
RETRY_AFTER_RATE_LIMIT = 30
MAX_ATTEMPTS = 3
COST_PER_IMAGE = 0.04

TEST_IDS = [249, 306, 100, 150, 200, 300, 400, 500, 600, 50]

# Mappa colori maglie: nome squadra (DB o varianti) -> descrizione per il prompt
TEAM_JERSEYS = {
    "Atalanta BC": "black and blue striped",
    "Atalanta": "black and blue striped",
    "Bologna FC 1909": "red and blue striped",
    "Bologna": "red and blue striped",
    "Cagliari Calcio": "dark red",
    "Cagliari": "dark red",
    "Como 1907": "blue",
    "Como": "blue",
    "Empoli FC": "blue",
    "Empoli": "blue",
    "ACF Fiorentina": "purple",
    "Fiorentina": "purple",
    "Genoa CFC": "red and dark blue halved",
    "Genoa": "red and dark blue halved",
    "FC Internazionale Milano": "blue and black striped",
    "Inter": "blue and black striped",
    "Juventus FC": "black and white striped",
    "Juventus": "black and white striped",
    "SS Lazio": "light blue",
    "Lazio": "light blue",
    "US Lecce": "yellow and red striped",
    "Lecce": "yellow and red striped",
    "AC Milan": "red and black striped",
    "Milan": "red and black striped",
    "AC Monza": "red and white",
    "Monza": "red and white",
    "SSC Napoli": "light blue",
    "Napoli": "light blue",
    "Parma Calcio 1913": "white with blue and yellow cross",
    "Parma": "white with blue and yellow cross",
    "AS Roma": "dark red with orange details",
    "Roma": "dark red with orange details",
    "Torino FC": "dark red granata",
    "Torino": "dark red granata",
    "Udinese Calcio": "black and white striped",
    "Udinese": "black and white striped",
    "Venezia FC": "black green and orange",
    "Venezia": "black green and orange",
    "Hellas Verona FC": "blue and yellow",
    "Verona": "blue and yellow",
    "US Sassuolo": "green and black striped",
    "Sassuolo": "green and black striped",
    "Pisa SC": "blue and black striped",
    "Pisa": "blue and black striped",
    "US Cremonese": "red and gray striped",
    "Cremonese": "red and gray striped",
}


def get_db_connection():
    """Connessione DB (stessa logica di script che usano psycopg2)."""
    import psycopg2
    # Da variabili d'ambiente (docker-compose) o default
    host = os.getenv("DB_HOST", os.getenv("POSTGRES_HOST", "db"))
    port = os.getenv("DB_PORT", os.getenv("POSTGRES_PORT", "5432"))
    dbname = os.getenv("DB_NAME", os.getenv("POSTGRES_DB", "fantastar"))
    user = os.getenv("DB_USER", os.getenv("POSTGRES_USER", "fantastar"))
    password = os.getenv("DB_PASSWORD", os.getenv("POSTGRES_PASSWORD", "fantastar"))
    return psycopg2.connect(
        host=host,
        port=port,
        dbname=dbname,
        user=user,
        password=password,
    )


def get_players(ids: list[int] | None = None) -> list[dict]:
    """
    Ritorna lista di {id, name, team_name} dal DB.
    Schema: players.real_team_id -> real_teams.id (tabella real_teams, non teams).
    """
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        if ids:
            if len(ids) == 1:
                cur.execute(
                    "SELECT p.id, p.name, COALESCE(t.name, '') as team_name FROM players p "
                    "LEFT JOIN real_teams t ON p.real_team_id = t.id WHERE p.is_active = True AND p.id = %s",
                    (ids[0],),
                )
            else:
                cur.execute(
                    "SELECT p.id, p.name, COALESCE(t.name, '') as team_name FROM players p "
                    "LEFT JOIN real_teams t ON p.real_team_id = t.id WHERE p.is_active = True AND p.id IN %s ORDER BY p.id",
                    (tuple(ids),),
                )
        else:
            cur.execute(
                "SELECT p.id, p.name, COALESCE(t.name, '') as team_name FROM players p "
                "LEFT JOIN real_teams t ON p.real_team_id = t.id WHERE p.is_active = True ORDER BY p.id",
            )
        rows = cur.fetchall()
        cur.close()
        conn.close()
        return [{"id": r[0], "name": r[1] or "", "team_name": r[2] or ""} for r in rows]
    except Exception as e:
        logger.warning("get_players (psycopg2) fallito: %s, uso fallback SQLAlchemy", e)
        return []


def get_jersey_color(team_name: str) -> str:
    """Cerca match esatto o parziale in TEAM_JERSEYS, poi parole chiave, infine default blue."""
    if not team_name or not team_name.strip():
        return "blue"
    name = team_name.strip()
    # Match esatto
    if name in TEAM_JERSEYS:
        return TEAM_JERSEYS[name]
    # Match parziale (chiave in nome squadra o viceversa)
    name_lower = name.lower()
    for key, color in TEAM_JERSEYS.items():
        if key.lower() in name_lower or name_lower in key.lower():
            return color
    # Fallback parole chiave
    if "atalanta" in name_lower:
        return "black and blue striped"
    if "bologna" in name_lower:
        return "red and blue striped"
    if "inter" in name_lower or "internazionale" in name_lower:
        return "blue and black striped"
    if "milan" in name_lower and "monza" not in name_lower:
        return "red and black striped"
    if "napoli" in name_lower:
        return "light blue"
    if "roma" in name_lower:
        return "dark red with orange details"
    if "juve" in name_lower or "juventus" in name_lower:
        return "black and white striped"
    if "lazio" in name_lower:
        return "light blue"
    if "torino" in name_lower:
        return "dark red granata"
    if "fiorentina" in name_lower:
        return "purple"
    if "sassuolo" in name_lower:
        return "green and black striped"
    if "cremonese" in name_lower:
        return "red and gray striped"
    return "blue"


def _load_key_from_file() -> str | None:
    if not OPENAI_KEY_FILE.is_file():
        return None
    try:
        key = OPENAI_KEY_FILE.read_text(encoding="utf-8").strip()
        return key if key and not key.startswith("#") else None
    except Exception:
        return None


def get_client(api_key: str | None):
    key = api_key or os.environ.get("OPENAI_API_KEY") or _load_key_from_file()
    if not key:
        raise SystemExit(
            "Fornisci la chiave OpenAI: --api-key, env OPENAI_API_KEY, "
            f"oppure salvala in {OPENAI_KEY_FILE}"
        )
    return __import__("openai").OpenAI(api_key=key)


def get_players_from_db(mode: str, id_list: list[int] | None) -> list[dict]:
    from sqlalchemy import create_engine
    from sqlalchemy.orm import Session

    from app.config import settings
    from app.models.player import Player
    from app.models.real_team import RealTeam

    sync_url = getattr(settings, "DATABASE_URL", None) or os.environ.get("DATABASE_URL")
    if not sync_url:
        return _fallback_player_list(mode, id_list)
    if "+asyncpg" in (sync_url or ""):
        sync_url = sync_url.replace("postgresql+asyncpg://", "postgresql://")
    engine = create_engine(sync_url)
    with Session(engine) as session:
        if mode == "all":
            q = (
                session.query(Player.id, Player.name, RealTeam.name.label("team_name"), Player.position)
                .outerjoin(RealTeam, Player.real_team_id == RealTeam.id)
                .where(Player.is_active == True)
                .order_by(Player.id)
            )
            rows = q.all()
            return [{"id": r.id, "name": r.name, "team_name": r.team_name or "", "position": r.position} for r in rows]
        ids = id_list or TEST_IDS
        q = (
            session.query(Player.id, Player.name, RealTeam.name.label("team_name"), Player.position)
            .outerjoin(RealTeam, Player.real_team_id == RealTeam.id)
            .where(Player.id.in_(ids))
        )
        rows = q.all()
        return [{"id": r.id, "name": r.name, "team_name": r.team_name or "", "position": r.position} for r in rows]


def _fallback_player_list(mode: str, id_list: list[int] | None) -> list[dict]:
    ids = id_list if id_list else TEST_IDS
    return [{"id": i, "name": "", "team_name": "", "position": "CEN"} for i in ids]




def photo_path(pid: int) -> Path | None:
    """Priorità: 1) cropped/{id}.png  2) {id}_cutout.png  3) {id}.png"""
    cropped = CROPPED_DIR / f"{pid}.png"
    if cropped.exists():
        return cropped
    cutout = PHOTOS_DIR / f"{pid}_cutout.png"
    if cutout.exists():
        return cutout
    normal = PHOTOS_DIR / f"{pid}.png"
    if normal.exists():
        return normal
    return None


def _response_to_bytes(response_or_json) -> bytes | None:
    """Estrae i byte immagine da response (SDK) o da dict (HTTP json)."""
    import httpx
    if hasattr(response_or_json, "data") and response_or_json.data and len(response_or_json.data) > 0:
        item = response_or_json.data[0]
        if getattr(item, "b64_json", None):
            return base64.b64decode(item.b64_json)
        if getattr(item, "url", None):
            with httpx.Client(timeout=60.0) as h:
                r = h.get(item.url)
                r.raise_for_status()
                return r.content
    if isinstance(response_or_json, dict) and response_or_json.get("data") and len(response_or_json["data"]) > 0:
        item = response_or_json["data"][0]
        if item.get("b64_json"):
            return base64.b64decode(item["b64_json"])
        if item.get("url"):
            with httpx.Client(timeout=60.0) as h:
                r = h.get(item["url"])
                r.raise_for_status()
                return r.content
    return None


def _edit_prompt(jersey_color: str) -> str:
    """Prompt per stile Disney/Pixar moderno (Luca, Soul): elegante, realistico, non caricatura."""
    return f"""Transform this photo into a high-quality 3D rendered portrait in the style of modern Disney Pixar animated films like Luca, Soul, or Incredibles 2.

STYLE REQUIREMENTS:
- Realistic proportions - do NOT exaggerate features. Keep normal-sized eyes, ears, nose, and head.
- Smooth, clean 3D render with soft lighting and subtle shadows
- Slightly stylized but NOT caricature - the person should look like a handsome/beautiful animated version of themselves
- Warm, natural skin tones with subtle subsurface scattering
- Eyes should be expressive but NORMAL sized, not oversized cartoon eyes
- Hair should have volume and texture, rendered in 3D with individual strand details

COMPOSITION:
- Frontal view, half-body portrait showing head, neck, and upper chest/shoulders
- Plain white to very light grey gradient background
- Slight friendly expression, natural and confident
- The character wears a simple {jersey_color} V-neck soccer jersey with NO logos, NO text, NO badges, NO numbers

CRITICAL - LIKENESS:
- The 3D character MUST closely resemble the real person in the photo
- Preserve exact: hair color, hair style, skin tone, facial hair (beard/stubble/clean-shaven), eye color, face shape, jawline
- Keep any distinctive features: dimples, freckles, scars, broad nose, thin lips, etc.
- The result should be immediately recognizable as a stylized version of this specific person

DO NOT make it look like a cartoon caricature. Think premium mobile game character or animated movie protagonist."""


def generate_avatar(photo_path: Path, jersey_color: str, api_key: str, client) -> tuple[bytes | None, str | None]:
    """
    Genera avatar con gpt-image-1 SOLO via /v1/images/edits.
    Metodo 1: client.images.edit. Metodo 2: HTTP diretto.
    Se entrambi falliscono ritorna (None, error); non genera nulla.
    """
    prompt = _edit_prompt(jersey_color)
    e1 = e2 = None

    # Metodo 1: SDK client.images.edit
    try:
        print("  Tentativo: gpt-image-1 via images.edit...")
        with open(photo_path, "rb") as img_file:
            response = client.images.edit(
                model="gpt-image-1",
                image=img_file,
                prompt=prompt,
                size="1024x1024",
            )
        print("  SUCCESSO: gpt-image-1 images.edit")
        out = _response_to_bytes(response)
        if out is not None:
            return out, None
    except Exception as e1:
        print(f"  images.edit ERRORE: {e1}")

    # Metodo 2: chiamata HTTP diretta
    try:
        print("  Tentativo: HTTP diretto a /v1/images/edits...")
        import httpx
        url = "https://api.openai.com/v1/images/edits"
        headers = {"Authorization": f"Bearer {api_key}"}
        with open(photo_path, "rb") as img_file:
            files = {"image": ("photo.png", img_file, "image/png")}
            data = {
                "model": "gpt-image-1",
                "prompt": _edit_prompt(jersey_color),
                "size": "1024x1024",
            }
            with httpx.Client(timeout=120.0) as h:
                resp = h.post(url, headers=headers, files=files, data=data)
        if resp.status_code != 200:
            raise Exception(f"HTTP {resp.status_code}: {resp.text[:500]}")
        print("  SUCCESSO: HTTP diretto")
        result = resp.json()
        out = _response_to_bytes(result)
        if out is not None:
            return out, None
    except Exception as e2:
        print(f"  HTTP diretto ERRORE: {e2}")

    err_msg = f"Tutti i metodi falliti. Errore 1: {e1}, Errore 2: {e2}"
    logger.warning(err_msg)
    return None, err_msg


def save_avatar(image_bytes: bytes, output_path: Path) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, "wb") as f:
        f.write(image_bytes)


def update_player_avatar_url(pid: int, avatar_path: str) -> bool:
    try:
        from sqlalchemy import create_engine, text
        from app.config import settings
        sync_url = getattr(settings, "DATABASE_URL", None) or os.environ.get("DATABASE_URL")
        if not sync_url:
            return False
        if "+asyncpg" in (sync_url or ""):
            sync_url = sync_url.replace("postgresql+asyncpg://", "postgresql://")
        engine = create_engine(sync_url)
        with engine.connect() as conn:
            conn.execute(text("UPDATE players SET avatar_url = :url WHERE id = :id"), {"url": avatar_path, "id": pid})
            conn.commit()
        return True
    except Exception:
        return False


def run_one(client, player: dict, api_key: str) -> tuple[bool, str | None]:
    pid = player["id"]
    team_name = player.get("team_name") or ""
    path = photo_path(pid)
    if not path:
        return False, "no_photo"

    jersey = get_jersey_color(team_name)
    for attempt in range(MAX_ATTEMPTS):
        try:
            image_bytes, err = generate_avatar(path, jersey, api_key, client)
            if err:
                return False, err
            if not image_bytes:
                return False, "no_image"
            out_path = AVATARS_DIR / f"{pid}.png"
            save_avatar(image_bytes, out_path)
            update_player_avatar_url(pid, f"/static/avatars/{pid}.png")
            return True, None
        except Exception as e:
            err_str = str(e).lower()
            if "429" in err_str or "rate" in err_str:
                if attempt < MAX_ATTEMPTS - 1:
                    time.sleep(RETRY_AFTER_RATE_LIMIT)
                    continue
            return False, str(e)
    return False, "max_attempts"


def main() -> None:
    parser = argparse.ArgumentParser(description="Genera avatar Disney/Pixar con gpt-image-1 (endpoint /v1/images/edits)")
    parser.add_argument("--test", action="store_true", help="10 ID di test")
    parser.add_argument("--all", action="store_true", help="Tutti i giocatori con foto")
    parser.add_argument("--ids", type=str, help="ID separati da virgola (es. 249,306)")
    parser.add_argument("--api-key", type=str, default=None, help="OpenAI API key")
    args = parser.parse_args()

    id_list = None
    if args.ids:
        try:
            id_list = [int(x.strip()) for x in args.ids.split(",") if x.strip()]
        except ValueError:
            print("Errore: --ids deve essere una lista di numeri separati da virgola")
            sys.exit(1)
        if not id_list:
            print("Nessun ID con --ids")
            sys.exit(1)
    elif args.test:
        id_list = TEST_IDS
    elif not args.all:
        print("Specifica --test, --all o --ids <lista>")
        sys.exit(1)

    try:
        api_key = args.api_key or os.environ.get("OPENAI_API_KEY") or _load_key_from_file()
        if not api_key:
            raise SystemExit(
                "Fornisci la chiave OpenAI: --api-key, env OPENAI_API_KEY, "
                f"oppure salvala in {OPENAI_KEY_FILE}"
            )
        client = get_client(args.api_key)
    except SystemExit as e:
        print(e)
        sys.exit(1)

    # Carica giocatori dal DB (id, name, team_name): prima psycopg2, poi fallback SQLAlchemy
    if args.all:
        raw = get_players(None)
        if not raw:
            raw = get_players_from_db("all", None)
        players = [p for p in raw if photo_path(p["id"])]
    else:
        raw = get_players(id_list)
        if not raw:
            raw = get_players_from_db("ids", id_list)
        players = [p for p in raw if photo_path(p["id"])]
        missing = [p["id"] for p in raw if not photo_path(p["id"])]
        if missing:
            print(f"Attenzione: nessuna foto per ID {missing}, saltati.")

    if not players:
        print("Nessun giocatore con foto da processare.")
        sys.exit(0)

    AVATARS_DIR.mkdir(parents=True, exist_ok=True)
    generated = 0
    errors: list[tuple[int, str, str]] = []

    for i, player in enumerate(players):
        pid = player["id"]
        name = player.get("name") or str(pid)
        team_name = player.get("team_name") or ""
        jersey_color = get_jersey_color(team_name)
        print(f"[{i+1}/{len(players)}] {pid} {name} ({team_name}) - maglia: {jersey_color}")
        success, err = run_one(client, player, api_key)
        if success:
            generated += 1
            print(f"  OK -> static/avatars/{pid}.png")
        else:
            errors.append((pid, name, err or "unknown"))
            print(f"  Errore: {err}")
        if i < len(players) - 1:
            time.sleep(SLEEP_BETWEEN)

    print("\n--- Report ---")
    print(f"Avatar generati: {generated}")
    print(f"Errori: {len(errors)}")
    if errors:
        for pid, name, msg in errors[:20]:
            print(f"  - {pid} ({name}): {msg}")
        if len(errors) > 20:
            print(f"  ... e altri {len(errors) - 20}")
    print(f"Costo stimato: ${generated * COST_PER_IMAGE:.2f}")


if __name__ == "__main__":
    main()
