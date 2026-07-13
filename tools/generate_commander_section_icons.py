#!/usr/bin/env python3
"""Generate 隊長台帳 section icons (64x64, codex-adjacent style)."""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets/ui/commander"
SIZE = 64

SPECS: list[tuple[str, tuple[int, int, int], str]] = [
    ("ICO_CMD_Overview", (220, 196, 140), "overview"),
    ("ICO_CMD_GiftBox", (200, 150, 90), "gift"),
    ("ICO_CMD_Assets", (242, 200, 90), "assets"),
    ("ICO_CMD_Members", (140, 190, 220), "members"),
    ("ICO_CMD_Records", (160, 175, 210), "records"),
    ("ICO_CMD_Titles", (242, 210, 120), "titles"),
]


def frame(draw: ImageDraw.ImageDraw, accent: tuple[int, int, int]) -> None:
    dark = tuple(max(0, c // 4) for c in accent)
    draw.rounded_rectangle((2, 2, SIZE - 3, SIZE - 3), radius=8, fill=(*dark, 255))
    draw.rounded_rectangle((4, 4, SIZE - 5, SIZE - 5), radius=6, outline=(*accent, 255), width=2)


def draw_overview(draw: ImageDraw.ImageDraw, cx: int, cy: int, accent: tuple[int, int, int]) -> None:
    draw.rounded_rectangle((cx - 16, cy - 20, cx + 16, cy + 20), radius=4, fill=(232, 220, 190, 255))
    draw.arc((cx - 16, cy - 26, cx + 16, cy - 14), 0, 180, fill=(*accent, 255), width=2)
    draw.arc((cx - 16, cy + 14, cx + 16, cy + 26), 180, 360, fill=(*accent, 255), width=2)
    for y in range(cy - 10, cy + 14, 6):
        draw.line((cx - 10, y, cx + 8, y), fill=(170, 150, 120, 180), width=1)
    draw.ellipse((cx + 10, cy - 18, cx + 22, cy - 6), fill=(*accent, 255))


def draw_gift(draw: ImageDraw.ImageDraw, cx: int, cy: int, accent: tuple[int, int, int]) -> None:
    dark = tuple(max(0, c // 2) for c in accent)
    draw.rounded_rectangle((cx - 18, cy - 6, cx + 18, cy + 18), radius=4, fill=(*dark, 255))
    draw.rectangle((cx - 18, cy - 12, cx + 18, cy - 2), fill=(*accent, 255))
    draw.rectangle((cx - 2, cy - 12, cx + 2, cy + 18), fill=(240, 220, 180, 255))
    draw.arc((cx - 10, cy - 20, cx - 2, cy - 10), 0, 180, fill=(240, 220, 180, 255), width=3)
    draw.arc((cx + 2, cy - 20, cx + 10, cy - 10), 0, 180, fill=(240, 220, 180, 255), width=3)


def draw_assets(draw: ImageDraw.ImageDraw, cx: int, cy: int, accent: tuple[int, int, int]) -> None:
    draw.ellipse((cx - 14, cy - 2, cx + 14, cy + 18), fill=(120, 90, 40, 255), outline=(*accent, 255), width=2)
    draw.ellipse((cx - 8, cy - 10, cx + 2, cy), fill=(*accent, 255))
    draw.ellipse((cx - 2, cy - 12, cx + 8, cy - 2), fill=(255, 230, 140, 255))
    draw.polygon([(cx + 10, cy - 14), (cx + 18, cy - 6), (cx + 12, cy + 2), (cx + 6, cy - 4)], fill=(120, 200, 255, 255))


def draw_members(draw: ImageDraw.ImageDraw, cx: int, cy: int, accent: tuple[int, int, int]) -> None:
    for dx, col in [(-14, accent), (0, (200, 220, 240)), (14, accent)]:
        x = cx + dx
        draw.ellipse((x - 5, cy - 14, x + 5, cy - 4), fill=(*col, 255))
        draw.rounded_rectangle((x - 7, cy - 2, x + 7, cy + 16), radius=3, fill=(*col, 220))


def draw_records(draw: ImageDraw.ImageDraw, cx: int, cy: int, accent: tuple[int, int, int]) -> None:
    draw.rounded_rectangle((cx - 16, cy - 18, cx + 16, cy + 18), radius=3, fill=(210, 220, 235, 255), outline=(*accent, 255), width=2)
    for i, w in enumerate([18, 14, 20, 12]):
        y = cy - 10 + i * 6
        draw.line((cx - 10, y, cx - 10 + w, y), fill=(*accent, 200), width=2)
    draw.line((cx + 8, cy + 8, cx + 14, cy + 14), fill=(90, 160, 90, 255), width=2)
    draw.line((cx + 14, cy + 8, cx + 8, cy + 14), fill=(90, 160, 90, 255), width=2)


def draw_titles(draw: ImageDraw.ImageDraw, cx: int, cy: int, accent: tuple[int, int, int]) -> None:
    pts = [(cx, cy - 18), (cx + 8, cy - 6), (cx + 18, cy - 8), (cx + 10, cy + 2), (cx + 14, cy + 16), (cx, cy + 10), (cx - 14, cy + 16), (cx - 10, cy + 2), (cx - 18, cy - 8), (cx - 8, cy - 6)]
    draw.polygon(pts, fill=(*accent, 255), outline=(255, 240, 200, 255))
    draw.ellipse((cx - 5, cy - 5, cx + 5, cy + 5), fill=(40, 35, 30, 255))


DRAWERS = {
    "overview": draw_overview,
    "gift": draw_gift,
    "assets": draw_assets,
    "members": draw_members,
    "records": draw_records,
    "titles": draw_titles,
}


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for fname, accent, kind in SPECS:
        img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        frame(draw, accent)
        DRAWERS[kind](draw, SIZE // 2, SIZE // 2 + 1, accent)
        path = OUT_DIR / f"{fname}.png"
        img.save(path, "PNG")
        print(f"  wrote {path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
