extends GutTest
## P3-EQ-LEG-001 — x-5 初回ボス討伐のレジェンド防具・装飾確定ドロップ。

const _DungeonController = preload("res://scripts/dungeon/DungeonController.gd")
const _DungeonTierConfig = preload("res://scripts/dungeon/DungeonTierConfig.gd")
const _EquipmentEnhancer = preload("res://scripts/equipment/EquipmentEnhancer.gd")

func _make_controller(stage_id: String) -> Node:
	var dc: Node = _DungeonController.new()
	add_child_autofree(dc)
	dc.start_stage(stage_id)
	return dc

func test_first_boss_clear_grants_legendary_pair() -> void:
	GameState.stage_progress.erase("mourngate_1_5")
	GameState.armor_inventory.clear()
	GameState.accessory_inventory.clear()
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NORMAL
	var dc: Node = _make_controller("mourngate_1_5")
	var stage: Resource = dc.current_stage_data
	var bonus: Dictionary = dc.apply_boss_legendary_loot(stage, str(stage.boss_id))
	assert_eq(str(bonus["armor_id"]), "serdion_ward_plate")
	assert_eq(str(bonus["accessory_id"]), "mourngate_royal_seal")
	## Biome固定2＋ビルド拡張L1（P3-EQ-LEG-BUILD-001）
	assert_eq(GameState.armor_inventory.size() + GameState.accessory_inventory.size(), 3)
	assert_true(_inventory_has_armor("serdion_ward_plate"))
	assert_true(_inventory_has_accessory("mourngate_royal_seal"))
	assert_false(str(bonus.get("build_id", "")).is_empty())
	var biome_armor: Resource = _find_armor("serdion_ward_plate")
	assert_true(
		_EquipmentEnhancer.get_equip_level(biome_armor) >= 4,
		"ボス章 enemy_level=5 帯のドロップLv"
	)


func test_summon_kill_does_not_grant_legendary() -> void:
	## ネレイオン召喚（黒潮鮫）撃破では潮鳴王の鎧を出さない。
	GameState.stage_progress.erase("blackshore_4_5")
	GameState.armor_inventory.clear()
	GameState.accessory_inventory.clear()
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NORMAL
	var dc: Node = _make_controller("blackshore_4_5")
	var stage: Resource = dc.current_stage_data
	assert_false(dc.is_run_boss_kill(DataRegistry.get_enemy_data("black_tide_shark")))
	assert_true(dc.is_run_boss_kill(DataRegistry.get_enemy_data("nereion")))
	var bonus: Dictionary = dc.apply_boss_legendary_loot(stage, "black_tide_shark")
	assert_true(str(bonus["armor_id"]).is_empty())
	assert_true(str(bonus["accessory_id"]).is_empty())
	assert_eq(GameState.armor_inventory.size(), 0)
	bonus = dc.apply_boss_legendary_loot(stage, "nereion")
	assert_eq(str(bonus["armor_id"]), "nereion_tide_plate")
	assert_eq(str(bonus["accessory_id"]), "pharos_beacon_ring")


func _inventory_has_armor(armor_id: String) -> bool:
	for inst: Variant in GameState.armor_inventory:
		if inst != null and str(inst.armor_id) == armor_id:
			return true
	return false


func _inventory_has_accessory(accessory_id: String) -> bool:
	for inst: Variant in GameState.accessory_inventory:
		if inst != null and str(inst.accessory_id) == accessory_id:
			return true
	return false


func _find_armor(armor_id: String) -> Resource:
	for inst: Variant in GameState.armor_inventory:
		if inst != null and str(inst.armor_id) == armor_id:
			return inst
	return null

func test_repeat_clear_skips_legendary() -> void:
	GameState.stage_progress.erase("mourngate_1_5")
	GameState.mark_stage_cleared("mourngate_1_5", _DungeonTierConfig.TIER_NORMAL)
	GameState.armor_inventory.clear()
	GameState.accessory_inventory.clear()
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NORMAL
	var dc: Node = _make_controller("mourngate_1_5")
	var bonus: Dictionary = dc.apply_boss_legendary_loot(dc.current_stage_data, "serdion")
	assert_true(str(bonus["armor_id"]).is_empty())
	assert_true(str(bonus["accessory_id"]).is_empty())
	assert_eq(GameState.armor_inventory.size(), 0)
	assert_eq(GameState.accessory_inventory.size(), 0)

func test_hard_tier_first_clear_grants_legendary() -> void:
	## P3-BAL-DROP-001: Hard/NM もティア別初回で ★ 防具＋装飾を付与
	GameState.stage_progress.erase("mourngate_1_5")
	GameState.armor_inventory.clear()
	GameState.accessory_inventory.clear()
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_HARD
	var dc: Node = _make_controller("mourngate_1_5")
	var bonus: Dictionary = dc.apply_boss_legendary_loot(dc.current_stage_data, "serdion")
	assert_eq(str(bonus["armor_id"]), "serdion_ward_plate")
	assert_eq(str(bonus["accessory_id"]), "mourngate_royal_seal")
	assert_eq(GameState.armor_inventory.size() + GameState.accessory_inventory.size(), 3)
	assert_true(_inventory_has_armor("serdion_ward_plate"))
	assert_true(_inventory_has_accessory("mourngate_royal_seal"))


func test_hard_repeat_clear_skips_legendary() -> void:
	GameState.stage_progress.erase("mourngate_1_5")
	GameState.mark_stage_cleared("mourngate_1_5", _DungeonTierConfig.TIER_HARD)
	GameState.armor_inventory.clear()
	GameState.accessory_inventory.clear()
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_HARD
	var dc: Node = _make_controller("mourngate_1_5")
	var bonus: Dictionary = dc.apply_boss_legendary_loot(dc.current_stage_data, "serdion")
	assert_true(str(bonus["armor_id"]).is_empty())
	assert_true(str(bonus["accessory_id"]).is_empty())


func test_whisperwood_first_boss_clear_grants_legendary_pair() -> void:
	GameState.stage_progress.erase("whisperwood_2_5")
	GameState.armor_inventory.clear()
	GameState.accessory_inventory.clear()
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NORMAL
	var dc: Node = _make_controller("whisperwood_2_5")
	var bonus: Dictionary = dc.apply_boss_legendary_loot(dc.current_stage_data, "granvel")
	assert_eq(str(bonus["armor_id"]), "granvel_bark_plate")
	assert_eq(str(bonus["accessory_id"]), "silvaria_covenant_ring")

