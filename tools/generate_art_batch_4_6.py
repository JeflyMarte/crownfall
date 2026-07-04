#!/usr/bin/env python3
"""Generate ui: menu icons, skill MVP icons, and per-dungeon floor tiles."""
from __future__ import annotations

import colorsys
import json
import re
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance, ImageFont

ROOT = Path(__file__).resolve().parents[1]
MENU_OUT = ROOT / "assets/ui/menu"
SKILL_OUT = ROOT / "assets/ui/skills"
MG_FLOOR = ROOT / "assets/dungeon/mourngate/env/TILE_Graveyard_Floor_01.png"

RARITY_BG = [
    ((38, 38, 42), (153, 153, 153)),
    ((18, 28, 52), (77, 140, 242)),
    ((34, 20, 58), (179, 115, 242)),
    ((52, 40, 12), (242, 191, 64)),
]

DUNGEON_HUES = [
    ("mourngate", None),
    ("astoria_ruins", 0.08),
    ("whisperwood", 0.30),
    ("green_hollow", 0.33),
    ("mistfen", 0.42),
    ("broken_marsh", 0.06),
    ("blackshore", 0.54),
    ("westbay_flats", 0.11),
    ("frostridge", 0.58),
    ("frostwall_path", 0.56),
]

UI_SPECS: list[tuple[str, str, tuple[int, int, int]]] = [
    ("ICO_UI_Hero.png", "英", (220, 180, 90)),
    ("ICO_UI_Blacksmith.png", "鍛", (200, 120, 60)),
    ("ICO_UI_Roster.png", "編", (140, 200, 140)),
    ("ICO_UI_Merchant.png", "商", (220, 200, 80)),
    ("ICO_UI_Legacy.png", "遺", (180, 150, 220)),
    ("ICO_UI_Menu.png", "≡", (200, 200, 200)),
    ("ICO_UI_Dungeon.png", "城", (160, 160, 180)),
    ("ICO_UI_Arena.png", "闘", (220, 100, 80)),
    ("ICO_UI_Guild.png", "公", (100, 160, 220)),
    ("ICO_UI_Missions.png", "任", (120, 200, 160)),
    ("ICO_UI_Gold.png", "G", (255, 215, 80)),
]

SKILL_MVP: list[tuple[str, int, str]] = [
    ("slash_attack", 0, "slash"),
    ("mend", 0, "heal"),
    ("empower", 1, "buff"),
    ("guard_strike", 0, "guard"),
    ("aimed_shot", 1, "ranged"),
    ("hex_bolt", 1, "dark"),
    ("arc_bolt", 1, "thunder"),
    ("venom_burst", 2, "poison"),
    ("iron_guard", 0, "defense"),
    ("hunter_mark", 1, "mark"),
    ("kindling_strike", 1, "fire"),
    ("rime_touch", 1, "ice"),
    ("static_strike", 1, "thunder"),
    ("sanctal_strike", 2, "holy"),
    ("umbral_strike", 2, "dark"),
    ("titan_roar", 3, "ultimate"),
    ("ouga_retsudan", 3, "ultimate"),
    ("dead_eye", 3, "ultimate"),
    ("beast_dominion", 3, "ultimate"),
    ("grand_elixir", 3, "ultimate"),
]


def snake_to_pascal(snake: str) -> str:
    return "".join(part.capitalize() for part in snake.split("_"))


def tint_image(img: Image.Image, hue: float | None, sat_mult: float = 1.15) -> Image.Image:
    if hue is None:
        return img.copy()
    img = img.convert("RGBA")
    rgb = Image.merge("RGB", img.split()[:3])
    hsv = rgb.convert("HSV")
    h, s, v = hsv.split()
    h_data = h.load()
    s_data = s.load()
    target = int(hue * 255) % 256
    for y in range(h.size[1]):
        for x in range(h.size[0]):
            if s_data[x, y] > 10:
                h_data[x, y] = target
            s_data[x, y] = min(255, int(s_data[x, y] * sat_mult))
    tinted = Image.merge("HSV", (h, s, v)).convert("RGBA")
    tinted.putalpha(img.split()[3])
    return tinted


def draw_round_frame(draw: ImageDraw.ImageDraw, size: int, rarity: int, margin: int = 6) -> None:
    rarity = max(0, min(3, rarity))
    dark, gem = RARITY_BG[rarity]
    draw.rounded_rectangle((margin, margin, size - margin - 1, size - margin - 1), radius=14, fill=dark)
    draw.rounded_rectangle((margin + 2, margin + 2, size - margin - 3, size - margin - 3), radius=12, outline=gem, width=2)
    gx, gy = size - 22, 10
    draw.polygon([(gx, gy + 6), (gx + 6, gy), (gx + 12, gy + 6), (gx + 6, gy + 12)], fill=gem)


def draw_skill_glyph(draw: ImageDraw.ImageDraw, cx: int, cy: int, kind: str, color: tuple[int, int, int]) -> None:
    if kind == "slash":
        draw.polygon([(cx - 18, cy + 16), (cx + 4, cy - 22), (cx + 10, cy - 16), (cx - 12, cy + 22)], fill=color)
    elif kind == "heal":
        draw.rectangle((cx - 5, cy - 18, cx + 5, cy + 18), fill=color)
        draw.rectangle((cx - 18, cy - 5, cx + 18, cy + 5), fill=color)
    elif kind == "buff":
        draw.polygon([(cx, cy - 20), (cx + 18, cy + 12), (cx - 18, cy + 12)], fill=color)
    elif kind == "guard":
        draw.polygon([(cx, cy - 20), (cx + 22, cy - 6), (cx + 14, cy + 20), (cx - 14, cy + 20), (cx - 22, cy - 6)], outline=color, width=3)
    elif kind == "ranged":
        draw.arc((cx - 20, cy - 20, cx + 20, cy + 20), 200, 340, fill=color, width=3)
        draw.line((cx + 12, cy - 8, cx + 24, cy - 18), fill=color, width=3)
    elif kind == "fire":
        draw.polygon([(cx, cy - 22), (cx + 14, cy + 8), (cx, cy + 18), (cx - 14, cy + 8)], fill=(255, 120, 40))
    elif kind == "ice":
        for dx, dy in ((0, -18), (16, 8), (-16, 8)):
            draw.polygon([(cx + dx, cy + dy - 8), (cx + dx + 6, cy + dy + 10), (cx + dx - 6, cy + dy + 10)], fill=(140, 220, 255))
    elif kind == "thunder":
        draw.polygon([(cx - 4, cy - 20), (cx + 10, cy - 2), (cx + 2, cy - 2), (cx + 8, cy + 20), (cx - 12, cy), (cx - 2, cy)], fill=(255, 240, 80))
    elif kind == "holy":
        draw.ellipse((cx - 16, cy - 16, cx + 16, cy + 16), outline=(255, 240, 180), width=3)
        draw.line((cx, cy - 10, cx, cy + 10), fill=(255, 240, 180), width=3)
        draw.line((cx - 10, cy, cx + 10, cy), fill=(255, 240, 180), width=3)
    elif kind == "dark":
        draw.ellipse((cx - 14, cy - 14, cx + 14, cy + 14), fill=(90, 40, 130))
        draw.ellipse((cx - 6, cy - 6, cx + 2, cy + 2), fill=(20, 10, 30))
    elif kind == "poison":
        draw.ellipse((cx - 10, cy + 2, cx + 10, cy + 18), fill=(80, 200, 60))
        draw.ellipse((cx - 8, cy - 14, cx - 2, cy - 4), fill=(80, 200, 60))
        draw.ellipse((cx + 2, cy - 16, cx + 8, cy - 6), fill=(80, 200, 60))
    elif kind == "defense":
        draw.rectangle((cx - 18, cy - 12, cx + 18, cy + 16), outline=color, width=3)
        draw.line((cx - 18, cy - 4, cx + 18, cy - 4), fill=color, width=2)
    elif kind == "mark":
        draw.ellipse((cx - 12, cy - 12, cx + 12, cy + 12), outline=(255, 80, 120), width=3)
        draw.ellipse((cx - 4, cy - 4, cx + 4, cy + 4), fill=(255, 80, 120))
    elif kind == "ultimate":
        for i in range(8):
            ang = i * 0.785
            x1 = cx + int(8 * __import__("math").cos(ang))
            y1 = cy + int(8 * __import__("math").sin(ang))
            x2 = cx + int(22 * __import__("math").cos(ang))
            y2 = cy + int(22 * __import__("math").sin(ang))
            draw.line((x1, y1, x2, y2), fill=(255, 220, 80), width=2)
        draw.ellipse((cx - 8, cy - 8, cx + 8, cy + 8), fill=(255, 220, 80))
    else:
        draw.ellipse((cx - 12, cy - 12, cx + 12, cy + 12), fill=color)


def glyph_color(kind: str) -> tuple[int, int, int]:
    return {
        "slash": (230, 230, 240),
        "heal": (100, 230, 120),
        "buff": (255, 180, 60),
        "guard": (120, 170, 255),
        "ranged": (200, 220, 200),
        "defense": (170, 170, 190),
        "mark": (255, 120, 150),
    }.get(kind, (220, 220, 230))


def make_menu_icon(filename: str, glyph: str, accent: tuple[int, int, int]) -> None:
    size = 64
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle((4, 4, size - 5, size - 5), radius=10, fill=(24, 22, 28))
    draw.rounded_rectangle((6, 6, size - 7, size - 7), radius=8, outline=accent, width=2)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc", 28)
    except OSError:
        font = ImageFont.load_default()
    bbox = draw.textbbox((0, 0), glyph, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    draw.text(((size - tw) // 2, (size - th) // 2 - 2), glyph, fill=accent, font=font)
    img.save(MENU_OUT / filename, "PNG")


def make_skill_icon(skill_id: str, rarity: int, kind: str) -> None:
    size = 128
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_round_frame(draw, size, rarity)
    draw_skill_glyph(draw, size // 2, size // 2 + 4, kind, glyph_color(kind))
    fname = f"ICO_SKILL_{snake_to_pascal(skill_id)}.png"
    img.save(SKILL_OUT / fname, "PNG")


def generate_floors() -> int:
    base = Image.open(MG_FLOOR).convert("RGBA")
    count = 0
    for dungeon_id, hue in DUNGEON_HUES:
        out_dir = ROOT / "assets/dungeon" / dungeon_id / "env"
        out_dir.mkdir(parents=True, exist_ok=True)
        if hue is None:
            floor = base
        else:
            floor = tint_image(base, hue)
            if dungeon_id in ("frostridge", "frostwall_path"):
                floor = ImageEnhance.Brightness(floor).enhance(1.06)
        floor.save(out_dir / "TILE_Floor.png", "PNG")
        count += 1
        print(f"  floor {dungeon_id}")
    return count


def write_manifest(skills: list[tuple[str, int, str]]) -> None:
    manifest = {
        "skills": [
            {"id": sid, "file": f"ICO_SKILL_{snake_to_pascal(sid)}.png", "rarity": r, "kind": k}
            for sid, r, k in skills
        ]
    }
    (ROOT / "tools/skill_icon_manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8"
    )


if __name__ == "__main__":
    MENU_OUT.mkdir(parents=True, exist_ok=True)
    SKILL_OUT.mkdir(parents=True, exist_ok=True)
    print("UI menu icons...")
    for spec in UI_SPECS:
        make_menu_icon(*spec)
        print(f"  {spec[0]}")
    print("Skill MVP icons...")
    for entry in SKILL_MVP:
        make_skill_icon(*entry)
        print(f"  {entry[0]}")
    write_manifest(SKILL_MVP)
    print("Floor tiles...")
    n = generate_floors()
    print(f"Done. floors={n} menu={len(UI_SPECS)} skills={len(SKILL_MVP)}")
