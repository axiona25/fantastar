#!/usr/bin/env python3
"""
Genera avatar cartoon (mezzo busto) con AnimeGANv2 PyTorch dalle foto giocatori.
Legge da static/photos/ (NON modifica). Salva in static/avatars/.
torch.hub scarica automaticamente i pesi da GitHub.

SETUP: pip install torch torchvision Pillow opencv-python-headless

Uso:
  --test      : 10 giocatori (usa --quality high)
  --all       : tutti i 657
  --ids       : ID specifici (es. --ids 249,306,100)
  --quality   : low | medium (default) | high
  --style     : anime | celeba (default) | paprika
  --compare   : per UN giocatore genera tutti e 3 gli stili in test_<style>_<id>.png

Eseguire: docker-compose exec backend python3 scripts/generate_cartoon_avatars.py --compare --ids 249
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

backend_dir = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(backend_dir))

PHOTOS_DIR = backend_dir / "static" / "photos"
AVATARS_DIR = backend_dir / "static" / "avatars"
OUT_SIZE = 512  # output finale (più dettaglio di 400)

# Quality: (model_size, preprocess, double_pass, postprocess)
QUALITY_LOW = "low"      # 512, singolo passaggio (veloce)
QUALITY_MEDIUM = "medium"  # 768, singolo + post (default)
QUALITY_HIGH = "high"    # 1024, doppio passaggio + pre/post (migliore)

# Stili: nome argomento -> pretrained (torch.hub)
STYLE_ANIME = "anime"    # face_paint_512_v2 (anime giapponese)
STYLE_CELEBA = "celeba"  # celeba_distill (western cartoon, vicino a Disney) - default
STYLE_PAPRIKA = "paprika"  # paprika (stile film Paprika, colori vivaci)
STYLE_PRETRAINED = {
    STYLE_ANIME: "face_paint_512_v2",
    STYLE_CELEBA: "celeba_distill",
    STYLE_PAPRIKA: "paprika",
}

TEST_IDS = [249, 306, 1, 100, 150, 200, 300, 400, 500, 600]


def load_animegan_model(style: str = STYLE_CELEBA, device=None):
    """Carica il modello AnimeGANv2 (torch.hub). style: anime | celeba | paprika."""
    import torch

    if device is None:
        device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    style_name = STYLE_PRETRAINED.get(style, STYLE_PRETRAINED[STYLE_CELEBA])
    model = torch.hub.load(
        "bryandlee/animegan2-pytorch:main",
        "generator",
        pretrained=style_name,
    )
    model = model.to(device)
    model.eval()
    return model


def _round_to_multiple_of_8(n: int) -> int:
    return max(64, (n // 8) * 8)


def cartoonize_animegan(model, img_pil, size: int = 512) -> "Image.Image":
    """
    img_pil: PIL Image RGB
    size: lato quadrato (multiplo di 8). Il modello accetta qualsiasi dimensione multipla di 8.
    returns: PIL Image cartoon RGB (size x size)
    """
    import torch
    from PIL import Image
    from torchvision.transforms.functional import to_tensor, to_pil_image

    size = _round_to_multiple_of_8(size)
    device = next(model.parameters()).device
    img_resized = img_pil.resize((size, size), Image.LANCZOS)

    with torch.no_grad():
        input_tensor = to_tensor(img_resized).unsqueeze(0) * 2 - 1
        output = model(input_tensor.to(device)).cpu()[0]
        output = (output * 0.5 + 0.5).clip(0, 1)

    return to_pil_image(output)


def load_image(pid: int) -> tuple["np.ndarray | None", "np.ndarray | None"]:
    """
    Carica cutout se esiste, altrimenti foto normale.
    Ritorna (BGR 3 canali su sfondo bianco se RGBA, alpha_mask).
    alpha_mask: (H,W) uint8 0-255, None se non cutout. Usato dopo cartoon per forzare bianco dove alpha=0.
    """
    import cv2
    import numpy as np

    cutout_path = PHOTOS_DIR / f"{pid}_cutout.png"
    photo_path = PHOTOS_DIR / f"{pid}.png"
    path = cutout_path if cutout_path.exists() else (photo_path if photo_path.exists() else None)
    if not path or not path.is_file():
        return None, None

    img = cv2.imread(str(path), cv2.IMREAD_UNCHANGED)
    if img is None:
        return None, None

    if img.ndim == 2:
        img = cv2.cvtColor(img, cv2.COLOR_GRAY2BGR)
        return img, None
    if img.ndim == 3 and img.shape[-1] == 4:
        alpha_uint8 = img[:, :, 3].copy()  # maschera da riapplicare dopo cartoon
        alpha = img[:, :, 3].astype(np.float32) / 255.0
        bgr = img[:, :, :3].copy()
        white_bg = np.ones_like(bgr, dtype=np.uint8) * 255
        for c in range(3):
            bgr[:, :, c] = (alpha * bgr[:, :, c].astype(np.float32) + (1 - alpha) * white_bg[:, :, c]).astype(np.uint8)
        return bgr, alpha_uint8
    return img, None


def detect_face(img_bgr) -> tuple[int, int, int, int] | None:
    """
    Face detection con più tentativi. Ritorna (x, y, w, h) della faccia più grande, o None.
    Ordine: frontal default 1.1 → 1.05 → frontal_alt2 → profile.
    """
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


def _white_ratio(crop_bgr: "np.ndarray") -> float:
    """Frazione di pixel quasi bianchi (R,G,B >= 250)."""
    import numpy as np

    w = (crop_bgr[:, :, 0] >= 250) & (crop_bgr[:, :, 1] >= 250) & (crop_bgr[:, :, 2] >= 250)
    return float(np.count_nonzero(w)) / crop_bgr.shape[0] / crop_bgr.shape[1]


def _paste_crop_onto_canvas(
    img_bgr: "np.ndarray",
    alpha_mask: "np.ndarray | None",
    side: int,
    x_left: int,
    y_top: int,
) -> tuple["np.ndarray", "np.ndarray | None"]:
    """Crea canvas bianco side x side e incolla la porzione di immagine disponibile (con padding se esce)."""
    import numpy as np

    h_img, w_img = img_bgr.shape[:2]
    canvas_bgr = np.ones((side, side, 3), dtype=np.uint8) * 255
    canvas_alpha = np.zeros((side, side), dtype=np.uint8) if alpha_mask is not None else None
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
    if h_copy <= 0 or w_copy <= 0:
        return canvas_bgr, canvas_alpha
    canvas_bgr[dst_y_s : dst_y_s + h_copy, dst_x_s : dst_x_s + w_copy] = img_bgr[src_y_s:src_y_e, src_x_s:src_x_e]
    if canvas_alpha is not None and alpha_mask is not None:
        canvas_alpha[dst_y_s : dst_y_s + h_copy, dst_x_s : dst_x_s + w_copy] = alpha_mask[
            src_y_s:src_y_e, src_x_s:src_x_e
        ]
    return canvas_bgr, canvas_alpha


def crop_half_bust(
    img_bgr: "np.ndarray",
    alpha_mask: "np.ndarray | None",
    face: tuple[int, int, int, int] | None,
) -> tuple["np.ndarray", "np.ndarray | None"]:
    """
    Crop quadrato mezzo busto (testa + collo + spalle). Gestisce figura intera e 3/4.
    Proporzioni: spazio sopra testa 40%, viso + collo+spalle sotto; crop quadrato centrato sul viso.
    Se esce dai bordi: canvas bianco con porzione incollata. Validazione: troppo piccolo o >80% bianco → fallback o retry.
    """
    import numpy as np

    h_img, w_img = img_bgr.shape[:2]
    use_face = face is not None
    face_mult = 2.8  # primo tentativo

    if use_face:
        x, y, w, h = face
        face_center_x = x + w // 2
        face_center_y = y + h // 2
        # Crop quadrato: altezza totale ~2.6*h (0.4 sopra + h viso + 1.2 sotto); usiamo 2.8*h per margine
        # Top: 70% di h sopra il centro del viso (così ~0.4*h sopra la testa)
        side = int(h * face_mult)
        side = max(side, 64)
        if side < 100:
            use_face = False
        else:
            y_top = face_center_y - int(h * 0.7)
            x_left = face_center_x - side // 2
            canvas_bgr, canvas_alpha = _paste_crop_onto_canvas(img_bgr, alpha_mask, side, x_left, y_top)
            if _white_ratio(canvas_bgr) > 0.8:
                # Sfondo quasi tutto bianco (cutout con viso piccolo): riprova con crop più largo
                face_mult = 3.4
                side = max(64, int(h * face_mult))
                y_top = face_center_y - int(h * 0.7)
                x_left = face_center_x - side // 2
                canvas_bgr, canvas_alpha = _paste_crop_onto_canvas(img_bgr, alpha_mask, side, x_left, y_top)
                if _white_ratio(canvas_bgr) > 0.8:
                    use_face = False

    if not use_face:
        # Fallback: crop dalla parte superiore (dove di solito c'è il viso)
        # Portrait: 50% superiore; landscape: centro; dimensione min(w, h*0.6), 5% dall'alto, centrato orizz.
        side = int(min(w_img, h_img * 0.6))
        side = max(side, 64)
        side = min(side, h_img, w_img)
        y_top = int(0.05 * h_img)
        x_left = (w_img - side) // 2
        canvas_bgr, canvas_alpha = _paste_crop_onto_canvas(img_bgr, alpha_mask, side, x_left, y_top)

    return canvas_bgr, canvas_alpha


def apply_white_background(cartoon_rgb: "np.ndarray", alpha_crop_resized: "np.ndarray | None") -> "np.ndarray":
    """
    Sfondo bianco puro: dove alpha era 0 (o pixel quasi bianchi) → (255,255,255).
    cartoon_rgb: (H, W, 3) uint8 RGB (qualsiasi dimensione).
    """
    import numpy as np

    out = cartoon_rgb.copy()
    if alpha_crop_resized is not None:
        mask_bg = alpha_crop_resized < 128
        out[mask_bg] = [255, 255, 255]
    else:
        near_white = (cartoon_rgb[:, :, 0] > 250) & (cartoon_rgb[:, :, 1] > 250) & (cartoon_rgb[:, :, 2] > 250)
        out[near_white] = [255, 255, 255]
    return out


def preprocess_for_model(img_pil: "Image.Image", do_enhance: bool) -> "Image.Image":
    """Contrasto +15%, nitidezza +20% prima del modello (se do_enhance)."""
    if not do_enhance:
        return img_pil
    from PIL import ImageEnhance

    enhancer = ImageEnhance.Contrast(img_pil)
    img_pil = enhancer.enhance(1.15)
    enhancer = ImageEnhance.Sharpness(img_pil)
    img_pil = enhancer.enhance(1.2)
    return img_pil


def postprocess_cartoon(cartoon_pil: "Image.Image", do_enhance: bool) -> "Image.Image":
    """Nitidezza +30%, saturazione +10% dopo cartoon (se do_enhance)."""
    if not do_enhance:
        return cartoon_pil
    from PIL import ImageEnhance

    enhancer = ImageEnhance.Sharpness(cartoon_pil)
    cartoon_pil = enhancer.enhance(1.3)
    enhancer = ImageEnhance.Color(cartoon_pil)
    cartoon_pil = enhancer.enhance(1.1)
    return cartoon_pil


def disney_post_process(img_pil: "Image.Image") -> "Image.Image":
    """Post-processing Disney/Pixar-like: pelle liscia, colori vivaci, contrasto e nitidezza."""
    from PIL import ImageEnhance, ImageFilter

    img = img_pil.filter(ImageFilter.SMOOTH_MORE)
    enhancer = ImageEnhance.Color(img)
    img = enhancer.enhance(1.3)
    enhancer = ImageEnhance.Contrast(img)
    img = enhancer.enhance(1.1)
    enhancer = ImageEnhance.Brightness(img)
    img = enhancer.enhance(1.05)
    enhancer = ImageEnhance.Sharpness(img)
    img = enhancer.enhance(1.2)
    return img


def get_quality_params(quality: str) -> tuple[int, bool, bool, bool]:
    """Ritorna (model_size, preprocess, double_pass, postprocess)."""
    if quality == QUALITY_LOW:
        return 512, False, False, False
    if quality == QUALITY_MEDIUM:
        return 768, False, False, True
    # high
    return 1024, True, True, True


def generate_avatar(
    pid: int,
    model,
    quality: str = QUALITY_MEDIUM,
    output_path: Path | None = None,
) -> tuple[bool, str | None, bool]:
    """
    Ritorna (success, error_message, face_detected).
    Pipeline: carica → crop mezzo busto → resize a model_size → pre → cartoon (1 o 2 pass) → sfondo bianco → Disney post → resize OUT_SIZE → salva.
    output_path: se fornito, salva qui (per --compare).
    """
    import cv2
    import numpy as np
    from PIL import Image

    model_size, do_pre, do_double, do_post = get_quality_params(quality)
    model_size = _round_to_multiple_of_8(model_size)

    img_bgr, alpha_mask = load_image(pid)
    if img_bgr is None:
        return False, "load_failed", False
    try:
        face = detect_face(img_bgr)
        crop_bgr, crop_alpha = crop_half_bust(img_bgr, alpha_mask, face)

        crop_rgb = cv2.cvtColor(crop_bgr, cv2.COLOR_BGR2RGB)
        img_pil = Image.fromarray(crop_rgb).resize((model_size, model_size), Image.LANCZOS)

        img_pil = preprocess_for_model(img_pil, do_pre)

        cartoon_pil = cartoonize_animegan(model, img_pil, size=model_size)
        if do_double:
            output2 = cartoonize_animegan(model, cartoon_pil, size=model_size)
            cartoon_pil = Image.blend(cartoon_pil, output2, alpha=0.4)  # 60% primo + 40% secondo (più cartoon)

        cartoon_rgb = np.array(cartoon_pil)
        alpha_resized = None
        if crop_alpha is not None:
            alpha_resized = np.array(Image.fromarray(crop_alpha).resize((model_size, model_size), Image.LANCZOS))
        cartoon_white = apply_white_background(cartoon_rgb, alpha_resized)
        out_pil = Image.fromarray(cartoon_white)

        if do_post:
            out_pil = disney_post_process(out_pil)
        out_pil = out_pil.resize((OUT_SIZE, OUT_SIZE), Image.LANCZOS)

        AVATARS_DIR.mkdir(parents=True, exist_ok=True)
        out_path = output_path if output_path is not None else AVATARS_DIR / f"{pid}.png"
        out_pil.save(str(out_path), "PNG", optimize=True)
        return True, None, (face is not None)
    except Exception as e:
        return False, str(e), False


def get_player_ids_and_names(mode: str, id_list: list[int] | None) -> list[tuple[int, str]]:
    if mode == "all":
        try:
            from app.config import settings
            from sqlalchemy import create_engine, text
            from sqlalchemy.orm import Session
            sync_url = settings.DATABASE_URL
            if "+asyncpg" in sync_url:
                sync_url = sync_url.replace("postgresql+asyncpg://", "postgresql://")
            engine = create_engine(sync_url)
            with Session(engine) as session:
                r = session.execute(text("SELECT id, name FROM players ORDER BY id"))
                return [(row[0], row[1] or "") for row in r.fetchall()]
        except Exception:
            seen = set()
            for f in PHOTOS_DIR.glob("*.png"):
                stem = f.stem
                if stem.isdigit():
                    seen.add(int(stem))
                elif stem.endswith("_cutout"):
                    try:
                        seen.add(int(stem.replace("_cutout", "")))
                    except ValueError:
                        pass
            return [(i, "") for i in sorted(seen)]
    ids = id_list if id_list else TEST_IDS
    try:
        from app.config import settings
        from sqlalchemy import create_engine, text
        from sqlalchemy.orm import Session
        sync_url = settings.DATABASE_URL
        if "+asyncpg" in sync_url:
            sync_url = sync_url.replace("postgresql+asyncpg://", "postgresql://")
        engine = create_engine(sync_url)
        with Session(engine) as session:
            id_to_name = {}
            for i in ids:
                r = session.execute(text("SELECT name FROM players WHERE id = :id"), {"id": i})
                row = r.fetchone()
                id_to_name[i] = row[0] if row else ""
            return [(i, id_to_name.get(i, "")) for i in ids]
    except Exception:
        return [(i, "") for i in ids]


def main() -> None:
    parser = argparse.ArgumentParser(description="Genera avatar cartoon AnimeGANv2 per giocatori")
    parser.add_argument("--test", action="store_true", help="Genera per 10 ID di test (usa quality=high)")
    parser.add_argument("--all", action="store_true", help="Genera per tutti i giocatori")
    parser.add_argument("--ids", type=str, help="ID separati da virgola (es. 249,306,100)")
    parser.add_argument(
        "--quality",
        choices=[QUALITY_LOW, QUALITY_MEDIUM, QUALITY_HIGH],
        default=QUALITY_MEDIUM,
        help="low=512 1 pass; medium=768+post (default); high=1024 2 pass+pre/post",
    )
    parser.add_argument(
        "--style",
        choices=[STYLE_ANIME, STYLE_CELEBA, STYLE_PAPRIKA],
        default=STYLE_CELEBA,
        help="anime=face_paint; celeba=western/Disney (default); paprika=Paprika",
    )
    parser.add_argument(
        "--compare",
        action="store_true",
        help="Per UN giocatore genera tutti e 3 gli stili in test_<style>_<id>.png (usa --ids)",
    )
    args = parser.parse_args()

    quality = QUALITY_HIGH if args.test else args.quality

    id_list = None
    if args.ids:
        try:
            id_list = [int(x.strip()) for x in args.ids.split(",") if x.strip()]
        except ValueError:
            print("Errore: --ids deve essere una lista di numeri separati da virgola")
            sys.exit(1)
        if not id_list:
            print("Nessun ID fornito con --ids")
            sys.exit(1)
        mode = "ids"
    elif args.all:
        mode = "all"
    elif args.test:
        mode = "test"
        id_list = TEST_IDS
    else:
        print("Specifica --test, --all, --compare o --ids <lista>")
        sys.exit(1)

    if args.compare:
        if len(id_list or []) != 1:
            print("--compare richiede esattamente un ID (es. --ids 249)")
            sys.exit(1)
        pid = (id_list or [TEST_IDS[0]])[0]
        players = [(pid, "")]
        AVATARS_DIR.mkdir(parents=True, exist_ok=True)
        quality = QUALITY_HIGH
        for style in [STYLE_ANIME, STYLE_CELEBA, STYLE_PAPRIKA]:
            print(f"Stile: {style} (pretrained={STYLE_PRETRAINED[style]})")
            model = load_animegan_model(style=style)
            out_path = AVATARS_DIR / f"test_{style}_{pid}.png"
            success, err, _ = generate_avatar(pid, model, quality=quality, output_path=out_path)
            if success:
                print(f"  Salvato: {out_path}")
            else:
                print(f"  Errore: {err}")
        print("Fatto. Confronta test_anime_*.png, test_celeba_*.png, test_paprika_*.png")
        return

    players = get_player_ids_and_names(mode, id_list)
    if not players:
        print("Nessun giocatore da processare.")
        sys.exit(0)

    print(f"Stile: {args.style} | Qualità: {quality} (output {OUT_SIZE}x{OUT_SIZE})")
    print("Caricamento modello AnimeGANv2 (torch.hub)...")
    model = load_animegan_model(style=args.style)
    print("Modello pronto.")

    AVATARS_DIR.mkdir(parents=True, exist_ok=True)
    generated = 0
    face_failed: list[str] = []
    errors: list[tuple[int, str, str]] = []

    for pid, name in players:
        success, err, face_detected = generate_avatar(pid, model, quality=quality)
        if success:
            generated += 1
            if not face_detected:
                face_failed.append(name or str(pid))
        else:
            errors.append((pid, name or "", err or "unknown"))

    print("\n--- Report ---")
    print(f"Avatar generati: {generated}")
    print(f"Face detection fallito: {len(face_failed)}")
    if face_failed:
        for n in face_failed[:30]:
            print(f"  - {n}")
        if len(face_failed) > 30:
            print(f"  ... e altri {len(face_failed) - 30}")
    print(f"Errori: {len(errors)}")
    if errors:
        for pid, name, msg in errors[:20]:
            print(f"  - {pid} ({name}): {msg}")
        if len(errors) > 20:
            print(f"  ... e altri {len(errors) - 20}")


if __name__ == "__main__":
    main()
