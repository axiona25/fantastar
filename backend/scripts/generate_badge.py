#!/usr/bin/env python3
"""Genera uno stemma in stile 3D Disney/Pixar da un'immagine sorgente"""

import argparse
import base64
import os
import sys
from pathlib import Path

# Permette import da backend
backend_dir = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(backend_dir))

from openai import OpenAI

BADGE_PROMPT = """Transform this fantasy football team badge/logo into a high-quality 3D rendered version in the style of modern Disney Pixar animated films.

STYLE REQUIREMENTS:
- 3D rendered with soft lighting, subtle shadows, and clean lines
- Keep the same circular/shield shape of the original badge
- Preserve ALL text exactly as it appears (team name, any words)
- Preserve the main character/figure but render it in 3D Pixar style with smooth skin, expressive features
- Preserve the color scheme of the original badge
- The ball and any symbols should also be rendered in 3D
- Clean, polished, premium quality - like an official emblem for an animated movie
- Background should be transparent

CRITICAL:
- Keep the EXACT same layout and composition as the original
- All text must be readable and correctly spelled
- The result should look like an official badge from a Pixar/Disney sports movie
- DO NOT change the design, only transform the style to 3D animated"""

HTTP_TIMEOUT = 120.0


def main() -> None:
    parser = argparse.ArgumentParser(description="Genera stemma 3D Disney/Pixar da immagine sorgente")
    parser.add_argument("--input", required=True, help="Path all'immagine stemma sorgente")
    parser.add_argument("--output", required=True, help="Path dove salvare lo stemma generato")
    parser.add_argument("--api-key", default=None, help="OpenAI API key (altrimenti env OPENAI_API_KEY)")
    args = parser.parse_args()

    api_key = args.api_key or os.environ.get("OPENAI_API_KEY")
    if not api_key:
        print("Errore: fornire --api-key o impostare OPENAI_API_KEY")
        sys.exit(1)

    out_dir = os.path.dirname(args.output)
    if out_dir:
        os.makedirs(out_dir, exist_ok=True)

    client = OpenAI(api_key=api_key, timeout=HTTP_TIMEOUT)

    print(f"Generando stemma 3D da: {args.input}")
    print(f"Output: {args.output}")

    with open(args.input, "rb") as img_file:
        response = client.images.edit(
            model="gpt-image-1",
            image=img_file,
            prompt=BADGE_PROMPT,
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
        print("ERRORE: nessun dato immagine")
        sys.exit(1)

    with open(args.output, "wb") as f:
        f.write(img_bytes)

    print(f"SUCCESSO! Stemma salvato in {args.output}")


if __name__ == "__main__":
    main()
