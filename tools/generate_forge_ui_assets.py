#!/usr/bin/env python3
"""Generate Blacksmith (forge) UI chrome assets for Crownfall.

Mock-aligned: dark cell frames with gold trim, ember glow on selection,
white silhouette stat icons.

Output: assets/ui/forge/*.png

Usage:
  python3 tools/generate_forge_ui_assets.py
"""
from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/ui/forge"

GOLD = (235, 198, 72)
GOLD_DARK = (140, 110, 40)
GOLD_MUTED = (110, 98, 78)
BG_DARK = (18, 14, 10)
CELL_BG = (32, 24, 18, 235)
EMBER = (255, 165, 55)
EMBER_GLOW = (255, 140, 40, 90)
WHITE = (245, 242, 235, 255)
GOLD_HI = (255, 230, 150)
BTN_BG = (14, 18, 28)  # blue-black metal (legacy flat fallback)
BTN_BG_DISABLED = (18, 18, 22)
BTN_W, BTN_H = 600, 100
BTN_RADIUS = 12
BTN_ACCENTS = {
    "produce": (90, 160, 220),
    "enhance": (120, 180, 255),
    "dismantle": (200, 110, 70),
    "bulk": (160, 140, 90),
}
FONT_PATHS = [
    ROOT / "assets/fonts/ShipporiMinchoB1-Bold.ttf",
    ROOT / "assets/fonts/NotoSansJP-VariableFont_wght.ttf",
    Path("/System/Library/Fonts/Hiragino Sans GB.ttc"),
]


def load_font(size: int) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for path in FONT_PATHS:
        if path.exists():
            try:
                return ImageFont.truetype(str(path), size)
            except OSError:
                continue
    return ImageFont.load_default()


RARITY_BORDERS = {
    0: (150, 145, 138),   # N
    1: (75, 130, 215),    # R
    2: (175, 95, 220),    # SR
    3: (235, 198, 72),    # SSR
}


def save(img: Image.Image, name: str) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / name
    img.save(path, optimize=True)
    print(f"wrote {path} ({img.size[0]}x{img.size[1]})")


def rounded_rect(draw: ImageDraw.ImageDraw, box, radius: int, fill, outline=None, width: int = 1) -> None:
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def _cell_frame(
    size: int,
    border: tuple[int, int, int],
    *,
    selected: bool = False,
    border_w: int = 2,
    bg: tuple[int, int, int, int] = CELL_BG,
) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    pad = 2
    box = (pad, pad, size - pad - 1, size - pad - 1)
    rounded_rect(draw, box, 12, bg, (*border, 255), border_w)

    if selected:
        glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        gdraw = ImageDraw.Draw(glow)
        gdraw.rounded_rectangle((1, 1, size - 2, size - 2), 13, outline=(*EMBER, 200), width=3)
        gdraw.rounded_rectangle((4, 4, size - 5, size - 5), 11, outline=(*GOLD, 180), width=1)
        img = Image.alpha_composite(img, glow.filter(ImageFilter.GaussianBlur(2)))

        hot = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        hdraw = ImageDraw.Draw(hot)
        hdraw.rounded_rectangle((0, 0, size - 1, size - 1), 14, fill=(255, 160, 50, 35))
        img = Image.alpha_composite(img, hot.filter(ImageFilter.GaussianBlur(5)))
    return img


def draw_item_cell_normal(size: int = 128) -> Image.Image:
    return _cell_frame(size, GOLD_MUTED, border_w=2)


def draw_item_cell_selected(size: int = 128) -> Image.Image:
    return _cell_frame(size, EMBER, selected=True, border_w=3)


def draw_item_cell_rarity(rarity: int, size: int = 128) -> Image.Image:
    border = RARITY_BORDERS.get(rarity, RARITY_BORDERS[0])
    return _cell_frame(size, border, border_w=3)


def draw_list_card_normal(w: int = 720, h: int = 168) -> Image.Image:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    rounded_rect(draw, (0, 0, w - 1, h - 1), 10, (24, 18, 13, 230), (*GOLD_MUTED, 200), 2)
    draw.line((12, 10, w - 12, 10), fill=(255, 220, 140, 30), width=1)
    return img


def draw_list_card_selected(w: int = 720, h: int = 168) -> Image.Image:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    rounded_rect(draw, (0, 0, w - 1, h - 1), 10, (38, 28, 16, 245), (*EMBER, 255), 3)
    rounded_rect(draw, (3, 3, w - 4, h - 4), 9, (0, 0, 0, 0), (*GOLD, 160), 1)
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(glow).rounded_rectangle((2, 2, w - 3, h - 3), 10, fill=(*EMBER_GLOW,))
    return Image.alpha_composite(glow.filter(ImageFilter.GaussianBlur(8)), img)


def draw_craft_chip(selected: bool, size: int = 112) -> Image.Image:
    if selected:
        return draw_item_cell_selected(size)
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    rounded_rect(draw, (2, 2, size - 3, size - 3), 10, (20, 28, 18, 235), (90, 170, 95, 200), 2)
    return img


def draw_material_cell(size: int = 96) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    rounded_rect(draw, (1, 1, size - 2, size - 2), 8, (20, 16, 12, 230), (*GOLD_MUTED, 220), 2)
    return img


def draw_stat_icon(kind: str, size: int = 64) -> Image.Image:
    """White silhouette pictograms (mock style), transparent background."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    if kind == "atk":
        # four-point star
        pts = []
        for i in range(8):
            ang = math.radians(-90 + i * 45)
            r = 22 if i % 2 == 0 else 9
            pts.append((cx + math.cos(ang) * r, cy + math.sin(ang) * r))
        draw.polygon(pts, fill=WHITE)
    elif kind == "def":
        draw.polygon(
            [(cx, cy - 20), (cx + 20, cy - 6), (cx + 13, cy + 18), (cx - 13, cy + 18), (cx - 20, cy - 6)],
            fill=WHITE,
            outline=(220, 215, 205, 255),
            width=2,
        )
        draw.polygon(
            [(cx, cy - 12), (cx + 10, cy - 2), (cx + 6, cy + 10), (cx - 6, cy + 10), (cx - 10, cy - 2)],
            fill=(32, 24, 18, 180),
        )
    elif kind == "crit":
        # crossed blades
        draw.polygon(
            [(cx - 18, cy + 14), (cx - 6, cy + 14), (cx + 2, cy - 18), (cx - 8, cy - 18)],
            fill=WHITE,
        )
        draw.polygon(
            [(cx + 18, cy + 14), (cx + 6, cy + 14), (cx - 2, cy - 18), (cx + 8, cy - 18)],
            fill=WHITE,
        )
        draw.rectangle((cx - 3, cy - 6, cx + 3, cy + 10), fill=WHITE)
    elif kind == "hp":
        draw.polygon(
            [
                (cx, cy + 16),
                (cx - 18, cy - 2),
                (cx - 8, cy - 16),
                (cx, cy - 6),
                (cx + 8, cy - 16),
                (cx + 18, cy - 2),
            ],
            fill=WHITE,
            outline=(220, 215, 205, 255),
            width=2,
        )
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


def draw_category_icon(kind: str, size: int = 144) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    rounded_rect(draw, (6, 6, size - 6, size - 6), 14, (22, 18, 14, 240), (*GOLD_DARK, 220), 2)
    cx, cy = size // 2, size // 2
    if kind == "weapon":
        draw.polygon(
            [(cx - 22, cy + 24), (cx + 22, cy + 24), (cx + 8, cy - 28), (cx - 8, cy - 28)],
            fill=(*GOLD, 255),
        )
        draw.rectangle((cx - 7, cy - 38, cx + 7, cy - 20), fill=(210, 210, 220, 255))
    elif kind == "armor":
        draw.polygon(
            [(cx, cy - 30), (cx + 28, cy - 8), (cx + 18, cy + 28), (cx - 18, cy + 28), (cx - 28, cy - 8)],
            fill=(100, 120, 160, 255),
            outline=(*GOLD, 255),
            width=3,
        )
    else:
        draw.ellipse((cx - 24, cy - 24, cx + 24, cy + 24), outline=(*GOLD, 255), width=4)
        draw.ellipse((cx - 10, cy - 10, cx + 10, cy + 10), fill=(180, 120, 220, 255))
    return img


def draw_anvil_panel(w: int = 1280, h: int = 400) -> Image.Image:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    rounded_rect(draw, (0, 0, w - 1, h - 1), 16, (16, 12, 10, 235), (*GOLD_DARK, 180), 2)
    ax = w // 2
    ay = h // 2 + 20
    draw.polygon(
        [(ax - 180, ay + 40), (ax + 180, ay + 40), (ax + 120, ay - 20), (ax - 120, ay - 20)],
        fill=(40, 38, 42, 200),
    )
    draw.rectangle((ax - 60, ay - 50, ax + 60, ay - 20), fill=(55, 52, 58, 220))
    draw.ellipse((ax - 200, ay + 30, ax + 200, ay + 90), fill=(30, 28, 32, 180))
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(glow)
    gdraw.ellipse((w // 2 - 220, h - 120, w // 2 + 220, h + 40), fill=(220, 90, 20, 70))
    img = Image.alpha_composite(img, glow.filter(ImageFilter.GaussianBlur(8)))
    return img


def draw_hero_glow(size: int = 800) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    for radius, alpha in ((280, 35), (200, 55), (120, 80)):
        draw.ellipse(
            (cx - radius, cy - radius, cx + radius, cy + radius),
            fill=(255, 170, 60, alpha),
        )
    return img.filter(ImageFilter.GaussianBlur(12))


def draw_tab_active(w: int = 440, h: int = 176) -> Image.Image:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    rounded_rect(draw, (4, 4, w - 4, h - 8), 12, (36, 28, 16, 245), (*GOLD, 255), 3)
    draw.rectangle((8, h - 12, w - 8, h - 4), fill=(*GOLD, 255))
    return img


def draw_produce_button(w: int = BTN_W, h: int = BTN_H) -> Image.Image:
    return draw_forge_cta_button("produce", w=w, h=h, enabled=True)


def _lerp_rgb(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))  # type: ignore[return-value]


def _metallic_button_fill(w: int, h: int, accent: tuple[int, int, int], *, enabled: bool) -> Image.Image:
    """Vertical blue-black metal plate with soft highlight band. No baked text."""
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    if enabled:
        top, mid, bot, hi_band = (28, 36, 48), (14, 18, 28), (8, 10, 16), (48, 62, 82)
    else:
        top, mid, bot, hi_band = (28, 28, 32), (18, 18, 22), (12, 12, 14), (36, 36, 40)
        accent = tuple(int(c * 0.45) for c in accent)  # type: ignore[assignment]
    for y in range(h):
        t = y / max(1, h - 1)
        if t < 0.35:
            c = _lerp_rgb(top, hi_band, t / 0.35)
        elif t < 0.55:
            c = _lerp_rgb(hi_band, mid, (t - 0.35) / 0.20)
        else:
            c = _lerp_rgb(mid, bot, (t - 0.55) / 0.45)
        brush = int(3 * math.sin(y * 0.55))
        row = (max(0, c[0] + brush), max(0, c[1] + brush), max(0, c[2] + brush + 2))
        for x in range(w):
            lx = x / max(1, w - 1)
            wash = max(0.0, 1.0 - lx * 4.5) * (0.12 if enabled else 0.05)
            r = min(255, int(row[0] + accent[0] * wash))
            g = min(255, int(row[1] + accent[1] * wash))
            b = min(255, int(row[2] + accent[2] * wash))
            sheen = math.exp(-((lx - 0.52) ** 2) / 0.08) * (0.10 if enabled else 0.04)
            r = min(255, int(r + 40 * sheen))
            g = min(255, int(g + 50 * sheen))
            b = min(255, int(b + 70 * sheen))
            px[x, y] = (r, g, b, 255)
    return img


def _rounded_mask(w: int, h: int, radius: int) -> Image.Image:
    m = Image.new("L", (w, h), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, w - 1, h - 1), radius=radius, fill=255)
    return m


def _subtle_left_motif(
    draw: ImageDraw.ImageDraw,
    h: int,
    accent: tuple[int, int, int],
    *,
    enabled: bool,
    motif: str,
) -> None:
    """Faint left ornament — keep empty-ish for Godot label/icon overlay."""
    a = 55 if enabled else 28
    col = (*accent, a)
    col2 = (200, 210, 220, a) if enabled else (120, 120, 125, a)
    cx, cy = 36, h // 2
    if motif == "produce":
        draw.polygon([(cx - 10, cy + 6), (cx + 10, cy + 6), (cx + 7, cy - 1), (cx - 7, cy - 1)], fill=col)
        draw.rectangle((cx - 4, cy - 8, cx + 4, cy - 1), fill=col)
        draw.ellipse((cx - 12, cy + 4, cx + 12, cy + 11), outline=col, width=1)
    elif motif == "enhance":
        draw.polygon([(cx - 6, cy + 8), (cx, cy - 10), (cx + 6, cy + 8)], outline=col2, width=1)
        draw.line((cx, cy - 2, cx, cy + 8), fill=col, width=1)
    elif motif == "dismantle":
        draw.line((cx - 10, cy + 8, cx + 10, cy - 8), fill=col, width=1)
        draw.line((cx - 8, cy - 6, cx + 6, cy + 6), fill=(*accent, max(20, a - 15)), width=1)
    elif motif == "bulk":
        for dx in (-8, 0, 8):
            draw.rectangle((cx - 4 + dx, cy - 6, cx + 4 + dx, cy + 6), outline=col, width=1)


def draw_forge_cta_button(
    motif: str = "produce",
    w: int = BTN_W,
    h: int = BTN_H,
    *,
    enabled: bool = True,
) -> Image.Image:
    """Mock-like blue-black metallic CTA with gold border. No baked text."""
    accent = BTN_ACCENTS.get(motif, BTN_ACCENTS["produce"])
    base = _metallic_button_fill(w, h, accent, enabled=enabled)
    mask = _rounded_mask(w, h, BTN_RADIUS)
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    img.paste(base, (0, 0))
    img.putalpha(mask)

    overlay = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    inset = 4
    if enabled:
        od.rounded_rectangle(
            (inset, inset, w - 1 - inset, h - 1 - inset),
            radius=BTN_RADIUS - 3,
            outline=(accent[0], accent[1], accent[2], 50),
            width=1,
        )
        od.line((14, 7, w - 14, 7), fill=(*GOLD_HI, 90), width=1)
        od.line((16, h - 9, w - 16, h - 9), fill=(20, 24, 32, 140), width=1)
    else:
        od.rounded_rectangle(
            (inset, inset, w - 1 - inset, h - 1 - inset),
            radius=BTN_RADIUS - 3,
            outline=(70, 70, 75, 60),
            width=1,
        )

    border = GOLD if enabled else (95, 90, 82)
    border2 = (180, 150, 55) if enabled else (70, 66, 60)
    od.rounded_rectangle((0, 0, w - 1, h - 1), radius=BTN_RADIUS, outline=(*border, 255), width=3)
    od.rounded_rectangle(
        (2, 2, w - 3, h - 3),
        radius=BTN_RADIUS - 2,
        outline=(*border2, 180 if enabled else 100),
        width=1,
    )
    tick = (*GOLD, 200 if enabled else 80)
    for x0 in (10, w - 18):
        for y0 in (8, h - 16):
            od.rectangle((x0, y0 + 3, x0 + 6, y0 + 4), fill=tick)

    _subtle_left_motif(od, h, accent, enabled=enabled, motif=motif)

    if enabled:
        glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        gd = ImageDraw.Draw(glow)
        if motif in ("produce", "enhance"):
            gd.ellipse((w // 2 - 140, h - 28, w // 2 + 140, h + 24), fill=(*accent, 40))
        else:
            gd.ellipse((w // 2 - 140, h - 28, w // 2 + 140, h + 24), fill=(255, 140, 60, 35))
        glow = glow.filter(ImageFilter.GaussianBlur(8))
        img = Image.alpha_composite(img, glow)
        a = img.split()[3]
        a = Image.composite(a, Image.new("L", (w, h), 0), mask)
        img.putalpha(a)

    img = Image.alpha_composite(img, overlay)
    a = img.split()[3]
    a = Image.composite(a, Image.new("L", (w, h), 0), mask)
    img.putalpha(a)
    return img


def draw_primary_button_frame(w: int = BTN_W, h: int = BTN_H, *, enabled: bool = True) -> Image.Image:
    return draw_forge_cta_button("enhance", w=w, h=h, enabled=enabled)


def _draw_button_text(
    draw: ImageDraw.ImageDraw,
    w: int,
    h: int,
    label: str,
    *,
    enabled: bool,
    text_shift_x: int = 0,
    font_size: int | None = None,
) -> None:
    """Optional debug label — production assets use Godot text overlay (no bake)."""
    size = font_size if font_size is not None else (28 if len(label) <= 7 else 24)
    font = load_font(size)
    text_color = (255, 244, 210, 255) if enabled else (130, 125, 118, 255)
    outline = (20, 14, 8, 220) if enabled else (30, 28, 26, 200)
    bbox = draw.textbbox((0, 0), label, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    tx = (w - tw) // 2 + text_shift_x
    ty = (h - th) // 2 - 2
    for ox, oy in [(-2, 0), (2, 0), (0, -2), (0, 2), (-1, -1), (1, 1)]:
        draw.text((tx + ox, ty + oy), label, font=font, fill=outline)
    draw.text((tx, ty), label, font=font, fill=text_color)


def draw_motif_primary_button(
    motif: str,
    w: int = BTN_W,
    h: int = BTN_H,
    *,
    enabled: bool = True,
) -> Image.Image:
    """Frame + faint motif only. Label text is drawn by Godot."""
    return draw_forge_cta_button(motif, w=w, h=h, enabled=enabled)


def draw_labeled_primary_button(
    label: str,
    motif: str,
    w: int = BTN_W,
    h: int = BTN_H,
    *,
    enabled: bool = True,
    font_size: int | None = None,
) -> Image.Image:
    img = draw_motif_primary_button(motif, w, h, enabled=enabled)
    draw = ImageDraw.Draw(img)
    _draw_button_text(
        draw, w, h, label, enabled=enabled, text_shift_x=14,
        font_size=font_size if font_size is not None else (26 if len(label) > 8 else 28),
    )
    return img


def main() -> int:
    save(draw_diamond(48), "UI_Ornament_Diamond.png")
    save(draw_back_arrow(48), "UI_Ico_Back_Gold.png")

    for kind in ("atk", "def", "crit", "hp"):
        save(draw_stat_icon(kind, 64), f"ICO_Forge_Stat_{kind.upper()}.png")

    # Category tab icons are owner art — run tools/preprocess_category_icons.py --apply

    save(draw_item_cell_normal(128), "UI_Forge_ItemCell_Normal.png")
    save(draw_item_cell_selected(128), "UI_Forge_ItemCell_Selected.png")
    for rarity, suffix in enumerate(["N", "R", "SR", "SSR"]):
        save(draw_item_cell_rarity(rarity, 128), f"UI_Forge_ItemCell_{suffix}.png")

    save(draw_list_card_normal(), "UI_Forge_ListCard_Normal.png")
    save(draw_list_card_selected(), "UI_Forge_ListCard_Selected.png")
    save(draw_craft_chip(False), "UI_Forge_CraftChip_Normal.png")
    save(draw_craft_chip(True), "UI_Forge_CraftChip_Selected.png")
    save(draw_material_cell(), "UI_Forge_MaterialCell.png")

    save(draw_anvil_panel(1280, 400), "UI_Forge_AnvilPanel.png")
    save(draw_hero_glow(800), "UI_Forge_HeroGlow.png")
    save(draw_tab_active(440, 176), "UI_Forge_Tab_Active.png")
    # Primary CTAs @ 600x100: blue-black metal + gold border; Godot overlays labels.
    save(draw_motif_primary_button("produce"), "UI_Forge_Btn_Produce.png")
    save(draw_motif_primary_button("produce", enabled=False), "UI_Forge_Btn_Produce_Disabled.png")
    save(draw_motif_primary_button("dismantle"), "UI_Forge_Btn_Dismantle.png")
    save(draw_motif_primary_button("dismantle", enabled=False), "UI_Forge_Btn_Dismantle_Disabled.png")
    save(draw_motif_primary_button("bulk"), "UI_Forge_Btn_BulkDismantle.png")
    save(draw_motif_primary_button("bulk", enabled=False), "UI_Forge_Btn_BulkDismantle_Disabled.png")
    save(draw_primary_button_frame(), "UI_Forge_Btn_Enhance.png")
    save(draw_primary_button_frame(enabled=False), "UI_Forge_Btn_Enhance_Disabled.png")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
