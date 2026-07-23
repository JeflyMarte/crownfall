#!/usr/bin/env python3
"""Generate equipment/material icons with rarity-colored backgrounds.

Reads resources/weapons|armors|accessories|materials/*.tres and writes PNGs under
assets/ui/equipment/ or assets/ui/materials/.
"""
from __future__ import annotations

import colorsys
import hashlib
import re
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageEnhance, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
EQUIP_OUT_DIR = ROOT / "assets/ui/equipment"
MAT_OUT_DIR = ROOT / "assets/ui/materials"
TEMPLATE_DIR = ROOT / "assets/ui"

RARITY_COLORS = [
    (0.60, 0.60, 0.60),
    (0.30, 0.55, 0.95),
    (0.70, 0.45, 0.95),
    (0.95, 0.75, 0.25),
]
RARITY_GEMS = ["◇", "◆", "✦", "★"]

ELEMENT_HUE = {
    "fire": 0.03,
    "ice": 0.58,
    "holy": 0.12,
    "dark": 0.78,
    "thunder": 0.72,
    "": None,
}

SKIP_IDS = {"unidentified"}

## 手描き／専用生成済みレジェンド武器。再生成で上書きしない。
LEGENDARY_HAND_DRAWN_WEAPON_IDS: set[str] = {
    "sanctified_dagger",
    "consecrated_maul",
    "silvaria_oathblade",
    "veld_branch_staff",
    "volgrave_thunderblade",
    "seradion_storm_staff",
    "nereidas_tideblade",
    "pharoslight_staff",
    "eldion_frostbrand",
    "umbra_terminus_staff",
    "stormveil_needle",
    "noctumbra_fang",
    "mistpierce_halberd",
    "eldion_spine",
    "pharos_flare",
    "shadowcord",
    "silvaria_fang",
    "eldion_claw",
}

CANONICAL_TEMPLATES = {
    "weapon": {
        "greatsword": TEMPLATE_DIR / "equipment/ICO_WPN_IronSword.png",
        "bow": TEMPLATE_DIR / "equipment/ICO_WPN_HuntingBow.png",
        "staff": TEMPLATE_DIR / "equipment/ICO_WPN_ApprenticeStaff.png",
        "dual_blades": TEMPLATE_DIR / "equipment/ICO_WPN_BoltKnife.png",
        "dagger": TEMPLATE_DIR / "equipment/ICO_WPN_SanctifiedDagger.png",
        "default": TEMPLATE_DIR / "equipment/ICO_WPN_HeaterBlade.png",
    },
    "armor": {
        "light": TEMPLATE_DIR / "equipment/ICO_ARM_LeatherArmor.png",
        "heavy": TEMPLATE_DIR / "equipment/ICO_ARM_BoneArmor.png",
    },
    "accessory": {
        "default": TEMPLATE_DIR / "equipment/ICO_ACC_SilverRing.png",
    },
    "material": {
        "relic": TEMPLATE_DIR / "materials/ICO_MAT_RelicShard.png",
        "elite_relic": TEMPLATE_DIR / "materials/ICO_MAT_EliteRelicShard.png",
        "bone": TEMPLATE_DIR / "materials/ICO_MAT_AncientBone.png",
        "metal": TEMPLATE_DIR / "materials/ICO_MAT_CursedIron.png",
        "hide": TEMPLATE_DIR / "materials/ICO_MAT_Leather.png",
        "fur": TEMPLATE_DIR / "materials/ICO_MAT_Leather.png",
        "crystal_core": TEMPLATE_DIR / "materials/ICO_MAT_RelicShard.png",
        "heart": TEMPLATE_DIR / "materials/ICO_MAT_RelicShard.png",
        "spike": TEMPLATE_DIR / "materials/ICO_MAT_RelicShard.png",
        "fang": TEMPLATE_DIR / "materials/ICO_MAT_AncientBone.png",
        "feather": TEMPLATE_DIR / "materials/ICO_MAT_Leather.png",
        "dust": TEMPLATE_DIR / "materials/ICO_MAT_RelicShard.png",
        "carapace": TEMPLATE_DIR / "materials/ICO_MAT_AncientBone.png",
        "antenna": TEMPLATE_DIR / "materials/ICO_MAT_CursedIron.png",
        "gem": TEMPLATE_DIR / "materials/ICO_MAT_EliteRelicShard.png",
        "default": TEMPLATE_DIR / "materials/ICO_MAT_RelicShard.png",
    },
}

SIZE = 128
ICON_SCALE = 0.82


def snake_to_pascal(snake: str) -> str:
    return "".join(part.capitalize() for part in snake.split("_"))


def parse_tres(path: Path) -> dict[str, str]:
    text = path.read_text(encoding="utf-8")
    data: dict[str, str] = {}
    for key in (
        "id",
        "armor_id",
        "accessory_id",
        "display_name",
        "rarity",
        "weapon_type",
        "element",
        "base_attack",
        "category",
    ):
        m = re.search(rf'^{key}\s*=\s*("?)([^"\n]+)\1', text, re.M)
        if m:
            data[key] = m.group(2).strip()
    if "id" not in data and "armor_id" in data:
        data["id"] = data["armor_id"]
    if "id" not in data and "accessory_id" in data:
        data["id"] = data["accessory_id"]
    # armor: first resist element as tint hint
    m = re.search(r'^resist_elements\s*=\s*Array\[String\]\(\["([^"]+)"', text, re.M)
    if m and "element" not in data:
        data["element"] = m.group(1)
    return data


def _rgb_float(rgb: tuple[float, float, float]) -> tuple[int, int, int]:
    return tuple(int(max(0, min(255, c * 255))) for c in rgb)


def rarity_bg(rarity: int) -> Image.Image:
    rarity = max(0, min(3, rarity))
    base = _rgb_float(RARITY_COLORS[rarity])
    dark = tuple(int(c * 0.28) for c in base)
    mid = tuple(int(c * 0.55) for c in base)
    light = tuple(int(min(255, c * 1.15 + 30)) for c in base)

    img = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    margin = 6
    draw.rounded_rectangle(
        (margin, margin, SIZE - margin - 1, SIZE - margin - 1),
        radius=14,
        fill=dark,
    )
    draw.rounded_rectangle(
        (margin + 2, margin + 2, SIZE - margin - 3, SIZE - margin - 3),
        radius=12,
        fill=mid,
    )
    # inner vignette
    vignette = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    vd = ImageDraw.Draw(vignette)
    vd.rounded_rectangle(
        (margin + 4, margin + 4, SIZE - margin - 5, SIZE - margin - 5),
        radius=10,
        fill=(0, 0, 0, 70),
    )
    img = Image.alpha_composite(img, vignette)

    # border glow
    border = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    bd = ImageDraw.Draw(border)
    bd.rounded_rectangle(
        (margin, margin, SIZE - margin - 1, SIZE - margin - 1),
        radius=14,
        outline=(*light, 220),
        width=2,
    )
    img = Image.alpha_composite(img, border)

    # corner gem marker
    gem_c = _rgb_float(RARITY_COLORS[rarity])
    gx, gy = SIZE - 22, 10
    gem = ImageDraw.Draw(img)
    gem.polygon(
        [(gx, gy + 6), (gx + 6, gy), (gx + 12, gy + 6), (gx + 6, gy + 12)],
        fill=(*gem_c, 240),
        outline=(255, 255, 255, 180),
    )
    return img


def _hash_hue(item_id: str) -> float:
    digest = hashlib.md5(item_id.encode()).hexdigest()
    return int(digest[:2], 16) / 255.0


def remove_matte_bg(
    img: Image.Image, dark_threshold: int = 28, light_threshold: int = 220
) -> Image.Image:
    img = img.convert("RGBA")
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            if r <= dark_threshold and g <= dark_threshold and b <= dark_threshold:
                px[x, y] = (r, g, b, 0)
            elif r >= light_threshold and g >= light_threshold and b >= light_threshold:
                px[x, y] = (r, g, b, 0)
            elif max(r, g, b) - min(r, g, b) < 18 and min(r, g, b) > 170:
                px[x, y] = (r, g, b, 0)
    return img


def tint_image(img: Image.Image, hue: float, sat_mult: float = 1.15) -> Image.Image:
    if hue is None:
        return img
    img = img.convert("RGBA")
    rgb = img.split()[0:3]
    base = Image.merge("RGB", rgb)
    hsv = base.convert("HSV")
    h, s, v = hsv.split()
    h_data = h.load()
    s_data = s.load()
    target = int(hue * 255) % 256
    for y in range(h.size[1]):
        for x in range(h.size[0]):
            if s_data[x, y] > 12:  # skip near-grayscale pixels
                h_data[x, y] = target
            s_data[x, y] = min(255, int(s_data[x, y] * sat_mult))
    tinted = Image.merge("HSV", (h, s, v)).convert("RGBA")
    tinted.putalpha(img.split()[3])
    return tinted


def pick_weapon_template(item_id: str, weapon_type: str) -> Path:
    templates = CANONICAL_TEMPLATES["weapon"]
    if any(k in item_id for k in ("dagger", "fang", "blade", "saw", "render", "knife")):
        if "great" in item_id or "cleaver" in item_id or "carver" in item_id or "edge" in item_id and "storm" not in item_id:
            pass
        elif "staff" not in item_id and "bow" not in item_id:
            if weapon_type == "dual_blades" or "blades" in item_id or "fang" in item_id:
                return templates["dual_blades"]
            if "dagger" in item_id or "sanctified" in item_id or "oathblade" in item_id or "tideblade" in item_id or "frostbrand" in item_id:
                return templates["dagger"]
    if weapon_type in templates:
        return templates[weapon_type]
    if "staff" in item_id:
        return templates["staff"]
    if "bow" in item_id:
        return templates["bow"]
    return templates["default"]


def pick_armor_template(rarity: int) -> Path:
    return (
        CANONICAL_TEMPLATES["armor"]["heavy"]
        if rarity >= 2
        else CANONICAL_TEMPLATES["armor"]["light"]
    )


def compose_icon(template_path: Path, item_id: str, element: str, rarity: int) -> Image.Image:
    # 背景は UI 側の枠線で表現するため、スプライトのみを透過 PNG に合成する。
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    sprite = Image.open(template_path)
    sprite = remove_matte_bg(sprite)

    hue = ELEMENT_HUE.get(element)
    if hue is None:
        hue = _hash_hue(item_id)
    sprite = tint_image(sprite, hue)

    tw = int(SIZE * ICON_SCALE)
    th = int(tw * sprite.height / sprite.width)
    sprite = sprite.resize((tw, th), Image.Resampling.NEAREST)
    ox = (SIZE - tw) // 2
    oy = (SIZE - th) // 2 + 2

    if rarity >= 2:
        sprite = ImageEnhance.Brightness(sprite).enhance(1.08)
        sprite = ImageEnhance.Contrast(sprite).enhance(1.06)
    if rarity >= 3:
        glow = sprite.filter(ImageFilter.GaussianBlur(2))
        glow = ImageEnhance.Brightness(glow).enhance(1.4)
        glow_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        glow_layer.paste(glow, (ox, oy), glow)
        canvas = Image.alpha_composite(canvas, glow_layer)

    canvas.paste(sprite, (ox, oy), sprite)
    return canvas


def pick_material_template(item_id: str, category: str, rarity: int) -> Path:
    templates = CANONICAL_TEMPLATES["material"]
    if item_id == "elite_relic_shard":
        return templates["elite_relic"]
    if category in templates:
        return templates[category]
    if "crystal" in item_id or "azure" in item_id:
        return templates["crystal_core"]
    if "bone" in item_id or "fang" in item_id:
        return templates["bone"]
    if "iron" in item_id or "metal" in item_id:
        return templates["metal"]
    if "leather" in item_id or "fur" in item_id:
        return templates["hide"]
    return templates["default"]


def material_element_hint(item_id: str, category: str) -> str:
    if any(k in item_id for k in ("azure", "crystal", "frost", "ice")):
        return "ice"
    if any(k in item_id for k in ("chrono", "clock", "resonance")):
        return "thunder"
    if any(k in item_id for k in ("dragon", "royal", "gold", "gem")):
        return "holy"
    if any(k in item_id for k in ("cursed", "umbral", "parasitic")):
        return "dark"
    if category in ("crystal_core", "heart", "spike"):
        return "ice"
    return ""


def output_name(category: str, item_id: str) -> str:
    prefix = {"weapon": "WPN", "armor": "ARM", "accessory": "ACC", "material": "MAT"}[category]
    return f"ICO_{prefix}_{snake_to_pascal(item_id)}.png"


def generate_equipment() -> list[tuple[str, str, str]]:
    EQUIP_OUT_DIR.mkdir(parents=True, exist_ok=True)
    mappings: list[tuple[str, str, str]] = []

    for folder, category in (
        ("weapons", "weapon"),
        ("armors", "armor"),
        ("accessories", "accessory"),
    ):
        for tres in sorted((ROOT / "resources" / folder).glob("*.tres")):
            data = parse_tres(tres)
            item_id = data.get("id", "")
            if not item_id or item_id in SKIP_IDS:
                continue
            rarity = int(data.get("rarity", "0"))
            element = data.get("element", "")
            fname = output_name(category, item_id)
            out_path = EQUIP_OUT_DIR / fname
            if category == "weapon" and item_id in LEGENDARY_HAND_DRAWN_WEAPON_IDS:
                if out_path.exists():
                    mappings.append(
                        (category, item_id, f"res://assets/ui/equipment/{fname}")
                    )
                    print(f"  {category}:{item_id} skip hand-drawn -> {fname}")
                    continue

            if category == "weapon":
                template = pick_weapon_template(item_id, data.get("weapon_type", "greatsword"))
            elif category == "armor":
                template = pick_armor_template(rarity)
            else:
                template = CANONICAL_TEMPLATES["accessory"]["default"]

            icon = compose_icon(template, item_id, element, rarity)
            icon.save(out_path, "PNG")
            mappings.append(
                (category, item_id, f"res://assets/ui/equipment/{fname}")
            )
            print(f"  {category}:{item_id} r{rarity} -> {fname}")

    return mappings


def generate_materials() -> list[tuple[str, str, str]]:
    MAT_OUT_DIR.mkdir(parents=True, exist_ok=True)
    mappings: list[tuple[str, str, str]] = []

    for tres in sorted((ROOT / "resources/materials").glob("*.tres")):
        data = parse_tres(tres)
        item_id = data.get("id", "")
        if not item_id:
            continue
        rarity = int(data.get("rarity", "0"))
        category = data.get("category", "relic")
        element = material_element_hint(item_id, category)
        template = pick_material_template(item_id, category, rarity)
        icon = compose_icon(template, item_id, element, rarity)
        fname = output_name("material", item_id)
        out_path = MAT_OUT_DIR / fname
        icon.save(out_path, "PNG")
        mappings.append(
            ("material", item_id, f"res://assets/ui/materials/{fname}")
        )
        print(f"  material:{item_id} r{rarity} ({category}) -> {fname}")

    return mappings


def update_icon_paths(mappings: list[tuple[str, str, str]]) -> None:
    path = ROOT / "scripts/ui/IconPaths.gd"
    text = path.read_text(encoding="utf-8")

    for category, item_id, res_path in mappings:
        key = f'"{category}:{item_id}"'
        pattern = rf'(\t{re.escape(key)}:\s*")([^"]+)(")'
        if re.search(pattern, text):
            text = re.sub(pattern, rf"\1{res_path}\3", text)
        else:
            anchors = [
                f'"{category}:unidentified"',
                '"currency:arcane_crystal"',
                '"enemy:sepia_hound"',
            ]
            insert = f'\t"{category}:{item_id}":           "{res_path}",\n'
            for anchor in anchors:
                needle = f"\t{anchor}"
                if needle in text:
                    text = text.replace(needle, insert + needle, 1)
                    break

    path.write_text(text, encoding="utf-8")


if __name__ == "__main__":
    print("Generating equipment icons...")
    equip_maps = generate_equipment()
    print(f"Generated {len(equip_maps)} equipment icons.")
    print("Generating material icons...")
    mat_maps = generate_materials()
    print(f"Generated {len(mat_maps)} material icons.")
    all_maps = equip_maps + mat_maps
    print("Updating IconPaths.gd...")
    update_icon_paths(all_maps)
    print("Done.")
