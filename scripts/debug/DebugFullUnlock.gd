class_name DebugFullUnlock
extends RefCounted

## タイトル「デバッグ」用フル所持プリセット。
## 金 999999 / 魔晶石 9999・全装備（武／防／装）・装備LvMAX・全キャラ LvMAX・
## 指揮官 S+99・図鑑全開放・進行解放。

const _DungeonTierConfig = preload("res://scripts/dungeon/DungeonTierConfig.gd")
const _WeaponStatResolver = preload("res://scripts/equipment/WeaponStatResolver.gd")
const _ArmorStatResolver = preload("res://scripts/equipment/ArmorStatResolver.gd")
const _AccessoryStatResolver = preload("res://scripts/equipment/AccessoryStatResolver.gd")
const _GachaLimitBreak = preload("res://scripts/gacha/GachaLimitBreak.gd")
const _CombatBossPhases = preload("res://scripts/combat/CombatBossPhases.gd")
const _DiscoveryRegistry = preload("res://scripts/discovery/DiscoveryRegistry.gd")
const _CatalogHelper = preload("res://scripts/codex/CatalogHelper.gd")
const _CommanderProfile = preload("res://scripts/commander/CommanderProfile.gd")
const _CommanderTitles = preload("res://scripts/commander/CommanderTitles.gd")
const _CommanderPermitBoost = preload("res://scripts/commander/CommanderPermitBoost.gd")
const _DebugAccess = preload("res://scripts/debug/DebugAccess.gd")

const DEBUG_GOLD: int = 999_999
const DEBUG_GACHA_TOKEN: int = 9_999
## owned_helpers 所持数（1=未凸、6=+5 頭打ち）。
## 上限-1（+4）にして限界突破券を1枚試せる余地を残す。
const DEBUG_HELPER_OWNED_COUNT: int = _GachaLimitBreak.MAX_BREAKTHROUGH
const DEBUG_MATERIAL_QTY: int = 999
## 指揮官等級（P3-CMD-RANK-SPLUS-001）。デバッグは S+99 固定。
const DEBUG_COMMANDER_S_PLUS: int = 99


## 現在の GameState をデバッグ用フル所持へ上書きする。セーブは呼び出し側。
static func apply() -> void:
	if not _DebugAccess.is_allowed():
		push_warning("DebugFullUnlock.apply blocked outside debug builds")
		return
	GameState.reset_for_new_game()
	GameState.debug_full_unlock = true
	GameState.survey_staff_nonoka_unlocked = true
	GameState.pending_nonoka_survey_join = false
	GameState.gold = DEBUG_GOLD
	GameState.gacha_token = DEBUG_GACHA_TOKEN
	_unlock_all_starters_and_helpers()
	_max_all_character_levels()
	_grant_all_equipment()
	_unlock_all_craft_recipes()
	_grant_all_materials()
	_grant_all_relics()
	TicketInventory.grant_debug_stock(Constants.DEBUG_TICKET_GRANT_EACH)
	_unlock_all_progress()
	_unlock_all_codex()
	_max_commander_rank()
	var _PetSystem = preload("res://scripts/pets/PetSystem.gd")
	_PetSystem.unlock_pet(_PetSystem.PET_ASH_ID, false)
	_PetSystem.unlock_pet(_PetSystem.PET_INK_ID, false)
	_PetSystem.grant_starter_pet()
	## LvMAX 後に解放スキルを装備へ反映
	if GameState.active_pet != null:
		GameState.active_pet.level = LevelSystem.MAX_LEVEL
		GameState.active_pet.exp = 0
		_PetSystem.sync_pet_runtime(GameState.active_pet)
	GameState.current_dungeon_id = Constants.MOURNGATE_DUNGEON_ID
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NORMAL
	var first_stage: Resource = DataRegistry.get_stage_by_chapter(Constants.MOURNGATE_DUNGEON_ID, 1)
	GameState.current_stage_id = str(first_stage.id) if first_stage != null else ""
	GameState.starter_pick_pending = false
	const _IntroTutorialConfig := preload("res://scripts/intro/IntroTutorialConfig.gd")
	_IntroTutorialConfig.mark_done()
	GameState.normalize_roster_rarity()
	GameState.normalize_all_equipped_skills()
	GameState.normalize_all_equipped_passives()
	GameState.migrate_formation_slots_if_needed()


static func _unlock_all_starters_and_helpers() -> void:
	GameState.seed_all_starters_unlocked()
	GameState.owned_helpers.clear()
	if not Constants.are_gacha_helpers_playable():
		return
	for helper in DataRegistry.get_gacha_pool_helper_data():
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
	for staged_id: String in Constants.GACHA_HELPER_OMITTED_IDS:
		var staged: Resource = DataRegistry.get_gacha_helper_data(staged_id)
		if staged == null:
			continue
		GameState.owned_helpers[staged_id] = DEBUG_HELPER_OWNED_COUNT
		var staged_member_id: String = "gacha_" + staged_id
		if GameState.find_roster_member_by_id(staged_member_id) != null:
			continue
		var staged_adv: Resource = GachaSystem.create_adventurer_from_helper(staged)
		GameState.add_roster_member(staged_adv)
		GameState._grant_member_starting_weapon(staged_adv)
	## 第2弾機巧士はプール復帰済みでも、旧デバッグセーブ／漏れに備えて明示付与。
	ensure_engineer_helpers()
	# 編成は先頭 ACTIVE_PARTY_SIZE（スターター優先のまま）
	GameState.party_members.clear()
	for i in mini(GameState.ACTIVE_PARTY_SIZE, GameState.roster.size()):
		GameState.party_members.append(GameState.roster[i])


## 機巧士3（トリム／ブラン／オルソ）をロスターへ。既存は触らない。
static func ensure_engineer_helpers() -> bool:
	if not _DebugAccess.is_allowed():
		return false
	if not Constants.are_gacha_helpers_playable():
		return false
	var added: bool = false
	for hid: String in ["helper_q", "helper_r", "helper_s"]:
		var helper: Resource = DataRegistry.get_gacha_helper_data(hid)
		if helper == null:
			continue
		if int(GameState.owned_helpers.get(hid, 0)) < 1:
			GameState.owned_helpers[hid] = DEBUG_HELPER_OWNED_COUNT
			added = true
		elif int(GameState.owned_helpers.get(hid, 0)) < DEBUG_HELPER_OWNED_COUNT:
			GameState.owned_helpers[hid] = DEBUG_HELPER_OWNED_COUNT
			added = true
		var member_id: String = "gacha_" + hid
		if GameState.find_roster_member_by_id(member_id) != null:
			continue
		var adv: Resource = GachaSystem.create_adventurer_from_helper(helper)
		if adv == null:
			continue
		adv.level = LevelSystem.MAX_LEVEL
		adv.exp = 0
		GameState.add_roster_member(adv)
		GameState._grant_member_starting_weapon(adv)
		added = true
	return added


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
		inst.equip_level = EquipmentEnhancer.EQUIP_MAX_LEVEL
		inst.equip_exp = 0
		_WeaponStatResolver.apply_drop_stats(inst, data)
		## デバッグ全所持は袋上限を超えてよい（検証用）。
		GameState.try_add_weapon_instance(inst, true)
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
		ainst.equip_level = EquipmentEnhancer.EQUIP_MAX_LEVEL
		ainst.equip_exp = 0
		_ArmorStatResolver.apply_drop_stats(ainst, data)
		GameState.try_add_armor_instance(ainst, true)
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
		xinst.equip_level = EquipmentEnhancer.EQUIP_MAX_LEVEL
		xinst.equip_exp = 0
		_AccessoryStatResolver.apply_drop_stats(xinst, data)
		GameState.try_add_accessory_instance(xinst, true)
		seq += 1
	# スターター武器が inventory に無いと装備復元が壊れるため、装備中を再付与
	for member in GameState.roster:
		if member == null:
			continue
		member.equipped_weapon = null
		member.equipped_armor = null
		member.equipped_accessory = null
		GameState._grant_member_starting_weapon(member)
	_max_all_equip_levels()


static func _max_all_equip_levels() -> void:
	for item: Variant in GameState.inventory:
		_set_equip_max_level(item as Resource)
	for item: Variant in GameState.armor_inventory:
		_set_equip_max_level(item as Resource)
	for item: Variant in GameState.accessory_inventory:
		_set_equip_max_level(item as Resource)
	for member: Variant in GameState.roster:
		if member == null:
			continue
		var adv: Resource = member as Resource
		_set_equip_max_level(adv.equipped_weapon)
		_set_equip_max_level(adv.equipped_armor)
		_set_equip_max_level(adv.equipped_accessory)


static func _set_equip_max_level(item: Resource) -> void:
	if item == null or not ("equip_level" in item):
		return
	item.equip_level = EquipmentEnhancer.EQUIP_MAX_LEVEL
	if "equip_exp" in item:
		item.equip_exp = 0


static func _max_commander_rank() -> void:
	_CommanderProfile.ensure_commander()
	var code: String = "S+%d" % DEBUG_COMMANDER_S_PLUS
	GameState.commander["acknowledged_rank"] = code
	GameState.commander.erase("_ack_needs_bootstrap")
	var rewarded: Array = ["C", "B", "A", "S"]
	for n: int in range(1, DEBUG_COMMANDER_S_PLUS + 1):
		rewarded.append("S+%d" % n)
	GameState.commander["rank_reward_ranks"] = rewarded
	GameState.commander["permit_points_earned"] = DEBUG_COMMANDER_S_PLUS
	_CommanderPermitBoost.ensure()
	_CommanderTitles.refresh_unlocks()


## 生産レシピ解放（P3-CRAFT-DISCOVER-001）。所持同期＋クラフト可能マスタ全解放。
static func _unlock_all_craft_recipes() -> void:
	const _CraftHelper := preload("res://scripts/crafting/CraftHelper.gd")
	_CraftHelper.sync_unlocks_from_owned()
	for data in DataRegistry.get_all_weapon_data():
		if data == null:
			continue
		var wid: String = str(data.id)
		if not wid.is_empty():
			_CraftHelper.try_unlock("weapon", wid)
	for data in DataRegistry.get_all_armor_data():
		if data == null:
			continue
		var aid: String = str(data.armor_id)
		if not aid.is_empty():
			_CraftHelper.try_unlock("armor", aid)
	for data in DataRegistry.get_all_accessory_data():
		if data == null:
			continue
		var xid: String = str(data.id)
		if not xid.is_empty():
			_CraftHelper.try_unlock("accessory", xid)


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
	for data in DataRegistry.get_all_weapon_data():
		if data == null:
			continue
		var wid: String = str(data.id)
		if not wid.is_empty():
			_DiscoveryRegistry.register("weapon", wid)
	for data in DataRegistry.get_all_armor_data():
		if data == null:
			continue
		var aid: String = str(data.armor_id)
		if not aid.is_empty():
			_DiscoveryRegistry.register("armor", aid)
	for data in DataRegistry.get_all_accessory_data():
		if data == null:
			continue
		var xid: String = str(data.id)
		if not xid.is_empty():
			_DiscoveryRegistry.register("accessory", xid)
	for data in DataRegistry.get_all_material_data():
		if data == null:
			continue
		var mid: String = str(data.id)
		if mid.is_empty():
			continue
		if EquipmentEnhancer.is_enhancement_material(mid):
			_DiscoveryRegistry.register("material", mid)
	for lore in _CatalogHelper.get_lore_entries():
		var lid: String = str(lore.get("id", ""))
		if not lid.is_empty():
			_DiscoveryRegistry.register("lore", lid)
	for he_id in _CatalogHelper.STARTER_HISTORY_IDS:
		_DiscoveryRegistry.register("history", str(he_id))
	for room_id in ["heal", "treasure", "merchant", "event", "elite", "trap"]:
		_DiscoveryRegistry.register("room", room_id)
