#!/usr/bin/env python3
"""Generate result screen UI button assets for Crownfall.

Output: assets/ui/result/*.png

Usage:
  python3 tools/generate_result_ui_assets.py
"""
from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/ui/result"

GOLD = (235, 198, 72)
GOLD_DARK = (140, 110, 40)
GOLD_HI = (255, 230, 150)
GOLD_BORDER = (217, 184, 71)
GOLD_MUTED = (115, 97, 51)
BTN_PRIMARY = (107, 82, 20)
BTN_PRIMARY_DISABLED = (48, 42, 28)
BTN_SECONDARY = (20, 20, 31)
BTN_SECONDARY_DISABLED = (36, 36, 42)
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
        border = GOLD_BORDER if enabled else (90, 85, 80)
    else:
        fill = BTN_SECONDARY if enabled else BTN_SECONDARY_DISABLED
        border = GOLD_MUTED if enabled else (80, 78, 74)
    rounded_rect(draw, (0, 0, w - 1, h - 1), 10, (*fill, 255), (*border, 255), 2)
    if enabled:
        draw.line((10, 6, w - 10, 6), fill=(*GOLD_HI, 100 if primary else 45), width=2)


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
        gdraw.ellipse((w // 2 - 160, h - 36, w // 2 + 160, h + 24), fill=(*GOLD, 40))
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
) -> None:
    font = load_font(font_size)
    text_color = (250, 235, 200, 255) if enabled else (130, 125, 118, 255)
    outline = (24, 18, 8, 220) if enabled else (30, 28, 26, 200)
    bbox = draw.textbbox((0, 0), label, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    tx = (w - tw) // 2
    ty = (h - th) // 2 - 2
    for ox, oy in [(-2, 0), (2, 0), (0, -2), (0, 2)]:
        draw.text((tx + ox, ty + oy), label, font=font, fill=outline)
    draw.text((tx, ty), label, font=font, fill=text_color)


def draw_labeled_button(
    label: str,
    w: int = 960,
    h: int = 128,
    *,
    primary: bool,
    enabled: bool = True,
    font_size: int = 34,
) -> Image.Image:
    img = _button_canvas(w, h, enabled=enabled, primary=primary)
    draw = ImageDraw.Draw(img)
    _draw_text(draw, w, h, label, enabled=enabled, font_size=font_size)
    return img


def draw_frame_button(
    w: int = 960,
    h: int = 128,
    *,
    primary: bool = True,
    enabled: bool = True,
) -> Image.Image:
    return _button_canvas(w, h, enabled=enabled, primary=primary)


def main() -> int:
    save(draw_frame_button(primary=True), "UI_Result_Btn_Next.png")
    save(draw_frame_button(primary=True, enabled=False), "UI_Result_Btn_Next_Disabled.png")
    save(draw_labeled_button("再挑戦", primary=False), "UI_Result_Btn_Retry.png")
    save(draw_labeled_button("再挑戦", primary=False, enabled=False), "UI_Result_Btn_Retry_Disabled.png")
    save(draw_labeled_button("拠点へ", primary=True), "UI_Result_Btn_Home.png")
    save(draw_labeled_button("拠点へ", primary=True, enabled=False), "UI_Result_Btn_Home_Disabled.png")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
