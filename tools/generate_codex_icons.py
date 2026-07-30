#!/usr/bin/env python3
"""Generate codex category icons (history / lore / guide / worldview) and optionally fix enemy portraits."""
from __future__ import annotations

import argparse
import hashlib
import math
import re
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
ENEMY_DIR = ROOT / "assets/codex/enemies"
CODEX_UI_DIR = ROOT / "assets/ui/codex"
ICON_PATHS = ROOT / "scripts/ui/IconPaths.gd"
HISTORY_MD = ROOT / "docs/specs/world/01_History.md"
FRAGMENTS_MD = ROOT / "docs/specs/world/12_Fragments.md"
GUIDE_CATALOG = ROOT / "scripts/codex/GuideCatalog.gd"

SIZE = 128
BLACK_THRESHOLD = 28
WHITE_THRESHOLD = 240

HISTORY_HUES = [
    (0.12, "王国"), (0.02, "戦争"), (0.58, "静寂"), (0.33, "探索"),
    (0.08, "遺産"), (0.72, "英雄"), (0.05, "崩落"), (0.48, "ギルド"), (0.10, "街道"),
]

# Unique guide theme assets (rotated across 33 entries).
GUIDE_THEMES: list[tuple[str, str, tuple[int, int, int], str]] = [
    ("Elements", "属性", (242, 140, 51), "elements"),
    ("Status", "状態", (140, 191, 242), "status"),
    ("Formation", "陣形", (120, 180, 140), "formation"),
    ("Skill", "技能", (200, 120, 220), "skill"),
    ("Weather", "天候", (100, 170, 210), "weather"),
    ("Rarity", "レア", (230, 190, 70), "rarity"),
    ("Enhance", "強化", (220, 140, 90), "enhance"),
    ("Survey", "調査", (130, 160, 200), "survey"),
    ("Hub", "拠点", (160, 140, 200), "hub"),
]

# Semantic map: guide_id -> theme stem (falls back to rotation).
GUIDE_THEME_BY_ID: dict[str, str] = {
    "COMBAT-G001": "Elements",
    "COMBAT-G002": "Status",
    "COMBAT-G003": "Formation",
    "COMBAT-G004": "Formation",
    "COMBAT-G005": "Formation",
    "COMBAT-G006": "Skill",
    "COMBAT-G007": "Skill",
    "COMBAT-G008": "Skill",
    "COMBAT-G009": "Skill",
    "COMBAT-G010": "Formation",
    "COMBAT-G011": "Skill",
    "COMBAT-G012": "Status",
    "COMBAT-G013": "Weather",
    "COMBAT-G014": "Weather",
    "COMBAT-G015": "Skill",
    "COMBAT-G016": "Skill",
    "COMBAT-G017": "Skill",
    "EQUIP-G001": "Rarity",
    "EQUIP-G002": "Rarity",
    "EQUIP-G003": "Rarity",
    "EQUIP-G004": "Rarity",
    "EQUIP-G005": "Enhance",
    "EQUIP-G006": "Enhance",
    "EQUIP-G007": "Enhance",
    "EQUIP-G008": "Enhance",
    "EQUIP-G009": "Enhance",
    "SYS-G001": "Survey",
    "SYS-G002": "Hub",
    "SYS-G003": "Hub",
    "SYS-G004": "Hub",
    "SYS-G005": "Hub",
    "SYS-G006": "Survey",
    "SYS-G007": "Hub",
}

WORLD_HUES = [
    (0.55, "世界"), (0.08, "力"), (0.48, "ギルド"), (0.33, "境界"),
    (0.05, "暦"), (0.72, "王"), (0.78, "石"), (0.15, "裂け"),
    (0.10, "拠点"), (0.42, "記録"),
]


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


def _draw_world_orb(draw: ImageDraw.ImageDraw, cx: int, cy: int, accent: tuple[int, int, int], label: str = "") -> None:
    dark = tuple(max(0, c // 3) for c in accent)
    draw.ellipse((cx - 36, cy - 36, cx + 36, cy + 36), fill=(*dark, 255), outline=(*accent, 255), width=3)
    draw.ellipse((cx - 28, cy - 28, cx + 28, cy + 28), outline=(*accent, 180), width=2)
    draw.arc((cx - 28, cy - 14, cx + 28, cy + 14), 0, 360, fill=(*accent, 200), width=2)
    draw.line((cx, cy - 28, cx, cy + 28), fill=(*accent, 200), width=2)
    draw.line((cx - 28, cy, cx + 28, cy), fill=(*accent, 160), width=1)
    # Accent gem at center (no text — default PIL font lacks JP glyphs).
    draw.ellipse((cx - 6, cy - 6, cx + 6, cy + 6), fill=(240, 230, 210, 255), outline=(*accent, 255), width=1)
    _ = label


def _draw_guide_glyph(draw: ImageDraw.ImageDraw, cx: int, cy: int, kind: str, accent: tuple[int, int, int]) -> None:
    if kind == "elements":
        elems = [(242, 102, 38), (89, 166, 242), (242, 217, 51), (140, 64, 191), (242, 217, 120)]
        for i, col in enumerate(elems):
            ang = i * 2 * math.pi / 5 - math.pi / 2
            x = cx + int(22 * math.cos(ang))
            y = cy + int(22 * math.sin(ang))
            draw.ellipse((x - 8, y - 8, x + 8, y + 8), fill=(*col, 255))
        draw.ellipse((cx - 10, cy - 10, cx + 10, cy + 10), fill=(30, 28, 36, 255))
    elif kind == "status":
        cols = [(120, 200, 90), (242, 120, 50), (120, 190, 242)]
        for i, col in enumerate(cols):
            x = cx - 24 + i * 24
            draw.rounded_rectangle((x - 10, cy - 16, x + 10, cy + 16), radius=4, fill=(*col, 255))
            draw.ellipse((x - 4, cy - 4, x + 4, cy + 4), fill=(20, 18, 24, 255))
    elif kind == "formation":
        for i, (dx, dy) in enumerate([(-18, 10), (0, -14), (18, 10)]):
            draw.ellipse((cx + dx - 10, cy + dy - 10, cx + dx + 10, cy + dy + 10), fill=(*accent, 255))
        draw.polygon([(cx, cy - 2), (cx - 16, cy + 18), (cx + 16, cy + 18)], outline=(240, 230, 210, 200))
    elif kind == "skill":
        draw.polygon(
            [(cx, cy - 32), (cx + 22, cy - 8), (cx + 14, cy + 28), (cx - 14, cy + 28), (cx - 22, cy - 8)],
            fill=(*accent, 255),
        )
        draw.ellipse((cx - 8, cy - 8, cx + 8, cy + 8), fill=(30, 28, 36, 255))
    elif kind == "weather":
        draw.ellipse((cx - 16, cy - 22, cx + 8, cy + 2), fill=(242, 210, 90, 255))
        draw.ellipse((cx - 6, cy - 8, cx + 28, cy + 18), fill=(200, 210, 230, 255))
        draw.ellipse((cx - 28, cy - 2, cx + 4, cy + 24), fill=(180, 195, 220, 255))
        for i in range(3):
            x = cx - 12 + i * 12
            draw.line((x, cy + 18, x - 4, cy + 30), fill=(*accent, 255), width=2)
    elif kind == "rarity":
        def diamond(px: int, py: int, r: int, fill) -> None:
            draw.polygon([(px, py - r), (px + r, py), (px, py + r), (px - r, py)], fill=fill)

        for i in range(4):
            ang = i * 2 * math.pi / 4 - math.pi / 2
            x = cx + int(20 * math.cos(ang))
            y = cy + int(20 * math.sin(ang))
            diamond(x, y, 8, (*accent, 255))
        diamond(cx, cy, 12, (242, 220, 120, 255))
    elif kind == "enhance":
        draw.rounded_rectangle((cx - 22, cy - 8, cx + 22, cy + 28), radius=4, fill=(80, 70, 60, 255), outline=(*accent, 255), width=2)
        draw.polygon([(cx - 18, cy - 8), (cx, cy - 30), (cx + 18, cy - 8)], fill=(*accent, 255))
        draw.ellipse((cx - 6, cy + 4, cx + 6, cy + 16), fill=(242, 200, 80, 255))
    elif kind == "survey":
        draw.ellipse((cx - 26, cy - 26, cx + 26, cy + 26), outline=(*accent, 255), width=3)
        draw.ellipse((cx - 10, cy - 10, cx + 10, cy + 10), fill=(*accent, 255))
        draw.line((cx + 12, cy + 12, cx + 30, cy + 30), fill=(*accent, 255), width=4)
    else:  # hub
        draw.rounded_rectangle((cx - 28, cy - 8, cx + 28, cy + 28), radius=4, fill=(70, 60, 80, 255), outline=(*accent, 255), width=2)
        draw.polygon([(cx - 34, cy - 8), (cx, cy - 32), (cx + 34, cy - 8)], fill=(*accent, 255))
        draw.rectangle((cx - 6, cy + 8, cx + 6, cy + 28), fill=(40, 36, 48, 255))


def make_category_icon(accent: tuple[int, int, int], draw_fn, label: str = "") -> Image.Image:
    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    dark = tuple(max(0, c // 4) for c in accent)
    draw.rounded_rectangle((4, 4, SIZE - 5, SIZE - 5), radius=10, fill=(*dark, 255))
    draw.rounded_rectangle((6, 6, SIZE - 7, SIZE - 7), radius=8, outline=(*accent, 255), width=2)
    if label:
        draw_fn(draw, SIZE // 2, SIZE // 2 + 2, accent, label)
    else:
        draw_fn(draw, SIZE // 2, SIZE // 2 + 2, accent)
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


def parse_guide_ids() -> list[str]:
    text = GUIDE_CATALOG.read_text(encoding="utf-8")
    ids = re.findall(r'"((?:COMBAT|EQUIP|SYS)-G\d+)"', text)
    # Preserve order, unique
    seen: set[str] = set()
    out: list[str] = []
    for gid in ids:
        if gid not in seen:
            seen.add(gid)
            out.append(gid)
    return out


def parse_world_ids() -> list[str]:
    text = GUIDE_CATALOG.read_text(encoding="utf-8")
    ids = re.findall(r'"(WORLD-G\d+)"', text)
    seen: set[str] = set()
    out: list[str] = []
    for wid in ids:
        if wid not in seen:
            seen.add(wid)
            out.append(wid)
    return out


def lore_accent(lf_id: str) -> tuple[int, int, int]:
    lore_theme = {
        "ancient": (180, 160, 120),
        "mourngate": (140, 130, 160),
        "whisperwood": (90, 160, 90),
        "mistfen": (80, 140, 130),
    }
    for prefix, color in lore_theme.items():
        if lf_id.startswith(prefix):
            return color
    digest = hashlib.md5(lf_id.encode()).hexdigest()
    hue = int(digest[:2], 16) / 255.0
    return hue_to_rgb(hue)


def generate_history_icons() -> list[tuple[str, str, str]]:
    """Generate 9 unique history theme icons; map all HE entries by rotation (matches current IconPaths)."""
    mappings: list[tuple[str, str, str]] = []
    CODEX_UI_DIR.mkdir(parents=True, exist_ok=True)
    theme_files: list[str] = []
    for i, (hue, label) in enumerate(HISTORY_HUES):
        accent = hue_to_rgb(hue)
        fname = f"ICO_CDX_HIS_HE{i + 1:03d}.png"
        icon = make_category_icon(accent, _draw_scroll, str(i + 1))
        icon.save(CODEX_UI_DIR / fname, "PNG")
        theme_files.append(fname)
        print(f"  history theme {fname}")

    for i, (he_id, _title) in enumerate(parse_history_entries()):
        fname = theme_files[i % len(theme_files)]
        mappings.append(("history", he_id, f"res://assets/ui/codex/{fname}"))
        print(f"  history:{he_id} -> {fname}")
    return mappings


def generate_lore_icons() -> list[tuple[str, str, str]]:
    mappings: list[tuple[str, str, str]] = []
    for lf_id, _title in parse_lore_entries():
        accent = lore_accent(lf_id)
        fname = f"ICO_CDX_LF_{snake_to_pascal(lf_id)}.png"
        icon = make_category_icon(accent, _draw_fragment)
        icon.save(CODEX_UI_DIR / fname, "PNG")
        mappings.append(("lore", lf_id, f"res://assets/ui/codex/{fname}"))
        print(f"  lore:{lf_id} -> {fname}")
    return mappings


def generate_guide_icons() -> list[tuple[str, str, str]]:
    mappings: list[tuple[str, str, str]] = []
    theme_path: dict[str, str] = {}

    def make_guide_draw(kind: str):
        def draw_fn(draw, cx, cy, col, _lbl=""):
            _draw_guide_glyph(draw, cx, cy, kind, col)

        return draw_fn

    for stem, _label, accent, kind in GUIDE_THEMES:
        fname = f"ICO_CDX_GDE_{stem}.png"
        icon = make_category_icon(accent, make_guide_draw(kind))
        icon.save(CODEX_UI_DIR / fname, "PNG")
        theme_path[stem] = f"res://assets/ui/codex/{fname}"
        print(f"  guide theme {fname}")

    stems = [t[0] for t in GUIDE_THEMES]
    for i, guide_id in enumerate(parse_guide_ids()):
        stem = GUIDE_THEME_BY_ID.get(guide_id, stems[i % len(stems)])
        res_path = theme_path[stem]
        mappings.append(("guide", guide_id, res_path))
        print(f"  guide:{guide_id} -> {Path(res_path).name}")
    return mappings


def generate_worldview_icons() -> list[tuple[str, str, str]]:
    mappings: list[tuple[str, str, str]] = []
    theme_files: list[str] = []
    for i, (hue, label) in enumerate(WORLD_HUES):
        accent = hue_to_rgb(hue)
        fname = f"ICO_CDX_WLD_{i + 1:02d}.png"
        icon = make_category_icon(accent, _draw_world_orb, label[:1])
        icon.save(CODEX_UI_DIR / fname, "PNG")
        theme_files.append(fname)
        print(f"  worldview theme {fname}")

    for i, world_id in enumerate(parse_world_ids()):
        # Prefer WORLD-G001..050; skip any stray beyond catalog list order.
        if not re.match(r"^WORLD-G\d+$", world_id):
            continue
        fname = theme_files[i % len(theme_files)]
        mappings.append(("worldview", world_id, f"res://assets/ui/codex/{fname}"))
        print(f"  worldview:{world_id} -> {fname}")
    return mappings


def upsert_icon_paths(mappings: list[tuple[str, str, str]]) -> None:
    """Insert or update IconPaths.ICON_MAP entries for the given mappings."""
    text = ICON_PATHS.read_text(encoding="utf-8")
    marker = '\t"currency:arcane_crystal"'
    missing_lines: list[str] = []

    for category, entry_id, res_path in mappings:
        key = f'"{category}:{entry_id}"'
        pattern = rf"(\t{re.escape(key)}:\s*\")([^\"]+)(\")"
        if re.search(pattern, text):
            text = re.sub(pattern, rf"\1{res_path}\3", text)
        else:
            missing_lines.append(f'\t"{category}:{entry_id}":           "{res_path}",')

    if missing_lines:
        block = "\t# 図鑑カテゴリ（手引き・世界観解説）\n" + "\n".join(missing_lines) + "\n"
        if marker not in text:
            raise SystemExit(f"IconPaths marker not found: {marker}")
        text = text.replace(marker, block + marker, 1)

    ICON_PATHS.write_text(text, encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate codex UI icons")
    parser.add_argument(
        "--mode",
        choices=("guide-world", "all", "enemies"),
        default="guide-world",
        help="guide-world=手引き+WORLDのみ（既定） / all=歴史・断片含む / enemies=敵透過のみ",
    )
    args = parser.parse_args()

    all_maps: list[tuple[str, str, str]] = []

    if args.mode == "enemies":
        print("Fixing enemy portrait transparency...")
        n = fix_enemy_portraits()
        print(f"Fixed {n} enemy portraits.")
        return

    if args.mode == "all":
        print("Fixing enemy portrait transparency...")
        n = fix_enemy_portraits()
        print(f"Fixed {n} enemy portraits.")
        print("Generating history icons...")
        all_maps.extend(generate_history_icons())
        print("Generating lore icons...")
        all_maps.extend(generate_lore_icons())

    print("Generating guide icons...")
    all_maps.extend(generate_guide_icons())
    print("Generating worldview icons...")
    all_maps.extend(generate_worldview_icons())

    print("Updating IconPaths.gd...")
    upsert_icon_paths(all_maps)
    print(f"Done. Upserted {len(all_maps)} codex category icon mappings.")


if __name__ == "__main__":
    main()
