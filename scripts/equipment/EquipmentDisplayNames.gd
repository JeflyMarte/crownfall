class_name EquipmentDisplayNames
extends RefCounted

const _WeaponStatResolver = preload("res://scripts/equipment/WeaponStatResolver.gd")
const _ElementResolver = preload("res://scripts/combat/ElementResolver.gd")

## 装備個体の表示名（パーフェクトロール⭐️はステータス行側で表示）。

static func get_instance_name(item: Resource, category: String) -> String:
	if item == null:
		return "—"
	var base_name: String = ""
	match category:
		"weapon":
			base_name = _weapon_base_name(item)
		"armor":
			base_name = DataRegistry.get_armor_name(str(item.armor_id))
			base_name += EquipmentEnhancer.format_equip_level_tag(item)
		"accessory":
			base_name = DataRegistry.get_accessory_name(str(item.accessory_id))
			base_name += EquipmentEnhancer.format_equip_level_tag(item)
		_:
			return "—"
	return base_name

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
