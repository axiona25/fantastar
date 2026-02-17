#!/usr/bin/env python3
"""Genera stemmi squadra in stile 3D Disney/Pixar da immagini in source/ (gpt-image-1).

Input:  static/media/team_badges/source/  (PNG/JPG)
Output: static/media/team_badges/         (PNG 3D)

Dopo la generazione, aggiorna automaticamente badges_names.json: il nome per ogni
nuovo PNG viene letto dall'immagine con Vision API (gpt-4o-mini). Fallback su filename se Vision fallisce.
"""

from __future__ import annotations

import argparse
import base64
import json
import logging
import os
import sys
import time
from pathlib import Path

backend_dir = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(backend_dir))

from openai import OpenAI

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)

SLEEP_DEFAULT = 2
RETRY_AFTER_RATE_LIMIT = 60
RETRY_BACKOFF = [5, 15, 30]
HTTP_TIMEOUT = 120.0
COST_PER_IMAGE = 0.04

INPUT_DIR_DEFAULT = backend_dir / "static" / "media" / "team_badges" / "source"
OUTPUT_DIR_DEFAULT = backend_dir / "static" / "media" / "team_badges"
EXTENSIONS = (".png", ".jpg", ".jpeg", ".webp")

TEAM_BADGE_PROMPT = """Transform this image into a high-quality 3D rendered team badge/emblem in the style of modern Disney Pixar animated films.

STYLE REQUIREMENTS:
- 3D rendered with soft lighting, subtle shadows, and clean polished surfaces
- If there is a character or animal, render it in 3D Pixar style with smooth features and expressive details
- If there is text, preserve it exactly as it appears, rendered in 3D with slight depth/emboss effect
- Preserve the original color scheme
- The badge should look like a premium sports team emblem from an animated movie
- Clean circular or shield shape
- Professional, polished, high quality

COMPOSITION:
- Keep the same general layout as the original
- Center the main subject
- Output as a clean badge/emblem shape

CRITICAL:
- Preserve any text exactly as written
- Keep the same colors and theme
- Make it look premium and professional
- Style must be consistent: 3D Disney Pixar animated look
- Output on a completely transparent background"""


def _load_key_from_file() -> str | None:
    key_file = backend_dir / "secrets" / "openai_api_key.txt"
    if not key_file.is_file():
        return None
    try:
        key = key_file.read_text(encoding="utf-8").strip()
        return key if key and not key.startswith("#") else None
    except Exception:
        return None


def get_client(api_key: str | None) -> OpenAI:
    key = api_key or os.environ.get("OPENAI_API_KEY") or _load_key_from_file()
    if not key:
        raise SystemExit(
            "Fornisci la chiave OpenAI: --api-key, env OPENAI_API_KEY, "
            "oppure salvala in backend/secrets/openai_api_key.txt"
        )
    return OpenAI(api_key=key, timeout=HTTP_TIMEOUT)


def _resolve_path(p: Path) -> Path:
    if not p.is_absolute():
        return backend_dir / p
    return p


def generate_one(client: OpenAI, input_path: Path, output_path: Path) -> bool:
    """Genera un singolo stemma 3D."""
    for attempt, backoff in enumerate(RETRY_BACKOFF):
        try:
            with open(input_path, "rb") as img_file:
                response = client.images.edit(
                    model="gpt-image-1",
                    image=img_file,
                    prompt=TEAM_BADGE_PROMPT,
                    size="1024x1024",
                    background="transparent",
                )

            image_data = response.data[0]
            if hasattr(image_data, "b64_json") and image_data.b64_json:
                img_bytes = base64.b64decode(image_data.b64_json)
            elif hasattr(image_data, "url") and image_data.url:
                import httpx

                r = httpx.get(image_data.url, timeout=HTTP_TIMEOUT)
                r.raise_for_status()
                img_bytes = r.content
            else:
                raise ValueError("Nessun dato immagine nella response")

            output_path.parent.mkdir(parents=True, exist_ok=True)
            with open(output_path, "wb") as f:
                f.write(img_bytes)

            return True

        except Exception as e:
            err_str = str(e)
            if "429" in err_str or "rate" in err_str.lower():
                logger.warning("Rate limit, attendo %ss...", RETRY_AFTER_RATE_LIMIT)
                time.sleep(RETRY_AFTER_RATE_LIMIT)
                continue
            logger.warning("Tentativo %d/3 fallito: %s", attempt + 1, e)
            if attempt < len(RETRY_BACKOFF) - 1:
                time.sleep(backoff)
            else:
                logger.error("FALLITO dopo 3 tentativi: %s", input_path)
                return False
    return False


VISION_PROMPT = """Look at this team badge/emblem image. What is the exact main text or name written on the badge (e.g. team name, club name)? Reply with ONLY that text, in the same language and spelling as on the image. No quotes, no explanation. If there are multiple words, keep them as written. If you cannot read any text clearly, reply with a very short descriptive name in English (e.g. "Red Lion", "Golden Shield")."""


def _filename_to_display_name(filename: str) -> str:
    """Fallback: da nome file a nome leggibile."""
    stem = Path(filename).stem
    name = stem.replace("_", " ").replace("-", " ").strip()
    return name.title() if name else stem


def extract_name_from_image(client: OpenAI, image_path: Path) -> str | None:
    """
    Estrae il nome scritto sullo stemma usando Vision API (gpt-4o-mini).
    Ritorna il testo letto dall'immagine o None in caso di errore.
    """
    try:
        with open(image_path, "rb") as f:
            b64 = base64.standard_b64encode(f.read()).decode("ascii")
    except Exception as e:
        logger.warning("Impossibile leggere immagine %s: %s", image_path, e)
        return None

    try:
        response = client.chat.completions.create(
            model="gpt-4o-mini",
            messages=[
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": VISION_PROMPT},
                        {
                            "type": "image_url",
                            "image_url": {"url": f"data:image/png;base64,{b64}"},
                        },
                    ],
                }
            ],
            max_tokens=150,
        )
        text = (response.choices[0].message.content or "").strip()
        return text if text else None
    except Exception as e:
        logger.warning("Vision API fallita per %s: %s", image_path.name, e)
        return None


def sync_badges_names_json(
    output_dir: Path,
    client: OpenAI | None = None,
    sleep_sec: float = 1.0,
) -> int:
    """
    Aggiorna badges_names.json: per ogni PNG in output_dir che non è nel JSON,
    estrae il nome dall'immagine (Vision API) e lo aggiunge. Fallback su filename se Vision fallisce.
    Ritorna il numero di voci aggiunte.
    """
    json_path = output_dir / "badges_names.json"
    names_map: dict[str, str] = {}
    if json_path.is_file():
        try:
            with open(json_path, encoding="utf-8") as f:
                data = json.load(f)
            if isinstance(data, dict):
                names_map = {str(k): str(v) for k, v in data.items()}
        except (json.JSONDecodeError, TypeError):
            pass

    pngs = sorted(p for p in output_dir.iterdir() if p.is_file() and p.suffix.lower() == ".png")
    to_process = [p for p in pngs if p.name not in names_map]
    added = 0

    for i, p in enumerate(to_process):
        name = p.name
        display_name: str | None = None
        if client:
            logger.info("[Vision] Lettura nome da immagine: %s", name)
            display_name = extract_name_from_image(client, p)
            if i < len(to_process) - 1:
                time.sleep(sleep_sec)
        if display_name is None:
            display_name = _filename_to_display_name(name)
            logger.info("Fallback filename per %s → %s", name, display_name)
        names_map[name] = display_name
        added += 1
        logger.info("Aggiunto a badges_names.json: %s → %s", name, display_name)

    if added > 0 or not json_path.is_file():
        with open(json_path, "w", encoding="utf-8") as f:
            json.dump(names_map, f, ensure_ascii=False, indent=2)
        logger.info("Scritto %s (%d voci totali, %d nuove)", json_path, len(names_map), added)
    return added


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Genera stemmi squadra 3D Disney/Pixar da source/ (gpt-image-1)"
    )
    parser.add_argument("--test", action="store_true", help="Solo prime 3 immagini")
    parser.add_argument("--all", action="store_true", help="Processa tutte le immagini")
    parser.add_argument("--api-key", type=str, default=None, help="OpenAI API key")
    parser.add_argument(
        "--input-dir",
        type=Path,
        default=None,
        help=f"Cartella sorgente (default: static/media/team_badges/source/)",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=None,
        help="Cartella output (default: static/media/team_badges/)",
    )
    parser.add_argument(
        "--sleep",
        type=float,
        default=SLEEP_DEFAULT,
        help=f"Secondi di pausa tra una richiesta e l'altra (default: {SLEEP_DEFAULT})",
    )
    parser.add_argument(
        "--no-skip-existing",
        action="store_true",
        help="Rigenera anche se l'output esiste già",
    )
    args = parser.parse_args()

    input_dir = _resolve_path(args.input_dir or INPUT_DIR_DEFAULT)
    output_dir = _resolve_path(args.output_dir or OUTPUT_DIR_DEFAULT)
    sleep_sec = args.sleep

    if not (args.test or args.all):
        print("Specifica --test (prime 3) o --all")
        sys.exit(1)

    try:
        client = get_client(args.api_key)
    except SystemExit as e:
        print(e)
        sys.exit(1)

    if not input_dir.is_dir():
        print(f"Cartella sorgente non trovata: {input_dir}")
        sys.exit(1)

    files = sorted(
        f for f in input_dir.iterdir()
        if f.is_file() and f.suffix.lower() in EXTENSIONS
    )
    if args.test:
        files = files[:3]
    if not files:
        print(f"Nessuna immagine in {input_dir}")
        sys.exit(0)

    output_dir.mkdir(parents=True, exist_ok=True)
    generated = 0
    skipped = 0
    errors = 0
    failed: list[str] = []
    start_time = time.monotonic()

    for i, input_path in enumerate(files):
        output_name = input_path.stem + ".png"
        output_path = output_dir / output_name

        if output_path.exists() and not args.no_skip_existing:
            skipped += 1
            logger.info("[%d/%d] Skip (esiste): %s", i + 1, len(files), output_name)
            continue

        logger.info("[%d/%d] Generando: %s", i + 1, len(files), input_path.name)

        if generate_one(client, input_path, output_path):
            generated += 1
            logger.info("  OK → %s", output_path)
        else:
            errors += 1
            failed.append(input_path.name)

        if i < len(files) - 1:
            time.sleep(sleep_sec)

        if (i + 1) % 5 == 0 and len(files) > 5:
            print(f"--- Progresso: {i+1}/{len(files)} - Generati: {generated} - Errori: {errors} ---")

    elapsed = time.monotonic() - start_time
    print("\n--- REPORT FINALE ---")
    print(f"Totale: {len(files)}")
    print(f"Generati: {generated}")
    print(f"Skippati: {skipped}")
    print(f"Errori: {errors}")
    if failed:
        print(f"Falliti: {failed}")
    print(f"Costo stimato: ${generated * COST_PER_IMAGE:.2f}")
    print(f"Tempo: {int(elapsed // 60)}m {int(elapsed % 60)}s")

    # Aggiornamento automatico di badges_names.json: nome letto dall'immagine (Vision API)
    added = sync_badges_names_json(output_dir, client=client, sleep_sec=sleep_sec)
    if added > 0:
        print(f"\nbadges_names.json aggiornato: {added} nuove voci (nome letto dall'immagine).")
    else:
        print("\nbadges_names.json già aggiornato.")


if __name__ == "__main__":
    main()
