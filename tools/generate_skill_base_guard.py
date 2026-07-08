#!/usr/bin/env python3
"""Generate ICO_SKILL_BASE_Guard combined source (128x128) for install_skill_base_icon."""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/ui/skills/base/_source_Guard_combined.png"
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


def draw_impact(draw: ImageDraw.ImageDraw) -> None:
    glow = (220, 228, 240, 200)
    white = (245, 248, 255, 255)
    cx, cy = 78, 58
    for r in (28, 22, 16):
        bbox = (cx - r, cy - r, cx + r, cy + r)
        draw.arc(bbox, start=250, end=330, fill=glow if r == 28 else white, width=3 if r == 22 else 2)
    for i in range(8):
        ang = math.radians(255 + i * 11)
        x0 = int(cx + 8 * math.cos(ang))
        y0 = int(cy + 8 * math.sin(ang))
        x1 = int(cx + (22 + i % 2 * 4) * math.cos(ang))
        y1 = int(cy + (22 + i % 2 * 4) * math.sin(ang))
        draw.line((x0, y0, x1, y1), fill=white, width=2)
    for i in range(10):
        ang = math.radians(260 + i * 7)
        x = int(cx + 18 * math.cos(ang))
        y = int(cy + 18 * math.sin(ang))
        px(draw, x, y, white)


def draw_shield(draw: ImageDraw.ImageDraw) -> None:
    steel = (150, 158, 172, 255)
    steel_dark = (88, 94, 108, 255)
    steel_hi = (210, 218, 230, 255)
    rim = (58, 62, 72, 255)
    hand = (16, 16, 18, 255)

    # heater shield body
    shield_pts = [(34, 34), (74, 34), (82, 58), (74, 96), (34, 96), (26, 58)]
    draw.polygon(shield_pts, fill=steel, outline=rim)
    draw.polygon([(38, 38), (70, 38), (76, 58), (70, 90), (38, 90), (32, 58)], fill=steel_dark)
    draw.line((42, 40, 68, 88), fill=steel_hi, width=2)
    draw.line((36, 58, 78, 58), fill=steel_hi, width=1)
    draw.ellipse((48, 52, 60, 64), fill=(72, 78, 92, 255), outline=rim, width=1)

    # arm + hand pushing shield
    draw.rectangle((58, 72, 88, 86), fill=hand)
    draw.ellipse((52, 78, 66, 92), fill=hand)


def main() -> None:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_frame(draw)
    draw_impact(draw)
    draw_shield(draw)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT, "PNG")
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
