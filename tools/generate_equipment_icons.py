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
	"seam_breaker_maul",
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
	"abyss_veinblade",
	"abyss_rootfang",
	"abyss_mirestaff",
	"abyss_netherbow",
	"abyss_riftclaw",
	"volley_horizon_bow",
	"vanguard_war_bow",
	"regicide_longbow",
	"amplify_orb_staff",
	"silent_rite_staff",
	"packbond_staff",
	"mendweaver_staff",
	"blightcord_bow",
	"pulsekeen_edge",
	"aegis_line_sword",
	"coil_spring_dual",
	"pyrebrand_maul",
	"chronos_toki_sword",
	"chronos_toki_dual",
	"chronos_toki_staff",
	"chronos_toki_bow",
	"valgard_antique_blade",
	"valgard_antique_dual",
	"valgard_antique_rod",
	"valgard_antique_arrow",
	"albark_namerefuse_sword",
	"albark_namerefuse_dual",
	"albark_namerefuse_staff",
	"albark_namerefuse_bow",
	"albark_namerefuse_hammer",
	"forge_slag_sword",
	"forge_slag_dual",
	"forge_slag_staff",
	"forge_slag_bow",
	"forge_slag_hammer",
	# 灰冠の九（手描きAI初版・再生成スキップ）
	"kaiwan_crosslit",
	"kaiwan_vendict",
	"kaiwan_silent",
	"kaiwan_perfidy",
	"kaiwan_nox",
	"kaiwan_false",
	"kaiwan_saltine",
	"kaiwan_wiltes",
	"kaiwan_relictos",
}

## 戦鎚梯子A — 手描きICO接続済（P3-EQ-WARHAMMER-001-A）。再生成で上書きしない。
WARHAMMER_HAND_DRAWN_WEAPON_IDS: set[str] = {
	"iron_warhammer",
	"mire_warhammer",
	"verdant_maul",
	"ridge_maul",
	"black_sand_maul",
	"storm_maul",
	"pyre_maul",
	"glacier_maul",
	"lighthouse_maul",
	"thunderfen_maul",
	"symbiont_maul",
	"permafrost_maul",
	"sanctum_tide_maul",
	"seam_breaker_maul",
}

## 専用生成済みレジェンド防具（テンプレ流用防止）。
LEGENDARY_HAND_DRAWN_ARMOR_IDS: set[str] = {
	"serdion_ward_plate",
	"granvel_bark_plate",
	"moldgar_abyss_mail",
	"nereion_tide_plate",
	"eldion_glacier_aegis",
	"immortal_cenotaph_plate",
	"chronos_toki_armor",
	"valgard_antique_armor",
	"albark_namerefuse_armor",
	"forge_slag_armor",
	"kaiwan_primehide",
	"kaiwan_bloodmail",
	"kaiwan_voidrobe",
	"kaiwan_oathbreak",
	"kaiwan_duskmail",
	"kaiwan_forgepate",
	"kaiwan_tideskin",
	"kaiwan_thornmail",
	"kaiwan_lastcoil",
	# ビルド拡張L（P3-EQ-LEG-BUILD-001）
	"bloodpact_plate",
	"flurry_light_mail",
	"bulwark_role_plate",
	"cover_aegis_cloak",
	"hexweave_robe",
	# ペット／ヒーラービルドL（P3-EQ-PET-HEAL-BUILD-001）
	"beastcall_mantle",
	"field_salve_robe",
}

## 専用生成済みレジェンド装飾。
LEGENDARY_HAND_DRAWN_ACCESSORY_IDS: set[str] = {
	"mourngate_royal_seal",
	"silvaria_covenant_ring",
	"seradis_archive_seal",
	"frostridge_boundary_signet",
	"pharos_beacon_ring",
	"council_hegemony_seal",
	"chronos_toki_orb",
	"valgard_antique_amulet",
	"albark_namerefuse_circlet",
	"forge_slag_seal",
	"kaiwan_initio",
	"kaiwan_venomband",
	"kaiwan_unlock",
	"kaiwan_curseband",
	"kaiwan_nocturne",
	"kaiwan_sparkle",
	"kaiwan_reefhook",
	"kaiwan_wither",
	"kaiwan_nextedge",
	# ビルド拡張L（P3-EQ-LEG-BUILD-001）
	"blade_dance_ring",
	"pierce_charm",
	"pulse_amulet",
	"beastlord_fang",
	"apothecary_vial",
	# クラシックL装飾補充（P3-EQ-CLASSIC-L-ACC-001）
	"bloodvein_signet",
	"ironvow_amulet",
	"quicksigil_charm",
	"dawnrally_brooch",
	"trapgear_charm",
	"overheat_amulet",
	"seam_focus_sigil",
}

CANONICAL_TEMPLATES = {
    "weapon": {
        "sword": TEMPLATE_DIR / "equipment/ICO_WPN_IronSword.png",
        "greatsword": TEMPLATE_DIR / "equipment/ICO_WPN_IronSword.png",  # 旧互換
        "bow": TEMPLATE_DIR / "equipment/ICO_WPN_HuntingBow.png",
        "staff": TEMPLATE_DIR / "equipment/ICO_WPN_ApprenticeStaff.png",
        "dual_blades": TEMPLATE_DIR / "equipment/ICO_WPN_BoltKnife.png",
        "dagger": TEMPLATE_DIR / "equipment/ICO_WPN_SanctifiedDagger.png",
        "hammer": TEMPLATE_DIR / "equipment/ICO_WPN_IronWarhammer.png",
        "default": TEMPLATE_DIR / "equipment/ICO_WPN_HeaterBlade.png",
    },
    "armor": {
        ## 再生成で上書きしないよう _templates を正とする（ensure_armor_templates）。
        "light": TEMPLATE_DIR / "equipment/_templates/ICO_ARM_Light.png",
        "heavy": TEMPLATE_DIR / "equipment/_templates/ICO_ARM_Heavy.png",
    },
    "accessory": {
        "ring": TEMPLATE_DIR / "equipment/_templates/ICO_ACC_Generic_Ring.png",
        "charm": TEMPLATE_DIR / "equipment/_templates/ICO_ACC_Generic_Charm.png",
        "talisman": TEMPLATE_DIR / "equipment/_templates/ICO_ACC_Generic_Talisman.png",
        "seal": TEMPLATE_DIR / "equipment/_templates/ICO_ACC_Generic_Seal.png",
        "default": TEMPLATE_DIR / "equipment/_templates/ICO_ACC_Generic_Ring.png",
    },
    "material": {
        "relic": TEMPLATE_DIR / "materials/ICO_MAT_RelicShard.png",
        "ore": TEMPLATE_DIR / "materials/ICO_MAT_BaseOre.png",
        "elite_relic": TEMPLATE_DIR / "materials/ICO_MAT_EliteRelicShard.png",
        "bone": TEMPLATE_DIR / "materials/ICO_MAT_AncientBone.png",
        "metal": TEMPLATE_DIR / "materials/ICO_MAT_CursedIron.png",
        "hide": TEMPLATE_DIR / "materials/ICO_MAT_Leather.png",
        "fur": TEMPLATE_DIR / "materials/ICO_MAT_Leather.png",
        "crystal_core": TEMPLATE_DIR / "materials/ICO_MAT_BaseOre.png",
        "heart": TEMPLATE_DIR / "materials/ICO_MAT_BaseOre.png",
        "spike": TEMPLATE_DIR / "materials/ICO_MAT_BaseOre.png",
        "fang": TEMPLATE_DIR / "materials/ICO_MAT_AncientBone.png",
        "feather": TEMPLATE_DIR / "materials/ICO_MAT_Leather.png",
        "dust": TEMPLATE_DIR / "materials/ICO_MAT_BaseOre.png",
        "carapace": TEMPLATE_DIR / "materials/ICO_MAT_AncientBone.png",
        "antenna": TEMPLATE_DIR / "materials/ICO_MAT_CursedIron.png",
        "gem": TEMPLATE_DIR / "materials/ICO_MAT_EliteRelicShard.png",
        "default": TEMPLATE_DIR / "materials/ICO_MAT_BaseOre.png",
    },
}

SIZE = 128
ICON_SCALE = 0.82
ARMOR_TEMPLATE_SEED_LIGHT = TEMPLATE_DIR / "equipment/ICO_ARM_LeatherArmor.png"
ARMOR_TEMPLATE_SEED_HEAVY = TEMPLATE_DIR / "equipment/ICO_ARM_BoneArmor.png"


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


def ensure_armor_templates() -> None:
	"""再生成でシードを壊さないよう、初回だけ _templates に退避する。"""
	light = CANONICAL_TEMPLATES["armor"]["light"]
	heavy = CANONICAL_TEMPLATES["armor"]["heavy"]
	light.parent.mkdir(parents=True, exist_ok=True)
	if not light.exists():
		src = ARMOR_TEMPLATE_SEED_LIGHT if ARMOR_TEMPLATE_SEED_LIGHT.exists() else ARMOR_TEMPLATE_SEED_HEAVY
		Image.open(src).convert("RGBA").save(light, "PNG")
		print(f"  seeded armor light template -> {light.relative_to(ROOT)}")
	if not heavy.exists():
		src = ARMOR_TEMPLATE_SEED_HEAVY if ARMOR_TEMPLATE_SEED_HEAVY.exists() else ARMOR_TEMPLATE_SEED_LIGHT
		Image.open(src).convert("RGBA").save(heavy, "PNG")
		print(f"  seeded armor heavy template -> {heavy.relative_to(ROOT)}")


def infer_accessory_type(item_id: str) -> str:
    """Mirror AccessoryIconHelper.infer_type (keep in sync)."""
    id_ = (item_id or "").lower()
    if any(k in id_ for k in ("seal", "sigil")):
        return "seal"
    if any(k in id_ for k in ("charm", "brooch", "lantern")):
        return "charm"
    if any(k in id_ for k in ("talisman", "amulet", "orb")):
        return "talisman"
    if any(k in id_ for k in ("ring", "signet", "band")):
        return "ring"
    return "ring"


def pick_accessory_template(item_id: str) -> Path:
    templates = CANONICAL_TEMPLATES["accessory"]
    acc_type = infer_accessory_type(item_id)
    return templates.get(acc_type, templates["default"])


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


def pick_armor_template(item_id: str, rarity: int) -> Path:
	ensure_armor_templates()
	light_keys = ("cloak", "garb", "robe", "vestment", "vest", "linen", "cloth", "hide")
	heavy_keys = ("plate", "mail", "aegis", "armor", "scale", "chitin", "bone")
	lid = item_id.lower()
	if any(k in lid for k in light_keys) and not any(k in lid for k in ("plate", "mail", "aegis")):
		return CANONICAL_TEMPLATES["armor"]["light"]
	if any(k in lid for k in heavy_keys):
		return CANONICAL_TEMPLATES["armor"]["heavy"]
	return (
		CANONICAL_TEMPLATES["armor"]["heavy"]
		if rarity >= 2
		else CANONICAL_TEMPLATES["armor"]["light"]
	)


## 素材名ヒント → 色相（耐性 element より優先。革が氷青になる事故を防ぐ）。
MATERIAL_HUE = {
	"leather": 0.07,
	"hide": 0.07,
	"fur": 0.08,
	"cloth": 0.58,
	"cloak": 0.62,
	"garb": 0.10,
	"robe": 0.78,
	"vestment": 0.12,
	"vest": 0.72,
	"linen": 0.11,
	"plate": 0.58,
	"mail": 0.55,
	"scale": 0.42,
	"bone": 0.10,
	"chitin": 0.09,
	"crystal": 0.72,
	"bark": 0.08,
	"moss": 0.28,
	"kelp": 0.38,
	"tide": 0.52,
	"snow": 0.55,
	"glacier": 0.55,
	"dragon": 0.03,
	"wyvern": 0.78,
	"rune": 0.70,
	"crypt": 0.75,
	"votive": 0.12,
	"warden": 0.55,
	"libris": 0.70,
	"aurora": 0.55,
	"moldgar": 0.30,
	"mourngate": 0.78,
	"ship": 0.58,
	"whale": 0.55,
	"mycel": 0.30,
	"bog": 0.28,
	"mire": 0.10,
	"sepia": 0.08,
	"lament": 0.75,
}


def _armor_material_key(item_id: str) -> str:
	lid = item_id.lower()
	## 長い／具体キーを先に。
	ordered = sorted(MATERIAL_HUE.keys(), key=len, reverse=True)
	for key in ordered:
		if key in lid:
			return key
	return ""


def _armor_hue(item_id: str, element: str) -> float:
	## 素材名ベース。耐性 element はフォールバックのみ（革+ice≠シアン）。
	mat = _armor_material_key(item_id)
	if mat:
		return float(MATERIAL_HUE[mat])
	hue = ELEMENT_HUE.get(element)
	if hue is not None:
		return float(hue)
	return _hash_hue(item_id)


def lift_crushed_blacks(img: Image.Image, floor: int = 38) -> Image.Image:
	"""不透明な潰れた黒を少し持ち上げ、セル背景との同化を防ぐ。"""
	img = img.convert("RGBA")
	px = img.load()
	w, h = img.size
	for y in range(h):
		for x in range(w):
			r, g, b, a = px[x, y]
			if a < 40:
				continue
			mx = max(r, g, b)
			if mx >= floor:
				continue
			# 黒寄りを floor 付近まで持ち上げ（色相は維持）
			scale = float(floor) / float(max(1, mx))
			nr = min(255, int(r * scale))
			ng = min(255, int(g * scale))
			nb = min(255, int(b * scale))
			px[x, y] = (nr, ng, nb, a)
	return img


def apply_color_wash(img: Image.Image, hue: float, strength: float = 0.42) -> Image.Image:
	"""グレー金属にも効く色ウォッシュ（HSV の S が低い画素も染める）。"""
	img = img.convert("RGBA")
	arr_rgb = img.convert("RGB")
	wash_rgb = tuple(int(c * 255) for c in colorsys.hsv_to_rgb(hue % 1.0, 0.55, 0.92))
	wash = Image.new("RGB", img.size, wash_rgb)
	# 不透明部だけブレンド
	alpha = img.split()[3]
	blended = Image.blend(arr_rgb, wash, max(0.0, min(1.0, strength)))
	out = blended.convert("RGBA")
	out.putalpha(alpha)
	return out


def add_silhouette_rim(img: Image.Image, rim_rgb: tuple[int, int, int] = (48, 42, 36)) -> Image.Image:
	"""シルエット外周に薄い暗いリム（クリーム halo 禁止）。"""
	img = img.convert("RGBA")
	alpha = img.split()[3]
	## 1px 相当（MaxFilter 3）で細い輪郭のみ。
	dilated = alpha.filter(ImageFilter.MaxFilter(3))
	rim_mask = ImageChops.subtract(dilated, alpha)
	rim_layer = Image.new("RGBA", img.size, (*rim_rgb, 0))
	rim_layer.putalpha(rim_mask.point(lambda v: 140 if v > 16 else 0))
	return Image.alpha_composite(rim_layer, img)


def compose_armor_icon(template_path: Path, item_id: str, element: str, rarity: int) -> Image.Image:
	"""N〜Epic 防具向け: 素材色分け＋軽い黒持ち上げ＋細い暗リム。"""
	canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
	sprite = Image.open(template_path).convert("RGBA")
	## 防具は暗い金属が本体なので、全域黒キーはしない（穴でセルが透ける）。
	## 端の白マットのみ弱く除去。
	sprite = remove_matte_bg(sprite, dark_threshold=8, light_threshold=235)
	sprite = lift_crushed_blacks(sprite, floor=34)

	hue = _armor_hue(item_id, element)
	## 個体差: hash でウォッシュ強さ・明るさを少しずらす（弱め＝素材色を残す）。
	digest = hashlib.md5(item_id.encode()).hexdigest()
	wash_boost = 0.12 + (int(digest[2:4], 16) / 255.0) * 0.10
	bright = 1.02 + (0.02 * rarity) + (int(digest[4:6], 16) / 255.0) * 0.04
	sprite = apply_color_wash(sprite, hue, strength=wash_boost)
	sprite = tint_image(sprite, hue, sat_mult=1.08)
	sprite = ImageEnhance.Brightness(sprite).enhance(bright)
	sprite = ImageEnhance.Contrast(sprite).enhance(1.04 + 0.02 * rarity)

	tw = int(SIZE * ICON_SCALE)
	th = int(tw * sprite.height / max(1, sprite.width))
	sprite = sprite.resize((tw, th), Image.Resampling.NEAREST)
	## リムはリサイズ後に付与（縮小で輪郭が消えないように）。
	sprite = add_silhouette_rim(sprite, rim_rgb=(48, 42, 36))
	ox = (SIZE - tw) // 2
	oy = (SIZE - th) // 2 + 2

	if rarity >= 2:
		glow = sprite.filter(ImageFilter.GaussianBlur(1))
		glow = ImageEnhance.Brightness(glow).enhance(1.12)
		glow_layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
		glow_layer.paste(glow, (ox, oy), glow)
		canvas = Image.alpha_composite(canvas, glow_layer)

	canvas.paste(sprite, (ox, oy), sprite)
	return canvas


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
    ## 現行炉研ぎ5種は専用PNGを正とする（IconPaths と一致）。
    dedicated = {
        "relic_shard": TEMPLATE_DIR / "materials/ICO_MAT_RelicShard.png",
        "base_ore": TEMPLATE_DIR / "materials/ICO_MAT_BaseOre.png",
        "epic_ore": TEMPLATE_DIR / "materials/ICO_MAT_EpicOre.png",
        "elite_relic_shard": TEMPLATE_DIR / "materials/ICO_MAT_EliteRelicShard.png",
        "ancient_bone": TEMPLATE_DIR / "materials/ICO_MAT_AncientBone.png",
    }
    if item_id in dedicated:
        return dedicated[item_id]
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


def generate_equipment(categories: set[str] | None = None) -> list[tuple[str, str, str]]:
    EQUIP_OUT_DIR.mkdir(parents=True, exist_ok=True)
    mappings: list[tuple[str, str, str]] = []
    if categories is None:
        categories = {"weapon", "armor", "accessory"}
    if "armor" in categories:
        ensure_armor_templates()

    for folder, category in (
        ("weapons", "weapon"),
        ("armors", "armor"),
        ("accessories", "accessory"),
    ):
        if category not in categories:
            continue
        for tres in sorted((ROOT / "resources" / folder).glob("*.tres")):
            data = parse_tres(tres)
            item_id = data.get("id", "")
            if not item_id or item_id in SKIP_IDS:
                continue
            rarity = int(data.get("rarity", "0"))
            element = data.get("element", "")
            fname = output_name(category, item_id)
            out_path = EQUIP_OUT_DIR / fname
            protected = (
                (category == "weapon" and item_id in LEGENDARY_HAND_DRAWN_WEAPON_IDS)
                or (category == "weapon" and item_id in WARHAMMER_HAND_DRAWN_WEAPON_IDS)
                or (category == "armor" and item_id in LEGENDARY_HAND_DRAWN_ARMOR_IDS)
                or (category == "accessory" and item_id in LEGENDARY_HAND_DRAWN_ACCESSORY_IDS)
            )
            if protected and out_path.exists():
                mappings.append(
                    (category, item_id, f"res://assets/ui/equipment/{fname}")
                )
                print(f"  {category}:{item_id} skip hand-drawn -> {fname}")
                continue

            if category == "weapon":
                template = pick_weapon_template(item_id, data.get("weapon_type", "sword"))
                icon = compose_icon(template, item_id, element, rarity)
            elif category == "armor":
                template = pick_armor_template(item_id, rarity)
                icon = compose_armor_icon(template, item_id, element, rarity)
            else:
                template = pick_accessory_template(item_id)
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
    import argparse

    parser = argparse.ArgumentParser(description="Generate equipment/material icons")
    parser.add_argument(
        "--armor-only",
        action="store_true",
        help="Regenerate armor icons only (skip weapons/accessories/materials)",
    )
    args = parser.parse_args()

    if args.armor_only:
        print("Generating armor icons only...")
        equip_maps = generate_equipment({"armor"})
        print(f"Generated {len(equip_maps)} armor icons.")
        print("Updating IconPaths.gd...")
        update_icon_paths(equip_maps)
        print("Done.")
    else:
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
