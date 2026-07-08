#!/usr/bin/env python3
"""Generate ICO_SKILL_BASE_Bow combined source (128x128) for install_skill_base_icon."""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/ui/skills/base/_source_Bow_combined.png"
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


def draw_bow(draw: ImageDraw.ImageDraw) -> None:
    wood = (92, 86, 78, 255)
    wood_hi = (130, 124, 114, 255)
    wood_lo = (58, 54, 48, 255)
    grip = (48, 44, 40, 255)
    string_c = (230, 234, 240, 255)

    # recurve bow limbs (left curve)
    draw.arc((18, 24, 58, 104), start=70, end=290, fill=wood_lo, width=5)
    draw.arc((20, 26, 56, 102), start=70, end=290, fill=wood, width=3)
    draw.arc((22, 28, 54, 100), start=80, end=280, fill=wood_hi, width=1)
    draw.rectangle((36, 58, 44, 70), fill=grip)

    # bowstring V (drawn back)
    draw.line((38, 30, 52, 58), fill=string_c, width=2)
    draw.line((38, 98, 52, 58), fill=string_c, width=2)


def draw_arrow(draw: ImageDraw.ImageDraw) -> None:
    shaft = (170, 174, 182, 255)
    white = (245, 248, 255, 255)
    head = white
    cy = 58

    # shaft
    draw.line((48, cy, 92, cy), fill=shaft, width=2)
    draw.line((50, cy - 1, 90, cy - 1), fill=white, width=1)

    # fletching (left)
    draw.polygon([(48, cy), (38, cy - 8), (42, cy), (38, cy + 8)], fill=white)
    draw.polygon([(44, cy), (36, cy - 5), (40, cy), (36, cy + 5)], fill=(210, 216, 228, 255))

    # arrowhead (right)
    draw.polygon([(92, cy), (106, cy - 7), (106, cy + 7)], fill=head)
    draw.polygon([(94, cy), (102, cy - 4), (102, cy + 4)], fill=(210, 216, 228, 255))


def draw_speed_fx(draw: ImageDraw.ImageDraw) -> None:
    white = (245, 248, 255, 255)
    glow = (200, 208, 220, 210)
    cx, cy = 108, 58
    for i in range(5):
        y = cy - 8 + i * 4
        draw.line((cx - 10 - i, y, cx + 6, y), fill=glow if i % 2 else white, width=1)
    for i in range(8):
        ang = math.radians(-8 + i * 4)
        x = int(cx + 4 + i * 2)
        y = int(cy + math.sin(ang) * (6 + i))
        px(draw, x, y, white)
        if i % 3 == 0:
            px(draw, x + 1, y - 1, glow)
            px(draw, x, y + 1, glow)


def main() -> None:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_frame(draw)
    draw_bow(draw)
    draw_arrow(draw)
    draw_speed_fx(draw)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT, "PNG")
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
