extends Node

func get_appraised_weapons() -> Array:
	return GameState.inventory.filter(func(item: Resource) -> bool: return item.is_appraised)

func get_appraised_armors() -> Array:
	return GameState.armor_inventory.filter(func(item: Resource) -> bool: return item.is_appraised)

func get_appraised_accessories() -> Array:
	return GameState.accessory_inventory.filter(func(item: Resource) -> bool: return item.is_appraised)

func get_appraised_weapons_for_member(member_index: int) -> Array:
	var member: Resource = null
	if _is_valid_member_index(member_index):
		member = GameState.party_members[member_index]
	var out: Array = []
	for item in _filter_items_for_member(get_appraised_weapons(), member_index):
		if member != null and not JobStatCalculator.can_equip_weapon(member, item):
			continue
		out.append(item)
	return out

func get_appraised_armors_for_member(member_index: int) -> Array:
	return _filter_items_for_member(get_appraised_armors(), member_index)

func get_appraised_accessories_for_member(member_index: int) -> Array:
	return _filter_items_for_member(get_appraised_accessories(), member_index)

func equip_weapon_for_member(item: Resource, member: Resource) -> void:
	if member == null or item == null:
		return
	if not JobStatCalculator.can_equip_weapon(member, item):
		return
	GameState.clear_item_from_other_roster_members(item, member)
	## 装備Lv は永続値。装着者キャラLvへのクリップは EXP 成長時のみ（P3-EQ-LVL-001-4）。
	member.equipped_weapon = item
	## 連打着脱で同期フルセーブすると弱機フリーズ（ロックと同型）。
	SaveManager.request_save()
	GameState.mark_equipped_item_owner_cache_dirty()

func equip_armor_for_member(item: Resource, member: Resource) -> void:
	if member == null or item == null:
		return
	GameState.clear_item_from_other_roster_members(item, member)
	member.equipped_armor = item
	SaveManager.request_save()
	GameState.mark_equipped_item_owner_cache_dirty()

func equip_accessory_for_member(item: Resource, member: Resource) -> void:
	if member == null or item == null:
		return
	GameState.clear_item_from_other_roster_members(item, member)
	member.equipped_accessory = item
	SaveManager.request_save()
	GameState.mark_equipped_item_owner_cache_dirty()

func unequip_weapon_for_member(member: Resource) -> void:
	if member == null:
		return
	member.equipped_weapon = null
	SaveManager.request_save()
	GameState.mark_equipped_item_owner_cache_dirty()

func unequip_armor_for_member(member: Resource) -> void:
	if member == null:
		return
	member.equipped_armor = null
	SaveManager.request_save()
	GameState.mark_equipped_item_owner_cache_dirty()

func unequip_accessory_for_member(member: Resource) -> void:
	if member == null:
		return
	member.equipped_accessory = null
	SaveManager.request_save()
	GameState.mark_equipped_item_owner_cache_dirty()

func equip_weapon(item: Resource, member_index: int) -> void:
	if not _is_valid_member_index(member_index):
		return
	var member: Resource = GameState.party_members[member_index]
	equip_weapon_for_member(item, member)

func equip_armor(item: Resource, member_index: int) -> void:
	if not _is_valid_member_index(member_index):
		return
	var member: Resource = GameState.party_members[member_index]
	equip_armor_for_member(item, member)

func equip_accessory(item: Resource, member_index: int) -> void:
	if not _is_valid_member_index(member_index):
		return
	var member: Resource = GameState.party_members[member_index]
	equip_accessory_for_member(item, member)

func unequip_weapon(member_index: int) -> void:
	if not _is_valid_member_index(member_index):
		return
	unequip_weapon_for_member(GameState.party_members[member_index])

func unequip_armor(member_index: int) -> void:
	if not _is_valid_member_index(member_index):
		return
	unequip_armor_for_member(GameState.party_members[member_index])

func unequip_accessory(member_index: int) -> void:
	if not _is_valid_member_index(member_index):
		return
	unequip_accessory_for_member(GameState.party_members[member_index])

func _filter_items_for_member(items: Array, member_index: int) -> Array:
	var out: Array = []
	var member: Resource = null
	if _is_valid_member_index(member_index):
		member = GameState.party_members[member_index]
	for item in items:
		var owner: Resource = GameState.find_item_equipped_owner(item)
		if owner == null or owner == member:
			out.append(item)
	return out

func _is_valid_member_index(member_index: int) -> bool:
	return member_index >= 0 and member_index < GameState.party_members.size()
