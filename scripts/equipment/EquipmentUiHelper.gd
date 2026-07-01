class_name EquipmentUiHelper
extends RefCounted

const RARITY_GEMS: Array[String] = ["◇", "◆", "✦", "★"]
const LEVEL_CAP: int = 20

const SORT_LABELS: Dictionary = {
	"rarity": "レアリティ",
	"name": "名前",
}

const EQUIPPED_FILTER_LABELS: Dictionary = {
	"all": "すべて",
	"equipped": "装備中",
	"unequipped": "未装備",
}

static func rarity_gem(rarity: int) -> String:
	return RARITY_GEMS[clampi(rarity, 0, RARITY_GEMS.size() - 1)]

static func stars_text(rarity: int) -> String:
	return RosterUiHelper.stars_text(clampi(rarity, 1, 5))

static func level_line(level: int, max_level: int = LEVEL_CAP) -> String:
	return "Lv.%d / %d" % [clampi(level, 1, max_level), max_level]

static func enhance_badge(item: Resource, category: String) -> String:
	if category != "weapon" or item == null:
		return ""
	var level: int = EquipmentEnhancer.get_enhance_level(item)
	if level <= 0:
		return ""
	return "+%d" % level

static func equipped_member_index(item: Resource) -> int:
	if item == null:
		return -1
	return GameState.find_item_equipped_member_index(item)

static func equipped_owner_job_id(item: Resource) -> String:
	var idx: int = equipped_member_index(item)
	if idx < 0:
		return ""
	var member: Resource = GameState.get_member(idx)
	if member == null:
		return ""
	return str(member.job_id)

static func filter_by_equipped_state(
	entries: Array,
	state: String,
	member_index: int
) -> Array:
	if state == "all":
		return entries
	var out: Array = []
	for entry in entries:
		if entry is not Dictionary:
			continue
		var item: Resource = entry.get("item")
		var owner: int = equipped_member_index(item)
		var on_self: bool = owner == member_index
		if state == "equipped" and owner >= 0:
			out.append(entry)
		elif state == "unequipped" and owner < 0:
			out.append(entry)
		elif state == "equipped_self" and on_self:
			out.append(entry)
	return out

static func sort_inventory_entries(entries: Array, sort_by: String = "rarity") -> Array:
	var sorted: Array = entries.duplicate()
	if sort_by == "name":
		sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return _entry_sort_name(a.get("item"), str(a.get("category", ""))) < \
				_entry_sort_name(b.get("item"), str(b.get("category", "")))
		)
		return sorted
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
