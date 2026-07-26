class_name PassiveIconHelper
extends RefCounted

## パッシブアイコン。`assets/ui/passives/ICO_PASSIVE_{PascalCase}.png` を参照。
## キャラ固有などで専用PNGが無い場合は `ICON_ALIAS` / `ICON_PATH_OVERRIDE` へ。

const DISPLAY_SIZE: Vector2 = Vector2(44, 44)
const ROOT: String = "res://assets/ui/passives/"
const FALLBACK_PATH: String = ROOT + "ICO_PASSIVE_BattleFervor.png"

## 専用アート未作成 → 近い既存パッシブ id（職帯アイコン群）。
const ICON_ALIAS: Dictionary = {
	# 基本5人
	"ald_royal_flame": "sword_charge",
	"galen_sacred_bastion": "bulwark",
	"mirei_swarm_resonance": "pack_instinct",
	"elias_field_elixir": "spare_vial",
	# ガチャ助っ人
	"leon_sword_focus": "sword_charge",
	"durante_vial_echo": "spare_vial",
	"ivar_trail_sight": "foresight",
	"serin_quick_mend": "panacea_gift",
	"mira_beast_call": "tamer_whistle",
	"valden_iron_oath": "unyielding_stance",
	"kaida_arena_edge": "battle_fervor",
	"garm_caravan_guard": "greatshield_order",
	"lenore_seal_echo": "sword_charge",
	"torva_frost_breath": "battle_fervor",
	"borg_gate_voice": "wind_reading",
	"neri_waterfowl_call": "pack_instinct",
	"hodaka_blood_price": "battle_fervor",
	"sian_silent_line": "formation_eye",
}

## パッシブ群に近い絵が無い場合の直接パス（スキルベース等）。
const ICON_PATH_OVERRIDE: Dictionary = {
	"riva_lone_focus": "res://assets/ui/skills/base/ICO_SKILL_BASE_Poison_fg.png",
}


static func icon_path(passive_id: String) -> String:
	if passive_id.is_empty():
		return ""
	var parts: PackedStringArray = passive_id.split("_")
	var pascal: String = ""
	for part in parts:
		if part.is_empty():
			continue
		pascal += part.substr(0, 1).to_upper() + part.substr(1)
	if pascal.is_empty():
		return ""
	return ROOT + "ICO_PASSIVE_%s.png" % pascal


static func resolve_texture_path(passive_id: String) -> String:
	if passive_id.is_empty():
		return ""
	if ICON_PATH_OVERRIDE.has(passive_id):
		var override_path: String = str(ICON_PATH_OVERRIDE[passive_id])
		if not override_path.is_empty() and ResourceLoader.exists(override_path):
			return override_path
	var resolved_id: String = passive_id
	if ICON_ALIAS.has(passive_id):
		var alias_id: String = str(ICON_ALIAS[passive_id])
		if not alias_id.is_empty():
			resolved_id = alias_id
	var path: String = icon_path(resolved_id)
	if not path.is_empty() and ResourceLoader.exists(path):
		return path
	path = IconPaths.passive_icon_path(resolved_id)
	if not path.is_empty() and ResourceLoader.exists(path):
		return path
	## エイリアス解決後も無い場合のみ、元 id の IconPaths / Pascal を試す。
	if resolved_id != passive_id:
		path = icon_path(passive_id)
		if not path.is_empty() and ResourceLoader.exists(path):
			return path
		path = IconPaths.passive_icon_path(passive_id)
		if not path.is_empty() and ResourceLoader.exists(path):
			return path
	if ResourceLoader.exists(FALLBACK_PATH):
		return FALLBACK_PATH
	return ""


static func make_icon(passive_id: String, display_size: Vector2 = DISPLAY_SIZE) -> Control:
	var path: String = resolve_texture_path(passive_id)
	if path.is_empty():
		return null
	var tex: Texture2D = load(path) as Texture2D
	if tex == null:
		return null
	var icon := TextureRect.new()
	icon.texture = tex
	icon.custom_minimum_size = display_size
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon
