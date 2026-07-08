#!/usr/bin/env python3
"""Generate passive icon: battle_fervor (高揚)."""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/ui/passives/ICO_PASSIVE_BattleFervor.png"
SIZE = 128

GOLD = (212, 175, 72, 255)
GOLD_HI = (255, 232, 140, 255)
GOLD_LO = (140, 108, 42, 255)
BG = (42, 44, 50, 255)
ARMOR = (58, 60, 68, 255)
SKIN = (150, 110, 80, 255)
BLADE = (245, 248, 255, 255)
AURA = (255, 220, 120, 200)


def px(draw: ImageDraw.ImageDraw, x: int, y: int, c: tuple[int, int, int, int]) -> None:
    if 0 <= x < SIZE and 0 <= y < SIZE:
        draw.point((x, y), fill=c)


def draw_frame(draw: ImageDraw.ImageDraw) -> None:
    draw.rounded_rectangle((0, 0, SIZE - 1, SIZE - 1), radius=10, fill=GOLD_LO)
    draw.rounded_rectangle((2, 2, SIZE - 3, SIZE - 3), radius=9, outline=GOLD_HI, width=1)
    draw.rounded_rectangle((6, 6, SIZE - 7, SIZE - 7), radius=8, fill=BG, outline=GOLD, width=1)


def draw_arrow(draw: ImageDraw.ImageDraw, cx: int, cy: int, scale: int = 1) -> None:
    s = scale
    draw.polygon([(cx, cy - 10 * s), (cx + 5 * s, cy), (cx, cy - 2 * s), (cx - 5 * s, cy)], fill=GOLD_HI)
    draw.rectangle((cx - 2 * s, cy, cx + 2 * s, cy + 10 * s), fill=GOLD)


def draw_aura(draw: ImageDraw.ImageDraw) -> None:
    cx = 64
    for i in range(6):
        y = 96 - i * 8
        draw.arc((cx - 30 + i * 2, y - 8, cx + 30 - i * 2, y + 8), start=200, end=340, fill=AURA, width=2)
    for i in range(12):
        px(draw, 40 + (i * 5) % 48, 88 - (i % 4) * 6, GOLD_HI)


def draw_hand_sword(draw: ImageDraw.ImageDraw) -> None:
    cx = 64
    # armored hand
    draw.ellipse((cx - 18, 72, cx + 18, 100), fill=ARMOR, outline=GOLD)
    draw.ellipse((cx - 12, 76, cx + 12, 96), fill=SKIN)
    # sword hilt
    draw.rectangle((cx - 4, 58, cx + 4, 76), fill=GOLD)
    draw.rectangle((cx - 10, 56, cx + 10, 60), fill=GOLD_HI)
    # blade with arrow tip
    draw.polygon([(cx - 5, 56), (cx + 5, 56), (cx + 3, 20), (cx, 10), (cx - 3, 20)], fill=BLADE, outline=GOLD_HI)
    draw.polygon([(cx - 2, 24), (cx + 2, 24), (cx, 12)], fill=GOLD_HI)


def main() -> None:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_frame(draw)
    draw_aura(draw)
    draw_arrow(draw, 28, 52, 1)
    draw_arrow(draw, 100, 52, 1)
    draw_hand_sword(draw)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT, "PNG")
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
