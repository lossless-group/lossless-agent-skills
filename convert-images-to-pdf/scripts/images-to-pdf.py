#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["pillow>=11", "pymupdf>=1.24", "numpy>=1.26", "pillow-heif>=0.18"]
# ///
"""
images-to-pdf.py — turn a folder of slide images (screenshots, exports, photos of
pages) into ONE lean PDF deck: one page per image, sized to the image, JPEG inside.

Settled defaults (from memopop-orchestrator/scripts/slim_deck.py and deck_analyst.py,
measured 28.0 MB -> 1.4 MB on a retina-screenshot deck; do not drift without a reason):
  long side capped at 1600 px   (16:9 -> 1600x900; retina screenshots are 2-3x this)
  JPEG quality 85, optimize=True
  assembled with PyMuPDF        (not img2pdf, not Ghostscript, not ImageMagick)

Order:
  --order auto     macOS screenshot names -> capture time (earliest = page 1);
                   anything else -> natural filename sort (slide-2 before slide-10)
  --order capture  timestamp in the filename, else file birth time
  --order name     natural filename sort

Usage:
  images-to-pdf.py <dir | img img ...> -o deck.pdf [--max-long 1600] [--quality 85]
                   [--order auto|capture|name] [--crop-chrome] [--dry-run]

Never overwrites the output and never deletes an input.
Exit codes: 0 ok, 2 bad args / nothing to do, 3 output exists.
"""

import argparse
import datetime as dt
import os
import re
import sys
from pathlib import Path

import pymupdf
from PIL import Image, ImageOps

try:
    from pillow_heif import register_heif_opener

    register_heif_opener()
except Exception:
    pass

EXTS = {".png", ".jpg", ".jpeg", ".webp", ".tif", ".tiff", ".heic", ".heif", ".bmp"}

# "Screenshot 2026-11-22 at 9.05.03 AM.png", "Screen Shot 2020-01-01 at 10.01.00 PM (2).png",
# 24h locales "Screenshot 2026-11-22 at 21.05.03.png". macOS puts U+202F before AM/PM.
SHOT_RE = re.compile(
    r"Screen ?[Ss]hot (\d{4})-(\d{2})-(\d{2}) at (\d{1,2})\.(\d{2})\.(\d{2})"
    r"(?:[\s  ]*([AP]M))?(?:\s*\((\d+)\))?",
)


def capture_key(p: Path):
    m = SHOT_RE.search(p.name)
    if m:
        y, mo, d, h, mi, s, ampm, dup = m.groups()
        h = int(h)
        if ampm == "PM" and h != 12:
            h += 12
        if ampm == "AM" and h == 12:
            h = 0
        t = dt.datetime(int(y), int(mo), int(d), h, int(mi), int(s))
        return (t.timestamp(), int(dup or 0), p.name)
    st = p.stat()
    return (getattr(st, "st_birthtime", st.st_mtime), 0, p.name)


def natural_key(p: Path):
    return [int(t) if t.isdigit() else t.lower() for t in re.split(r"(\d+)", p.name)]


def collect(inputs: list[str]) -> list[Path]:
    files: list[Path] = []
    for i in inputs:
        p = Path(i).expanduser()
        if p.is_dir():
            files += [f for f in p.iterdir() if f.is_file() and f.suffix.lower() in EXTS]
        elif p.is_file() and p.suffix.lower() in EXTS:
            files.append(p)
        else:
            print(f"  skip (not an image or dir): {p}", file=sys.stderr)
    return list(dict.fromkeys(files))


def detect_chrome_box(images: list[Image.Image]):
    """Viewer chrome (DocSend/Drive/browser bars) is not the founder's deck. Crop only
    when EVERY page agrees on the same box; a disagreeing box means guessing."""
    import numpy as np

    boxes = set()
    for im in images:
        a = np.asarray(im.convert("RGB")).astype(float).mean(axis=2)
        h, w = a.shape
        rows = a.mean(axis=1)
        dark = np.where(rows < 90)[0]
        top_d, bot_d = dark[dark < h * 0.25], dark[dark > h * 0.75]
        top = int(top_d.max()) + 1 if len(top_d) else 0
        bot = int(bot_d.min()) if len(bot_d) else h
        colm = a[top + 20 : bot - 20].mean(axis=0)
        bright = np.where(colm > 150)[0]
        left, right = (int(bright.min()), int(bright.max()) + 1) if len(bright) else (0, w)
        boxes.add((left, top, right, bot))
    if len(boxes) != 1:
        print(f"  chrome crop: pages disagree ({len(boxes)} boxes), not cropping")
        return None
    box = boxes.pop()
    if box == (0, 0, images[0].width, images[0].height):
        return None
    print(f"  chrome crop: {box} (unanimous across {len(images)} pages)")
    return box


def normalize(img: Image.Image, max_long: int) -> Image.Image:
    img = ImageOps.exif_transpose(img)
    if img.mode in ("RGBA", "LA", "P"):
        img = img.convert("RGBA")
        bg = Image.new("RGB", img.size, (255, 255, 255))
        bg.paste(img, mask=img.split()[-1])
        img = bg
    elif img.mode != "RGB":
        img = img.convert("RGB")
    long = max(img.size)
    if long > max_long:
        s = max_long / long
        img = img.resize((round(img.width * s), round(img.height * s)), Image.LANCZOS)
    return img


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("inputs", nargs="+")
    ap.add_argument("-o", "--out", required=True, type=Path)
    ap.add_argument("--max-long", type=int, default=1600)
    ap.add_argument("--quality", type=int, default=85)
    ap.add_argument("--order", choices=["auto", "capture", "name"], default="auto")
    ap.add_argument("--crop-chrome", action="store_true")
    ap.add_argument("--dry-run", action="store_true", help="print the page order and stop")
    a = ap.parse_args()

    files = collect(a.inputs)
    if not files:
        print("error: no images found", file=sys.stderr)
        return 2
    order = a.order
    if order == "auto":
        order = "capture" if all(SHOT_RE.search(f.name) for f in files) else "name"
    files.sort(key=capture_key if order == "capture" else natural_key)

    print(f"{len(files)} images, order={order}")
    for n, f in enumerate(files, 1):
        print(f"  {n:3d}  {f.name}")
    if a.dry_run:
        return 0
    if a.out.exists():
        print(f"error: {a.out} exists; refusing to overwrite", file=sys.stderr)
        return 3

    src_bytes = sum(f.stat().st_size for f in files)
    images = [Image.open(f) for f in files]
    box = detect_chrome_box(images) if a.crop_chrome else None

    doc = pymupdf.open()
    sizes = set()
    import io

    for im in images:
        if box:
            im = im.crop(box)
        im = normalize(im, a.max_long)
        buf = io.BytesIO()
        im.save(buf, "JPEG", quality=a.quality, optimize=True)
        w, h = im.size
        sizes.add((w, h))
        page = doc.new_page(width=w, height=h)
        page.insert_image(pymupdf.Rect(0, 0, w, h), stream=buf.getvalue())
    a.out.parent.mkdir(parents=True, exist_ok=True)
    doc.save(str(a.out), deflate=True, garbage=4)
    doc.close()

    out_bytes = a.out.stat().st_size
    mb = lambda b: b / 1_000_000
    print(f"\n  pages  : {len(files)}   page px: {', '.join(f'{w}x{h}' for w, h in sorted(sizes))}")
    print(f"  source : {mb(src_bytes):7.1f} MB")
    print(f"  pdf    : {mb(out_bytes):7.1f} MB  ({out_bytes / src_bytes:.1%} of source, "
          f"{mb(out_bytes) / len(files) * 1000:.0f} KB/page)")
    print(f"  -> {a.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
