#!/usr/bin/env python3
"""Generate unique ultimate icon: grand_elixir (グランドエリクサー)."""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/ui/skills/ICO_SKILL_GrandElixir.png"
SIZE = 128

FRAME = (48, 50, 58, 255)
FRAME_HI = (88, 92, 102, 255)
BG = (28, 32, 30, 255)
GREEN = (100, 180, 90, 255)
GREEN_HI = (160, 240, 140, 255)
GREEN_CORE = (220, 255, 200, 255)
GEM = (80, 160, 70, 255)
HAND = (170, 176, 188, 255)
CUFF = (90, 140, 80, 255)
CORK = (88, 64, 42, 255)
WHITE = (245, 248, 255, 255)


def px(draw: ImageDraw.ImageDraw, x: int, y: int, c: tuple[int, int, int, int]) -> None:
    if 0 <= x < SIZE and 0 <= y < SIZE:
        draw.point((x, y), fill=c)


def draw_frame(draw: ImageDraw.ImageDraw) -> None:
    draw.rounded_rectangle((0, 0, SIZE - 1, SIZE - 1), radius=8, fill=FRAME)
    draw.rounded_rectangle((3, 3, SIZE - 4, SIZE - 4), radius=7, outline=FRAME_HI, width=2)
    draw.rounded_rectangle((8, 8, SIZE - 9, SIZE - 9), radius=6, fill=BG, outline=FRAME_HI, width=1)
    for cx, cy in ((64, 12), (64, 116), (12, 64), (116, 64)):
        draw.polygon([(cx, cy - 4), (cx + 4, cy), (cx, cy + 4), (cx - 4, cy)], fill=GEM)
    for cx, cy in ((16, 16), (112, 16), (16, 112), (112, 112)):
        draw.ellipse((cx - 5, cy + 2, cx + 5, cy + 10), fill=GREEN, outline=FRAME_HI)
        draw.rectangle((cx - 2, cy - 4, cx + 2, cy + 2), fill=FRAME_HI)


def draw_vapor(draw: ImageDraw.ImageDraw) -> None:
    cx = 64
    for side in (-1, 1):
        for i in range(4):
            ox = side * (12 + i * 4)
            draw.arc((cx + ox - 10, 28 + i * 4, cx + ox + 10, 56 + i * 4), start=200, end=340, fill=GREEN_HI, width=2)


def draw_flask(draw: ImageDraw.ImageDraw) -> None:
    cx = 64
    draw.ellipse((cx - 22, 48, cx + 22, 92), fill=GREEN, outline=GREEN_HI)
    draw.ellipse((cx - 16, 54, cx + 16, 86), fill=(60, 120, 55, 200))
    draw.rectangle((cx - 8, 36, cx + 8, 52), fill=GREEN_HI, outline=FRAME_HI)
    draw.rectangle((cx - 10, 32, cx + 10, 38), fill=CORK)
    # falling drop + ripples
    draw.ellipse((cx - 3, 58, cx + 3, 66), fill=GREEN_CORE)
    for r in (8, 14, 20):
        draw.ellipse((cx - r, 68 - r // 3, cx + r, 68 + r // 3), outline=GREEN_CORE, width=1)
    draw.line([(cx - 24, 64), (cx + 24, 64)], fill=WHITE, width=1)
    for ox, oy in ((-10, -8), (8, -12), (14, 4), (-12, 6)):
        px(draw, cx + ox, 60 + oy, WHITE)
        if ox > 0:
            draw.line([(cx + ox, 60 + oy), (cx + ox, 60 + oy + 4)], fill=WHITE, width=1)
            draw.line([(cx + ox - 2, 60 + oy + 2), (cx + ox + 2, 60 + oy + 2)], fill=WHITE, width=1)


def draw_hands(draw: ImageDraw.ImageDraw) -> None:
    cx = 64
    for side in (-1, 1):
        ox = side * 18
        draw.polygon([(cx + ox, 96), (cx + ox - side * 12, 104), (cx + ox - side * 6, 112), (cx + ox + side * 4, 106)], fill=HAND, outline=FRAME_HI)
        x0 = cx + ox - (8 if side > 0 else 2)
        x1 = cx + ox + (2 if side > 0 else 8)
        draw.rectangle((x0, 108, x1, 114), fill=CUFF)


def main() -> None:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_frame(draw)
    draw_vapor(draw)
    draw_flask(draw)
    draw_hands(draw)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT, "PNG")
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
