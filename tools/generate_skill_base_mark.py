#!/usr/bin/env python3
"""Generate ICO_SKILL_BASE_Mark combined source (128x128) for install_skill_base_icon."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/ui/skills/base/_source_Mark_combined.png"
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


def draw_crosshair(draw: ImageDraw.ImageDraw) -> None:
    cx, cy = 64, 58
    ring = (200, 208, 220, 255)
    ring_dark = (120, 128, 142, 255)
    accent = (245, 248, 255, 255)
    mark = (230, 120, 130, 255)

    draw.ellipse((cx - 30, cy - 30, cx + 30, cy + 30), outline=ring_dark, width=2)
    draw.ellipse((cx - 22, cy - 22, cx + 22, cy + 22), outline=ring, width=2)
    draw.ellipse((cx - 10, cy - 10, cx + 10, cy + 10), outline=accent, width=2)
    draw.ellipse((cx - 3, cy - 3, cx + 3, cy + 3), fill=mark)

    draw.line((cx - 36, cy, cx - 14, cy), fill=accent, width=2)
    draw.line((cx + 14, cy, cx + 36, cy), fill=accent, width=2)
    draw.line((cx, cy - 36, cx, cy - 14), fill=accent, width=2)
    draw.line((cx, cy + 14, cx, cy + 36), fill=accent, width=2)

    # corner brackets
    for ox, oy, sx, sy in [(-24, -24, 1, 1), (24, -24, -1, 1), (-24, 24, 1, -1), (24, 24, -1, -1)]:
        x0, y0 = cx + ox, cy + oy
        draw.line((x0, y0, x0 + 10 * sx, y0), fill=ring, width=2)
        draw.line((x0, y0, x0, y0 + 10 * sy), fill=ring, width=2)


def draw_eye_hint(draw: ImageDraw.ImageDraw) -> None:
    """Small hunter eye above target."""
    white = (245, 248, 255, 255)
    lid = (58, 62, 72, 255)
    cx, cy = 64, 34
    draw.arc((cx - 14, cy - 6, cx + 14, cy + 10), start=200, end=340, fill=lid, width=2)
    draw.ellipse((cx - 8, cy, cx + 8, cy + 8), outline=white, width=1)
    draw.ellipse((cx - 3, cy + 3, cx + 3, cy + 9), fill=white)


def main() -> None:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_frame(draw)
    draw_crosshair(draw)
    draw_eye_hint(draw)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT, "PNG")
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
