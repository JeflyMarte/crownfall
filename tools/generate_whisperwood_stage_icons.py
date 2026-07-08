#!/usr/bin/env python3
"""Post-process whisperwood stage dungeon icons to 1024x1024 PNG.

Source PNGs are placed in assets/dungeon/whisperwood/stages/ as:
  ICO_DG_Whisperwood_2_1.png .. ICO_DG_Whisperwood_2_5.png

Usage (after adding/replacing raw art):
  python3 tools/generate_whisperwood_stage_icons.py
  python3 tools/generate_whisperwood_stage_icons.py --input path/to/raw.png --chapter 3
"""
from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets/dungeon/whisperwood/stages"
TARGET = 1024


def normalize_icon(src: Path, dst: Path) -> None:
    img = Image.open(src).convert("RGBA")
    w, h = img.size
    side = min(w, h)
    left = (w - side) // 2
    top = (h - side) // 2
    img = img.crop((left, top, left + side, top + side))
    img = img.resize((TARGET, TARGET), Image.Resampling.LANCZOS)
    dst.parent.mkdir(parents=True, exist_ok=True)
    img.save(dst, optimize=True)
    print(f"wrote {dst} ({TARGET}x{TARGET})")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, help="Single raw PNG to normalize")
    parser.add_argument("--chapter", type=int, choices=range(1, 6), help="Chapter 1-5 for --input")
    args = parser.parse_args()

    if args.input is not None:
        if args.chapter is None:
            parser.error("--chapter is required with --input")
        normalize_icon(args.input, OUT_DIR / f"ICO_DG_Whisperwood_2_{args.chapter}.png")
        return 0

    for chapter in range(1, 6):
        src = OUT_DIR / f"ICO_DG_Whisperwood_2_{chapter}.png"
        if not src.exists():
            print(f"skip missing: {src}")
            continue
        tmp = src.with_suffix(".tmp.png")
        normalize_icon(src, tmp)
        tmp.replace(src)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
