class_name EventExclusiveRewards
extends RefCounted

## 降臨セット装備ドロップ（P3-DG-EVENT-SET-001／P3-BAL-DESCENT-SET-DROP-ONE-001）。

const _WeaponStatResolver := preload("res://scripts/equipment/WeaponStatResolver.gd")
const _WeaponInstance := preload("res://scripts/domain/WeaponInstance.gd")
const _ArmorStatResolver := preload("res://scripts/equipment/ArmorStatResolver.gd")
const _ArmorInstance := preload("res://scripts/domain/ArmorInstance.gd")
const _AccessoryStatResolver := preload("res://scripts/equipment/AccessoryStatResolver.gd")
const _AccessoryInstance := preload("res://scripts/domain/AccessoryInstance.gd")
const _Sets := preload("res://scripts/equipment/EquipmentSetBonuses.gd")
const _JobStatCalculator := preload("res://scripts/equipment/JobStatCalculator.gd")
const _DungeonTierConfig := preload("res://scripts/dungeon/DungeonTierConfig.gd")

## 再周回のみ。撃破1回あたり最大1個（一度に複数は出さない）。
const RECLEAR_CHANCE: float = 0.40


static func is_event_dungeon(dungeon_id: String) -> bool:
	return not _Sets.set_id_for_dungeon(dungeon_id).is_empty()


static func is_event_exclusive_weapon(item_id: String) -> bool:
	return _Sets.set_id_of_weapon(item_id) != ""


static func is_event_exclusive_armor(item_id: String) -> bool:
	return _Sets.set_id_of_armor(item_id) != ""


static func is_event_exclusive_accessory(item_id: String) -> bool:
	return _Sets.set_id_of_accessory(item_id) != ""


static func is_event_exclusive_equip(item_id: String) -> bool:
	return _Sets.is_set_piece_id(item_id)


static func is_event_exclusive_relic(_relic_id: String) -> bool:
	return false


## 撃破1回あたりエンシェント装備は最大1個（初回確定／再周回40%）。
## 戻り値: {weapon_id, armor_id, accessory_id}
static func apply_boss_loot(dungeon_id: String, tier: int) -> Dictionary:
	var out: Dictionary = {"weapon_id": "", "armor_id": "", "accessory_id": "", "relic_id": ""}
	var set_id: String = _Sets.set_id_for_dungeon(dungeon_id)
	if set_id.is_empty():
		return out
	var t: int = _DungeonTierConfig.clamp_tier(tier)
	var first_clear: bool = not GameState.is_dungeon_tier_cleared(dungeon_id, t)
	if not first_clear and randf() >= RECLEAR_CHANCE:
		return out
	return _grant_picked_piece(set_id, out)


static func _grant_picked_piece(set_id: String, out: Dictionary) -> Dictionary:
	var armor_id: String = str(_Sets.ARMOR_BY_SET.get(set_id, ""))
	var accessory_id: String = str(_Sets.ACCESSORY_BY_SET.get(set_id, ""))
	var pick: String = _pick_one_piece(set_id)
	if pick.is_empty():
		return out
	if pick == armor_id:
		if _grant_armor(pick):
			out["armor_id"] = pick
	elif pick == accessory_id:
		if _grant_accessory(pick):
			out["accessory_id"] = pick
	elif _grant_weapon(pick):
		out["weapon_id"] = pick
	return out


static func source_label(dungeon_id: String) -> String:
	match dungeon_id:
		"chronos_mausoleum":
			return "時王の霊廟"
		"valgard_boundary":
			return "ストームクラウン境界廊"
		"north_reach":
			return "天望の塔"
		"red_forge_depths":
			return "星炉火口"
		_:
			return ""


static func _owns_weapon(weapon_id: String) -> bool:
	for item in GameState.inventory:
		if item != null and str(item.weapon_id) == weapon_id:
			return true
	return false


static func _owns_armor(armor_id: String) -> bool:
	for item in GameState.armor_inventory:
		if item != null and str(item.armor_id) == armor_id:
			return true
	return false


static func _owns_accessory(accessory_id: String) -> bool:
	for item in GameState.accessory_inventory:
		if item != null and str(item.accessory_id) == accessory_id:
			return true
	return false


static func _pick_weapon_for_party(weapons: Array) -> String:
	if weapons.is_empty():
		return ""
	var preferred: Array[String] = []
	var unowned: Array[String] = []
	for wid in weapons:
		var id: String = str(wid)
		if _owns_weapon(id):
			continue
		unowned.append(id)
		var data: Resource = DataRegistry.get_weapon_data(id)
		if data == null:
			continue
		for member in GameState.party_members:
			if member == null:
				continue
			if _JobStatCalculator.can_equip_weapon_data(member, data):
				preferred.append(id)
				break
	if not preferred.is_empty():
		return preferred[randi() % preferred.size()]
	if not unowned.is_empty():
		return unowned[randi() % unowned.size()]
	return str(weapons[randi() % weapons.size()])


static func _pick_one_piece(set_id: String) -> String:
	var missing: Array[String] = []
	var all_ids: Array[String] = _Sets.all_piece_ids(set_id)
	var weapons: Array = _Sets.WEAPONS_BY_SET.get(set_id, [])
	for pid in all_ids:
		var owned: bool = false
		if pid in weapons:
			owned = _owns_weapon(pid)
		elif pid == str(_Sets.ARMOR_BY_SET.get(set_id, "")):
			owned = _owns_armor(pid)
		else:
			owned = _owns_accessory(pid)
		if not owned:
			missing.append(pid)
	var pool: Array[String] = missing if not missing.is_empty() else all_ids
	if pool.is_empty():
		return ""
	## 池が武器のみなら編成向きを優先。混在時は部位を等確率。
	var only_weapons := true
	for pid in pool:
		if pid not in weapons:
			only_weapons = false
			break
	if only_weapons:
		return _pick_weapon_for_party(pool)
	return pool[randi() % pool.size()]


static func _grant_weapon(weapon_id: String) -> bool:
	if not is_event_exclusive_weapon(weapon_id):
		return false
	var weapon_data: Resource = DataRegistry.get_weapon_data(weapon_id)
	if weapon_data == null:
		return false
	var instance: Resource = _WeaponInstance.new()
	instance.instance_id = "evt_%s_%d_%d" % [weapon_id, Time.get_ticks_msec(), randi() % 100000]
	instance.weapon_id = weapon_id
	_WeaponStatResolver.apply_drop_stats(instance, weapon_data)
	instance.is_appraised = true
	if not GameState.try_add_weapon_instance(instance):
		return false
	## トーストは EventBus 側。note より先に emit（register 済みだとトースト欠落）。
	if EventBus.has_signal("weapon_obtained"):
		EventBus.weapon_obtained.emit(weapon_id)
	GameState.note_equipment_obtained(instance)
	GameState.mark_equipment_new(instance)
	GameState.record_last_run_equipment_drop(instance, "weapon")
	return true


static func _grant_armor(armor_id: String) -> bool:
	if not is_event_exclusive_armor(armor_id):
		return false
	var armor_data: Resource = DataRegistry.get_armor_data(armor_id)
	if armor_data == null:
		return false
	var instance: Resource = _ArmorInstance.new()
	instance.instance_id = "evt_%s_%d_%d" % [armor_id, Time.get_ticks_msec(), randi() % 100000]
	instance.armor_id = armor_id
	_ArmorStatResolver.apply_drop_stats(instance, armor_data)
	instance.is_appraised = true
	if not GameState.try_add_armor_instance(instance):
		return false
	if EventBus.has_signal("armor_obtained"):
		EventBus.armor_obtained.emit(armor_id)
	GameState.note_equipment_obtained(instance)
	GameState.mark_equipment_new(instance)
	GameState.record_last_run_equipment_drop(instance, "armor")
	return true


static func _grant_accessory(accessory_id: String) -> bool:
	if not is_event_exclusive_accessory(accessory_id):
		return false
	var accessory_data: Resource = DataRegistry.get_accessory_data(accessory_id)
	if accessory_data == null:
		return false
	var instance: Resource = _AccessoryInstance.new()
	instance.instance_id = "evt_%s_%d_%d" % [accessory_id, Time.get_ticks_msec(), randi() % 100000]
	instance.accessory_id = accessory_id
	_AccessoryStatResolver.apply_drop_stats(instance, accessory_data)
	instance.is_appraised = true
	if not GameState.try_add_accessory_instance(instance):
		return false
	if EventBus.has_signal("accessory_obtained"):
		EventBus.accessory_obtained.emit(accessory_id)
	GameState.note_equipment_obtained(instance)
	GameState.mark_equipment_new(instance)
	GameState.record_last_run_equipment_drop(instance, "accessory")
	return true
