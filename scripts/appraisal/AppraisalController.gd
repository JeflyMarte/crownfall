extends Node

const APPRAISAL_COST: int = 100
const _AffixRoller = preload("res://scripts/equipment/AffixRoller.gd")
const _AffixDisplayFormatter = preload("res://scripts/equipment/AffixDisplayFormatter.gd")

func count_unappraised() -> int:
	var count: int = 0
	for item in GameState.inventory:
		if not item.is_appraised:
			count += 1
	for item in GameState.armor_inventory:
		if not item.is_appraised:
			count += 1
	for item in GameState.accessory_inventory:
		if not item.is_appraised:
			count += 1
	return count

func get_batch_cost() -> int:
	return count_unappraised() * APPRAISAL_COST

func appraise_all() -> Dictionary:
	var count: int = 0
	var spent: int = 0
	var stopped_reason: String = "done"
	while has_unappraised():
		if not has_enough_gold():
			stopped_reason = "gold"
			break
		var result: Dictionary = appraise_next()
		if result.is_empty():
			break
		count += 1
		spent += APPRAISAL_COST
	return {"count": count, "spent": spent, "stopped_reason": stopped_reason}

func has_unappraised() -> bool:
	for item in GameState.inventory:
		if not item.is_appraised:
			return true
	for item in GameState.armor_inventory:
		if not item.is_appraised:
			return true
	for item in GameState.accessory_inventory:
		if not item.is_appraised:
			return true
	return false

func has_enough_gold() -> bool:
	return GameState.gold >= APPRAISAL_COST

func appraise_next() -> Dictionary:
	if not has_enough_gold() or not has_unappraised():
		return {}
	var item: Resource = _find_first_unappraised()
	if item == null:
		return {}
	item.is_appraised = true
	var affix_roll: Dictionary = _roll_affixes(item)
	_apply_affix_roll(item, affix_roll)
	GameState.gold -= APPRAISAL_COST
	SaveManager.save_game()
	return {
		"item": item,
		"affix_text": format_affix_reveal(
			item.prefix_ids,
			item.suffix_ids
		),
	}

func format_affix_reveal(prefix_ids: Array, suffix_ids: Array) -> String:
	return _AffixDisplayFormatter.format_reveal(prefix_ids, suffix_ids)

func _roll_affixes(item: Resource) -> Dictionary:
	var category: String = _get_equipment_category(item)
	if category.is_empty():
		return {}
	var rarity: int = _get_item_rarity(item)
	return _AffixRoller.roll_for_equipment(category, rarity)

func _apply_affix_roll(item: Resource, roll: Dictionary) -> void:
	if roll.is_empty() or roll.has("error"):
		item.prefix_ids = []
		item.suffix_ids = []
		return
	item.prefix_ids = _to_string_array(roll.get("prefix_ids", []))
	item.suffix_ids = _to_string_array(roll.get("suffix_ids", []))

func _get_equipment_category(item: Resource) -> String:
	if item is WeaponInstance:
		return _AffixRoller.CATEGORY_WEAPON
	if item is ArmorInstance:
		return _AffixRoller.CATEGORY_ARMOR
	if item is AccessoryInstance:
		return _AffixRoller.CATEGORY_ACCESSORY
	if "weapon_id" in item:
		return _AffixRoller.CATEGORY_WEAPON
	if "armor_id" in item:
		return _AffixRoller.CATEGORY_ARMOR
	if "accessory_id" in item:
		return _AffixRoller.CATEGORY_ACCESSORY
	return ""

func _get_item_rarity(item: Resource) -> int:
	if item is ArmorInstance:
		return item.rarity
	if item is WeaponInstance:
		var weapon_data: Resource = DataRegistry.get_weapon_data(item.weapon_id)
		if weapon_data != null:
			return weapon_data.rarity
	if item is AccessoryInstance:
		var accessory_data: Resource = DataRegistry.get_accessory_data(item.accessory_id)
		if accessory_data != null:
			return accessory_data.rarity
	return Enums.Rarity.COMMON

func _to_string_array(values: Array) -> Array[String]:
	var out: Array[String] = []
	for value in values:
		out.append(str(value))
	return out

func _find_first_unappraised() -> Resource:
	for item in GameState.inventory:
		if not item.is_appraised:
			return item
	for item in GameState.armor_inventory:
		if not item.is_appraised:
			return item
	for item in GameState.accessory_inventory:
		if not item.is_appraised:
			return item
	return null
