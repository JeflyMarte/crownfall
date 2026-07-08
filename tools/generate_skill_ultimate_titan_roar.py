#!/usr/bin/env python3
"""Generate unique ultimate icon: titan_roar (タイタンロア)."""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/ui/skills/ICO_SKILL_TitanRoar.png"
SIZE = 128

FRAME = (48, 50, 58, 255)
FRAME_HI = (88, 92, 102, 255)
SILVER = (170, 178, 190, 255)
BG = (32, 30, 40, 255)
PURPLE = (160, 100, 180, 255)
PURPLE_HI = (220, 160, 255, 255)
PURPLE_CORE = (255, 220, 255, 255)
GEM = (140, 80, 200, 255)
EYE = (200, 120, 255, 255)
STONE = (72, 70, 82, 255)


def px(draw: ImageDraw.ImageDraw, x: int, y: int, c: tuple[int, int, int, int]) -> None:
    if 0 <= x < SIZE and 0 <= y < SIZE:
        draw.point((x, y), fill=c)


def draw_frame(draw: ImageDraw.ImageDraw) -> None:
    draw.rounded_rectangle((0, 0, SIZE - 1, SIZE - 1), radius=8, fill=FRAME)
    draw.rounded_rectangle((3, 3, SIZE - 4, SIZE - 4), radius=7, outline=FRAME_HI, width=2)
    draw.rounded_rectangle((8, 8, SIZE - 9, SIZE - 9), radius=6, fill=BG, outline=SILVER, width=1)
    for cx, cy in ((16, 16), (112, 16), (16, 112), (112, 112), (64, 12), (64, 116), (12, 64), (116, 64)):
        draw.polygon([(cx, cy - 5), (cx + 5, cy), (cx, cy + 5), (cx - 5, cy)], fill=SILVER, outline=FRAME_HI)


def draw_titan_face(draw: ImageDraw.ImageDraw) -> None:
    cx, cy = 64, 42
    draw.ellipse((cx - 28, cy - 22, cx + 28, cy + 22), fill=STONE, outline=(58, 56, 68, 255))
    draw.ellipse((cx - 20, cy - 8, cx - 8, cy + 4), fill=EYE)
    draw.ellipse((cx + 8, cy - 8, cx + 20, cy + 4), fill=EYE)
    draw.arc((cx - 14, cy + 4, cx + 14, cy + 18), start=200, end=340, fill=(40, 38, 48, 255), width=3)


def draw_shockwaves(draw: ImageDraw.ImageDraw) -> None:
    cx, cy = 64, 68
    for r, w in ((46, 3), (38, 2), (30, 2), (22, 1)):
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), outline=PURPLE_HI if r > 30 else PURPLE, width=w)
    for i in range(16):
        ang = math.radians(i * 22.5)
        x1 = int(cx + 18 * math.cos(ang))
        y1 = int(cy + 18 * math.sin(ang))
        x2 = int(cx + 44 * math.cos(ang))
        y2 = int(cy + 44 * math.sin(ang))
        draw.line([(x1, y1), (x2, y2)], fill=PURPLE_CORE if i % 2 else PURPLE_HI, width=1)


def draw_shield(draw: ImageDraw.ImageDraw) -> None:
    cx = 64
    pts = [(cx, 52), (cx + 24, 62), (cx + 20, 96), (cx, 108), (cx - 20, 96), (cx - 24, 62)]
    draw.polygon(pts, fill=(58, 60, 72, 255), outline=SILVER)
    draw.polygon([(cx, 56), (cx + 18, 64), (cx + 14, 92), (cx, 102), (cx - 14, 92), (cx - 18, 64)], fill=(48, 50, 62, 255))
    draw.polygon([(cx - 8, 72), (cx, 66), (cx + 8, 72), (cx, 86)], fill=GEM, outline=PURPLE_HI)
    draw.polygon([(cx - 14, 70), (cx - 22, 78), (cx - 14, 86)], fill=SILVER)
    draw.polygon([(cx + 14, 70), (cx + 22, 78), (cx + 14, 86)], fill=SILVER)
    for rx in (cx - 18, cx + 14):
        draw.ellipse((rx, 74, rx + 6, 82), fill=FRAME_HI)


def draw_knockback(draw: ImageDraw.ImageDraw) -> None:
    body = (12, 12, 16, 255)
    for ox, flip in ((28, 1), (96, -1)):
        draw.ellipse((ox - 4, 98, ox + 4, 110), fill=body)
        draw.line([(ox, 94), (ox + 10 * flip, 88)], fill=body, width=3)
        draw.line([(ox, 94), (ox + 6 * flip, 104)], fill=body, width=2)
    for i in range(5):
        px(draw, 34 + i * 3, 92 - i, STONE)
        px(draw, 90 - i * 2, 90 + i, STONE)


def main() -> None:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_frame(draw)
    draw_titan_face(draw)
    draw_shockwaves(draw)
    draw_shield(draw)
    draw_knockback(draw)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT, "PNG")
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
