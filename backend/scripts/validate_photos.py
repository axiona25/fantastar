#!/usr/bin/env python3
"""
Analizza le foto dei giocatori in static/photos/{id}.png e le classifica per qualità.
Usa OpenCV face detection (multi-cascade come nello script avatar).
Per categoria B esegue crop automatico mezzo busto in static/photos/cropped/{id}.png.
Report CSV: static/photos/photo_report.csv

SETUP: opencv-python-headless (in requirements.txt).
Eseguire: docker-compose exec backend python3 scripts/validate_photos.py
"""
from __future__ import annotations

import csv
import sys
from pathlib import Path

backend_dir = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(backend_dir))

PHOTOS_DIR = backend_dir / "static" / "photos"
CROPPED_DIR = PHOTOS_DIR / "cropped"
REPORT_PATH = PHOTOS_DIR / "photo_report.csv"

# Soglie
MIN_IMAGE_SIDE = 100   # sotto questo → C (problematica)
OK_IMAGE_SIDE = 200    # sotto 200x200 non A
MIN_FACE_AREA_PCT = 15.0  # viso almeno 15% area per A


def detect_face(img_bgr) -> tuple[int, int, int, int] | None:
    """Face detection multi-cascade. Ritorna (x, y, w, h) o None."""
    import cv2

    gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)
    cascades = [
        (cv2.data.haarcascades + "haarcascade_frontalface_default.xml", 1.1),
        (cv2.data.haarcascades + "haarcascade_frontalface_default.xml", 1.05),
        (cv2.data.haarcascades + "haarcascade_frontalface_alt2.xml", 1.1),
        (cv2.data.haarcascades + "haarcascade_profileface.xml", 1.1),
    ]
    for cascade_path, scale in cascades:
        face_cascade = cv2.CascadeClassifier(cascade_path)
        if face_cascade.empty():
            continue
        faces = face_cascade.detectMultiScale(gray, scaleFactor=scale, minNeighbors=5, minSize=(30, 30))
        if len(faces) > 0:
            (x, y, w, h) = max(faces, key=lambda r: r[2] * r[3])
            return (int(x), int(y), int(w), int(h))
    return None


def crop_half_bust_from_face(img_bgr, face: tuple[int, int, int, int]):
    """Crop quadrato mezzo busto centrato sul viso (stesse regole dello script avatar)."""
    import numpy as np

    h_img, w_img = img_bgr.shape[:2]
    x, y, w, h = face
    face_center_x = x + w // 2
    face_center_y = y + h // 2
    side = max(64, int(h * 2.8))
    y_top = face_center_y - int(h * 0.7)
    x_left = face_center_x - side // 2

    canvas_bgr = np.ones((side, side, 3), dtype=np.uint8) * 255
    x_right = x_left + side
    y_bottom = y_top + side
    src_x_s = max(0, x_left)
    src_x_e = min(w_img, x_right)
    src_y_s = max(0, y_top)
    src_y_e = min(h_img, y_bottom)
    dst_x_s = src_x_s - x_left
    dst_y_s = src_y_s - y_top
    h_copy = src_y_e - src_y_s
    w_copy = src_x_e - src_x_s
    if h_copy > 0 and w_copy > 0:
        canvas_bgr[dst_y_s : dst_y_s + h_copy, dst_x_s : dst_x_s + w_copy] = img_bgr[
            src_y_s:src_y_e, src_x_s:src_x_e
        ]
    return canvas_bgr


def get_player_info() -> dict[int, tuple[str, str]]:
    """Ritorna {id: (name, team)} per tutti i giocatori (o id con nome vuoto se no DB)."""
    try:
        from sqlalchemy import create_engine
        from sqlalchemy.orm import Session
        from app.config import settings
        from app.models.player import Player
        from app.models.real_team import RealTeam

        sync_url = getattr(settings, "DATABASE_URL", None) or __import__("os").environ.get("DATABASE_URL")
        if not sync_url or "+asyncpg" in (sync_url or ""):
            sync_url = (sync_url or "").replace("postgresql+asyncpg://", "postgresql://")
        engine = create_engine(sync_url)
        with Session(engine) as session:
            q = (
                session.query(Player.id, Player.name, RealTeam.name.label("team_name"))
                .outerjoin(RealTeam, Player.real_team_id == RealTeam.id)
                .where(Player.is_active == True)
            )
            rows = q.all()
            return {r.id: (r.name or "", r.team_name or "") for r in rows}
    except Exception:
        return {}


def analyze_photo(photo_path: Path) -> dict:
    """
    Analizza una foto. Ritorna dict con:
    category (A|B|C), face_found, face_size_pct, original_size, notes, face (x,y,w,h o None), img_bgr.
    """
    import cv2

    img = cv2.imread(str(photo_path))
    if img is None:
        return {
            "category": "C",
            "face_found": False,
            "face_size_pct": 0.0,
            "original_size": "0x0",
            "notes": "immagine non leggibile o corrotta",
            "face": None,
            "img_bgr": None,
        }
    h_img, w_img = img.shape[:2]
    if img.ndim == 2:
        img = cv2.cvtColor(img, cv2.COLOR_GRAY2BGR)
    original_size = f"{w_img}x{h_img}"

    if w_img < MIN_IMAGE_SIDE or h_img < MIN_IMAGE_SIDE:
        return {
            "category": "C",
            "face_found": False,
            "face_size_pct": 0.0,
            "original_size": original_size,
            "notes": "immagine troppo piccola",
            "face": None,
            "img_bgr": img,
        }

    face = detect_face(img)
    total_area = w_img * h_img
    face_area_pct = (face[2] * face[3] / total_area * 100.0) if face else 0.0
    face_center_y = (face[1] + face[3] // 2) if face else 0
    in_upper_half = face_center_y < h_img / 2 if face else False

    # A: viso trovato, >= 15% area, viso nella metà superiore, immagine > 200x200
    if face and face_area_pct >= MIN_FACE_AREA_PCT and in_upper_half and w_img > OK_IMAGE_SIDE and h_img > OK_IMAGE_SIDE:
        return {
            "category": "A",
            "face_found": True,
            "face_size_pct": round(face_area_pct, 1),
            "original_size": original_size,
            "notes": "OK per avatar",
            "face": face,
            "img_bgr": img,
        }

    # B: viso trovato ma (area < 15% O viso non in metà superiore)
    if face:
        notes = []
        if face_area_pct < MIN_FACE_AREA_PCT:
            notes.append("viso piccolo (figura intera)")
        if not in_upper_half:
            notes.append("viso non in metà superiore")
        return {
            "category": "B",
            "face_found": True,
            "face_size_pct": round(face_area_pct, 1),
            "original_size": original_size,
            "notes": "; ".join(notes),
            "face": face,
            "img_bgr": img,
        }

    # C: nessun viso
    return {
        "category": "C",
        "face_found": False,
        "face_size_pct": 0.0,
        "original_size": original_size,
        "notes": "nessun viso rilevato",
        "face": None,
        "img_bgr": img,
    }


def main() -> None:
    # Solo foto {id}.png (non _cutout)
    photo_files = []
    for p in PHOTOS_DIR.glob("*.png"):
        if p.stem.isdigit():
            photo_files.append((int(p.stem), p))
    photo_files.sort(key=lambda x: x[0])

    if not photo_files:
        print("Nessuna foto trovata in", PHOTOS_DIR)
        return

    player_info = get_player_info()
    rows = []
    cat_a = []
    cat_b = []
    cat_c = []

    CROPPED_DIR.mkdir(parents=True, exist_ok=True)

    for pid, path in photo_files:
        name, team = player_info.get(pid, ("", ""))
        result = analyze_photo(path)
        cat = result["category"]
        rows.append({
            "id": pid,
            "name": name,
            "team": team,
            "category": cat,
            "face_found": result["face_found"],
            "face_size_pct": result["face_size_pct"],
            "original_size": result["original_size"],
            "notes": result["notes"],
        })

        if cat == "A":
            cat_a.append((pid, name))
        elif cat == "B":
            cat_b.append((pid, name))
            # Crop e salva in cropped/{id}.png
            if result["img_bgr"] is not None and result["face"] is not None:
                crop_bgr = crop_half_bust_from_face(result["img_bgr"], result["face"])
                out_path = CROPPED_DIR / f"{pid}.png"
                import cv2
                cv2.imwrite(str(out_path), crop_bgr)
        else:
            cat_c.append((pid, name))

    # CSV
    with open(REPORT_PATH, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=["id", "name", "team", "category", "face_found", "face_size_pct", "original_size", "notes"])
        w.writeheader()
        w.writerows(rows)

    print(f"Report salvato: {REPORT_PATH}")
    print()
    print(f"Categoria A (OK, pronte per avatar): {len(cat_a)} giocatori")
    print(f"Categoria B (croppate in static/photos/cropped/): {len(cat_b)} giocatori")
    print(f"Categoria C (problematiche): {len(cat_c)} giocatori")
    if cat_c:
        print()
        print("Lista C (problematiche):")
        for pid, name in cat_c:
            print(f"  - {pid} {name or '(senza nome)'}")


if __name__ == "__main__":
    main()
