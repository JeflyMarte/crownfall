#!/usr/bin/env python3
"""Generate ICO_SKILL_BASE_Poison combined source (128x128) for install_skill_base_icon."""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/ui/skills/base/_source_Poison_combined.png"
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


def draw_flask(draw: ImageDraw.ImageDraw) -> None:
    glass_hi = (200, 208, 218, 255)
    glass = (120, 128, 140, 255)
    glass_lo = (72, 78, 88, 255)
    liquid = (48, 54, 62, 255)
    cork = (58, 50, 42, 255)
    skull = (230, 236, 245, 255)
    cx = 64

    # round-bottom flask body
    draw.ellipse((cx - 22, 52, cx + 22, 96), fill=glass_lo, outline=glass)
    draw.ellipse((cx - 18, 56, cx + 18, 92), fill=liquid)
    draw.arc((cx - 22, 52, cx + 22, 96), start=120, end=240, fill=glass_hi, width=2)

    # neck
    draw.rectangle((cx - 8, 38, cx + 8, 56), fill=glass, outline=glass_lo)
    draw.rectangle((cx - 10, 34, cx + 10, 40), fill=cork)

    # skull & crossbones
    draw.ellipse((cx - 8, 64, cx + 8, 80), fill=skull)
    draw.ellipse((cx - 4, 68, cx - 1, 71), fill=liquid)
    draw.ellipse((cx + 1, 68, cx + 4, 71), fill=liquid)
    draw.rectangle((cx - 2, 74, cx + 2, 78), fill=liquid)
    draw.line((cx - 10, 84, cx + 10, 84), fill=skull, width=2)
    draw.line((cx - 6, 88, cx + 6, 80), fill=skull, width=2)
    draw.line((cx + 6, 88, cx - 6, 80), fill=skull, width=2)


def draw_vapor(draw: ImageDraw.ImageDraw) -> None:
    mist = (180, 188, 200, 200)
    white = (245, 248, 255, 255)
    cx, cy = 64, 48
    for i in range(5):
        ox = -16 + i * 8
        draw.arc((cx + ox - 10, cy - 8, cx + ox + 10, cy + 12), start=200, end=340, fill=mist, width=2)
    for i in range(10):
        ang = math.radians(220 + i * 14)
        r = 20 + (i % 3) * 4
        x = int(cx + r * math.cos(ang))
        y = int(cy + r * math.sin(ang))
        px(draw, x, y, white if i % 2 else mist)
        if i % 3 == 0:
            draw.ellipse((x - 2, y - 2, x + 2, y + 2), outline=mist, width=1)


def main() -> None:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_frame(draw)
    draw_vapor(draw)
    draw_flask(draw)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT, "PNG")
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
