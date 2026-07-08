#!/usr/bin/env python3
"""Generate ICO_SKILL_BASE_Snare combined source (128x128) for install_skill_base_icon."""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/ui/skills/base/_source_Snare_combined.png"
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


def draw_burst(draw: ImageDraw.ImageDraw) -> None:
    cx, cy = 64, 58
    white = (245, 248, 255, 255)
    glow = (190, 198, 210, 160)
    for i in range(12):
        ang = math.radians(i * 30)
        x1 = int(cx + 10 * math.cos(ang))
        y1 = int(cy + 10 * math.sin(ang))
        x2 = int(cx + 26 * math.cos(ang))
        y2 = int(cy + 26 * math.sin(ang))
        draw.line((x1, y1, x2, y2), fill=glow if i % 2 else white, width=1)


def draw_chain_segment(draw: ImageDraw.ImageDraw, p0: tuple[int, int], p1: tuple[int, int], c: tuple[int, int, int, int]) -> None:
    draw.line([p0, p1], fill=c, width=3)
    mx = (p0[0] + p1[0]) // 2
    my = (p0[1] + p1[1]) // 2
    draw.ellipse((mx - 3, my - 3, mx + 3, my + 3), outline=c, width=1)


def draw_chains(draw: ImageDraw.ImageDraw) -> None:
    white = (245, 248, 255, 255)
    shadow = (140, 148, 160, 255)
    cx, cy = 64, 58

    for corner in ((22, 22), (106, 22), (22, 94), (106, 94)):
        draw_chain_segment(draw, corner, (cx, cy), shadow)
        draw_chain_segment(draw, corner, (cx, cy), white)

    draw_chain_segment(draw, (cx - 18, cy - 28), (cx + 18, cy - 28), white)
    draw_chain_segment(draw, (cx - 20, cy + 4), (cx + 20, cy + 4), white)
    draw_chain_segment(draw, (cx - 14, cy + 22), (cx + 14, cy + 22), white)
    draw_chain_segment(draw, (cx - 22, cy - 8), (cx - 8, cy + 18), white)
    draw_chain_segment(draw, (cx + 22, cy - 8), (cx + 8, cy + 18), white)


def draw_silhouette(draw: ImageDraw.ImageDraw) -> None:
    body = (16, 16, 18, 255)
    outline = (230, 236, 245, 255)
    cx = 64

    # head
    draw.ellipse((cx - 8, 30, cx + 8, 46), fill=body, outline=outline, width=1)
    # torso
    draw.polygon([(cx - 12, 46), (cx + 12, 46), (cx + 10, 78), (cx - 10, 78)], fill=body, outline=outline)
    # arms
    draw.line((cx - 12, 50, cx - 22, 64), fill=outline, width=2)
    draw.line((cx + 12, 50, cx + 22, 64), fill=outline, width=2)
    draw.line((cx - 22, 64, cx - 18, 72), fill=body, width=3)
    draw.line((cx + 22, 64, cx + 18, 72), fill=body, width=3)
    # legs
    draw.line((cx - 6, 78, cx - 10, 96), fill=body, width=4)
    draw.line((cx + 6, 78, cx + 10, 96), fill=body, width=4)


def main() -> None:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_frame(draw)
    draw_burst(draw)
    draw_silhouette(draw)
    draw_chains(draw)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT, "PNG")
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
