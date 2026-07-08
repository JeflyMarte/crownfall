#!/usr/bin/env python3
"""Generate unique ultimate icon: ouga_retsudan (王牙列断)."""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/ui/skills/ICO_SKILL_OugaRetsudan.png"
SIZE = 128

GOLD = (212, 175, 72, 255)
GOLD_HI = (255, 232, 140, 255)
GOLD_LO = (140, 108, 42, 255)
BG = (42, 44, 50, 255)
BG_HI = (58, 60, 68, 255)
SLASH = (255, 248, 200, 255)
SLASH_CORE = (255, 255, 255, 255)
STEEL = (170, 178, 190, 255)
STEEL_LO = (88, 94, 104, 255)
EMBER = (255, 140, 50, 255)


def px(draw: ImageDraw.ImageDraw, x: int, y: int, c: tuple[int, int, int, int]) -> None:
    if 0 <= x < SIZE and 0 <= y < SIZE:
        draw.point((x, y), fill=c)


def draw_ultimate_frame(draw: ImageDraw.ImageDraw) -> None:
    draw.rounded_rectangle((0, 0, SIZE - 1, SIZE - 1), radius=8, fill=GOLD_LO)
    draw.rounded_rectangle((3, 3, SIZE - 4, SIZE - 4), radius=7, fill=GOLD)
    draw.rounded_rectangle((6, 6, SIZE - 7, SIZE - 7), radius=6, fill=GOLD_LO)
    draw.rounded_rectangle((10, 10, SIZE - 11, SIZE - 11), radius=5, fill=BG, outline=GOLD_HI, width=1)
    # corner spikes
    for cx, cy, dx, dy in (
        (14, 14, 1, 1), (114, 14, -1, 1), (14, 114, 1, -1), (114, 114, -1, -1),
        (64, 12, 0, 1), (64, 116, 0, -1), (12, 64, 1, 0), (116, 64, -1, 0),
    ):
        draw.polygon([(cx, cy), (cx + 8 * dx, cy + 2 * dy), (cx + 2 * dx, cy + 8 * dy)], fill=GOLD_HI)


def draw_crown_hint(draw: ImageDraw.ImageDraw) -> None:
    cx = 64
    crown = (72, 74, 82, 255)
    pts = [(cx - 16, 30), (cx - 10, 22), (cx - 4, 28), (cx, 20), (cx + 4, 28), (cx + 10, 22), (cx + 16, 30), (cx + 12, 34), (cx - 12, 34)]
    draw.polygon(pts, fill=crown)


def draw_triple_slash(draw: ImageDraw.ImageDraw) -> None:
    for offset in (-10, 0, 10):
        pts = [(24 + offset, 98), (46 + offset, 76), (88 + offset, 34), (102 + offset, 20)]
        for i in range(len(pts) - 1):
            draw.line([pts[i], pts[i + 1]], fill=GOLD_HI, width=5)
            draw.line([pts[i], pts[i + 1]], fill=SLASH, width=3)
            draw.line([pts[i], pts[i + 1]], fill=SLASH_CORE, width=1)
        for i in range(8):
            t = i / 7
            x = int(24 + offset + (78 + offset) * t)
            y = int(98 - 78 * t)
            px(draw, x, y, SLASH_CORE)
            if i % 2 == 0:
                px(draw, x + 2, y - 1, GOLD_HI)


def draw_sword(draw: ImageDraw.ImageDraw) -> None:
    blade_pts = [(36, 88), (44, 80), (92, 32), (84, 24)]
    draw.polygon(blade_pts, fill=STEEL_LO, outline=STEEL)
    draw.polygon([(38, 86), (44, 80), (88, 28), (82, 24)], fill=STEEL)
    draw.line([(40, 84), (86, 28)], fill=(230, 236, 245, 255), width=1)
    draw.rectangle((82, 76, 90, 84), fill=GOLD)
    draw.rectangle((84, 84, 88, 96), fill=(48, 40, 32, 255))


def draw_armor_shards(draw: ImageDraw.ImageDraw) -> None:
    draw.polygon([(88, 88), (104, 82), (108, 96), (94, 104)], fill=STEEL_LO, outline=STEEL)
    draw.line([(94, 92), (100, 98)], fill=EMBER, width=2)
    draw.polygon([(72, 100), (80, 94), (86, 102), (78, 108)], fill=STEEL_LO)
    for i in range(6):
        ang = math.radians(200 + i * 18)
        x = int(76 + 20 * math.cos(ang))
        y = int(86 + 16 * math.sin(ang))
        px(draw, x, y, STEEL)
        px(draw, x + 1, y, GOLD_HI)


def main() -> None:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_ultimate_frame(draw)
    draw.rectangle((14, 14, SIZE - 15, SIZE - 15), fill=BG)
    draw_crown_hint(draw)
    draw_triple_slash(draw)
    draw_sword(draw)
    draw_armor_shards(draw)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT, "PNG")
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
