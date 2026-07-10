#!/usr/bin/env python3
"""Generate Equipment screen UI chrome assets for Crownfall.

Output: assets/ui/equipment_ui/*.png

Usage:
  python3 tools/generate_equipment_ui_assets.py
"""
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/ui/equipment_ui"
ICON_CELL_BASE = OUT / "_ref/IconCell_Base.png"

GOLD = (235, 198, 72)
GOLD_DARK = (140, 110, 40)
BG_DARK = (22, 18, 14)
WARM = (55, 38, 28)
RARITY_BORDERS = {
    0: (140, 140, 140),
    1: (70, 120, 220),
    2: (170, 90, 220),
    3: (235, 198, 72),
}
# 暗い金属地色 + レアリティ色を控えめにティント（SSR はさらに弱め）。
CELL_BG_BASE = (28, 22, 16)
CELL_BG_ALPHA = 235
RARITY_BG_TINT = {0: 0.12, 1: 0.12, 2: 0.12, 3: 0.08}
INV_CELL_MARGINS = (12, 12, 12, 12)
_ICON_CELL_TEXTURE_CACHE: dict[int, Image.Image] = {}
# Owner art imported via tools/import_equipment_inv_cell_frames.py — do not overwrite.
HAND_DRAWN_INV_CELL_LABELS: set[str] = set()


def save(img: Image.Image, name: str) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / name
    if path.exists() and name.startswith("UI_Equip_InvCell_"):
        label = name.removeprefix("UI_Equip_InvCell_").removesuffix(".png")
        if label in HAND_DRAWN_INV_CELL_LABELS:
            print(f"skip hand-drawn {path.name}")
            return
    img.save(path, optimize=True)
    print(f"wrote {path} ({img.size[0]}x{img.size[1]})")


def rounded_rect(draw: ImageDraw.ImageDraw, box, radius: int, fill, outline=None, width: int = 1) -> None:
    draw.rounded_rectangle(box, radius=radius, fill=fill, outline=outline, width=width)


def draw_background(w: int = 720, h: int = 1280) -> Image.Image:
    img = Image.new("RGB", (w, h), BG_DARK)
    draw = ImageDraw.Draw(img)
    for y in range(h):
        t = y / h
        c = (
            int(22 + 18 * t),
            int(16 + 12 * t),
            int(12 + 8 * t),
        )
        draw.line((0, y, w, y), fill=c)
    random.seed(42)
    for _ in range(120):
        x, y = random.randint(0, w), random.randint(0, h)
        a = random.randint(8, 22)
        draw.ellipse((x, y, x + 2, y + 2), fill=(GOLD[0], GOLD[1], GOLD[2], a))
    glow = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(glow)
    gdraw.ellipse((w // 2 - 260, h // 3 - 80, w // 2 + 260, h // 3 + 220), fill=(90, 55, 25, 45))
    gdraw.ellipse((w // 2 - 200, h * 2 // 3, w // 2 + 200, h), fill=(40, 25, 15, 60))
    img = Image.alpha_composite(img.convert("RGBA"), glow.filter(ImageFilter.GaussianBlur(18))).convert("RGB")
    return img


def draw_diamond(size: int = 48) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx, cy = size // 2, size // 2
    r = size // 2 - 2
    pts = [(cx, cy - r), (cx + r, cy), (cx, cy + r), (cx - r, cy)]
    draw.polygon(pts, fill=(*GOLD, 230), outline=(*GOLD_DARK, 255))
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


def draw_stat_icon(kind: str, size: int = 72) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    rounded_rect(draw, (2, 2, size - 2, size - 2), 8, (28, 22, 16, 220), (*GOLD_DARK, 180), 1)
    cx, cy = size // 2, size // 2
    if kind == "hp":
        draw.polygon(
            [(cx, cy + 12), (cx - 14, cy - 2), (cx - 6, cy - 12), (cx, cy - 6), (cx + 6, cy - 12), (cx + 14, cy - 2)],
            fill=(200, 60, 70, 255),
        )
    elif kind == "atk":
        draw.polygon([(cx - 12, cy + 10), (cx + 12, cy + 10), (cx + 4, cy - 14), (cx - 4, cy - 14)], fill=(*GOLD, 255))
        draw.rectangle((cx - 4, cy - 20, cx + 4, cy - 10), fill=(210, 210, 220, 255))
    elif kind == "def":
        draw.polygon(
            [(cx, cy - 14), (cx + 14, cy - 4), (cx + 10, cy + 12), (cx - 10, cy + 12), (cx - 14, cy - 4)],
            fill=(110, 130, 170, 255),
            outline=(*GOLD, 255),
            width=2,
        )
    elif kind == "spd":
        for i in range(3):
            draw.polygon(
                [(cx - 10 + i * 8, cy + 8), (cx - 2 + i * 8, cy + 8), (cx + 2 + i * 8, cy - 10), (cx - 6 + i * 8, cy - 10)],
                fill=(120, 200, 220, 220 - i * 40),
            )
    elif kind == "crit":
        for i in range(4):
            ang = math.radians(45 + i * 90)
            draw.line(
                (cx + math.cos(ang) * 6, cy + math.sin(ang) * 6, cx + math.cos(ang) * 16, cy + math.sin(ang) * 16),
                fill=(255, 220, 80, 255),
                width=3,
            )
    elif kind == "critdmg":
        draw.ellipse((cx - 12, cy - 12, cx + 12, cy + 12), outline=(255, 120, 60, 255), width=3)
        draw.line((cx - 8, cy + 8, cx + 8, cy - 8), fill=(255, 180, 80, 255), width=3)
    return img


def draw_category_icon(kind: str, size: int = 96) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    rounded_rect(draw, (4, 4, size - 4, size - 4), 10, (22, 18, 14, 230), (*GOLD_DARK, 200), 2)
    cx, cy = size // 2, size // 2
    if kind == "all":
        draw.rectangle((cx - 14, cy - 14, cx + 14, cy + 14), outline=(*GOLD, 255), width=3)
        draw.line((cx - 14, cy, cx + 14, cy), fill=(*GOLD, 200), width=2)
        draw.line((cx, cy - 14, cx, cy + 14), fill=(*GOLD, 200), width=2)
    elif kind == "weapon":
        draw.polygon([(cx - 14, cy + 16), (cx + 14, cy + 16), (cx + 5, cy - 18), (cx - 5, cy - 18)], fill=(*GOLD, 255))
    elif kind == "armor":
        draw.polygon(
            [(cx, cy - 18), (cx + 18, cy - 4), (cx + 12, cy + 16), (cx - 12, cy + 16), (cx - 18, cy - 4)],
            fill=(100, 120, 160, 255),
            outline=(*GOLD, 255),
            width=2,
        )
    else:
        draw.ellipse((cx - 14, cy - 14, cx + 14, cy + 14), outline=(*GOLD, 255), width=3)
        draw.ellipse((cx - 6, cy - 6, cx + 6, cy + 6), fill=(180, 120, 220, 255))
    return img


def draw_filter_icon(size: int = 48) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.polygon([(8, 10), (40, 10), (28, 24), (28, 36), (20, 40), (20, 24)], outline=(*GOLD, 255), width=2)
    return img


def draw_char_card(w: int = 704, h: int = 440) -> Image.Image:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    rounded_rect(draw, (0, 0, w - 1, h - 1), 14, (18, 14, 10, 235), (*GOLD_DARK, 220), 3)
    draw.line((16, 12, w - 16, 12), fill=(255, 220, 140, 80), width=1)
    return img


def draw_pedestal(w: int = 200, h: int = 180) -> Image.Image:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    cx = w // 2
    draw.ellipse((cx - 70, h - 50, cx + 70, h - 10), fill=(40, 34, 28, 220), outline=(*GOLD_DARK, 180), width=2)
    draw.polygon([(cx - 50, h - 30), (cx + 50, h - 30), (cx + 36, h - 70), (cx - 36, h - 70)], fill=(55, 48, 40, 230))
    draw.ellipse((cx - 36, h - 78, cx + 36, h - 42), fill=(70, 60, 50, 200), outline=(*GOLD_DARK, 140), width=1)
    return img


def draw_tab(active: bool, w: int = 168, h: int = 72) -> Image.Image:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    if active:
        rounded_rect(draw, (2, 2, w - 2, h - 4), 10, (42, 34, 22, 245), (*GOLD, 255), 2)
        draw.rectangle((6, h - 8, w - 6, h - 2), fill=(*GOLD, 255))
    else:
        rounded_rect(draw, (2, 2, w - 2, h - 2), 10, (16, 13, 10, 210), (70, 60, 48, 180), 1)
    return img


def draw_slot_frame(locked: bool = False, size: int = 128) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    if locked:
        rounded_rect(draw, (2, 2, size - 2, size - 2), 10, (12, 10, 8, 220), (60, 55, 48, 160), 2)
        draw.line((size * 0.3, size * 0.3, size * 0.7, size * 0.7), fill=(90, 85, 78, 200), width=3)
        draw.line((size * 0.7, size * 0.3, size * 0.3, size * 0.7), fill=(90, 85, 78, 200), width=3)
    else:
        rounded_rect(draw, (2, 2, size - 2, size - 2), 10, (14, 11, 8, 230), (*GOLD_DARK, 200), 2)
    return img


def _blend_rgb(base: tuple[int, int, int], tint: tuple[int, int, int], ratio: float) -> tuple[int, int, int]:
    return tuple(int(round(base[i] + (tint[i] - base[i]) * ratio)) for i in range(3))


def _rounded_alpha_mask(size: int, pad: int = 2, radius: int = 12) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((pad, pad, size - pad - 1, size - pad - 1), radius=radius, fill=255)
    return mask


def _prepare_stone_texture(size: int) -> Image.Image:
    if size in _ICON_CELL_TEXTURE_CACHE:
        return _ICON_CELL_TEXTURE_CACHE[size].copy()
    if not ICON_CELL_BASE.exists():
        raise FileNotFoundError(f"Missing icon cell base art: {ICON_CELL_BASE}")

    src = Image.open(ICON_CELL_BASE).convert("RGBA")
    sw, sh = src.size
    inset = int(min(sw, sh) * 0.12)
    cropped = src.crop((inset, inset, sw - inset, sh - inset))
    tex = cropped.resize((size, size), Image.Resampling.LANCZOS)

    # 中央紋様を薄めて装備アイコンとの干渉を抑える。
    emblem_mask = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    edraw = ImageDraw.Draw(emblem_mask)
    cx, cy = size // 2, size // 2
    emblem_r = int(size * 0.36)
    edraw.ellipse((cx - emblem_r, cy - emblem_r, cx + emblem_r, cy + emblem_r), fill=(6, 4, 3, 118))
    tex = Image.alpha_composite(tex, emblem_mask.filter(ImageFilter.GaussianBlur(5)))

    tone = Image.new("RGBA", (size, size), (12, 9, 7, 42))
    tex = Image.alpha_composite(tex, tone)

    _ICON_CELL_TEXTURE_CACHE[size] = tex
    return tex.copy()


def draw_inv_cell(rarity: int, size: int = 144) -> Image.Image:
    border = RARITY_BORDERS.get(rarity, RARITY_BORDERS[0])
    tint_ratio = RARITY_BG_TINT.get(rarity, 0.12)
    pad = 2
    box = (pad, pad, size - pad - 1, size - pad - 1)
    mask = _rounded_alpha_mask(size, pad, 12)

    tex = _prepare_stone_texture(size)
    body = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    body.paste(tex, (0, 0), mask)

    tint_rgb = _blend_rgb(CELL_BG_BASE, border, tint_ratio)
    tint_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    tdraw = ImageDraw.Draw(tint_layer)
    tdraw.rounded_rectangle(box, radius=12, fill=(*tint_rgb, int(CELL_BG_ALPHA * 0.28)))
    img = Image.alpha_composite(body, tint_layer)

    draw = ImageDraw.Draw(img)
    rounded_rect(draw, box, 12, fill=None, outline=(*border, 255), width=3)

    shade = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    shdraw = ImageDraw.Draw(shade)
    shdraw.rounded_rectangle((pad + 2, size // 2, size - pad - 3, size - pad - 3), 9, fill=(0, 0, 0, 24))
    img = Image.alpha_composite(img, shade.filter(ImageFilter.GaussianBlur(2)))

    out = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out


def draw_button(w: int = 480, h: int = 96, disabled: bool = False) -> Image.Image:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    if disabled:
        rounded_rect(draw, (0, 0, w - 1, h - 1), 10, (20, 18, 16, 200), (70, 65, 58, 140), 1)
    else:
        rounded_rect(draw, (0, 0, w - 1, h - 1), 10, (48, 36, 14, 245), (*GOLD, 255), 2)
    return img


def draw_section_rule(w: int = 680, h: int = 24) -> Image.Image:
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.line((0, h // 2, w, h // 2), fill=(*GOLD_DARK, 180), width=1)
    cx = w // 2
    draw.polygon([(cx, 4), (cx + 6, h // 2), (cx, h - 4), (cx - 6, h // 2)], fill=(*GOLD, 220))
    return img


def main() -> int:
    wip = OUT / "_wip"
    for label in ("N", "R", "SR", "SSR"):
        if (wip / f"UI_Equip_InvCell_{label}.png").exists():
            HAND_DRAWN_INV_CELL_LABELS.add(label)
    save(draw_background(), "UI_BG_Equipment.png")
    save(draw_diamond(48), "UI_Ornament_Diamond.png")
    save(draw_back_arrow(48), "UI_Ico_Back_Gold.png")
    save(draw_char_card(), "UI_Equip_CharCard.png")
    save(draw_pedestal(), "UI_Equip_PortraitPedestal.png")
    save(draw_tab(True), "UI_Equip_Tab_Active.png")
    save(draw_tab(False), "UI_Equip_Tab_Inactive.png")
    save(draw_slot_frame(False), "UI_Equip_Slot_Frame.png")
    save(draw_slot_frame(True), "UI_Equip_Slot_Locked.png")
    save(draw_button(disabled=False), "UI_Equip_Btn_Unequip.png")
    save(draw_button(disabled=True), "UI_Equip_Btn_StatDetail_Disabled.png")
    save(draw_filter_icon(), "ICO_Equip_Filter.png")
    save(draw_section_rule(), "UI_Equip_SectionRule.png")
    for kind in ("hp", "atk", "def", "spd", "crit", "critdmg"):
        save(draw_stat_icon(kind), f"ICO_Equip_Stat_{kind.upper()}.png")
    # Category tab icons are owner art — run tools/preprocess_category_icons.py --apply
    save(draw_category_icon("all"), "ICO_Equip_Cat_All.png")
    for r, label in enumerate(["N", "R", "SR", "SSR"]):
        save(draw_inv_cell(r), f"UI_Equip_InvCell_{label}.png")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
