#!/usr/bin/env python3
"""
Divide un'immagine griglia di stemmi in singoli PNG separati.
Input: immagine con griglia 4 righe x 3 colonne (12 stemmi)
Output: 12 file PNG separati, ritagliati e puliti
"""

import argparse
import os
import sys

import numpy as np
from PIL import Image


def split_grid(input_path, output_dir, rows=4, cols=3, padding=0):
    """Divide un'immagine griglia in singoli stemmi. Crop stretto al contenuto e ridimensionamento
    uniforme (85% del quadrato 512x512) così tutti gli stemmi hanno la stessa dimensione visiva."""
    
    os.makedirs(output_dir, exist_ok=True)
    
    img = Image.open(input_path).convert("RGBA")
    width, height = img.size
    
    cell_width = width // cols
    cell_height = height // rows
    
    print(f"Immagine: {width}x{height}")
    print(f"Griglia: {rows}x{cols}, Cella: {cell_width}x{cell_height}")
    print(f"Output: {output_dir}")
    print()
    
    base_name = os.path.splitext(os.path.basename(input_path))[0]
    
    count = 0
    for row in range(rows):
        for col in range(cols):
            count += 1
            
            left = col * cell_width
            top = row * cell_height
            right = (col + 1) * cell_width
            bottom = (row + 1) * cell_height
            
            cell = img.crop((left, top, right, bottom))
            
            # 1. Converti sfondo nero/scuro in trasparente
            data = np.array(cell)
            # Pixel dove R+G+B totale < 80 → sfondo scuro
            brightness = data[:, :, 0].astype(int) + data[:, :, 1].astype(int) + data[:, :, 2].astype(int)
            is_dark = brightness < 80
            data[is_dark, 3] = 0
            cell = Image.fromarray(data)
            
            # 2. Trova il bounding box del contenuto REALE (non trasparente)
            bbox = cell.getbbox()
            if not bbox:
                print(f"  [{count:2d}] SKIP - vuota")
                continue
            
            # 3. Ritaglia STRETTO al contenuto (senza margini extra)
            cell = cell.crop(bbox)
            
            if cell.width < 50 or cell.height < 50:
                print(f"  [{count:2d}] SKIP - troppo piccolo")
                continue
            
            # 4. Ridimensiona per RIEMPIRE il quadrato al 85%
            # Tutti gli stemmi occupano la stessa % del quadrato → dimensione visiva uniforme
            target_size = 512
            usable_size = int(target_size * 0.85)  # 85% = stemma, 15% = margine uniforme
            
            scale = min(usable_size / cell.width, usable_size / cell.height)
            new_w = int(cell.width * scale)
            new_h = int(cell.height * scale)
            cell = cell.resize((new_w, new_h), Image.LANCZOS)
            
            # 5. Centra esattamente nel quadrato 512x512 trasparente
            square = Image.new("RGBA", (target_size, target_size), (0, 0, 0, 0))
            offset_x = (target_size - new_w) // 2
            offset_y = (target_size - new_h) // 2
            square.paste(cell, (offset_x, offset_y), cell)
            
            output_path = os.path.join(output_dir, f"{base_name}_{count:02d}.png")
            square.save(output_path, "PNG")
            print(f"  [{count:2d}] OK - contenuto {bbox[2]-bbox[0]}x{bbox[3]-bbox[1]} → {new_w}x{new_h} → 512x512")
    
    print(f"\nFatto! {count} celle processate")


def main():
    parser = argparse.ArgumentParser(description="Divide griglia stemmi in singoli PNG")
    parser.add_argument("--input", required=True, help="Immagine sorgente (griglia 4x3)")
    parser.add_argument("--output-dir", default=None, help="Cartella output (default: stessa cartella dell'input)")
    parser.add_argument("--rows", type=int, default=4, help="Numero righe nella griglia (default: 4)")
    parser.add_argument("--cols", type=int, default=3, help="Numero colonne nella griglia (default: 3)")
    parser.add_argument("--padding", type=int, default=5, help="Pixel di padding da escludere per cella (default: 5)")
    parser.add_argument("--all", action="store_true", help="Processa TUTTE le immagini nella cartella input")
    args = parser.parse_args()
    
    if args.all:
        # Processa tutte le immagini nella cartella
        input_dir = args.input
        output_dir = args.output_dir or "static/media/league_badges/"
        os.makedirs(output_dir, exist_ok=True)
        
        extensions = ('.png', '.jpg', '.jpeg', '.webp')
        images = [f for f in sorted(os.listdir(input_dir)) if f.lower().endswith(extensions)]
        
        print(f"Trovate {len(images)} immagini in {input_dir}")
        for img_file in images:
            print(f"\n--- Processando: {img_file} ---")
            split_grid(
                os.path.join(input_dir, img_file),
                output_dir,
                rows=args.rows,
                cols=args.cols,
                padding=args.padding,
            )
    else:
        output_dir = args.output_dir or "static/media/league_badges/"
        split_grid(args.input, output_dir, args.rows, args.cols, args.padding)


if __name__ == "__main__":
    main()
