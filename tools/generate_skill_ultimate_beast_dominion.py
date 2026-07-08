#!/usr/bin/env python3
"""Generate unique ultimate icon: beast_dominion (ビーストドミニオン)."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/ui/skills/ICO_SKILL_BeastDominion.png"
SIZE = 128

FRAME = (48, 50, 58, 255)
FRAME_HI = (170, 178, 190, 255)
BG = (22, 20, 24, 255)
ORANGE = (230, 140, 60, 255)
ORANGE_HI = (255, 200, 100, 255)
ORANGE_CORE = (255, 240, 180, 255)
GEM = (220, 120, 40, 255)
CHAIN = (140, 148, 158, 255)
VINE = (48, 58, 42, 255)
ICE = (200, 230, 255, 255)
POISON = (120, 200, 70, 255)
POISON_AMBER = (220, 180, 60, 255)
BEAST = (12, 12, 16, 255)


def px(draw: ImageDraw.ImageDraw, x: int, y: int, c: tuple[int, int, int, int]) -> None:
    if 0 <= x < SIZE and 0 <= y < SIZE:
        draw.point((x, y), fill=c)


def draw_frame(draw: ImageDraw.ImageDraw) -> None:
    draw.rounded_rectangle((0, 0, SIZE - 1, SIZE - 1), radius=8, fill=FRAME)
    draw.rounded_rectangle((3, 3, SIZE - 4, SIZE - 4), radius=7, outline=FRAME_HI, width=2)
    draw.rounded_rectangle((10, 10, SIZE - 11, SIZE - 11), radius=5, fill=BG)
    for cx, cy, dx, dy in ((14, 14, 1, 1), (114, 14, -1, 1), (14, 114, 1, -1), (114, 114, -1, -1)):
        draw.polygon([(cx, cy), (cx + 8 * dx, cy + 10 * dy), (cx + 2 * dx, cy + 2 * dy)], fill=FRAME_HI)
    for cx, cy in ((64, 12), (64, 116)):
        draw.polygon([(cx, cy - 4), (cx + 4, cy), (cx, cy + 4), (cx - 4, cy)], fill=GEM)


def draw_ice_fx(draw: ImageDraw.ImageDraw) -> None:
    for ox, oy in ((18, 44), (22, 62), (16, 78)):
        draw.line([(ox, oy), (ox, oy + 8), (ox + 6, oy + 4), (ox, oy)], fill=ICE, width=1)
        px(draw, ox + 2, oy + 2, ICE)
    for i in range(4):
        px(draw, 20 + i, 52 + i, (180, 210, 240, 200))


def draw_poison_fx(draw: ImageDraw.ImageDraw) -> None:
    for ox, oy, c in ((104, 48, POISON_AMBER), (110, 66, POISON), (100, 82, POISON_AMBER)):
        draw.ellipse((ox - 4, oy - 5, ox + 4, oy + 3), fill=c)
        px(draw, ox, oy - 6, c)
    for ox, oy in ((108, 56), (102, 72)):
        draw.ellipse((ox - 2, oy - 2, ox + 2, oy + 2), outline=POISON, width=1)


def draw_eye(draw: ImageDraw.ImageDraw) -> None:
    cx, cy = 64, 38
    draw.ellipse((cx - 30, cy - 18, cx + 30, cy + 18), fill=(58, 48, 40, 255), outline=ORANGE)
    draw.ellipse((cx - 22, cy - 12, cx + 22, cy + 12), fill=ORANGE)
    draw.ellipse((cx - 6, cy - 14, cx + 6, cy + 14), fill=(18, 16, 20, 255))
    draw.ellipse((cx - 3, cy - 8, cx + 3, cy + 8), fill=ORANGE_CORE)
    for sx in (cx - 24, cx - 12, cx + 12, cx + 22):
        draw.arc((sx - 4, cy - 16, sx + 4, cy - 8), start=0, end=180, fill=ORANGE_HI, width=1)


def draw_beast(draw: ImageDraw.ImageDraw) -> None:
    cx, cy = 64, 92
    draw.ellipse((cx - 16, cy - 14, cx + 16, cy + 6), fill=BEAST)
    draw.polygon([(cx - 10, cy - 10), (cx - 4, cy - 22), (cx + 2, cy - 10)], fill=BEAST)
    draw.polygon([(cx + 6, cy - 10), (cx + 12, cy - 20), (cx + 14, cy - 8)], fill=BEAST)
    draw.ellipse((cx - 18, cy - 4, cx - 10, cy + 2), fill=ORANGE_HI)


def draw_restraints(draw: ImageDraw.ImageDraw) -> None:
    cx, cy = 64, 80
    draw.arc((cx - 20, cy - 10, cx + 20, cy + 20), start=200, end=340, fill=CHAIN, width=3)
    draw.arc((cx - 14, cy - 4, cx + 14, cy + 16), start=210, end=330, fill=CHAIN, width=2)
    for ox in (-12, 0, 12):
        draw.line([(cx + ox, cy), (cx + ox + 4, cy + 14)], fill=VINE, width=2)


def main() -> None:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_frame(draw)
    draw_ice_fx(draw)
    draw_poison_fx(draw)
    draw_eye(draw)
    draw_beast(draw)
    draw_restraints(draw)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT, "PNG")
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
