#!/usr/bin/env python3
"""Generate ICO_SKILL_BASE_Hex combined source (128x128) for install_skill_base_icon."""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/ui/skills/base/_source_Hex_combined.png"
SIZE = 128


def px(draw: ImageDraw.ImageDraw, x: int, y: int, c: tuple[int, int, int, int]) -> None:
    if 0 <= x < SIZE and 0 <= y < SIZE:
        draw.point((x, y), fill=c)


def draw_frame(draw: ImageDraw.ImageDraw) -> None:
    outer = (38, 40, 46, 255)
    hi = (72, 76, 84, 255)
    lo = (22, 24, 28, 255)
    inner_edge = (58, 60, 68, 255)
    draw.rounded_rectangle((0, 0, SIZE - 1, SIZE - 1), radius=10, fill=outer)
    draw.rounded_rectangle((2, 2, SIZE - 3, SIZE - 3), radius=9, outline=hi, width=1)
    draw.rounded_rectangle((4, 4, SIZE - 5, SIZE - 5), radius=8, outline=lo, width=1)
    draw.rounded_rectangle((10, 10, SIZE - 11, SIZE - 11), radius=6, fill=(108, 110, 118, 255), outline=inner_edge, width=1)


def draw_book(draw: ImageDraw.ImageDraw) -> None:
    cover = (48, 50, 58, 255)
    page = (170, 174, 182, 255)
    line_c = (120, 124, 134, 255)
    cx = 64
    draw.polygon([(cx - 28, 88), (cx + 28, 88), (cx + 32, 104), (cx - 32, 104)], fill=cover)
    draw.polygon([(cx - 24, 84), (cx, 80), (cx + 24, 84), (cx + 24, 96), (cx, 92), (cx - 24, 96)], fill=page)
    for y in (86, 90, 94):
        draw.line((cx - 18, y, cx - 4, y), fill=line_c, width=1)
        draw.line((cx + 4, y, cx + 18, y), fill=line_c, width=1)


def draw_sigil(draw: ImageDraw.ImageDraw) -> None:
    cx, cy = 64, 52
    white = (245, 248, 255, 255)
    glow = (200, 208, 220, 220)
    dark = (88, 92, 104, 255)

    draw.ellipse((cx - 28, cy - 28, cx + 28, cy + 28), outline=glow, width=2)
    draw.ellipse((cx - 20, cy - 20, cx + 20, cy + 20), outline=white, width=2)

    # diamond star center
    draw.polygon([(cx, cy - 10), (cx + 10, cy), (cx, cy + 10), (cx - 10, cy)], outline=white, fill=dark)
    draw.ellipse((cx - 3, cy - 3, cx + 3, cy + 3), fill=(38, 40, 46, 255))

    # cardinal rune ticks
    for ang in (0, 90, 180, 270):
        rad = math.radians(ang - 90)
        x0 = int(cx + 14 * math.cos(rad))
        y0 = int(cy + 14 * math.sin(rad))
        x1 = int(cx + 18 * math.cos(rad))
        y1 = int(cy + 18 * math.sin(rad))
        draw.line((x0, y0, x1, y1), fill=white, width=2)
        px(draw, x1, y1, white)


def draw_smoke_fx(draw: ImageDraw.ImageDraw) -> None:
    mist = (170, 176, 188, 180)
    white = (245, 248, 255, 255)
    cx, cy = 64, 40
    for i in range(6):
        ox = -18 + i * 7
        draw.arc((cx + ox - 8, cy - 10, cx + ox + 8, cy + 6), start=200, end=340, fill=mist, width=2)
    for i in range(12):
        x = cx - 20 + (i * 4) % 40
        y = cy - 8 + (i * 3) % 16
        px(draw, x, y, white if i % 2 else mist)


def main() -> None:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_frame(draw)
    draw_book(draw)
    draw_sigil(draw)
    draw_smoke_fx(draw)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT, "PNG")
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
