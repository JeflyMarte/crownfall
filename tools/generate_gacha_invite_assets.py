#!/usr/bin/env python3
"""Procedural fallback invitation sprites (P3-GACHA-REVEAL-001).

本番見た目は AI 封書＋クロマキー（`tools/process_gacha_invite_ai_assets.py`）を優先。
本スクリプトはフォールバック／SealShard 等の再生成用。

Usage:
  python3 tools/generate_gacha_invite_assets.py
"""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/ui/gacha_ui"

PARCHMENT = (214, 196, 160, 255)
PARCHMENT_DARK = (168, 142, 108, 255)
PARCHMENT_EDGE = (120, 96, 70, 255)
GOLD = (220, 180, 70, 255)
GOLD_SOFT = (235, 210, 120, 200)
WAX_RED = (150, 36, 42, 255)
WAX_DARK = (90, 20, 26, 255)
IRON = (90, 88, 86, 255)
GLOW = (255, 190, 90, 255)


def save(img: Image.Image, name: str) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / name
    img.save(path, optimize=True)
    print(f"wrote {path} ({img.size[0]}x{img.size[1]})")


def _noise_parchment(size: tuple[int, int]) -> Image.Image:
    w, h = size
    base = Image.new("RGBA", size, PARCHMENT)
    px = base.load()
    for y in range(h):
        for x in range(w):
            n = ((x * 17 + y * 31) ^ (x * y)) % 24
            r, g, b, a = px[x, y]
            px[x, y] = (r - n // 2, g - n // 3, b - n // 4, a)
    return base


def _draw_gold_corners(draw: ImageDraw.ImageDraw, box: tuple[int, int, int, int], arm: int = 18) -> None:
    x0, y0, x1, y1 = box
    for (ax, ay, dx, dy) in (
        (x0, y0, 1, 1),
        (x1, y0, -1, 1),
        (x0, y1, 1, -1),
        (x1, y1, -1, -1),
    ):
        draw.line((ax, ay, ax + dx * arm, ay), fill=GOLD, width=3)
        draw.line((ax, ay, ax, ay + dy * arm), fill=GOLD, width=3)


def _draw_wax_seal(draw: ImageDraw.ImageDraw, cx: int, cy: int, radius: int, color) -> None:
    draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), fill=color)
    inner = max(4, radius - 6)
    draw.ellipse(
        (cx - inner, cy - inner, cx + inner, cy + inner),
        outline=WAX_DARK if color[0] > 100 else (40, 40, 40, 255),
        width=2,
    )
    # compass-ish mark
    draw.line((cx, cy - inner + 2, cx, cy + inner - 2), fill=GOLD_SOFT, width=2)
    draw.line((cx - inner + 2, cy, cx + inner - 2, cy), fill=GOLD_SOFT, width=2)
    draw.ellipse((cx - 3, cy - 3, cx + 3, cy + 3), fill=GOLD)


def draw_invite_sealed(size: tuple[int, int] = (320, 220)) -> Image.Image:
    w, h = size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    paper = _noise_parchment((w - 24, h - 24))
    img.paste(paper, (12, 12), paper)
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle((12, 12, w - 12, h - 12), radius=10, outline=PARCHMENT_EDGE, width=3)
    # flap triangle hint
    draw.polygon(
        [(12, 12), (w // 2, h // 2 - 10), (w - 12, 12)],
        fill=(*PARCHMENT_DARK[:3], 90),
    )
    _draw_gold_corners(draw, (18, 18, w - 18, h - 18), arm=22)
    _draw_wax_seal(draw, w // 2, h // 2 + 8, 28, WAX_RED)
    # soft shadow edge
    return img.filter(ImageFilter.SMOOTH_MORE)


def draw_invite_opening(size: tuple[int, int] = (320, 240)) -> Image.Image:
    w, h = size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # back panel
    back = _noise_parchment((w - 40, h - 50))
    img.paste(back, (20, 40), back)
    draw.rounded_rectangle((20, 40, w - 20, h - 10), radius=8, outline=PARCHMENT_EDGE, width=2)
    # open flap (tilted up)
    flap = Image.new("RGBA", (w - 40, h // 2), (0, 0, 0, 0))
    fd = ImageDraw.Draw(flap)
    fd.polygon(
        [(0, flap.size[1] - 8), (flap.size[0] // 2, 4), (flap.size[0], flap.size[1] - 8)],
        fill=PARCHMENT,
    )
    fd.line(
        [(0, flap.size[1] - 8), (flap.size[0] // 2, 4), (flap.size[0], flap.size[1] - 8)],
        fill=PARCHMENT_EDGE,
        width=2,
    )
    img.paste(flap, (20, 8), flap)
    # inner warm light slit
    for i, alpha in enumerate((40, 90, 160, 220)):
        pad = 40 - i * 6
        draw.ellipse(
            (pad, h // 2 - 10, w - pad, h - 20),
            fill=(255, 200, 110, alpha // 2),
        )
    # broken wax shards
    cx, cy = w // 2, h // 2 + 20
    for dx, dy, r in ((-18, 8, 10), (14, -6, 9), (4, 18, 7), (-8, -14, 6)):
        draw.ellipse((cx + dx - r, cy + dy - r, cx + dx + r, cy + dy + r), fill=WAX_RED)
    _draw_gold_corners(draw, (24, 44, w - 24, h - 14), arm=16)
    return img.filter(ImageFilter.SMOOTH_MORE)


def draw_invite_open_frame(size: tuple[int, int] = (280, 300)) -> Image.Image:
    w, h = size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    paper = _noise_parchment((w - 16, h - 16))
    img.paste(paper, (8, 8), paper)
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle((8, 8, w - 8, h - 8), radius=12, outline=GOLD, width=3)
    # portrait window cut (transparent center)
    cut = (36, 48, w - 36, h - 70)
    for y in range(cut[1], cut[3]):
        for x in range(cut[0], cut[2]):
            img.putpixel((x, y), (0, 0, 0, 0))
    draw.rounded_rectangle(cut, radius=8, outline=GOLD_SOFT, width=2)
    _draw_gold_corners(draw, (14, 14, w - 14, h - 14), arm=20)
    # small wax at bottom
    _draw_wax_seal(draw, w // 2, h - 34, 16, WAX_RED)
    return img


def draw_invite_glow(size: tuple[int, int] = (360, 360)) -> Image.Image:
    w, h = size
    img = Image.new("RGBA", size, (0, 0, 0, 0))
    cx, cy = w // 2, h // 2
    px = img.load()
    max_r = min(w, h) // 2 - 4
    for y in range(h):
        for x in range(w):
            d = math.hypot(x - cx, y - cy) / max_r
            if d >= 1.0:
                continue
            a = int((1.0 - d) ** 2 * 180)
            px[x, y] = (GLOW[0], GLOW[1], GLOW[2], a)
    return img.filter(ImageFilter.GaussianBlur(radius=10))


def draw_seal_shard(size: int = 48) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.polygon(
        [(8, 10), (40, 6), (44, 28), (22, 42), (6, 30)],
        fill=WAX_RED,
        outline=WAX_DARK,
    )
    return img


def main() -> None:
    save(draw_invite_sealed(), "UI_Gacha_Invite_Sealed.png")
    save(draw_invite_opening(), "UI_Gacha_Invite_Opening.png")
    save(draw_invite_open_frame(), "UI_Gacha_Invite_OpenFrame.png")
    save(draw_invite_glow(), "UI_Gacha_Invite_Glow.png")
    save(draw_seal_shard(), "UI_Gacha_Invite_SealShard.png")
    # iron seal variant tint sheet (sealed with iron wax for ★2 modulate base)
    sealed_iron = draw_invite_sealed()
    # recolor red wax-ish pixels toward iron — simple pass
    px = sealed_iron.load()
    for y in range(sealed_iron.size[1]):
        for x in range(sealed_iron.size[0]):
            r, g, b, a = px[x, y]
            if a > 200 and r > 100 and r > g + 40 and r > b + 40:
                px[x, y] = (*IRON[:3], a)
    save(sealed_iron, "UI_Gacha_Invite_Sealed_Star2.png")


if __name__ == "__main__":
    main()
