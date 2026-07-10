#!/usr/bin/env python3
"""Import WIP legendary weapon icons into assets/ui/equipment at 64x64 RGBA.

Usage:
  python3 tools/import_legendary_weapon_icons.py
  python3 tools/import_legendary_weapon_icons.py --src /path/to/icons
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SRC = ROOT / "assets/ui/equipment/_wip"
OUT_DIR = ROOT / "assets/ui/equipment"
TARGET_SIZE = 64
SAFE_SCALE = 0.82

sys.path.insert(0, str(ROOT / "tools"))
from generate_equipment_icons import LEGENDARY_HAND_DRAWN_WEAPON_IDS, output_name  # noqa: E402


def remove_matte_bg(img: Image.Image, threshold: int = 32) -> Image.Image:
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size
    corners = [px[0, 0], px[w - 1, 0], px[0, h - 1], px[w - 1, h - 1]]
    bg = corners[0][:3]
    if all(
        abs(c[0] - bg[0]) < 20 and abs(c[1] - bg[1]) < 20 and abs(c[2] - bg[2]) < 20
        for c in corners
    ):
        for y in range(h):
            for x in range(w):
                r, g, b, a = px[x, y]
                if abs(r - bg[0]) <= threshold and abs(g - bg[1]) <= threshold and abs(b - bg[2]) <= threshold:
                    px[x, y] = (r, g, b, 0)
    return img


def fit_to_canvas(img: Image.Image, size: int = TARGET_SIZE) -> Image.Image:
    img = remove_matte_bg(img)
    bbox = img.getbbox()
    if bbox is None:
        return Image.new("RGBA", (size, size), (0, 0, 0, 0))
    cropped = img.crop(bbox)
    max_dim = int(size * SAFE_SCALE)
    cw, ch = cropped.size
    scale = min(max_dim / cw, max_dim / ch)
    nw = max(1, int(round(cw * scale)))
    nh = max(1, int(round(ch * scale)))
    resized = cropped.resize((nw, nh), Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    ox = (size - nw) // 2
    oy = (size - nh) // 2 + 2
    canvas.paste(resized, (ox, oy), resized)
    return canvas


def find_source(src_dir: Path, weapon_id: str) -> Path | None:
    fname = output_name("weapon", weapon_id)
    for candidate in (src_dir / fname, src_dir / f"{weapon_id}.png"):
        if candidate.exists():
            return candidate
    return None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--src", type=Path, default=DEFAULT_SRC)
    args = parser.parse_args()
    src_dir: Path = args.src
    if not src_dir.exists():
        print(f"Missing source dir: {src_dir}")
        return 1

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    imported = 0
    missing: list[str] = []
    for weapon_id in sorted(LEGENDARY_HAND_DRAWN_WEAPON_IDS):
        src = find_source(src_dir, weapon_id)
        if src is None:
            missing.append(weapon_id)
            continue
        out = OUT_DIR / output_name("weapon", weapon_id)
        icon = fit_to_canvas(Image.open(src))
        icon.save(out, "PNG")
        print(f"imported {weapon_id} <- {src.name} -> {out.name}")
        imported += 1

    if missing:
        print("missing:", ", ".join(missing))
    print(f"done: {imported}/{len(LEGENDARY_HAND_DRAWN_WEAPON_IDS)}")
    return 0 if not missing else 1


if __name__ == "__main__":
    raise SystemExit(main())
