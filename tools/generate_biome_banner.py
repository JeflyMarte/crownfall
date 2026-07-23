#!/usr/bin/env python3
"""Normalize biome title banners for dungeon select accordion headers.

Output: assets/ui/dungeon/BAN_DG_{BiomePascal}.png

Default mode preserves the source aspect (title-baked key art).
Legacy thin-strip mode: --strip-height 112

Usage:
  python3 tools/generate_biome_banner.py --input path/to.png --biome mourngate
  python3 tools/generate_biome_banner.py --input path/to.png --biome mourngate --strip-height 112
"""
from __future__ import annotations

import argparse
import re
from pathlib import Path

from PIL import Image

try:
    RESAMPLE_LANCZOS = Image.Resampling.LANCZOS
except AttributeError:
    RESAMPLE_LANCZOS = Image.LANCZOS

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets/ui/dungeon"
TARGET_W = 1408
WHITE_THRESHOLD = 235
WHITE_SOFT = 250


def biome_filename(biome_id: str) -> str:
    parts = biome_id.split("_")
    pascal = "".join(p.capitalize() for p in parts)
    return f"BAN_DG_{pascal}.png"


def remove_light_matte(img: Image.Image) -> Image.Image:
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            dist = max(255 - r, 255 - g, 255 - b)
            if dist <= 255 - WHITE_THRESHOLD:
                px[x, y] = (r, g, b, 0)
            elif dist <= 255 - WHITE_SOFT:
                fade = (dist - (255 - WHITE_THRESHOLD)) / max(1, WHITE_THRESHOLD - WHITE_SOFT)
                px[x, y] = (r, g, b, int(a * fade))
    return img


def normalize_banner(src: Path, dst: Path, strip_height: int | None = None) -> None:
    img = remove_light_matte(Image.open(src))
    w, h = img.size
    scale = TARGET_W / float(w)
    resized_h = max(1, int(round(h * scale)))
    img = img.resize((TARGET_W, resized_h), RESAMPLE_LANCZOS)
    if strip_height is not None and strip_height > 0:
        target_h = strip_height
        if resized_h > target_h:
            top = (resized_h - target_h) // 2
            img = img.crop((0, top, TARGET_W, top + target_h))
        elif resized_h < target_h:
            canvas = Image.new("RGBA", (TARGET_W, target_h), (0, 0, 0, 0))
            offset_y = (target_h - resized_h) // 2
            canvas.paste(img, (0, offset_y), img)
            img = canvas
    dst.parent.mkdir(parents=True, exist_ok=True)
    img.save(dst, optimize=True)
    print(f"wrote {dst} ({img.size[0]}x{img.size[1]})")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, help="Raw banner PNG")
    parser.add_argument("--biome", type=str, default="mourngate", help="Biome id (e.g. mourngate)")
    parser.add_argument(
        "--strip-height",
        type=int,
        default=None,
        help="Optional center-crop height (legacy thin strip). Omit to preserve aspect.",
    )
    args = parser.parse_args()

    if args.input is not None:
        if not re.fullmatch(r"[a-z0-9_]+", args.biome):
            parser.error("invalid biome id")
        normalize_banner(args.input, OUT_DIR / biome_filename(args.biome), args.strip_height)
        return 0

    raw = OUT_DIR / "BAN_DG_Mourngate_raw.png"
    if raw.exists():
        normalize_banner(raw, OUT_DIR / "BAN_DG_Mourngate.png")
    else:
        print(f"skip missing: {raw}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
