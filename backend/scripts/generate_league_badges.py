#!/usr/bin/env python3
"""Genera stemmi lega in stile 3D Disney/Pixar da immagini sorgente con gpt-image-1.

Sorgenti: static/media/league_badges/ (PNG, esclusi source/ e 3d/)
Output: static/media/league_badges/3d/

Dopo la generazione, copia nel frontend:
  cp backend/static/media/league_badges/3d/*.png frontend_mobile/assets/images/league_badges/
  oppure usa --copy-to-frontend
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

SLEEP_BETWEEN = 2
RETRY_AFTER_RATE_LIMIT = 60
RETRY_BACKOFF = [5, 15, 30]
HTTP_TIMEOUT = 120.0
COST_PER_IMAGE = 0.04

INPUT_DIR = backend_dir / "static" / "media" / "league_badges"
OUTPUT_DIR = backend_dir / "static" / "media" / "league_badges" / "3d"
EXTENSIONS = (".png", ".jpg", ".jpeg", ".webp")

LEAGUE_BADGE_PROMPT = """Transform this fantasy football league badge into a high-quality 3D rendered emblem in the style of modern Disney Pixar animated films (like Luca, Soul, Incredibles 2).

STYLE REQUIREMENTS:
- Premium 3D render with soft lighting, subtle shadows, and clean polished surfaces
- Smooth materials with subsurface scattering effect on metallic/gold parts
- Slight glossy/reflective finish on the badge surface
- If there is a character, animal, or object, render it in detailed 3D Pixar style
- If there are stars, trophies, balls, or other symbols, make them look like polished 3D objects
- Preserve the original color scheme exactly
- Clean circular or shield badge shape with a subtle 3D depth/thickness (like a real pin or medal)

COMPOSITION:
- Keep the same general layout and elements as the original
- Center the main subject
- The badge should look like a premium collectible pin or medal
- Add subtle rim/edge lighting to give it a 3D coin-like appearance

CRITICAL:
- Preserve ALL visual elements from the original (symbols, objects, decorations)
- Keep the same colors and theme
- Make it look premium, polished, and consistent
- ALL badges must have the SAME style: same lighting direction (top-left), same glossiness level, same 3D depth
- The result should look like it belongs in a premium mobile game UI
- Output on a completely transparent background with NO shadows on the ground"""


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


def generate_one(client: OpenAI, input_path: Path, output_path: Path) -> bool:
    """Genera un singolo stemma 3D."""
    for attempt, backoff in enumerate(RETRY_BACKOFF):
        try:
            with open(input_path, "rb") as img_file:
                response = client.images.edit(
                    model="gpt-image-1",
                    image=img_file,
                    prompt=LEAGUE_BADGE_PROMPT,
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
        description="Genera stemmi lega 3D Disney/Pixar con gpt-image-1 (images.edit)"
    )
    parser.add_argument("--test", action="store_true", help="Solo prime 3 immagini")
    parser.add_argument("--all", action="store_true", help="Processa tutte le immagini")
    parser.add_argument(
        "--ids",
        type=str,
        help="Nomi file specifici separati da virgola senza estensione (es. L01_01,L01_02)",
    )
    parser.add_argument("--api-key", type=str, default=None, help="OpenAI API key")
    parser.add_argument(
        "--no-skip-existing",
        action="store_true",
        help="Rigenera anche se l'output esiste già",
    )
    parser.add_argument("--input-dir", type=Path, default=None, help="Cartella sorgente PNG")
    parser.add_argument("--output-dir", type=Path, default=None, help="Cartella output 3D")
    parser.add_argument(
        "--copy-to-frontend",
        action="store_true",
        help="Copia gli stemmi 3D in frontend_mobile/assets/images/league_badges/",
    )
    args = parser.parse_args()

    input_dir = args.input_dir or INPUT_DIR
    output_dir = args.output_dir or OUTPUT_DIR
    input_dir = Path(input_dir)
    output_dir = Path(output_dir)

    if not (args.test or args.all or args.ids):
        print("Specifica --test, --all o --ids <nomi>")
        sys.exit(1)

    try:
        client = get_client(args.api_key)
    except SystemExit as e:
        print(e)
        sys.exit(1)

    output_dir.mkdir(parents=True, exist_ok=True)

    # Scansiona solo file nella cartella principale (escludi source/ e 3d/)
    all_files: list[str] = []
    for f in sorted(input_dir.iterdir()):
        if f.is_file() and f.suffix.lower() in EXTENSIONS:
            all_files.append(f.name)

    if args.ids:
        names = [x.strip() for x in args.ids.split(",") if x.strip()]
        all_files = [f for f in all_files if Path(f).stem in names]

    if args.test:
        all_files = all_files[:3]

    if not all_files:
        print("Nessun file trovato!")
        sys.exit(0)

    print(f"Trovati {len(all_files)} stemmi da processare")

    generated = 0
    skipped = 0
    errors = 0
    failed: list[str] = []
    start_time = time.monotonic()

    for i, filename in enumerate(all_files):
        input_path = input_dir / filename
        output_name = Path(filename).stem + ".png"
        output_path = output_dir / output_name

        if output_path.exists() and not args.no_skip_existing:
            skipped += 1
            logger.info("[%d/%d] Skip (esiste): %s", i + 1, len(all_files), output_name)
            continue

        logger.info("[%d/%d] Generando: %s", i + 1, len(all_files), filename)

        if generate_one(client, input_path, output_path):
            generated += 1
            logger.info("  OK → %s", output_path)
        else:
            errors += 1
            failed.append(filename)

        if i < len(all_files) - 1:
            time.sleep(SLEEP_BETWEEN)

        if (i + 1) % 5 == 0:
            print(f"--- Progresso: {i+1}/{len(all_files)} - Generati: {generated} - Errori: {errors} ---")

    elapsed = time.monotonic() - start_time
    print("\n--- REPORT FINALE ---")
    print(f"Totale: {len(all_files)}")
    print(f"Generati: {generated}")
    print(f"Skippati: {skipped}")
    print(f"Errori: {errors}")
    if failed:
        print(f"Falliti: {failed}")
    print(f"Costo stimato: ${generated * COST_PER_IMAGE:.2f}")
    print(f"Tempo: {int(elapsed // 60)}m {int(elapsed % 60)}s")

    if args.copy_to_frontend:
        import shutil

        frontend_badges = backend_dir.parent / "frontend_mobile" / "assets" / "images" / "league_badges"
        frontend_badges.mkdir(parents=True, exist_ok=True)
        count = 0
        for p in output_dir.glob("*.png"):
            shutil.copy2(p, frontend_badges / p.name)
            count += 1
        print(f"Copiati {count} stemmi 3D in {frontend_badges}")


if __name__ == "__main__":
    main()
