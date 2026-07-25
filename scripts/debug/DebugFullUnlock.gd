class_name DebugFullUnlock
extends RefCounted

## タイトル「デバッグ」用フル所持プリセット。
## 金 999999 / 魔晶石 9999・全装備（武／防／装）・全キャラ LvMAX・図鑑全開放・進行解放。

const _DungeonTierConfig = preload("res://scripts/dungeon/DungeonTierConfig.gd")
const _WeaponStatResolver = preload("res://scripts/equipment/WeaponStatResolver.gd")
const _ArmorStatResolver = preload("res://scripts/equipment/ArmorStatResolver.gd")
const _AccessoryStatResolver = preload("res://scripts/equipment/AccessoryStatResolver.gd")
const _GachaLimitBreak = preload("res://scripts/gacha/GachaLimitBreak.gd")
const _CombatBossPhases = preload("res://scripts/combat/CombatBossPhases.gd")
const _DiscoveryRegistry = preload("res://scripts/discovery/DiscoveryRegistry.gd")
const _CatalogHelper = preload("res://scripts/codex/CatalogHelper.gd")

const DEBUG_GOLD: int = 999_999
const DEBUG_GACHA_TOKEN: int = 9_999
## owned_helpers 所持数（1=未凸、6=+5 頭打ち）。
## 上限-1（+4）にして限界突破券を1枚試せる余地を残す。
const DEBUG_HELPER_OWNED_COUNT: int = _GachaLimitBreak.MAX_BREAKTHROUGH
const DEBUG_MATERIAL_QTY: int = 999


## 現在の GameState をデバッグ用フル所持へ上書きする。セーブは呼び出し側。
static func apply() -> void:
	GameState.reset_for_new_game()
	GameState.debug_full_unlock = true
	GameState.gold = DEBUG_GOLD
	GameState.gacha_token = DEBUG_GACHA_TOKEN
	_unlock_all_starters_and_helpers()
	_max_all_character_levels()
	_grant_all_equipment()
	_grant_all_materials()
	_grant_all_relics()
	TicketInventory.grant_debug_stock(Constants.DEBUG_TICKET_GRANT_EACH)
	_unlock_all_progress()
	_unlock_all_codex()
	var _PetSystem = preload("res://scripts/pets/PetSystem.gd")
	_PetSystem.unlock_pet(_PetSystem.PET_ASH_ID, false)
	_PetSystem.unlock_pet(_PetSystem.PET_INK_ID, false)
	_PetSystem.ensure_starter_pet()
	GameState.current_dungeon_id = Constants.MOURNGATE_DUNGEON_ID
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NORMAL
	var first_stage: Resource = DataRegistry.get_stage_by_chapter(Constants.MOURNGATE_DUNGEON_ID, 1)
	GameState.current_stage_id = str(first_stage.id) if first_stage != null else ""
	GameState.starter_pick_pending = false
	GameState.normalize_roster_rarity()
	GameState.normalize_all_equipped_skills()
	GameState.normalize_all_equipped_passives()
	GameState.migrate_formation_slots_if_needed()


static func _unlock_all_starters_and_helpers() -> void:
	GameState.seed_all_starters_unlocked()
	GameState.owned_helpers.clear()
	if not Constants.are_gacha_helpers_playable():
		return
	for helper in DataRegistry.get_all_gacha_helper_data():
		if helper == null:
			continue
		var hid: String = str(helper.id)
		if hid.is_empty():
			continue
		GameState.owned_helpers[hid] = DEBUG_HELPER_OWNED_COUNT
		var member_id: String = "gacha_" + hid
		if GameState.find_roster_member_by_id(member_id) != null:
			continue
		var adv: Resource = GachaSystem.create_adventurer_from_helper(helper)
		GameState.add_roster_member(adv)
		GameState._grant_member_starting_weapon(adv)
	# 編成は先頭 ACTIVE_PARTY_SIZE（スターター優先のまま）
	GameState.party_members.clear()
	for i in mini(GameState.ACTIVE_PARTY_SIZE, GameState.roster.size()):
		GameState.party_members.append(GameState.roster[i])


static func _max_all_character_levels() -> void:
	for member in GameState.roster:
		_set_member_max_level(member)
	_set_member_max_level(GameState.active_pet)


static func _set_member_max_level(member: Resource) -> void:
	if member == null:
		return
	member.level = LevelSystem.MAX_LEVEL
	member.exp = 0


static func _grant_all_equipment() -> void:
	GameState.inventory.clear()
	GameState.armor_inventory.clear()
	GameState.accessory_inventory.clear()
	var seq: int = 0
	for data in DataRegistry.get_all_weapon_data():
		if data == null:
			continue
		var wid: String = str(data.id)
		if wid.is_empty():
			continue
		var inst: Resource = WeaponInstance.new()
		inst.instance_id = "debug_wpn_%s_%d" % [wid, seq]
		inst.weapon_id = wid
		inst.is_appraised = true
		inst.equip_level = 1
		_WeaponStatResolver.apply_drop_stats(inst, data)
		GameState.inventory.append(inst)
		_DiscoveryRegistry.register("weapon", wid)
		seq += 1
	for data in DataRegistry.get_all_armor_data():
		if data == null:
			continue
		var aid: String = str(data.armor_id)
		if aid.is_empty():
			continue
		var ainst: Resource = ArmorInstance.new()
		ainst.instance_id = "debug_arm_%s_%d" % [aid, seq]
		ainst.armor_id = aid
		ainst.is_appraised = true
		ainst.rarity = int(data.rarity)
		ainst.equip_level = 1
		_ArmorStatResolver.apply_drop_stats(ainst, data)
		GameState.armor_inventory.append(ainst)
		seq += 1
	for data in DataRegistry.get_all_accessory_data():
		if data == null:
			continue
		var xid: String = str(data.id)
		if xid.is_empty():
			continue
		var xinst: Resource = AccessoryInstance.new()
		xinst.instance_id = "debug_acc_%s_%d" % [xid, seq]
		xinst.accessory_id = xid
		xinst.is_appraised = true
		xinst.equip_level = 1
		_AccessoryStatResolver.apply_drop_stats(xinst, data)
		GameState.accessory_inventory.append(xinst)
		seq += 1
	# スターター武器が inventory に無いと装備復元が壊れるため、装備中を再付与
	for member in GameState.roster:
		if member == null:
			continue
		member.equipped_weapon = null
		member.equipped_armor = null
		member.equipped_accessory = null
		GameState._grant_member_starting_weapon(member)


static func _grant_all_materials() -> void:
	GameState.material_inventory.clear()
	for data in DataRegistry.get_all_material_data():
		if data == null:
			continue
		var mid: String = str(data.id)
		if mid.is_empty():
			continue
		if not EquipmentEnhancer.is_enhancement_material(mid):
			continue
		GameState.material_inventory[mid] = DEBUG_MATERIAL_QTY
		_DiscoveryRegistry.register("material", mid)


static func _grant_all_relics() -> void:
	GameState.owned_relics.clear()
	for rid in CombatPassives.relic_passive_ids():
		GameState.unlock_relic(str(rid))


static func _unlock_all_progress() -> void:
	GameState.stage_progress.clear()
	GameState.dungeon_progress.clear()
	GameState.dungeon_tier_cleared.clear()
	for stage in DataRegistry.get_all_stage_data():
		if stage == null:
			continue
		var sid: String = str(stage.id)
		if sid.is_empty():
			continue
		var tiers: Dictionary = {}
		for t in range(_DungeonTierConfig.TIER_COUNT):
			tiers[str(t)] = true
		GameState.stage_progress[sid] = {"cleared": true, "tiers": tiers}
	for data in DataRegistry.get_all_dungeon_data():
		if data == null:
			continue
		var did: String = str(data.id)
		if did.is_empty():
			continue
		GameState.dungeon_progress[did] = {"cleared": true}
		var per: Dictionary = {}
		for t in range(_DungeonTierConfig.TIER_COUNT):
			per[str(t)] = true
		GameState.dungeon_tier_cleared[did] = per


static func _unlock_all_codex() -> void:
	GameState.enemy_codex.clear()
	for data in DataRegistry.get_all_enemy_data():
		if data == null:
			continue
		var eid: String = str(data.id)
		if eid.is_empty():
			continue
		var phases: Array = []
		var n: int = _CombatBossPhases.phase_count(eid)
		for i in range(maxi(1, n)):
			phases.append(i)
		GameState.enemy_codex[eid] = {
			"seen": true,
			"kills": GameState.STAGE5_KILLS,
			"phases_seen": phases,
		}
		_DiscoveryRegistry.register("enemy", eid)
	for data in DataRegistry.get_all_dungeon_data():
		if data == null:
			continue
		var did: String = str(data.id)
		if did.is_empty():
			continue
		_DiscoveryRegistry.register("dungeon", did)
	for lore in _CatalogHelper.get_lore_entries():
		var lid: String = str(lore.get("id", ""))
		if not lid.is_empty():
			_DiscoveryRegistry.register("lore", lid)
	for room_id in ["heal", "treasure", "merchant", "event", "elite", "trap"]:
		_DiscoveryRegistry.register("room", room_id)
