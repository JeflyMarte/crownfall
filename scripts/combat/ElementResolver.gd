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

static func is_valid_element(element_id: String) -> bool:
	return ELEMENT_NAMES.has(element_id)

static func get_display_name(element_id: String) -> String:
	return str(ELEMENT_NAMES.get(element_id, ""))

static func get_damage_multiplier(
	attack_element: String,
	weakness: Array[String],
	resist: Array[String] = []
) -> float:
	if attack_element.is_empty() or not is_valid_element(attack_element):
		return 1.0
	if attack_element in weakness:
		return WEAKNESS_MULTIPLIER
	if attack_element in resist:
		return RESIST_MULTIPLIER
	return 1.0
