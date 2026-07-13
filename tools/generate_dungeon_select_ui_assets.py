#!/usr/bin/env python3
"""Generate dungeon select UI button assets for Crownfall.

Output: assets/ui/dungeon_select/*.png

Usage:
  python3 tools/generate_dungeon_select_ui_assets.py
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/ui/dungeon_select"

GOLD = (235, 198, 72)
GOLD_DARK = (140, 110, 40)
GOLD_HI = (255, 230, 150)
TEAL = (90, 170, 165)
TEAL_DARK = (45, 95, 110)
GOLD_MUTED = (110, 98, 78)
BTN_PRIMARY = (20, 42, 52)
BTN_PRIMARY_DISABLED = (36, 38, 42)
BTN_SECONDARY = (28, 30, 38)
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


def _draw_frame(
    draw: ImageDraw.ImageDraw,
    w: int,
    h: int,
    *,
    enabled: bool,
    primary: bool,
) -> None:
    if primary:
        fill = BTN_PRIMARY if enabled else BTN_PRIMARY_DISABLED
        border = TEAL if enabled else (90, 85, 80)
    else:
        fill = BTN_SECONDARY if enabled else BTN_PRIMARY_DISABLED
        border = GOLD_MUTED if enabled else (80, 78, 74)
    rounded_rect(draw, (0, 0, w - 1, h - 1), 12, (*fill, 255), (*border, 255), 3)
    if enabled:
        draw.line((10, 6, w - 10, 6), fill=(*GOLD_HI, 90 if primary else 50), width=2)


def _button_canvas(
    w: int,
    h: int,
    *,
    enabled: bool = True,
    primary: bool = True,
) -> Image.Image:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    _draw_frame(draw, w, h, enabled=enabled, primary=primary)
    if enabled and primary:
        glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        gdraw = ImageDraw.Draw(glow)
        gdraw.ellipse((w // 2 - 160, h - 36, w // 2 + 160, h + 24), fill=(*TEAL, 50))
        img = Image.alpha_composite(img, glow.filter(ImageFilter.GaussianBlur(6)))
        draw = ImageDraw.Draw(img)
        _draw_frame(draw, w, h, enabled=enabled, primary=primary)
    return img


def _draw_text(
    draw: ImageDraw.ImageDraw,
    w: int,
    h: int,
    label: str,
    *,
    enabled: bool,
    font_size: int,
    shift_x: int = 0,
) -> None:
    font = load_font(font_size)
    text_color = (235, 248, 245, 255) if enabled else (130, 125, 118, 255)
    outline = (10, 20, 24, 220) if enabled else (30, 28, 26, 200)
    bbox = draw.textbbox((0, 0), label, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    tx = (w - tw) // 2 + shift_x
    ty = (h - th) // 2 - 2
    for ox, oy in [(-2, 0), (2, 0), (0, -2), (0, 2)]:
        draw.text((tx + ox, ty + oy), label, font=font, fill=outline)
    draw.text((tx, ty), label, font=font, fill=text_color)


def _draw_depart_motif(draw: ImageDraw.ImageDraw, h: int, *, enabled: bool) -> None:
    col = TEAL if enabled else (100, 98, 94)
    gold = GOLD if enabled else (110, 105, 98)
    cx, cy = 42, h // 2
    draw.polygon([(cx - 14, cy - 16), (cx + 6, cy - 16), (cx + 6, cy - 24), (cx + 20, cy - 8),
                  (cx + 6, cy + 8), (cx + 6, cy), (cx - 14, cy)], fill=col)
    draw.arc((cx - 20, cy - 6, cx + 24, cy + 22), 200, 340, fill=gold, width=2)


def draw_depart_button(w: int = 960, h: int = 128, *, enabled: bool = True) -> Image.Image:
    img = _button_canvas(w, h, enabled=enabled, primary=True)
    draw = ImageDraw.Draw(img)
    if enabled:
        _draw_depart_motif(draw, h, enabled=True)
    _draw_text(draw, w, h, "選択して出発", enabled=enabled, font_size=34, shift_x=16)
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


def draw_select_button(label: str, w: int = 352, h: int = 160, *, enabled: bool = True) -> Image.Image:
    img = _button_canvas(w, h, enabled=enabled, primary=enabled)
    draw = ImageDraw.Draw(img)
    _draw_text(draw, w, h, label, enabled=enabled, font_size=30)
    return img


def draw_confirm_button(label: str, w: int = 400, h: int = 112, *, yes: bool, enabled: bool = True) -> Image.Image:
    img = _button_canvas(w, h, enabled=enabled, primary=yes)
    draw = ImageDraw.Draw(img)
    if yes and enabled:
        cx, cy = 52, h // 2
        draw.polygon([(cx - 8, cy), (cx - 2, cy + 8), (cx + 12, cy - 10)], fill=(*TEAL, 255))
    _draw_text(draw, w, h, label, enabled=enabled, font_size=36, shift_x=8 if yes else 0)
    return img


def main() -> int:
    save(draw_back_arrow(48), "UI_Ico_Back_Gold.png")
    save(draw_depart_button(), "UI_DG_Btn_Depart.png")
    save(draw_depart_button(enabled=False), "UI_DG_Btn_Depart_Disabled.png")
    save(draw_select_button("選択"), "UI_DG_Btn_Select.png")
    save(draw_select_button("ロック中", enabled=False), "UI_DG_Btn_Select_Disabled.png")
    save(draw_confirm_button("はい", yes=True), "UI_DG_Btn_ConfirmYes.png")
    save(draw_confirm_button("はい", yes=True, enabled=False), "UI_DG_Btn_ConfirmYes_Disabled.png")
    save(draw_confirm_button("いいえ", yes=False), "UI_DG_Btn_ConfirmNo.png")
    save(draw_confirm_button("いいえ", yes=False, enabled=False), "UI_DG_Btn_ConfirmNo_Disabled.png")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
