#!/usr/bin/env python3
"""Generate ICO_SKILL_BASE_Slash combined source (128x128) for install_skill_base_icon."""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/ui/skills/base/_source_Slash_combined.png"
SIZE = 128


def px(draw: ImageDraw.ImageDraw, x: int, y: int, c: tuple[int, int, int, int]) -> None:
    if 0 <= x < SIZE and 0 <= y < SIZE:
        draw.point((x, y), fill=c)


def line(draw: ImageDraw.ImageDraw, p0: tuple[int, int], p1: tuple[int, int], c: tuple[int, int, int, int], w: int = 1) -> None:
    draw.line([p0, p1], fill=c, width=w)


def draw_frame(draw: ImageDraw.ImageDraw) -> None:
    outer = (38, 40, 46, 255)
    hi = (72, 76, 84, 255)
    lo = (22, 24, 28, 255)
    inner_edge = (58, 60, 68, 255)
    draw.rounded_rectangle((0, 0, SIZE - 1, SIZE - 1), radius=10, fill=outer)
    draw.rounded_rectangle((2, 2, SIZE - 3, SIZE - 3), radius=9, outline=hi, width=1)
    draw.rounded_rectangle((4, 4, SIZE - 5, SIZE - 5), radius=8, outline=lo, width=1)
    draw.rounded_rectangle((10, 10, SIZE - 11, SIZE - 11), radius=6, fill=(108, 110, 118, 255), outline=inner_edge, width=1)


def draw_sword(draw: ImageDraw.ImageDraw) -> None:
    blade = (170, 178, 190, 255)
    blade_mid = (120, 128, 142, 255)
    blade_edge = (230, 236, 245, 255)
    guard_c = (58, 60, 68, 255)
    hilt = (44, 36, 30, 255)
    hand = (16, 16, 18, 255)

    # blade polygon (bottom-right -> top-left)
    blade_pts = [(88, 92), (96, 84), (44, 28), (36, 36)]
    draw.polygon(blade_pts, fill=blade)
    draw.polygon([(90, 90), (94, 86), (42, 30), (38, 34)], fill=blade_edge)
    line(draw, (86, 88), (40, 32), blade_mid, 2)

    draw.rectangle((84, 80, 92, 88), fill=guard_c)
    draw.rectangle((86, 88, 90, 98), fill=hilt)
    draw.ellipse((85, 96, 91, 102), fill=(30, 24, 20, 255))

    # hand silhouette
    draw.ellipse((82, 86, 98, 102), fill=hand)
    draw.rectangle((88, 90, 102, 104), fill=hand)


def draw_slash_arc(draw: ImageDraw.ImageDraw) -> None:
    white = (245, 248, 255, 255)
    glow = (200, 210, 225, 220)
    cx, cy = 58, 56
    for r in (34, 30, 26):
        bbox = (cx - r, cy - r, cx + r, cy + r)
        draw.arc(bbox, start=300, end=20, fill=glow if r == 34 else white, width=4 if r == 30 else 2)
    for i in range(14):
        ang = math.radians(300 + i * 6.5)
        rr = 28 + (i % 3) * 2
        x = int(cx + rr * math.cos(ang))
        y = int(cy + rr * math.sin(ang))
        px(draw, x, y, white)
        if i % 2 == 0:
            px(draw, x + 1, y, glow)


def main() -> None:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_frame(draw)
    draw_slash_arc(draw)
    draw_sword(draw)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT, "PNG")
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
