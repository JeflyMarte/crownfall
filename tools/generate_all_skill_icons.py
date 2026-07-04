#!/usr/bin/env python3
"""Generate skill icons for all SkillData resources and update IconPaths."""
from __future__ import annotations

import math
import re
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
SKILL_DIR = ROOT / "resources/skills"
OUT_DIR = ROOT / "assets/ui/skills"
ICON_PATHS = ROOT / "scripts/ui/IconPaths.gd"

RARITY_BG = [
    ((38, 38, 42), (153, 153, 153)),
    ((18, 28, 52), (77, 140, 242)),
    ((34, 20, 58), (179, 115, 242)),
    ((52, 40, 12), (242, 191, 64)),
]


def snake_to_pascal(snake: str) -> str:
    return "".join(part.capitalize() for part in snake.split("_"))


def parse_skill(path: Path) -> dict[str, str]:
    text = path.read_text(encoding="utf-8")
    data: dict[str, str] = {}
    for key in (
        "id", "skill_type", "effect_type", "slot_type", "element",
        "apply_status_id", "apply_status_id2", "tags",
    ):
        m = re.search(rf'^{key}\s*=\s*(?:"([^"]*)"|Array\[String\]\(([^)]*)\))', text, re.M)
        if m:
            data[key] = m.group(1) if m.group(1) is not None else m.group(2)
    return data


def infer_kind(data: dict[str, str]) -> str:
    tags = data.get("tags", "")
    effect = data.get("effect_type", "")
    slot = data.get("slot_type", "")
    element = data.get("element", "")
    status = data.get("apply_status_id", "") + data.get("apply_status_id2", "")
    skill_type = data.get("skill_type", "")

    if slot == "ultimate" or skill_type == "boss":
        return "ultimate"
    if effect == "heal":
        return "heal"
    if effect == "buff":
        return "buff"
    if slot == "defend" or "shield" in tags:
        return "guard"
    if "poison" in status or "poison" in tags:
        return "poison"
    if element == "fire" or "fire" in tags or "ignite" in status:
        return "fire"
    if element == "ice" or "ice" in tags or "chill" in status:
        return "ice"
    if element == "thunder" or "thunder" in tags or "shock" in status:
        return "thunder"
    if element == "holy" or "holy" in tags:
        return "holy"
    if element == "dark" or "dark" in tags or "curse" in status:
        return "dark"
    if "mark" in tags or "mark" in status:
        return "mark"
    if "ranged" in tags or "long" in data.get("range_type", ""):
        return "ranged"
    if "defense" in tags or "guard" in tags:
        return "defense"
    if skill_type == "enemy":
        return "dark"
    return "slash"


def infer_rarity(data: dict[str, str]) -> int:
    if data.get("slot_type") == "ultimate" or data.get("skill_type") == "boss":
        return 3
    if data.get("skill_type") == "enemy":
        return 2
    if data.get("effect_type") == "buff":
        return 1
    if float(re.search(r"power_multiplier\s*=\s*([0-9.]+)", Path("").read_text() if False else "0") or 0) > 2:
        return 2
    return 1 if data.get("skill_type") == "player" else 0


def infer_rarity_from_file(path: Path, data: dict[str, str]) -> int:
    if data.get("slot_type") == "ultimate" or data.get("skill_type") == "boss":
        return 3
    if data.get("skill_type") == "enemy":
        return 2
    text = path.read_text(encoding="utf-8")
    m = re.search(r"power_multiplier\s*=\s*([0-9.]+)", text)
    power = float(m.group(1)) if m else 1.0
    if power >= 2.5:
        return 3
    if power >= 1.8 or data.get("effect_type") == "buff":
        return 2
    if data.get("skill_type") == "player":
        return 1
    return 0


def draw_round_frame(draw: ImageDraw.ImageDraw, size: int, rarity: int, margin: int = 6) -> None:
    rarity = max(0, min(3, rarity))
    dark, gem = RARITY_BG[rarity]
    draw.rounded_rectangle((margin, margin, size - margin - 1, size - margin - 1), radius=14, fill=dark)
    draw.rounded_rectangle((margin + 2, margin + 2, size - margin - 3, size - margin - 3), radius=12, outline=gem, width=2)


def glyph_color(kind: str) -> tuple[int, int, int]:
    return {
        "slash": (230, 230, 240),
        "heal": (100, 230, 120),
        "buff": (255, 180, 60),
        "guard": (120, 170, 255),
        "ranged": (200, 220, 200),
        "defense": (170, 170, 190),
        "mark": (255, 120, 150),
        "fire": (255, 120, 40),
        "ice": (140, 220, 255),
        "thunder": (255, 240, 80),
        "holy": (255, 240, 180),
        "dark": (180, 120, 220),
        "poison": (80, 200, 60),
        "ultimate": (255, 220, 80),
    }.get(kind, (220, 220, 230))


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
            ang = i * math.pi / 4
            x2 = cx + int(22 * math.cos(ang))
            y2 = cy + int(22 * math.sin(ang))
            draw.line((cx, cy, x2, y2), fill=(255, 220, 80), width=2)
        draw.ellipse((cx - 8, cy - 8, cx + 8, cy + 8), fill=(255, 220, 80))
    else:
        draw.ellipse((cx - 12, cy - 12, cx + 12, cy + 12), fill=color)


def make_skill_icon(skill_id: str, rarity: int, kind: str) -> str:
    size = 128
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    draw_round_frame(draw, size, rarity)
    draw_skill_glyph(draw, size // 2, size // 2 + 4, kind, glyph_color(kind))
    fname = f"ICO_SKILL_{snake_to_pascal(skill_id)}.png"
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    img.save(OUT_DIR / fname, "PNG")
    return f"res://assets/ui/skills/{fname}"


def update_icon_paths(mappings: list[tuple[str, str]]) -> None:
    text = ICON_PATHS.read_text(encoding="utf-8")
    block_lines = ["\t# スキルアイコン（全量自動生成）"]
    for skill_id, res_path in sorted(mappings, key=lambda x: x[0]):
        block_lines.append(f'\t"skill:{skill_id}":           "{res_path}",')
    block = "\n".join(block_lines) + "\n"

    if re.search(r"\t# スキルアイコン（全量自動生成）", text):
        text = re.sub(
            r"\t# スキルアイコン（全量自動生成）[\s\S]*?(?=\n\t\"status:|\n\t\"currency:|\n\t\"nav:|\n\t\"history:)",
            block.rstrip() + "\n",
            text,
            count=1,
        )
    elif re.search(r'\t"skill:', text):
        text = re.sub(
            r'\t"skill:[^"]+":[^\n]*\n(?:\t"skill:[^"]+":[^\n]*\n)*',
            block,
            text,
            count=1,
        )
    else:
        anchor = '\t"status:poison"'
        text = text.replace(anchor, block + anchor, 1)

    ICON_PATHS.write_text(text, encoding="utf-8")


def main() -> None:
    mappings: list[tuple[str, str]] = []
    for path in sorted(SKILL_DIR.glob("*.tres")):
        data = parse_skill(path)
        skill_id = data.get("id", path.stem)
        if not skill_id:
            continue
        kind = infer_kind(data)
        rarity = infer_rarity_from_file(path, data)
        res_path = make_skill_icon(skill_id, rarity, kind)
        mappings.append((skill_id, res_path))
    update_icon_paths(mappings)
    print(f"Generated {len(mappings)} skill icons.")


if __name__ == "__main__":
    main()
