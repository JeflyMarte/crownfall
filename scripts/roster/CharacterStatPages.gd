class_name CharacterStatPages
extends RefCounted

## キャラ画面カード StatsGrid のページ切替（P3-UX-CHR-STAT-PAGES-001）。
## 装備タブ「装備中の効果」も同3ページ（P3-UX-CHR-EFFECT-PAGES-001）。
## 0=基本 / 1=特殊 / 2=詳細。行数は各ページ6前後でカード高を揃える。

const _AffixStatCalculator := preload("res://scripts/equipment/AffixStatCalculator.gd")
const _WeaponStatResolver := preload("res://scripts/equipment/WeaponStatResolver.gd")
const _ArmorStatResolver := preload("res://scripts/equipment/ArmorStatResolver.gd")
const _AccessoryStatResolver := preload("res://scripts/equipment/AccessoryStatResolver.gd")
const _ElementResolver := preload("res://scripts/combat/ElementResolver.gd")
const _CombatTags := preload("res://scripts/combat/CombatTags.gd")

const PAGE_BASIC: int = 0
const PAGE_SPECIAL: int = 1
const PAGE_DETAIL: int = 2
const PAGE_COUNT: int = 3

const PAGE_TITLES: PackedStringArray = ["基本", "特殊", "詳細"]

const _STATUS_FALLBACK: Dictionary = {
	"poison": "毒",
	"chill": "冷気",
	"shock": "感電",
	"ignite": "炎上",
	"curse": "呪詛",
	"stun": "気絶",
	"bleed": "出血",
}


static func clamp_page(page: int) -> int:
	return clampi(page, 0, PAGE_COUNT - 1)


static func page_title(page: int) -> String:
	var p: int = clamp_page(page)
	return str(PAGE_TITLES[p])


## rows: [{ "key": String, "label": String, "value": String }, ...]
static func rows_for_page(member: Resource, page: int, basic_stats: Dictionary) -> Array:
	match clamp_page(page):
		PAGE_SPECIAL:
			return _special_rows(member)
		PAGE_DETAIL:
			return _detail_rows(member)
		_:
			return _basic_rows(basic_stats)


## 装備タブ「装備中の効果」。基本は装備寄与（+表記）、特殊／詳細は装備由来 summarize。
## basic_bonuses: attack/defense/hp/crit_rate/crit_damage/attack_speed
static func equipment_effect_rows_for_page(
	member: Resource,
	page: int,
	basic_bonuses: Dictionary
) -> Array:
	match clamp_page(page):
		PAGE_SPECIAL:
			return _special_rows(member)
		PAGE_DETAIL:
			return _detail_rows(member)
		_:
			return _equipment_basic_effect_rows(basic_bonuses)


## 既存 EffectsGrid の並び（攻撃|会心率／防御|会心ダメ／HP|速度）。
static func _equipment_basic_effect_rows(bonuses: Dictionary) -> Array:
	return [
		_row("attack", "攻撃力", _format_effect_int(int(bonuses.get("attack", 0)))),
		_row(
			"crit_rate",
			"クリティカル率",
			_format_effect_percent(float(bonuses.get("crit_rate", 0.0)))
		),
		_row("defense", "防御力", _format_effect_int(int(bonuses.get("defense", 0)))),
		_row(
			"crit_damage",
			"クリティカルダメージ",
			_format_effect_percent(float(bonuses.get("crit_damage", 0.0)))
		),
		_row("hp", "HP", _format_effect_int(int(bonuses.get("hp", 0)))),
		_row(
			"speed",
			"攻撃速度",
			_format_effect_speed(float(bonuses.get("attack_speed", 0.0)))
		),
	]


static func _format_effect_int(value: int) -> String:
	return "+%d" % value


static func _format_effect_percent(value: float) -> String:
	return "+%.0f%%" % (value * 100.0)


static func _format_effect_speed(value: float) -> String:
	if is_zero_approx(value):
		return "+0"
	return "+%.1f" % value


static func _basic_rows(stats: Dictionary) -> Array:
	return [
		_row("hp", "HP", str(int(stats.get("hp", 0)))),
		_row("attack", "攻撃力", str(int(stats.get("attack", 0)))),
		_row("defense", "防御力", str(int(stats.get("defense", 0)))),
		_row("speed", "速度", "%.1f" % float(stats.get("speed", 0.0))),
		_row("crit_rate", "会心率", "%.0f%%" % (float(stats.get("crit_rate", 0.0)) * 100.0)),
		_row("crit_damage", "会心ダメ", "%.0f%%" % (float(stats.get("crit_damage", 0.0)) * 100.0)),
	]


static func _special_rows(member: Resource) -> Array:
	var snap: Dictionary = summarize(member)
	return [
		_row("element", "属性", str(snap.get("element_label", "なし"))),
		_row("element_power", "属性値", str(snap.get("element_power_label", "—"))),
		_row("resist", "耐性", str(snap.get("resist_label", "なし"))),
		_row("gold_gain", "Gold獲得", str(snap.get("gold_label", "+0%"))),
		_row("exp_gain", "EXP獲得", str(snap.get("exp_label", "+0%"))),
		_row("rare_drop", "レアドロ", str(snap.get("rare_drop_label", "+0%"))),
	]


static func _detail_rows(member: Resource) -> Array:
	var snap: Dictionary = summarize(member)
	return [
		_row("material_gain", "素材獲得", str(snap.get("material_label", "+0"))),
		_row("on_hit_status", "状態付与", str(snap.get("status_label", "なし"))),
		_row("bane", "生態特効", str(snap.get("bane_label", "なし"))),
		_row("healing", "回復量", str(snap.get("healing_label", "+0"))),
		_row("evasion", "回避", str(snap.get("evasion_label", "+0%"))),
		_row("immunity", "異常無効", str(snap.get("immunity_label", "なし"))),
	]


static func summarize(member: Resource) -> Dictionary:
	var out: Dictionary = {
		"element_label": "なし",
		"element_power_label": "—",
		"resist_label": "なし",
		"gold_label": "+0%",
		"exp_label": "+0%",
		"rare_drop_label": "+0%",
		"material_label": "+0",
		"status_label": "なし",
		"bane_label": "なし",
		"healing_label": "+0",
		"evasion_label": "+0%",
		"immunity_label": "なし",
	}
	if member == null:
		return out
	var weapon: Resource = member.equipped_weapon if "equipped_weapon" in member else null
	var armor: Resource = member.equipped_armor if "equipped_armor" in member else null
	var accessory: Resource = member.equipped_accessory if "equipped_accessory" in member else null
	var affix: Dictionary = _AffixStatCalculator.get_bonuses_for_member(member)
	var evasion_total: float = 0.0

	if weapon != null:
		var elem: String = _WeaponStatResolver.resolve_element(weapon)
		var elem_name: String = _ElementResolver.get_display_name(elem)
		if not elem_name.is_empty():
			out["element_label"] = elem_name
			var ep: int = _WeaponStatResolver.resolve_element_power(weapon)
			out["element_power_label"] = str(ep) if ep > 0 else "0"
		var bane: Dictionary = _WeaponStatResolver.resolve_bane(weapon)
		var bane_class: String = str(bane.get("class", ""))
		if not bane_class.is_empty():
			var mult: float = float(bane.get("mult", 1.3))
			out["bane_label"] = "%s ×%.1f" % [_bane_display(bane_class), mult]
		var sid: String = _WeaponStatResolver.resolve_on_hit_status_id(weapon)
		if not sid.is_empty():
			var chance: float = _WeaponStatResolver.resolve_on_hit_status_chance(weapon)
			out["status_label"] = "%s %.0f%%" % [_status_display(sid), chance * 100.0]

	if armor != null:
		var resists: Array[String] = _ArmorStatResolver.resolve_resist_elements(armor)
		if not resists.is_empty():
			var names: PackedStringArray = []
			for e in resists:
				var nm: String = _ElementResolver.get_display_name(str(e))
				if not nm.is_empty():
					names.append(nm)
			if not names.is_empty():
				out["resist_label"] = "・".join(names)
		evasion_total += _ArmorStatResolver.resolve_evasion_rate(armor)
		if "status_immunities" in armor and armor.status_immunities is Array:
			var imm_names: PackedStringArray = []
			for sid2 in armor.status_immunities:
				var inm: String = _status_display(str(sid2))
				if not inm.is_empty():
					imm_names.append(inm)
			if not imm_names.is_empty():
				out["immunity_label"] = "・".join(imm_names)

	if accessory != null:
		evasion_total += _AccessoryStatResolver.resolve_evasion_rate(accessory)

	## 報酬率: Affix 集計は装飾・防具込み（乗算は 1.0 基準）。
	var gold_mult: float = float(affix.get("gold_gain_mult", 1.0))
	var exp_mult: float = float(affix.get("exp_gain_mult", 1.0))
	var rare_add: float = float(affix.get("rare_drop_add", 0.0))
	out["gold_label"] = _format_rate_bonus(gold_mult - 1.0)
	out["exp_label"] = _format_rate_bonus(exp_mult - 1.0)
	out["rare_drop_label"] = _format_rate_bonus(rare_add)
	out["material_label"] = "+%d" % int(affix.get("material_gain_bonus", 0))
	out["healing_label"] = "+%d" % int(affix.get("healing_bonus", 0))
	out["evasion_label"] = _format_rate_bonus(evasion_total)
	return out


static func _format_rate_bonus(add: float) -> String:
	if is_zero_approx(add):
		return "+0%"
	return "%+.0f%%" % (add * 100.0)


static func _status_display(status_id: String) -> String:
	if status_id.is_empty():
		return ""
	if _CombatTags.is_known(status_id):
		return _CombatTags.display_name(status_id)
	return str(_STATUS_FALLBACK.get(status_id, status_id))


static func _bane_display(bane_class: String) -> String:
	match bane_class:
		"beast":
			return "獣特効"
		"undead":
			return "不死特効"
		"construct":
			return "構造特効"
		"dragon":
			return "竜特効"
		"insect":
			return "蟲特効"
		_:
			return bane_class if not bane_class.is_empty() else "特効"


static func _row(key: String, label: String, value: String) -> Dictionary:
	return {"key": key, "label": label, "value": value}
