#!/usr/bin/env python3
"""Genera avatar allenatori 3D Disney/Pixar da immagini in source/ (gpt-image-1).

Input:  static/media/fanta_allenatori/source/  (PNG/JPG)
Output: static/media/fanta_allenatori/         (PNG 3D)

Stessa struttura e argomenti di generate_team_badges_3d.py: skip esistenti,
retry/rate-limit, --api-key, --input-dir, --output-dir, --sleep, --test/--all.
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

from openai import OpenAI

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)

SLEEP_DEFAULT = 2
RETRY_AFTER_RATE_LIMIT = 60
RETRY_BACKOFF = [5, 15, 30]
HTTP_TIMEOUT = 120.0
COST_PER_IMAGE = 0.04

INPUT_DIR_DEFAULT = backend_dir / "static" / "media" / "fanta_allenatori" / "source"
OUTPUT_DIR_DEFAULT = backend_dir / "static" / "media" / "fanta_allenatori"
EXTENSIONS = (".png", ".jpg", ".jpeg", ".webp")

COACH_AVATAR_PROMPT = """Transform this image into a stunning 3D Disney/Pixar style cartoon character portrait of a fantasy football coach/manager.

CRITICAL FRAMING RULES:
- The ENTIRE head must be fully visible, including the TOP of the head/hair - NEVER crop or cut off the top of the head
- Leave adequate space/margin ABOVE the head (at least 10% of image height)
- Frame from chest/shoulders up, centered in the image
- The character must fit comfortably within the frame with space on all sides

Style rules:
- Keep the SAME character appearance, pose, clothing, and expression from the original image
- High-quality Pixar/Disney 3D animated character style
- Slightly exaggerated but appealing proportions
- Smooth, clean 3D rendering with realistic lighting
- Vibrant, rich colors
- Friendly, charismatic expression
- Background MUST be transparent

Output: Half-body portrait, fully visible head with margin above, transparent background."""


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
    """Genera un singolo avatar 3D."""
    for attempt, backoff in enumerate(RETRY_BACKOFF):
        try:
            with open(input_path, "rb") as img_file:
                response = client.images.edit(
                    model="gpt-image-1",
                    image=img_file,
                    prompt=COACH_AVATAR_PROMPT,
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


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Genera avatar allenatori 3D Disney/Pixar da source/ (gpt-image-1)"
    )
    parser.add_argument("--test", action="store_true", help="Solo prime 3 immagini")
    parser.add_argument("--all", action="store_true", help="Processa tutte le immagini")
    parser.add_argument("--api-key", type=str, default=None, help="OpenAI API key")
    parser.add_argument(
        "--input-dir",
        type=Path,
        default=None,
        help="Cartella sorgente (default: static/media/fanta_allenatori/source/)",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=None,
        help="Cartella output (default: static/media/fanta_allenatori/)",
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


if __name__ == "__main__":
    main()
