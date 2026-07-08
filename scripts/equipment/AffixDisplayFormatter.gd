class_name AffixDisplayFormatter
extends RefCounted

## M6 Affix 表示整形（P2-Task032）。UI 専用。gameplay 変更なし。

const PERCENT_STAT_TYPES: Array[String] = [
	"Gold Gain",
	"EXP Gain",
	"Rare Drop",
	"Critical",
	"Attack Speed",
	"Rare Drop Rate",
	"Chill",
	"Shock",
	"Poison",
	"Ignite",
]

const STAT_TYPE_LABELS: Dictionary = {
	"Attack": "攻撃",
	"Defense": "防御",
	"HP": "HP",
	"Chill": "冷却付与",
	"Shock": "感電付与",
	"Poison": "毒付与",
	"Ignite": "炎上付与",
	"Attack Speed": "攻撃速度",
	"Critical": "クリティカル率",
	"Gold Gain": "ゴールド獲得",
	"EXP Gain": "経験値獲得",
	"Healing": "回復量",
	"Material Gain": "素材獲得",
	"Rare Drop": "レアドロップ",
}

static func format_for_instance(item: Resource) -> String:
	if item == null or not item.is_appraised:
		return ""
	var prefix_ids: Array = item.prefix_ids if "prefix_ids" in item else []
	var suffix_ids: Array = item.suffix_ids if "suffix_ids" in item else []
	return format_affix_block(prefix_ids, suffix_ids)

static func format_affix_block(prefix_ids: Array, suffix_ids: Array) -> String:
	var effects: String = _format_effect_line(prefix_ids, suffix_ids)
	if effects.is_empty():
		return ""
	return "追加効果: %s" % effects

static func format_reveal(prefix_ids: Array, suffix_ids: Array) -> String:
	var names: String = _format_name_line(prefix_ids, suffix_ids)
	if names.is_empty():
		return ""
	return "【追加効果】" + names.replace(" / ", "・")

static func _format_name_line(prefix_ids: Array, suffix_ids: Array) -> String:
	var labels: PackedStringArray = []
	for affix_id in prefix_ids:
		labels.append(_affix_display_name(str(affix_id)))
	for affix_id in suffix_ids:
		labels.append(_affix_display_name(str(affix_id)))
	return " / ".join(labels)

static func _format_effect_line(prefix_ids: Array, suffix_ids: Array) -> String:
	var effects: PackedStringArray = []
	for affix_id in prefix_ids:
		_append_effect_label(effects, str(affix_id))
	for affix_id in suffix_ids:
		_append_effect_label(effects, str(affix_id))
	return " / ".join(effects)

static func _append_effect_label(target: PackedStringArray, affix_id: String) -> void:
	if affix_id.is_empty():
		return
	var affix_data: Resource = DataRegistry.get_affix_data(affix_id)
	if affix_data == null or affix_data.stat_type.is_empty():
		return
	var label: String = _stat_type_label(str(affix_data.stat_type))
	target.append("%s%s" % [label, _format_effect_value(
		str(affix_data.stat_type),
		float(affix_data.value)
	)])

static func _stat_type_label(stat_type: String) -> String:
	return str(STAT_TYPE_LABELS.get(stat_type, stat_type))

static func _affix_display_name(affix_id: String) -> String:
	if affix_id.is_empty():
		return ""
	var affix_data: Resource = DataRegistry.get_affix_data(affix_id)
	if affix_data != null and not affix_data.display_name.is_empty():
		return affix_data.display_name
	return affix_id

static func _format_effect_value(stat_type: String, value: float) -> String:
	if stat_type in PERCENT_STAT_TYPES:
		return "+%d%%" % int(round(value * 100.0))
	if is_equal_approx(value, float(int(value))):
		return "+%d" % int(value)
	return "+%.1f" % value

static func append_to_text(base_text: String, item: Resource) -> String:
	var affix_text: String = format_for_instance(item)
	if affix_text.is_empty():
		return base_text
	return base_text + "\n" + affix_text
