class_name SkillIconHelper
extends RefCounted

## 味方スキル用ベースアイコン（最大10種）＋ジョブ色 tint。
## assets/ui/skills/base/ICO_SKILL_BASE_{Base}_fg.png（透過）を参照。
##
## アイコン方針（P3-UI-SKILL-ICON-C）:
## 1. 装備枠①②・通常表示 → make_ally_equipped_icon（ベース fg + パーティ色のみ）
## 2. 必殺スロット → make_ultimate_icon（個別 ICO_SKILL_* 優先 → なければベース+tint）
## 3. 敵・図鑑・MVP フォールバック → make_unique_icon（IconPaths 個別）
## 個別 ICO_SKILL_* は非必殺の装備スキル行では意図的に使わない。

const BASE_DIR: String = "res://assets/ui/skills/base/"
const DISPLAY_SIZE: Vector2 = Vector2(44, 44)

## 未インストールベースのフォールバック（将来ベース追加までの安全網）。
const BASE_ART_FALLBACK: Dictionary = {
	"buff": "heal",
	"ultimate": "slash",
}

const SKILL_TO_BASE: Dictionary = {
	"slash_attack": "slash",
	"swift_slash": "slash",
	"fierce_slash": "slash",
	"apex_slash": "slash",
	"chain_slash": "slash",
	"rend_slash": "slash",
	"armor_cleave": "slash",
	"pierce_line": "slash",
	"kindling_strike": "slash",
	"static_strike": "slash",
	"rime_touch": "slash",
	"sanctal_strike": "slash",
	"umbral_strike": "slash",
	"guard_strike": "guard",
	"iron_guard": "guard",
	"heavy_guard": "guard",
	"menace_strike": "guard",
	"stunning_blow": "guard",
	"fear_chain": "guard",
	"shield_ram": "guard",
	"break_stance": "guard",
	"apex_guard": "guard",
	"quick_shot": "bow",
	"power_shot": "bow",
	"aimed_shot": "bow",
	"apex_shot": "bow",
	"break_arrow": "bow",
	"vital_shot": "bow",
	"beast_bite": "bow",
	"apex_tame": "bow",
	"focus_mark": "mark",
	"hunter_mark": "mark",
	"mark_pursuit": "mark",
	"alpha_strike": "mark",
	"hex_bolt": "hex",
	"curse_sigil": "hex",
	"plague_bolt": "hex",
	"frail_dust": "hex",
	"vulnerable_surge": "hex",
	"arc_bolt": "hex",
	"apex_hex": "hex",
	"toxin_dart": "poison",
	"venom_burst": "poison",
	"snare_shot": "snare",
	"entangle": "snare",
	"hamstring_slash": "snare",
	"mend": "heal",
	"salve_burst": "heal",
	"empower": "buff",
	"herd_call": "buff",
	"ultimate_strike": "ultimate",
	"ouga_retsudan": "slash",
	"titan_roar": "guard",
	"grand_elixir": "heal",
	"dead_eye": "mark",
	"beast_dominion": "bow",
}


static func get_base_id(skill_id: String) -> String:
	return str(SKILL_TO_BASE.get(skill_id, ""))


static func resolve_base_id(skill_id: String) -> String:
	var base_id: String = get_base_id(skill_id)
	if base_id.is_empty():
		return ""
	while not base_id.is_empty() and not has_base_art(base_id):
		var fallback: String = str(BASE_ART_FALLBACK.get(base_id, ""))
		if fallback.is_empty() or fallback == base_id:
			return ""
		base_id = fallback
	return base_id


static func has_base_art(base_id: String) -> bool:
	return not base_id.is_empty() and ResourceLoader.exists(_fg_path(base_id))


static func make_unique_icon(skill_id: String, display_size: Vector2 = DISPLAY_SIZE) -> Control:
	var tex: Texture2D = IconPaths.get_icon_texture(skill_id, "skill")
	if tex == null:
		return null
	var icon := TextureRect.new()
	icon.texture = tex
	icon.custom_minimum_size = display_size
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


## 装備枠①②など — ベース fg + パーティ色（個別 ICO_SKILL_* は使わない）。
static func make_ally_equipped_icon(skill_id: String, member: Resource, display_size: Vector2 = DISPLAY_SIZE) -> Control:
	return make_icon(skill_id, member, display_size)


## 必殺スロット — 個別アイコン優先、なければベース+tint。
static func make_ultimate_icon(skill_id: String, member: Resource, display_size: Vector2 = DISPLAY_SIZE) -> Control:
	var icon: Control = make_unique_icon(skill_id, display_size)
	if icon != null:
		return icon
	return make_ally_equipped_icon(skill_id, member, display_size)


static func make_icon(skill_id: String, member: Resource, display_size: Vector2 = DISPLAY_SIZE) -> Control:
	var base_id: String = resolve_base_id(skill_id)
	if base_id.is_empty():
		return null
	return _make_layered_icon(base_id, member, display_size)


static func _make_layered_icon(base_id: String, member: Resource, display_size: Vector2) -> Control:
	var fg_tex: Texture2D = load(_fg_path(base_id)) as Texture2D
	if fg_tex == null:
		return null
	var icon := TextureRect.new()
	icon.texture = fg_tex
	icon.custom_minimum_size = display_size
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tint: Color = PartyLogColors.party_color(member)
	icon.modulate = Color(tint.r, tint.g, tint.b, 1.0)
	return icon


static func _fg_path(base_id: String) -> String:
	return BASE_DIR + "ICO_SKILL_BASE_%s_fg.png" % _base_file_token(base_id)


static func _base_file_token(base_id: String) -> String:
	return base_id.substr(0, 1).to_upper() + base_id.substr(1)
