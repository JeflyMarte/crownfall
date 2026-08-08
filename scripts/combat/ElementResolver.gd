class_name ElementResolver
extends RefCounted

## モンハン型: 属性は弱点で追加ダメージ、耐性で軽減。無属性攻撃は倍率 1.0。

const WEAKNESS_MULTIPLIER: float = 1.25
const RESIST_MULTIPLIER: float = 0.75

const ELEMENT_NAMES: Dictionary = {
	"fire": "炎",
	"ice": "氷",
	"thunder": "電気",
	"dark": "闇",
	"holy": "聖",
}

## 別名 → 正規 id（表示・判定の両方で正規化）。
const ELEMENT_ALIASES: Dictionary = {
	"lightning": "thunder",
	"light": "holy",
}

## 武器名先頭用（「炎の」形式）。UI 表示名と戦闘内属性表示名は分離。
const ELEMENT_WEAPON_PREFIX: Dictionary = {
	"fire": "炎の",
	"ice": "氷の",
	"thunder": "雷の",
	"dark": "闇の",
	"holy": "聖の",
}

static func normalize_element_id(element_id: String) -> String:
	if element_id.is_empty():
		return ""
	return str(ELEMENT_ALIASES.get(element_id, element_id))

static func is_valid_element(element_id: String) -> bool:
	return ELEMENT_NAMES.has(normalize_element_id(element_id))

static func get_display_name(element_id: String) -> String:
	return str(ELEMENT_NAMES.get(normalize_element_id(element_id), ""))

static func get_weapon_prefix(element_id: String) -> String:
	var eid: String = normalize_element_id(element_id)
	if eid.is_empty() or not ELEMENT_NAMES.has(eid):
		return ""
	return str(ELEMENT_WEAPON_PREFIX.get(eid, ""))


## 属性攻撃スキル用の対応状態（炎→炎上など）。未対応は空。
static func status_id_for_element(element_id: String) -> String:
	match normalize_element_id(element_id):
		"fire":
			return "ignite"
		"ice":
			return "chill"
		"thunder":
			return "shock"
		"dark":
			return "curse"
		"holy":
			return "vulnerable"
		_:
			return ""

static func get_damage_multiplier(
	attack_element: String,
	weakness: Array[String],
	resist: Array[String] = []
) -> float:
	var eid: String = normalize_element_id(attack_element)
	if eid.is_empty() or not ELEMENT_NAMES.has(eid):
		return 1.0
	for w: String in weakness:
		if normalize_element_id(str(w)) == eid:
			return WEAKNESS_MULTIPLIER
	for r: String in resist:
		if normalize_element_id(str(r)) == eid:
			return RESIST_MULTIPLIER
	return 1.0
