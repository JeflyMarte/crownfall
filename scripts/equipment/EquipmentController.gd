extends Node

func get_appraised_weapons() -> Array:
	return GameState.inventory.filter(func(item: Resource) -> bool: return item.is_appraised)

func get_appraised_armors() -> Array:
	return GameState.armor_inventory.filter(func(item: Resource) -> bool: return item.is_appraised)

func get_appraised_accessories() -> Array:
	return GameState.accessory_inventory.filter(func(item: Resource) -> bool: return item.is_appraised)

func get_appraised_weapons_for_member(member_index: int) -> Array:
	return _filter_items_for_member(get_appraised_weapons(), member_index)

func get_appraised_armors_for_member(member_index: int) -> Array:
	return _filter_items_for_member(get_appraised_armors(), member_index)

func get_appraised_accessories_for_member(member_index: int) -> Array:
	return _filter_items_for_member(get_appraised_accessories(), member_index)

func equip_weapon(item: Resource, member_index: int) -> void:
	if not _is_valid_member_index(member_index):
		return
	GameState.clear_item_from_other_members(item, member_index)
	EquipmentEnhancer.clamp_equip_level_to_member(item, GameState.party_members[member_index])
	GameState.party_members[member_index].equipped_weapon = item
	SaveManager.save_game()

func equip_armor(item: Resource, member_index: int) -> void:
	if not _is_valid_member_index(member_index):
		return
	GameState.clear_item_from_other_members(item, member_index)
	EquipmentEnhancer.clamp_equip_level_to_member(item, GameState.party_members[member_index])
	GameState.party_members[member_index].equipped_armor = item
	SaveManager.save_game()

func equip_accessory(item: Resource, member_index: int) -> void:
	if not _is_valid_member_index(member_index):
		return
	GameState.clear_item_from_other_members(item, member_index)
	EquipmentEnhancer.clamp_equip_level_to_member(item, GameState.party_members[member_index])
	GameState.party_members[member_index].equipped_accessory = item
	SaveManager.save_game()

func unequip_weapon(member_index: int) -> void:
	if not _is_valid_member_index(member_index):
		return
	GameState.party_members[member_index].equipped_weapon = null
	SaveManager.save_game()

func unequip_armor(member_index: int) -> void:
	if not _is_valid_member_index(member_index):
		return
	GameState.party_members[member_index].equipped_armor = null
	SaveManager.save_game()

func unequip_accessory(member_index: int) -> void:
	if not _is_valid_member_index(member_index):
		return
	GameState.party_members[member_index].equipped_accessory = null
	SaveManager.save_game()

func _filter_items_for_member(items: Array, member_index: int) -> Array:
	var out: Array = []
	for item in items:
		var owner_index: int = GameState.find_item_equipped_member_index(item)
		if owner_index < 0 or owner_index == member_index:
			out.append(item)
	return out

func _is_valid_member_index(member_index: int) -> bool:
	return member_index >= 0 and member_index < GameState.party_members.size()
