#!/usr/bin/env python3
"""
Genera stemmi/carte 3D Disney/Pixar da immagini in una cartella sorgente.
Usa gpt-image-1 images.edit. Output sempre PNG trasparente.

Tipi: team_badges (stemmi squadre), league_badges (stemmi leghe), cards (carte).
Cartelle: source/ per input, output nella cartella media corrispondente.
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

MEDIA_DIR = backend_dir / "static" / "media"
SECRETS_DIR = backend_dir / "secrets"
OPENAI_KEY_FILE = SECRETS_DIR / "openai_api_key.txt"

SLEEP_BETWEEN = 2
RETRY_AFTER_RATE_LIMIT = 60
MAX_ATTEMPTS = 3
RETRY_BACKOFF = [5, 15, 30]
HTTP_TIMEOUT = 120.0

IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp"}

# Prompt per stemmi squadra (team_badges)
BADGE_PROMPT_TEAM = """Transform this image into a high-quality 3D rendered team badge/emblem in the style of modern Disney Pixar animated films.

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
- Style must be consistent: 3D Disney Pixar animated look"""

# Prompt per stemmi lega/campionato (league_badges)
BADGE_PROMPT_LEAGUE = """Transform this image into a high-quality 3D rendered league/championship badge or logo in the style of modern Disney Pixar animated films.

STYLE REQUIREMENTS:
- 3D rendered with soft lighting, subtle shadows, and clean polished surfaces
- If there is a trophy, shield, or symbol, render it in 3D Pixar style with smooth surfaces and depth
- If there is text (league name, year), preserve it exactly as it appears, rendered in 3D with slight depth/emboss effect
- Preserve the original color scheme
- The badge should look like an official league emblem from an animated sports movie
- Clean circular or shield shape, premium quality

COMPOSITION:
- Keep the same general layout as the original
- Center the main subject (trophy, shield, logo)
- Output as a clean badge/emblem shape

CRITICAL:
- Preserve any text exactly as written
- Keep the same colors and theme
- Make it look premium and professional
- Style must be consistent: 3D Disney Pixar animated look"""

# Placeholder per carte giocatori (cards) – da raffinare in seguito
BADGE_PROMPT_CARDS = """Transform this image into a high-quality 3D rendered collectible card in the style of modern Disney Pixar animated films.

STYLE REQUIREMENTS:
- 3D rendered with soft lighting, subtle shadows, and clean polished surfaces
- If there is a character or portrait, render it in 3D Pixar style
- If there is text, preserve it exactly as it appears
- Preserve the original color scheme
- The card should look like a premium collectible from an animated movie
- Professional, polished, high quality

COMPOSITION:
- Keep the same general layout as the original
- Center the main subject
- Output as a clean card shape

CRITICAL:
- Preserve any text exactly as written
- Style must be consistent: 3D Disney Pixar animated look"""

PROMPTS = {
    "team_badges": BADGE_PROMPT_TEAM,
    "league_badges": BADGE_PROMPT_LEAGUE,
    "cards": BADGE_PROMPT_CARDS,
}

DEFAULT_PATHS = {
    "team_badges": (MEDIA_DIR / "team_badges" / "source", MEDIA_DIR / "team_badges"),
    "league_badges": (MEDIA_DIR / "league_badges" / "source", MEDIA_DIR / "league_badges"),
    "cards": (MEDIA_DIR / "cards" / "source", MEDIA_DIR / "cards"),
}


def _load_key_from_file() -> str | None:
    if not OPENAI_KEY_FILE.is_file():
        return None
    try:
        key = OPENAI_KEY_FILE.read_text(encoding="utf-8").strip()
        return key if key and not key.startswith("#") else None
    except Exception:
        return None


def get_client(api_key: str) -> "OpenAI":
    from openai import OpenAI
    return OpenAI(api_key=api_key, timeout=HTTP_TIMEOUT)


def _response_to_bytes(response_or_json) -> bytes | None:
    import httpx
    if hasattr(response_or_json, "data") and response_or_json.data and len(response_or_json.data) > 0:
        item = response_or_json.data[0]
        if getattr(item, "b64_json", None):
            return base64.b64decode(item.b64_json)
        if getattr(item, "url", None):
            with httpx.Client(timeout=HTTP_TIMEOUT) as h:
                r = h.get(item.url)
                r.raise_for_status()
                return r.content
    if isinstance(response_or_json, dict) and response_or_json.get("data") and len(response_or_json["data"]) > 0:
        item = response_or_json["data"][0]
        if item.get("b64_json"):
            return base64.b64decode(item["b64_json"])
        if item.get("url"):
            with httpx.Client(timeout=HTTP_TIMEOUT) as h:
                r = h.get(item["url"])
                r.raise_for_status()
                return r.content
    return None


def generate_badge(image_path: Path, prompt: str, api_key: str, client) -> tuple[bytes | None, str | None]:
    """Genera stemma 3D con gpt-image-1. Ritorna (bytes, None) o (None, errore)."""
    import httpx
    e1 = e2 = None
    # Metodo 1: SDK
    try:
        with open(image_path, "rb") as img_file:
            response = client.images.edit(
                model="gpt-image-1",
                image=img_file,
                prompt=prompt,
                size="1024x1024",
                background="transparent",
            )
        out = _response_to_bytes(response)
        if out is not None:
            return out, None
    except Exception as e1:
        logger.debug("images.edit errore: %s", e1)
    # Metodo 2: HTTP diretto
    try:
        url = "https://api.openai.com/v1/images/edits"
        headers = {"Authorization": f"Bearer {api_key}"}
        with open(image_path, "rb") as img_file:
            files = {"image": (image_path.name, img_file, "image/png")}
            data = {
                "model": "gpt-image-1",
                "prompt": prompt,
                "size": "1024x1024",
                "background": "transparent",
            }
            with httpx.Client(timeout=HTTP_TIMEOUT) as h:
                resp = h.post(url, headers=headers, files=files, data=data, timeout=HTTP_TIMEOUT)
        if resp.status_code != 200:
            raise Exception(f"HTTP {resp.status_code}: {resp.text[:500]}")
        out = _response_to_bytes(resp.json())
        if out is not None:
            return out, None
    except Exception as e2:
        logger.debug("HTTP diretto errore: %s", e2)
    return None, f"Errore 1: {e1}, Errore 2: {e2}"


def run_one(
    source_path: Path,
    output_path: Path,
    prompt: str,
    api_key: str,
    client,
) -> tuple[bool, str | None]:
    """Genera un singolo stemma. Ritorna (True, None) o (False, messaggio_errore)."""
    for attempt in range(MAX_ATTEMPTS):
        if attempt > 0:
            backoff = RETRY_BACKOFF[attempt - 1]
            print(f"  Retry {attempt}/{MAX_ATTEMPTS} tra {backoff}s...")
            time.sleep(backoff)
        try:
            image_bytes, err = generate_badge(source_path, prompt, api_key, client)
            if err:
                err_lower = err.lower()
                if "429" in err_lower or "rate" in err_lower:
                    if attempt < MAX_ATTEMPTS - 1:
                        print(f"  Rate limit (429), attendo {RETRY_AFTER_RATE_LIMIT}s...")
                        time.sleep(RETRY_AFTER_RATE_LIMIT)
                        continue
                return False, err
            if not image_bytes:
                return False, "no_image"
            output_path.parent.mkdir(parents=True, exist_ok=True)
            output_path.write_bytes(image_bytes)
            return True, None
        except Exception as e:
            err_str = str(e).lower()
            if "429" in err_str or "rate" in err_str:
                if attempt < MAX_ATTEMPTS - 1:
                    print(f"  Rate limit (429), attendo {RETRY_AFTER_RATE_LIMIT}s...")
                    time.sleep(RETRY_AFTER_RATE_LIMIT)
                    continue
            return False, str(e)
    return False, "max_attempts"


def collect_source_images(input_dir: Path) -> list[Path]:
    """Ritorna lista di file immagine in input_dir, ordinati per nome."""
    if not input_dir.is_dir():
        return []
    out: list[Path] = []
    for p in input_dir.iterdir():
        if p.is_file() and p.suffix.lower() in IMAGE_EXTENSIONS:
            out.append(p)
    return sorted(out, key=lambda x: x.name.lower())


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Genera stemmi/carte 3D Disney/Pixar da cartella sorgente (gpt-image-1)"
    )
    parser.add_argument(
        "--type",
        choices=["team_badges", "league_badges", "cards"],
        default="team_badges",
        help="Tipo: team_badges, league_badges o cards (default: team_badges)",
    )
    parser.add_argument("--test", action="store_true", help="Processa solo le prime 3 immagini")
    parser.add_argument("--all", action="store_true", help="Processa tutte le immagini")
    parser.add_argument(
        "--input-dir",
        type=Path,
        default=None,
        help="Cartella sorgente (default: static/media/<type>/source/)",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=None,
        help="Cartella output (default: static/media/<type>/)",
    )
    parser.add_argument("--api-key", type=str, default=None, help="OpenAI API key")
    args = parser.parse_args()

    badge_type = args.type
    default_src, default_out = DEFAULT_PATHS[badge_type]
    input_dir = args.input_dir if args.input_dir is not None else default_src
    output_dir = args.output_dir if args.output_dir is not None else default_out

    if not args.test and not args.all:
        print("Specifica --test (prime 3) o --all")
        sys.exit(1)

    api_key = args.api_key or os.environ.get("OPENAI_API_KEY") or _load_key_from_file()
    if not api_key:
        print("Fornire --api-key o OPENAI_API_KEY o salvare chiave in", OPENAI_KEY_FILE)
        sys.exit(1)

    prompt = PROMPTS[badge_type]
    client = get_client(api_key)

    images = collect_source_images(input_dir)
    if not images:
        print(f"Nessuna immagine in {input_dir} (estensioni: {', '.join(IMAGE_EXTENSIONS)})")
        sys.exit(0)

    # Output sempre .png; nome = stemma del file sorgente
    to_process: list[tuple[Path, Path]] = []
    for src in images:
        out_path = output_dir / f"{src.stem}.png"
        if out_path.is_file():
            continue  # skip existing
        to_process.append((src, out_path))

    skipped = len(images) - len(to_process)
    if args.test:
        to_process = to_process[:3]
    if skipped:
        print(f"Skip esistenti: {skipped} file già presenti in output.")
    if not to_process:
        print("Nessun file da processare.")
        sys.exit(0)

    os.makedirs(output_dir, exist_ok=True)
    os.makedirs(input_dir, exist_ok=True)

    generated = 0
    errors: list[tuple[str, str]] = []
    failed_names: list[str] = []
    start_time = time.monotonic()
    total = len(to_process)

    for i, (src_path, out_path) in enumerate(to_process):
        print(f"[{i+1}/{total}] {src_path.name} -> {out_path.name}")
        try:
            success, err = run_one(src_path, out_path, prompt, api_key, client)
            if success:
                generated += 1
                print(f"  OK -> {out_path}")
            else:
                errors.append((src_path.name, err or "unknown"))
                failed_names.append(src_path.stem)
                print(f"  Errore: {err}")
        except Exception as e:
            logger.exception("Eccezione per %s: %s", src_path.name, e)
            errors.append((src_path.name, str(e)))
            failed_names.append(src_path.stem)
            print(f"  Errore: {e}")
        if (i + 1) % 10 == 0 and total > 10:
            pct = 100.0 * (i + 1) / total
            print(f"--- Progresso: {i+1}/{total} ({pct:.1f}%) - Errori: {len(errors)} ---")
        if i < total - 1:
            time.sleep(SLEEP_BETWEEN)

    elapsed = time.monotonic() - start_time
    minutes = int(elapsed // 60)
    seconds = int(elapsed % 60)

    print("\n--- REPORT FINALE ---")
    print(f"Totale considerati: {len(images)}")
    print(f"Generati: {generated}")
    print(f"Skippati (già esistenti): {skipped}")
    print(f"Errori: {len(errors)}")
    if failed_names:
        print(f"File falliti (stem): {failed_names}")
    print(f"Tempo totale: {minutes}m {seconds}s")


if __name__ == "__main__":
    main()
