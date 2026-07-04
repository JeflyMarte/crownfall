#!/usr/bin/env python3
"""Generate status effect icons for battle head badges."""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/ui/status"
SIZE = 32

STATUSES: list[tuple[str, tuple[int, int, int], str]] = [
    ("poison", (64, 192, 76), "poison"),
    ("chill", (89, 166, 242), "ice"),
    ("shock", (242, 217, 51), "thunder"),
    ("ignite", (242, 102, 38), "fire"),
    ("curse", (140, 64, 191), "curse"),
    ("stun", (178, 178, 191), "stun"),
    ("fear", (140, 89, 153), "fear"),
    ("vulnerable", (242, 115, 115), "crack"),
    ("armor_break", (204, 153, 76), "break"),
    ("mark", (242, 89, 140), "mark"),
    ("empower", (242, 140, 51), "buff"),
    ("guard", (102, 140, 217), "shield"),
]


def snake_to_pascal(snake: str) -> str:
    return "".join(part.capitalize() for part in snake.split("_"))


def draw_glyph(draw: ImageDraw.ImageDraw, cx: int, cy: int, kind: str, color: tuple[int, int, int]) -> None:
    if kind == "poison":
        draw.ellipse((cx - 5, cy - 10, cx + 5, cy), fill=color)
        draw.polygon([(cx, cy), (cx - 8, cy + 10), (cx + 8, cy + 10)], fill=color)
    elif kind == "ice":
        for i in range(6):
            ang = i * math.pi / 3 - math.pi / 2
            x2 = cx + int(10 * math.cos(ang))
            y2 = cy + int(10 * math.sin(ang))
            draw.line((cx, cy, x2, y2), fill=color, width=2)
    elif kind == "thunder":
        draw.polygon([(cx - 2, cy - 10), (cx + 6, cy - 1), (cx + 1, cy - 1), (cx + 4, cy + 10), (cx - 6, cy), (cx - 1, cy)], fill=color)
    elif kind == "fire":
        draw.polygon([(cx, cy - 11), (cx + 8, cy + 2), (cx + 2, cy + 2), (cx + 5, cy + 11), (cx - 5, cy + 11), (cx - 2, cy + 2), (cx - 8, cy + 2)], fill=color)
    elif kind == "curse":
        draw.arc((cx - 9, cy - 9, cx + 9, cy + 9), 30, 300, fill=color, width=2)
        draw.ellipse((cx - 3, cy - 3, cx + 3, cy + 3), fill=color)
    elif kind == "stun":
        for i in range(3):
            ang = i * 2.1
            draw.text((cx - 4 + int(7 * math.cos(ang)), cy - 6 + int(5 * math.sin(ang))), "*", fill=color)
    elif kind == "fear":
        draw.ellipse((cx - 8, cy - 6, cx + 8, cy + 8), outline=color, width=2)
        draw.ellipse((cx - 4, cy - 1, cx - 1, cy + 2), fill=(20, 10, 30))
        draw.ellipse((cx + 1, cy - 1, cx + 4, cy + 2), fill=(20, 10, 30))
    elif kind == "crack":
        draw.rectangle((cx - 9, cy - 8, cx + 9, cy + 8), outline=color, width=2)
        draw.line((cx - 6, cy - 4, cx + 2, cy + 2), fill=color, width=2)
        draw.line((cx + 2, cy + 2, cx + 7, cy - 6), fill=color, width=2)
    elif kind == "break":
        draw.polygon([(cx, cy - 9), (cx + 10, cy - 3), (cx + 6, cy + 9), (cx - 6, cy + 9), (cx - 10, cy - 3)], outline=color, width=2)
        draw.line((cx - 4, cy - 2, cx + 5, cy + 6), fill=color, width=2)
    elif kind == "mark":
        draw.ellipse((cx - 9, cy - 9, cx + 9, cy + 9), outline=color, width=2)
        draw.line((cx, cy - 5, cx, cy + 5), fill=color, width=2)
        draw.line((cx - 5, cy, cx + 5, cy), fill=color, width=2)
    elif kind == "buff":
        draw.polygon([(cx, cy - 10), (cx + 8, cy + 8), (cx - 8, cy + 8)], fill=color)
        draw.rectangle((cx - 2, cy - 4, cx + 2, cy + 4), fill=(30, 24, 18))
    elif kind == "shield":
        draw.polygon([(cx, cy - 9), (cx + 9, cy - 3), (cx + 6, cy + 9), (cx - 6, cy + 9), (cx - 9, cy - 3)], fill=color, outline=(20, 20, 30))
    else:
        draw.ellipse((cx - 8, cy - 8, cx + 8, cy + 8), fill=color)


def make_icon(status_id: str, accent: tuple[int, int, int], kind: str) -> None:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    dark = tuple(max(0, c // 4) for c in accent)
    draw.rounded_rectangle((1, 1, SIZE - 2, SIZE - 2), radius=5, fill=(*dark, 255))
    draw.rounded_rectangle((2, 2, SIZE - 3, SIZE - 3), radius=4, outline=(*accent, 255), width=1)
    draw_glyph(draw, SIZE // 2, SIZE // 2 + 1, kind, accent)
    fname = f"ICO_STA_{snake_to_pascal(status_id)}.png"
    img.save(OUT / fname, "PNG")
    print(f"  {fname}")


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    print("Status icons...")
    for spec in STATUSES:
        make_icon(*spec)
    print(f"Generated {len(STATUSES)} icons.")
