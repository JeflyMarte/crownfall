#!/usr/bin/env python3
"""Generate 隊長台帳 (Commander mypage) UI chrome assets for Crownfall.

Output: assets/ui/commander_ui/*.png

Usage:
  python3 tools/generate_commander_ui_assets.py
"""
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/ui/commander_ui"

GOLD = (220, 188, 110)
GOLD_DARK = (130, 100, 45)
GOLD_HI = (255, 235, 180)
BG_DARK = (12, 16, 28)
NAVY = (24, 36, 58)
NAVY_DISABLED = (36, 38, 42)
TEAL = (70, 120, 150)
TEAL_GLOW = (90, 150, 180)
TEAL_DARK = (45, 95, 110)
PARCHMENT = (190, 170, 130)
BTN_SECONDARY = (20, 28, 42)
BTN_SECONDARY_DISABLED = (36, 38, 42)
FONT_PATHS = [
    ROOT / "assets/fonts/ShipporiMinchoB1-Bold.ttf",
    ROOT / "assets/fonts/NotoSansJP-VariableFont_wght.ttf",
    Path("/System/Library/Fonts/Hiragino Sans GB.ttc"),
]


def save(img: Image.Image, name: str) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / name
    img.save(path, optimize=True)
    print(f"wrote {path} ({img.size[0]}x{img.size[1]})")


def load_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for path in FONT_PATHS:
        if path.exists():
            try:
                return ImageFont.truetype(str(path), size)
            except OSError:
                continue
    return ImageFont.load_default()


def rounded_rect(draw: ImageDraw.ImageDraw, box, radius: int, fill, outline=None, width: int = 1) -> None:
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def _draw_button_frame(
    draw: ImageDraw.ImageDraw,
    w: int,
    h: int,
    *,
    enabled: bool,
    primary: bool,
) -> None:
    if primary:
        fill = NAVY if enabled else NAVY_DISABLED
        border = TEAL_GLOW if enabled else (90, 85, 80)
    else:
        fill = BTN_SECONDARY if enabled else BTN_SECONDARY_DISABLED
        border = GOLD_DARK if enabled else (80, 78, 74)
    rounded_rect(draw, (0, 0, w - 1, h - 1), 10, (*fill, 255), (*border, 255), 2)
    if enabled:
        draw.line((10, 6, w - 10, 6), fill=(*GOLD_HI, 90 if primary else 45), width=2)


def _button_canvas(
    w: int,
    h: int,
    *,
    enabled: bool = True,
    primary: bool = False,
) -> Image.Image:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    _draw_button_frame(draw, w, h, enabled=enabled, primary=primary)
    if enabled and primary:
        glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        gdraw = ImageDraw.Draw(glow)
        gdraw.ellipse((w // 2 - 120, h - 30, w // 2 + 120, h + 20), fill=(*TEAL, 45))
        img = Image.alpha_composite(img, glow.filter(ImageFilter.GaussianBlur(5)))
        draw = ImageDraw.Draw(img)
        _draw_button_frame(draw, w, h, enabled=enabled, primary=primary)
    return img


def _draw_text(
    draw: ImageDraw.ImageDraw,
    w: int,
    h: int,
    label: str,
    *,
    enabled: bool,
    font_size: int,
) -> None:
    font = load_font(font_size)
    text_color = (235, 228, 210, 255) if enabled else (130, 125, 118, 255)
    outline = (12, 18, 28, 220) if enabled else (30, 28, 26, 200)
    bbox = draw.textbbox((0, 0), label, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    tx = (w - tw) // 2
    ty = (h - th) // 2 - 2
    for ox, oy in [(-2, 0), (2, 0), (0, -2), (0, 2)]:
        draw.text((tx + ox, ty + oy), label, font=font, fill=outline)
    draw.text((tx, ty), label, font=font, fill=text_color)


def draw_labeled_button(
    label: str,
    w: int,
    h: int,
    *,
    primary: bool = False,
    enabled: bool = True,
    font_size: int = 28,
) -> Image.Image:
    img = _button_canvas(w, h, enabled=enabled, primary=primary)
    draw = ImageDraw.Draw(img)
    _draw_text(draw, w, h, label, enabled=enabled, font_size=font_size)
    return img


def draw_diamond(size: int = 48) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    r = size // 2 - 2
    pts = [(cx, cy - r), (cx + r, cy), (cx, cy + r), (cx - r, cy)]
    draw.polygon(pts, fill=(*GOLD, 230), outline=(*GOLD_DARK, 255))
    draw.polygon(
        [(cx, cy - r + 4), (cx + r - 4, cy), (cx, cy + r - 4), (cx - r + 4, cy)],
        fill=(255, 235, 180, 110),
    )
    return img


def draw_back_arrow(size: int = 48) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.polygon(
        [(size * 0.62, size * 0.18), (size * 0.28, size * 0.5), (size * 0.62, size * 0.82)],
        fill=(*GOLD, 255),
    )
    draw.rectangle((size * 0.28, size * 0.42, size * 0.78, size * 0.58), fill=(*GOLD, 255))
    return img


def draw_background(w: int = 720, h: int = 1280) -> Image.Image:
    img = Image.new("RGB", (w, h), BG_DARK)
    draw = ImageDraw.Draw(img)
    for y in range(h):
        t = y / h
        c = (
            int(12 + 16 * t),
            int(16 + 20 * t),
            int(28 + 18 * t),
        )
        draw.line((0, y, w, y), fill=c)

    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(glow)
    gdraw.ellipse((w // 2 - 300, h // 4 - 60, w // 2 + 300, h // 4 + 340), fill=(*TEAL, 42))
    gdraw.ellipse((w // 2 - 220, h // 2 - 40, w // 2 + 220, h // 2 + 280), fill=(*NAVY, 70))
    gdraw.ellipse((w // 2 - 180, h * 3 // 4 - 80, w // 2 + 180, h - 40), fill=(35, 28, 18, 55))
    img = Image.alpha_composite(img.convert("RGBA"), glow.filter(ImageFilter.GaussianBlur(20))).convert("RGB")

    draw = ImageDraw.Draw(img)
    for y in range(180, h - 120, 28):
        draw.line((36, y, w - 36, y), fill=(PARCHMENT[0], PARCHMENT[1], PARCHMENT[2]), width=1)

    seal = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(seal)
    cx, cy = w // 2, 220
    for radius, alpha in ((150, 18), (118, 24), (86, 30), (54, 36)):
        sdraw.ellipse(
            (cx - radius, cy - radius, cx + radius, cy + radius),
            outline=(*GOLD, alpha),
            width=2,
        )
    for angle_deg in range(0, 360, 45):
        rad = math.radians(angle_deg)
        x1 = cx + int(math.cos(rad) * 58)
        y1 = cy + int(math.sin(rad) * 58)
        x2 = cx + int(math.cos(rad) * 92)
        y2 = cy + int(math.sin(rad) * 92)
        sdraw.line((x1, y1, x2, y2), fill=(*GOLD_DARK, 40), width=1)
    img = Image.alpha_composite(img.convert("RGBA"), seal.filter(ImageFilter.GaussianBlur(1))).convert("RGB")

    vignette = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    vdraw = ImageDraw.Draw(vignette)
    vdraw.rectangle((0, 0, w, 80), fill=(0, 0, 0, 70))
    vdraw.rectangle((0, h - 100, w, h), fill=(0, 0, 0, 90))
    for x in range(0, 48):
        a = int(55 * (1.0 - x / 48.0))
        vdraw.line((x, 0, x, h), fill=(0, 0, 0, a))
        vdraw.line((w - 1 - x, 0, w - 1 - x, h), fill=(0, 0, 0, a))
    img = Image.alpha_composite(img.convert("RGBA"), vignette).convert("RGB")

    random.seed(91)
    sparkle = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(sparkle)
    for _ in range(70):
        x, y = random.randint(0, w), random.randint(0, h)
        a = random.randint(10, 28)
        sdraw.ellipse((x, y, x + 2, y + 2), fill=(*GOLD, a))
    img = Image.alpha_composite(img.convert("RGBA"), sparkle).convert("RGB")
    return img


def draw_section_rule(w: int = 680, h: int = 24) -> Image.Image:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cy = h // 2
    draw.line((8, cy, w // 2 - 22, cy), fill=(*TEAL_GLOW, 200), width=2)
    draw.line((w // 2 + 22, cy, w - 8, cy), fill=(*TEAL_GLOW, 200), width=2)
    diamond = draw_diamond(20)
    img.paste(diamond, (w // 2 - 10, cy - 10), diamond)
    return img


def main() -> None:
    save(draw_background(), "UI_BG_Commander.png")
    save(draw_diamond(48), "UI_Ornament_Diamond.png")
    save(draw_section_rule(), "UI_CMD_SectionRule.png")
    save(draw_back_arrow(48), "UI_Ico_Back_Gold.png")
    save(draw_labeled_button("名前変更", 352, 128, font_size=26), "UI_CMD_Btn_Rename.png")
    save(draw_labeled_button("名前変更", 352, 128, enabled=False, font_size=26), "UI_CMD_Btn_Rename_Disabled.png")
    save(draw_labeled_button("すべて受け取る", 560, 144, primary=True, font_size=28), "UI_CMD_Btn_ClaimAll.png")
    save(draw_labeled_button("受け取る", 384, 160, primary=True, font_size=28), "UI_CMD_Btn_Claim.png")
    save(draw_labeled_button("鍛冶屋へ", 480, 160, font_size=28), "UI_CMD_Btn_Forge.png")
    save(draw_labeled_button("図鑑へ", 480, 160, font_size=28), "UI_CMD_Btn_Codex.png")
    save(draw_labeled_button("称号を外す", 480, 144, font_size=26), "UI_CMD_Btn_ClearTitle.png")
    save(draw_labeled_button("称号を外す", 480, 144, enabled=False, font_size=26), "UI_CMD_Btn_ClearTitle_Disabled.png")
    save(draw_labeled_button("受取", 240, 128, primary=True, font_size=26), "UI_CMD_Btn_DailyClaim.png")
    save(draw_labeled_button("済", 240, 128, enabled=False, font_size=26), "UI_CMD_Btn_DailyDone.png")
    save(draw_labeled_button("移動", 240, 128, enabled=False, font_size=26), "UI_CMD_Btn_DailyMove.png")


if __name__ == "__main__":
    main()
