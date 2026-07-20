#!/usr/bin/env python3
"""Generate Gacha (summon) screen UI chrome assets for Crownfall.

Output: assets/ui/gacha_ui/*.png

Usage:
  python3 tools/generate_gacha_ui_assets.py
  python3 tools/generate_gacha_ui_assets.py --force  # overwrite protected production art

Protected (use import_gacha_screen_art.py instead):
  UI_BG_Gacha.png, UI_Gacha_Banner_BG/Title/Catchcopy.png
"""
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/ui/gacha_ui"

GOLD = (235, 198, 72)
GOLD_DARK = (140, 110, 40)
BG_DARK = (10, 8, 22)
PURPLE = (120, 60, 200)
PURPLE_GLOW = (180, 100, 255)
TEAL = (90, 180, 220)
RED_RIBBON = (180, 45, 55)


# 本番アート。再生成で上書きすると出戻りする（既往: UI_BG_Gacha が星空プレースホルダに戻った）。
PROTECTED_ASSETS = frozenset(
    {
        "UI_BG_Gacha.png",
        "UI_Gacha_Banner_BG.png",
        "UI_Gacha_Banner_Title.png",
        "UI_Gacha_Banner_Catchcopy.png",
    }
)


def save(img: Image.Image, name: str, *, force: bool = False) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / name
    if name in PROTECTED_ASSETS and path.exists() and not force:
        print(f"skip protected {path} (use --force to overwrite)")
        return
    img.save(path, optimize=True)
    print(f"wrote {path} ({img.size[0]}x{img.size[1]})")


def rounded_rect(
    draw: ImageDraw.ImageDraw,
    box,
    radius: int,
    fill,
    outline=None,
    width: int = 1,
) -> None:
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def draw_diamond(size: int = 48) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    r = size // 2 - 2
    pts = [(cx, cy - r), (cx + r, cy), (cx, cy + r), (cx - r, cy)]
    draw.polygon(pts, fill=(*GOLD, 230), outline=(*GOLD_DARK, 255))
    draw.polygon(
        [(cx, cy - r + 4), (cx + r - 4, cy), (cx, cy + r - 4), (cx - r + 4, cy)],
        fill=(255, 230, 140, 120),
    )
    return img


def draw_back_arrow(size: int = 48) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.polygon(
        [(size * 0.62, size * 0.18), (size * 0.28, size * 0.5), (size * 0.62, size * 0.82)],
        fill=(*GOLD, 255),
    )
    draw.rectangle(
        (size * 0.28, size * 0.42, size * 0.78, size * 0.58),
        fill=(*GOLD, 255),
    )
    return img


def draw_token_icon(size: int = 64) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    for radius, alpha in ((28, 40), (22, 90), (16, 180)):
        draw.ellipse(
            (cx - radius, cy - radius, cx + radius, cy + radius),
            fill=(*PURPLE_GLOW, alpha),
        )
    pts = [
        (cx, cy - 18),
        (cx + 16, cy - 4),
        (cx + 10, cy + 16),
        (cx - 10, cy + 16),
        (cx - 16, cy - 4),
    ]
    draw.polygon(pts, fill=(200, 160, 255, 255), outline=(255, 240, 255, 255), width=2)
    draw.polygon(
        [(cx, cy - 10), (cx + 8, cy - 2), (cx + 5, cy + 8), (cx - 5, cy + 8), (cx - 8, cy - 2)],
        fill=(255, 255, 255, 140),
    )
    return img


def draw_background(w: int = 720, h: int = 1280) -> Image.Image:
    img = Image.new("RGB", (w, h), BG_DARK)
    draw = ImageDraw.Draw(img)
    for y in range(h):
        t = y / h
        c = (
            int(10 + 18 * t),
            int(8 + 10 * t),
            int(28 + 20 * t),
        )
        draw.line((0, y, w, y), fill=c)
    random.seed(77)
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(glow)
    gdraw.ellipse((w // 2 - 280, h // 3 - 120, w // 2 + 280, h // 3 + 320), fill=(*PURPLE, 55))
    gdraw.ellipse((w // 2 - 180, h // 2 - 80, w // 2 + 180, h // 2 + 200), fill=(*PURPLE_GLOW, 35))
    img = Image.alpha_composite(img.convert("RGBA"), glow.filter(ImageFilter.GaussianBlur(18))).convert("RGB")
    draw = ImageDraw.Draw(img)
    for _ in range(90):
        x, y = random.randint(0, w), random.randint(0, h)
        a = random.randint(12, 40)
        draw.ellipse((x, y, x + 2, y + 2), fill=(GOLD[0], GOLD[1], GOLD[2], a))
    return img


def draw_section_rule(w: int = 680, h: int = 24) -> Image.Image:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cy = h // 2
    draw.line((8, cy, w // 2 - 20, cy), fill=(*GOLD_DARK, 220), width=2)
    draw.line((w // 2 + 20, cy, w - 8, cy), fill=(*GOLD_DARK, 220), width=2)
    diamond = draw_diamond(20)
    img.paste(diamond, (w // 2 - 10, cy - 10), diamond)
    return img


def draw_tab(w: int = 220, h: int = 72, active: bool = True) -> Image.Image:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    if active:
        rounded_rect(draw, (2, 2, w - 2, h - 6), 10, (48, 32, 72, 245), (*GOLD, 255), 3)
        draw.rectangle((6, h - 10, w - 6, h - 4), fill=(*GOLD, 255))
        glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        ImageDraw.Draw(glow).rounded_rectangle((4, 4, w - 4, h - 8), 10, fill=(*PURPLE_GLOW, 50))
        img = Image.alpha_composite(glow.filter(ImageFilter.GaussianBlur(4)), img)
    else:
        rounded_rect(draw, (2, 4, w - 2, h - 2), 10, (18, 14, 28, 200), (70, 60, 90, 180), 2)
    return img


def draw_banner_frame(w: int = 696, h: int = 360) -> Image.Image:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    rounded_rect(draw, (0, 0, w - 1, h - 1), 14, (12, 8, 24, 230), (*GOLD_DARK, 220), 3)
    inner = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    idraw = ImageDraw.Draw(inner)
    idraw.rounded_rectangle((8, 8, w - 9, h - 9), 12, fill=(20, 12, 36, 180))
    img = Image.alpha_composite(img, inner)
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse((w - 260, 40, w + 20, h - 20), fill=(*PURPLE_GLOW, 60))
    img = Image.alpha_composite(img, glow.filter(ImageFilter.GaussianBlur(12)))
    return img


def draw_pity_bar_bg(w: int = 640, h: int = 28) -> Image.Image:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    rounded_rect(draw, (0, 0, w - 1, h - 1), h // 2, (16, 12, 24, 240), (*GOLD_DARK, 180), 2)
    return img


def draw_pity_bar_fill(w: int = 640, h: int = 28) -> Image.Image:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    rounded_rect(draw, (2, 2, w - 3, h - 3), h // 2 - 2, (200, 150, 40, 255), (*GOLD, 200), 1)
    draw.line((8, 6, w - 12, 6), fill=(255, 230, 150, 100), width=2)
    return img


def draw_pull_button(w: int = 320, h: int = 88, enabled: bool = True) -> Image.Image:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    if enabled:
        rounded_rect(draw, (0, 0, w - 1, h - 1), 12, (36, 48, 88, 255), (*GOLD, 255), 3)
        draw.line((10, 8, w - 10, 8), fill=(180, 200, 255, 80), width=2)
    else:
        rounded_rect(draw, (0, 0, w - 1, h - 1), 12, (28, 26, 34, 220), (80, 75, 90, 180), 2)
    return img


def draw_ribbon(w: int = 280, h: int = 56) -> Image.Image:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.polygon(
        [(0, h // 2), (16, 4), (w - 16, 4), (w, h // 2), (w - 16, h - 4), (16, h - 4)],
        fill=(*RED_RIBBON, 240),
        outline=(*GOLD, 255),
        width=2,
    )
    draw.line((20, 10, w - 20, 10), fill=(255, 200, 120, 80), width=1)
    return img


def draw_lineup_cell(size: int = 120) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    rounded_rect(draw, (2, 2, size - 2, size - 2), 10, (18, 14, 28, 235), (*GOLD_DARK, 200), 2)
    draw.rectangle((8, size - 28, size - 8, size - 8), fill=(8, 6, 14, 200))
    return img


def draw_panel_dark(w: int = 696, h: int = 200) -> Image.Image:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    rounded_rect(draw, (0, 0, w - 1, h - 1), 12, (14, 10, 22, 235), (*GOLD_DARK, 160), 2)
    return img


def draw_detail_button(w: int = 200, h: int = 48) -> Image.Image:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    rounded_rect(draw, (0, 0, w - 1, h - 1), 8, (20, 16, 30, 220), (*GOLD_DARK, 200), 2)
    return img


def draw_reveal_frame(w: int = 360, h: int = 420) -> Image.Image:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    rounded_rect(draw, (0, 0, w - 1, h - 1), 16, (16, 10, 28, 245), (*GOLD, 255), 4)
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(glow).rounded_rectangle((4, 4, w - 5, h - 5), 14, fill=(*PURPLE_GLOW, 45))
    return Image.alpha_composite(glow.filter(ImageFilter.GaussianBlur(6)), img)


def main(argv: list[str] | None = None) -> int:
    import sys

    args = list(sys.argv[1:] if argv is None else argv)
    force = "--force" in args
    bg_path = OUT / "UI_BG_Gacha.png"
    if force or not bg_path.exists():
        save(draw_background(), "UI_BG_Gacha.png", force=force)
    else:
        print(f"skip protected {bg_path} (use --force to overwrite)")
    save(draw_diamond(48), "UI_Ornament_Diamond.png", force=force)
    save(draw_back_arrow(48), "UI_Ico_Back_Gold.png", force=force)
    save(draw_section_rule(), "UI_Gacha_SectionRule.png", force=force)
    save(draw_banner_frame(), "UI_Gacha_Banner_Frame.png", force=force)
    save(draw_pity_bar_bg(), "UI_Gacha_PityBar_Bg.png", force=force)
    save(draw_pity_bar_fill(), "UI_Gacha_PityBar_Fill.png", force=force)
    save(draw_pull_button(320, 88, enabled=True), "UI_Gacha_Btn_1Pull.png", force=force)
    save(draw_pull_button(320, 88, enabled=False), "UI_Gacha_Btn_1Pull_Disabled.png", force=force)
    save(draw_lineup_cell(120), "UI_Gacha_LineupCell.png", force=force)
    save(draw_panel_dark(), "UI_Gacha_Panel_Dark.png", force=force)
    save(draw_detail_button(), "UI_Gacha_Btn_Detail.png", force=force)
    save(draw_token_icon(64), "ICO_Gacha_Token.png", force=force)
    save(draw_reveal_frame(), "UI_Gacha_Reveal_Frame.png", force=force)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
