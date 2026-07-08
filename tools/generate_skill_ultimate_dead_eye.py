#!/usr/bin/env python3
"""Generate unique ultimate icon: dead_eye (デッドアイ)."""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/ui/skills/ICO_SKILL_DeadEye.png"
SIZE = 128

FRAME = (72, 76, 84, 255)
FRAME_HI = (190, 198, 210, 255)
BG = (18, 20, 26, 255)
CYAN = (100, 200, 230, 255)
CYAN_HI = (180, 240, 255, 255)
CYAN_CORE = (240, 252, 255, 255)
RED = (240, 60, 70, 255)
FEATHER = (140, 148, 158, 255)
WHITE = (245, 248, 255, 255)
BODY = (12, 12, 16, 255)


def px(draw: ImageDraw.ImageDraw, x: int, y: int, c: tuple[int, int, int, int]) -> None:
    if 0 <= x < SIZE and 0 <= y < SIZE:
        draw.point((x, y), fill=c)


def draw_frame(draw: ImageDraw.ImageDraw) -> None:
    draw.rounded_rectangle((0, 0, SIZE - 1, SIZE - 1), radius=8, fill=FRAME)
    draw.rounded_rectangle((3, 3, SIZE - 4, SIZE - 4), radius=7, outline=FRAME_HI, width=2)
    draw.rounded_rectangle((6, 6, SIZE - 7, SIZE - 7), radius=6, outline=CYAN, width=1)
    draw.rounded_rectangle((10, 10, SIZE - 11, SIZE - 11), radius=5, fill=BG)
    for cx, cy, dx, dy in (
        (14, 14, 1, 1), (114, 14, -1, 1), (14, 114, 1, -1), (114, 114, -1, -1),
    ):
        draw.polygon([(cx, cy), (cx + 10 * dx, cy + 2 * dy), (cx + 2 * dx, cy + 10 * dy)], fill=FRAME_HI)


def draw_scope_bg(draw: ImageDraw.ImageDraw) -> None:
    cx, cy = 88, 58
    for r in (28, 20, 12):
        draw.ellipse((cx - r, cy - r, cx + r, cy + r), outline=(60, 64, 72, 255), width=1)
    for i in range(8):
        ang = math.radians(i * 45)
        x2 = int(cx + 30 * math.cos(ang))
        y2 = int(cy + 30 * math.sin(ang))
        draw.line([(cx, cy), (x2, y2)], fill=(50, 54, 62, 255), width=1)


def draw_eye(draw: ImageDraw.ImageDraw) -> None:
    cx, cy = 42, 58
    draw.ellipse((cx - 24, cy - 16, cx + 10, cy + 16), fill=FEATHER, outline=FRAME_HI)
    draw.ellipse((cx - 14, cy - 12, cx + 2, cy + 12), fill=WHITE)
    draw.ellipse((cx - 10, cy - 10, cx - 2, cy + 10), fill=CYAN)
    draw.ellipse((cx - 7, cy - 7, cx - 5, cy + 7), fill=(20, 24, 30, 255))
    # beam from pupil
    draw.rectangle((cx - 4, cy - 2, 96, cy + 2), fill=CYAN_HI)
    draw.rectangle((cx - 2, cy - 1, 94, cy + 1), fill=CYAN_CORE)


def draw_arrow(draw: ImageDraw.ImageDraw) -> None:
    cx, cy = 72, 58
    draw.line([(cx - 16, cy), (cx + 16, cy)], fill=(40, 44, 52, 255), width=3)
    draw.polygon([(cx + 16, cy), (cx + 26, cy - 5), (cx + 26, cy + 5)], fill=FRAME_HI)
    draw.polygon([(cx - 16, cy), (cx - 22, cy - 4), (cx - 22, cy + 4)], fill=FEATHER)


def draw_crosshair(draw: ImageDraw.ImageDraw) -> None:
    cx, cy = 96, 58
    draw.ellipse((cx - 14, cy - 14, cx + 14, cy + 14), outline=CYAN_HI, width=2)
    draw.line([(cx - 18, cy), (cx + 18, cy)], fill=CYAN, width=1)
    draw.line([(cx, cy - 18), (cx, cy + 18)], fill=CYAN, width=1)
    draw.polygon([(cx, cy - 4), (cx + 4, cy), (cx, cy + 4), (cx - 4, cy)], fill=RED)


def draw_impact(draw: ImageDraw.ImageDraw) -> None:
    for ox in (30, 50, 78, 98):
        draw.ellipse((ox - 3, 100, ox + 3, 112), fill=BODY)
        draw.line([(ox, 98), (ox + 6, 92)], fill=BODY, width=2)
    for i in range(6):
        px(draw, 40 + i * 5, 104 - i, FRAME_HI)


def main() -> None:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_frame(draw)
    draw_scope_bg(draw)
    draw_eye(draw)
    draw_arrow(draw)
    draw_crosshair(draw)
    draw_impact(draw)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT, "PNG")
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
