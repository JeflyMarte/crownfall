class_name EquipmentInventoryIndex
extends RefCounted

## 装備袋の表示用インデックス（B/C）。
## 袋の中身が変わったときだけ再構築し、UI はフィルタ／ソートで読むだけ。
## キャラ切替では触らない（装備者ハイライトは Owner キャッシュ＋セル差分）。

static var _signature: int = 0
static var _force_dirty: bool = true
static var _weapons: Array = []
static var _armors: Array = []
static var _accessories: Array = []
static var _relics: Array = []


static func mark_dirty() -> void:
	_force_dirty = true


static func reset_for_tests() -> void:
	_signature = 0
	_force_dirty = true
	_weapons.clear()
	_armors.clear()
	_accessories.clear()
	_relics.clear()


static func ensure_fresh() -> void:
	var sig: int = _compute_signature()
	if not _force_dirty and sig == _signature:
		return
	_rebuild_all()
	_signature = sig
	_force_dirty = false


## UI 向け: フィルタ済み＋ソート済みエントリ（item/relic_id/category/rarity/name）。
static func view_entries(
	inventory_filter: String,
	equipped_filter: String,
	effect_families: Array,
	sort_by: String
) -> Array:
	ensure_fresh()
	var entries: Array = []
	if inventory_filter == "all" or inventory_filter == "weapon":
		entries.append_array(_weapons)
	if inventory_filter == "all" or inventory_filter == "armor":
		entries.append_array(_armors)
	if inventory_filter == "all" or inventory_filter == "accessory":
		entries.append_array(_accessories)
	if inventory_filter == "relic":
		entries.append_array(_relics)
	if equipped_filter != "all":
		entries = _apply_equipped_filter(entries, equipped_filter)
	if inventory_filter != "relic":
		entries = EquipmentEffectFamilyFilter.filter_entries(entries, effect_families)
	return EquipmentUiHelper.sort_inventory_entries(entries, sort_by)


static func _apply_equipped_filter(entries: Array, equipped_filter: String) -> Array:
	var filtered: Array = []
	for entry in entries:
		if entry is not Dictionary:
			continue
		var category: String = str(entry.get("category", ""))
		if equipped_filter == "max":
			if category == "relic":
				continue
			var max_item: Resource = entry.get("item") as Resource
			if EquipmentRollHelper.has_any_perfect_roll(max_item):
				filtered.append(entry)
			continue
		var owner_member: Resource = null
		if category == "relic":
			owner_member = GameState.find_relic_equipped_owner(str(entry.get("relic_id", "")))
		else:
			owner_member = GameState.find_item_equipped_owner(entry.get("item") as Resource)
		var is_equipped: bool = owner_member != null
		match equipped_filter:
			"equipped":
				if is_equipped:
					filtered.append(entry)
			"unequipped":
				if not is_equipped:
					filtered.append(entry)
			_:
				filtered.append(entry)
	return filtered


static func _rebuild_all() -> void:
	_weapons.clear()
	_armors.clear()
	_accessories.clear()
	_relics.clear()
	for item in GameState.inventory:
		if item == null or not bool(item.is_appraised):
			continue
		_weapons.append(_make_item_entry(item, "weapon"))
	for item in GameState.armor_inventory:
		if item == null or not bool(item.is_appraised):
			continue
		_armors.append(_make_item_entry(item, "armor"))
	for item in GameState.accessory_inventory:
		if item == null or not bool(item.is_appraised):
			continue
		_accessories.append(_make_item_entry(item, "accessory"))
	for rid in GameState.owned_relics:
		var relic_id: String = str(rid)
		if relic_id.is_empty():
			continue
		_relics.append({
			"relic_id": relic_id,
			"category": "relic",
			"rarity": 0,
			"name": CombatPassives.relic_display_name(relic_id),
		})


static func _make_item_entry(item: Resource, category: String) -> Dictionary:
	return {
		"item": item,
		"category": category,
		"rarity": EquipmentUiHelper.entry_rarity_for_item(item, category),
		"name": EquipmentUiHelper.entry_sort_name_for_item(item, category),
	}


static func _compute_signature() -> int:
	## 件数＋代表メタで袋変更を検知（装備着脱だけでは変わらない）。
	var h: int = GameState.inventory.size()
	h = _mix(h, GameState.armor_inventory.size())
	h = _mix(h, GameState.accessory_inventory.size())
	h = _mix(h, GameState.owned_relics.size())
	h = _hash_bag(h, GameState.inventory, "weapon")
	h = _hash_bag(h, GameState.armor_inventory, "armor")
	h = _hash_bag(h, GameState.accessory_inventory, "accessory")
	for rid in GameState.owned_relics:
		h = _mix(h, str(rid).hash())
	return h


static func _hash_bag(h: int, bag: Array, category: String) -> int:
	for item in bag:
		if item == null:
			continue
		var iid: String = ""
		if "instance_id" in item:
			iid = str(item.instance_id)
		h = _mix(h, iid.hash())
		h = _mix(h, 1 if bool(item.is_appraised) else 0)
		if "equip_level" in item:
			h = _mix(h, int(item.equip_level))
		## 表示名に影響し得るカテゴリ識別子も含める。
		match category:
			"weapon":
				h = _mix(h, str(item.weapon_id).hash())
			"armor":
				h = _mix(h, str(item.armor_id).hash())
			"accessory":
				h = _mix(h, str(item.accessory_id).hash())
	return h


static func _mix(h: int, v: int) -> int:
	return ((h << 5) - h) + v
