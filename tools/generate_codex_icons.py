#!/usr/bin/env python3
"""Generate codex category icons and fix enemy portrait transparency."""
from __future__ import annotations

import hashlib
import math
import re
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
ENEMY_DIR = ROOT / "assets/codex/enemies"
CODEX_UI_DIR = ROOT / "assets/ui/codex"
ICON_PATHS = ROOT / "scripts/ui/IconPaths.gd"
HISTORY_MD = ROOT / "docs/specs/world/01_History.md"
FRAGMENTS_MD = ROOT / "docs/specs/world/12_Fragments.md"

SIZE = 128
BLACK_THRESHOLD = 28
WHITE_THRESHOLD = 240

HISTORY_HUES = [
    (0.12, "王国"), (0.02, "戦争"), (0.58, "静寂"), (0.33, "探索"),
    (0.08, "遺産"), (0.72, "英雄"), (0.05, "崩落"), (0.48, "ギルド"), (0.10, "街道"),
]

GUIDE_SPECS: list[tuple[str, str, tuple[int, int, int], str]] = [
    ("COMBAT-G001", "属性", (242, 140, 51), "elements"),
    ("COMBAT-G002", "状態", (140, 191, 242), "status"),
]

LORE_THEME: dict[str, tuple[int, int, int]] = {
    "ancient": (180, 160, 120),
    "mourngate": (140, 130, 160),
    "whisperwood": (90, 160, 90),
    "mistfen": (80, 140, 130),
}


def snake_to_pascal(snake: str) -> str:
    return "".join(part.capitalize() for part in snake.replace("-", "_").split("_"))


def hue_to_rgb(hue: float, sat: float = 0.65, val: float = 0.82) -> tuple[int, int, int]:
    import colorsys

    r, g, b = colorsys.hsv_to_rgb(hue % 1.0, sat, val)
    return int(r * 255), int(g * 255), int(b * 255)


def remove_matte_bg(img: Image.Image, kind: str, hard: int = 28, soft: int = 42) -> Image.Image:
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if kind == "black":
                dist = max(r, g, b)
            elif kind == "white":
                dist = max(255 - r, 255 - g, 255 - b)
            else:
                continue
            if dist <= hard:
                px[x, y] = (r, g, b, 0)
            elif dist <= soft:
                fade = (dist - hard) / max(1, soft - hard)
                px[x, y] = (r, g, b, int(a * fade))
    return img


def corner_bg_kind(img: Image.Image) -> str:
    rgb = img.convert("RGB")
    w, h = rgb.size
    corners = [rgb.getpixel((0, 0)), rgb.getpixel((w - 1, 0)), rgb.getpixel((0, h - 1)), rgb.getpixel((w - 1, h - 1))]
    if all(r <= BLACK_THRESHOLD and g <= BLACK_THRESHOLD and b <= BLACK_THRESHOLD for r, g, b in corners):
        return "black"
    if all(r >= WHITE_THRESHOLD and g >= WHITE_THRESHOLD and b >= WHITE_THRESHOLD for r, g, b in corners):
        return "white"
    return "unknown"


def fix_enemy_portraits() -> int:
    fixed = 0
    for path in sorted(ENEMY_DIR.glob("*.png")):
        img = Image.open(path)
        kind = corner_bg_kind(img) if img.mode != "RGBA" else "black"
        if kind == "unknown" and img.mode == "RGBA":
            continue
        out = remove_matte_bg(img, kind if kind != "unknown" else "black")
        out.save(path, "PNG")
        fixed += 1
        print(f"  fixed enemy: {path.name}")
    return fixed


def _draw_scroll(draw: ImageDraw.ImageDraw, cx: int, cy: int, accent: tuple[int, int, int], label: str) -> None:
    dark = tuple(max(0, c // 3) for c in accent)
    draw.rounded_rectangle((cx - 34, cy - 42, cx + 34, cy + 42), radius=8, fill=(*dark, 255))
    draw.rounded_rectangle((cx - 30, cy - 38, cx + 30, cy + 38), radius=6, fill=(232, 220, 190, 255))
    draw.arc((cx - 30, cy - 46, cx + 30, cy - 30), 0, 180, fill=(*accent, 255), width=3)
    draw.arc((cx - 30, cy + 30, cx + 30, cy + 46), 180, 360, fill=(*accent, 255), width=3)
    for y in range(cy - 20, cy + 24, 8):
        draw.line((cx - 20, y, cx + 18, y), fill=(170, 150, 120, 180), width=1)
    draw.text((cx - 8, cy - 8), label, fill=(*accent, 255))


def _draw_fragment(draw: ImageDraw.ImageDraw, cx: int, cy: int, accent: tuple[int, int, int]) -> None:
    pts = [(cx - 36, cy - 28), (cx + 28, cy - 34), (cx + 40, cy + 12), (cx + 8, cy + 38), (cx - 32, cy + 22)]
    draw.polygon(pts, fill=(210, 198, 170, 255), outline=(*accent, 255))
    for i in range(3):
        y = cy - 12 + i * 12
        draw.line((cx - 18, y, cx + 16, y), fill=(150, 130, 100, 200), width=2)
    draw.ellipse((cx + 8, cy - 18, cx + 22, cy - 4), outline=(*accent, 200), width=2)


def _draw_guide_glyph(draw: ImageDraw.ImageDraw, cx: int, cy: int, kind: str, accent: tuple[int, int, int]) -> None:
    if kind == "elements":
        elems = [(242, 102, 38), (89, 166, 242), (242, 217, 51), (140, 64, 191), (242, 217, 120)]
        for i, col in enumerate(elems):
            ang = i * 2 * math.pi / 5 - math.pi / 2
            x = cx + int(22 * math.cos(ang))
            y = cy + int(22 * math.sin(ang))
            draw.ellipse((x - 8, y - 8, x + 8, y + 8), fill=(*col, 255))
        draw.ellipse((cx - 10, cy - 10, cx + 10, cy + 10), fill=(30, 28, 36, 255))
    else:
        marks = ["毒", "炎", "氷"]
        for i, ch in enumerate(marks):
            x = cx - 24 + i * 24
            draw.rounded_rectangle((x - 10, cy - 14, x + 10, cy + 14), radius=4, fill=(*accent, 255))
            draw.text((x - 6, cy - 8), ch, fill=(20, 18, 24, 255))


def make_category_icon(accent: tuple[int, int, int], glyph: str, draw_fn, label: str = "") -> Image.Image:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    dark = tuple(max(0, c // 4) for c in accent)
    draw.rounded_rectangle((4, 4, SIZE - 5, SIZE - 5), radius=10, fill=(*dark, 255))
    draw.rounded_rectangle((6, 6, SIZE - 7, SIZE - 7), radius=8, outline=(*accent, 255), width=2)
    draw_fn(draw, SIZE // 2, SIZE // 2 + 2, accent, label) if label else draw_fn(draw, SIZE // 2, SIZE // 2 + 2, accent)
    return img


def parse_history_entries() -> list[tuple[str, str]]:
    text = HISTORY_MD.read_text(encoding="utf-8")
    entries: list[tuple[str, str]] = []
    for m in re.finditer(r"^# (HE-\d+)\s+(.+)$", text, re.M):
        entries.append((m.group(1), m.group(2).strip()))
    return entries


def parse_lore_entries() -> list[tuple[str, str]]:
    text = FRAGMENTS_MD.read_text(encoding="utf-8")
    entries: list[tuple[str, str]] = []
    for m in re.finditer(r"^# LF (\S+)\s+(.+)$", text, re.M):
        entries.append((m.group(1), m.group(2).strip()))
    return entries


def lore_accent(lf_id: str) -> tuple[int, int, int]:
    for prefix, color in LORE_THEME.items():
        if lf_id.startswith(prefix):
            return color
    digest = hashlib.md5(lf_id.encode()).hexdigest()
    hue = int(digest[:2], 16) / 255.0
    return hue_to_rgb(hue)


def generate_history_icons() -> list[tuple[str, str, str]]:
    mappings: list[tuple[str, str, str]] = []
    CODEX_UI_DIR.mkdir(parents=True, exist_ok=True)
    for i, (he_id, _title) in enumerate(parse_history_entries()):
        hue, label = HISTORY_HUES[i % len(HISTORY_HUES)]
        accent = hue_to_rgb(hue)
        safe = he_id.replace("-", "")
        fname = f"ICO_CDX_HIS_{safe}.png"
        icon = make_category_icon(accent, label, _draw_scroll, str(i + 1))
        icon.save(CODEX_UI_DIR / fname, "PNG")
        mappings.append(("history", he_id, f"res://assets/ui/codex/{fname}"))
        print(f"  history:{he_id} -> {fname}")
    return mappings


def generate_lore_icons() -> list[tuple[str, str, str]]:
    mappings: list[tuple[str, str, str]] = []
    for lf_id, _title in parse_lore_entries():
        accent = lore_accent(lf_id)
        fname = f"ICO_CDX_LF_{snake_to_pascal(lf_id)}.png"
        icon = make_category_icon(accent, "", _draw_fragment)
        icon.save(CODEX_UI_DIR / fname, "PNG")
        mappings.append(("lore", lf_id, f"res://assets/ui/codex/{fname}"))
        print(f"  lore:{lf_id} -> {fname}")
    return mappings


def generate_guide_icons() -> list[tuple[str, str, str]]:
    mappings: list[tuple[str, str, str]] = []

    def make_guide_draw(kind: str):
        def draw_fn(draw, cx, cy, col, _lbl=""):
            _draw_guide_glyph(draw, cx, cy, kind, col)

        return draw_fn

    for guide_id, _label, accent, kind in GUIDE_SPECS:
        fname = f"ICO_CDX_GDE_{snake_to_pascal(guide_id)}.png"
        icon = make_category_icon(accent, "", make_guide_draw(kind))
        icon.save(CODEX_UI_DIR / fname, "PNG")
        mappings.append(("guide", guide_id, f"res://assets/ui/codex/{fname}"))
        print(f"  guide:{guide_id} -> {fname}")
    return mappings


def update_icon_paths(mappings: list[tuple[str, str, str]]) -> None:
    text = ICON_PATHS.read_text(encoding="utf-8")
    block_lines = ["\t# 図鑑カテゴリ（歴史・記録・手引き）"]
    for category, entry_id, res_path in mappings:
        block_lines.append(f'\t"{category}:{entry_id}":           "{res_path}",')
    block = "\n".join(block_lines) + "\n"

    marker = '\t"currency:arcane_crystal"'
    if '"history:HE-001"' in text:
        for category, entry_id, res_path in mappings:
            key = f'"{category}:{entry_id}"'
            pattern = rf"(\t{re.escape(key)}:\s*\")([^\"]+)(\")"
            if re.search(pattern, text):
                text = re.sub(pattern, rf"\1{res_path}\3", text)
        ICON_PATHS.write_text(text, encoding="utf-8")
        return

    if marker in text:
        text = text.replace(marker, block + marker, 1)
    ICON_PATHS.write_text(text, encoding="utf-8")


def main() -> None:
    print("Fixing enemy portrait transparency...")
    n = fix_enemy_portraits()
    print(f"Fixed {n} enemy portraits.")

    print("Generating history icons...")
    history_maps = generate_history_icons()
    print("Generating lore icons...")
    lore_maps = generate_lore_icons()
    print("Generating guide icons...")
    guide_maps = generate_guide_icons()

    all_maps = history_maps + lore_maps + guide_maps
    print("Updating IconPaths.gd...")
    update_icon_paths(all_maps)
    print(f"Done. Generated {len(all_maps)} codex category icons.")


if __name__ == "__main__":
    main()
