class_name EquipmentDisplayNames
extends RefCounted

const _EquipmentRollHelper = preload("res://scripts/equipment/EquipmentRollHelper.gd")
const _WeaponStatResolver = preload("res://scripts/equipment/WeaponStatResolver.gd")
const _ElementResolver = preload("res://scripts/combat/ElementResolver.gd")

## 装備個体の表示名（パーフェクトロール⭐️付き）。

static func get_instance_name(item: Resource, category: String) -> String:
	if item == null:
		return "—"
	var base_name: String = ""
	match category:
		"weapon":
			base_name = _weapon_base_name(item)
		"armor":
			base_name = _armor_base_name(item)
		"accessory":
			base_name = _accessory_base_name(item)
		_:
			return "—"
	return base_name + _EquipmentRollHelper.perfect_roll_suffix(item)

static func _weapon_base_name(weapon: Resource) -> String:
	if weapon == null or str(weapon.weapon_id).is_empty():
		return ""
	var base_name: String = DataRegistry.get_weapon_name(str(weapon.weapon_id))
	var elem: String = _WeaponStatResolver.resolve_element(weapon)
	var prefix: String = _ElementResolver.get_weapon_prefix(elem)
	if not prefix.is_empty():
		base_name = prefix + base_name
	var level: int = EquipmentEnhancer.get_enhance_level(weapon)
	var lv_tag: String = EquipmentEnhancer.format_equip_level_tag(weapon)
	if level <= 0:
		return base_name + lv_tag
	return "%s%s +%d" % [base_name, lv_tag, level]

static func _armor_base_name(armor: Resource) -> String:
	if armor == null or str(armor.armor_id).is_empty():
		return ""
	var base_name: String = DataRegistry.get_armor_name(str(armor.armor_id))
	var lv_tag: String = EquipmentEnhancer.format_equip_level_tag(armor)
	var level: int = EquipmentEnhancer.get_enhance_level(armor)
	if level <= 0:
		return base_name + lv_tag
	return "%s%s +%d" % [base_name, lv_tag, level]

static func _accessory_base_name(accessory: Resource) -> String:
	if accessory == null or str(accessory.accessory_id).is_empty():
		return ""
	var base_name: String = DataRegistry.get_accessory_name(str(accessory.accessory_id))
	var lv_tag: String = EquipmentEnhancer.format_equip_level_tag(accessory)
	var level: int = EquipmentEnhancer.get_enhance_level(accessory)
	if level <= 0:
		return base_name + lv_tag
	return "%s%s +%d" % [base_name, lv_tag, level]
