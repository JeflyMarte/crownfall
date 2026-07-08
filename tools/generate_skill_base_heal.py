#!/usr/bin/env python3
"""Generate ICO_SKILL_BASE_Heal combined source (128x128) for install_skill_base_icon."""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/ui/skills/base/_source_Heal_combined.png"
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


def draw_glow(draw: ImageDraw.ImageDraw) -> None:
    cx, cy = 64, 50
    white = (245, 248, 255, 255)
    glow = (190, 198, 210, 180)
    draw.ellipse((cx - 30, cy - 30, cx + 30, cy + 30), outline=glow, width=2)
    draw.ellipse((cx - 22, cy - 22, cx + 22, cy + 22), outline=white, width=1)
    for i in range(8):
        ang = math.radians(i * 45)
        x1 = int(cx + 12 * math.cos(ang))
        y1 = int(cy + 12 * math.sin(ang))
        x2 = int(cx + 28 * math.cos(ang))
        y2 = int(cy + 28 * math.sin(ang))
        draw.line((x1, y1, x2, y2), fill=glow if i % 2 else white, width=1)
    for i in range(10):
        x = cx - 18 + (i * 5) % 36
        y = cy - 16 + (i * 4) % 28
        if i % 3 == 0:
            px(draw, x, y, white)
            px(draw, x + 1, y, white)
            px(draw, x, y + 1, white)
        else:
            px(draw, x, y, glow)


def draw_cross(draw: ImageDraw.ImageDraw) -> None:
    cx, cy = 64, 50
    white = (245, 248, 255, 255)
    outline = (88, 94, 104, 255)
    draw.rectangle((cx - 6, cy - 18, cx + 6, cy + 18), fill=white, outline=outline)
    draw.rectangle((cx - 18, cy - 6, cx + 18, cy + 6), fill=white, outline=outline)


def draw_hands(draw: ImageDraw.ImageDraw) -> None:
    skin = (170, 176, 188, 255)
    shadow = (100, 108, 120, 255)
    cx = 64
    # left cupped hand
    draw.polygon([(cx - 28, 96), (cx - 8, 78), (cx - 4, 88), (cx - 18, 100)], fill=skin, outline=shadow)
    draw.arc((cx - 26, 82, cx - 6, 98), start=200, end=340, fill=shadow, width=2)
    # right cupped hand
    draw.polygon([(cx + 28, 96), (cx + 8, 78), (cx + 4, 88), (cx + 18, 100)], fill=skin, outline=shadow)
    draw.arc((cx + 6, 82, cx + 26, 98), start=200, end=340, fill=shadow, width=2)


def main() -> None:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_frame(draw)
    draw_glow(draw)
    draw_hands(draw)
    draw_cross(draw)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT, "PNG")
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
