#!/usr/bin/env python3
"""Split a combined skill base icon into fg (+ optional bg mask) for SkillIconHelper.

Usage:
  python3 tools/install_skill_base_icon.py slash path/to/icon.png

Expects a 128x128 (or square) PNG with neutral gray inner background.
Outputs:
  assets/ui/skills/base/ICO_SKILL_BASE_{Base}_fg.png
  assets/ui/skills/base/ICO_SKILL_BASE_{Base}_bg.png
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets/ui/skills/base"
TARGET_SIZE = 128

VALID_BASES = {
    "slash", "guard", "bow", "mark", "hex", "poison", "snare", "heal", "buff", "ultimate",
}


def base_token(base_id: str) -> str:
    return base_id[:1].upper() + base_id[1:]


def is_inner_bg(r: int, g: int, b: int, a: int) -> bool:
    if a < 200:
        return False
    if max(r, g, b) - min(r, g, b) > 18:
        return False
    lum = (r + g + b) / 3.0
    return 70 <= lum <= 190


def split_icon(img: Image.Image) -> tuple[Image.Image, Image.Image]:
    rgba = img.convert("RGBA")
    w, h = rgba.size
    px = rgba.load()

    bg = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    fg = rgba.copy()
    bg_px = bg.load()
    fg_px = fg.load()

    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if is_inner_bg(r, g, b, a):
                bg_px[x, y] = (255, 255, 255, a)
                fg_px[x, y] = (0, 0, 0, 0)

    return fg, bg


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("base_id", choices=sorted(VALID_BASES))
    parser.add_argument("source", type=Path)
    parser.add_argument("--size", type=int, default=TARGET_SIZE)
    args = parser.parse_args()

    src: Path = args.source
    if not src.is_file():
        print(f"Missing source: {src}", file=sys.stderr)
        return 1

    img = Image.open(src)
    if img.size != (args.size, args.size):
        img = img.resize((args.size, args.size), Image.Resampling.NEAREST)

    fg, bg = split_icon(img)
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    token = base_token(args.base_id)
    fg_path = OUT_DIR / f"ICO_SKILL_BASE_{token}_fg.png"
    bg_path = OUT_DIR / f"ICO_SKILL_BASE_{token}_bg.png"
    fg.save(fg_path, "PNG")
    bg.save(bg_path, "PNG")
    print(f"Wrote {fg_path.relative_to(ROOT)}")
    print(f"Wrote {bg_path.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
