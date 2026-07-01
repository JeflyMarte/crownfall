class_name EquipmentUiHelper
extends RefCounted

const RARITY_GEMS: Array[String] = ["◇", "◆", "✦", "★"]

static func rarity_gem(rarity: int) -> String:
	return RARITY_GEMS[clampi(rarity, 0, RARITY_GEMS.size() - 1)]

static func enhance_badge(item: Resource, category: String) -> String:
	if category != "weapon" or item == null:
		return ""
	var level: int = EquipmentEnhancer.get_enhance_level(item)
	if level <= 0:
		return ""
	return "+%d" % level

static func sort_inventory_entries(entries: Array) -> Array:
	var sorted: Array = entries.duplicate()
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var item_a: Resource = a.get("item")
		var item_b: Resource = b.get("item")
		var cat_a: String = str(a.get("category", ""))
		var cat_b: String = str(b.get("category", ""))
		var rarity_a: int = _entry_rarity(item_a, cat_a)
		var rarity_b: int = _entry_rarity(item_b, cat_b)
		if rarity_a != rarity_b:
			return rarity_a > rarity_b
		return _entry_sort_name(item_a, cat_a) < _entry_sort_name(item_b, cat_b)
	)
	return sorted

static func _entry_rarity(item: Resource, category: String) -> int:
	if item == null:
		return 0
	match category:
		"weapon":
			var wd: Resource = DataRegistry.get_weapon_data(str(item.weapon_id))
			return int(wd.rarity) if wd != null else 0
		"armor":
			var ad: Resource = DataRegistry.get_armor_data(str(item.armor_id))
			return int(ad.rarity) if ad != null else 0
		"accessory":
			var ac: Resource = DataRegistry.get_accessory_data(str(item.accessory_id))
			return int(ac.rarity) if ac != null else 0
	return 0

static func _entry_sort_name(item: Resource, category: String) -> String:
	if item == null:
		return ""
	match category:
		"weapon":
			return EquipmentEnhancer.get_display_name(item)
		"armor":
			return DataRegistry.get_armor_name(str(item.armor_id))
		"accessory":
			return DataRegistry.get_accessory_name(str(item.accessory_id))
	return ""
