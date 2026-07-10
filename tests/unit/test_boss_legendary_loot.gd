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
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NORMAL
	var dc: Node = _make_controller("mourngate_1_5")
	var stage: Resource = dc.current_stage_data
	var bonus: Dictionary = dc.apply_boss_legendary_loot(stage)
	assert_eq(str(bonus["armor_id"]), "serdion_ward_plate")
	assert_eq(str(bonus["accessory_id"]), "mourngate_royal_seal")
	assert_eq(GameState.armor_inventory.size(), 1)
	assert_eq(GameState.accessory_inventory.size(), 1)
	assert_eq(str(GameState.armor_inventory[0].armor_id), "serdion_ward_plate")
	assert_eq(str(GameState.accessory_inventory[0].accessory_id), "mourngate_royal_seal")
	assert_true(
		_EquipmentEnhancer.get_equip_level(GameState.armor_inventory[0]) >= 4,
		"ボス章 enemy_level=5 帯のドロップLv"
	)

func test_repeat_clear_skips_legendary() -> void:
	GameState.stage_progress.erase("mourngate_1_5")
	GameState.mark_stage_cleared("mourngate_1_5", _DungeonTierConfig.TIER_NORMAL)
	GameState.armor_inventory.clear()
	GameState.accessory_inventory.clear()
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NORMAL
	var dc: Node = _make_controller("mourngate_1_5")
	var bonus: Dictionary = dc.apply_boss_legendary_loot(dc.current_stage_data)
	assert_true(str(bonus["armor_id"]).is_empty())
	assert_true(str(bonus["accessory_id"]).is_empty())
	assert_eq(GameState.armor_inventory.size(), 0)
	assert_eq(GameState.accessory_inventory.size(), 0)

func test_hard_tier_skips_legendary() -> void:
	GameState.stage_progress.erase("mourngate_1_5")
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_HARD
	var dc: Node = _make_controller("mourngate_1_5")
	var bonus: Dictionary = dc.apply_boss_legendary_loot(dc.current_stage_data)
	assert_true(str(bonus["armor_id"]).is_empty())
	assert_true(str(bonus["accessory_id"]).is_empty())


func test_whisperwood_first_boss_clear_grants_legendary_pair() -> void:
	GameState.stage_progress.erase("whisperwood_2_5")
	GameState.armor_inventory.clear()
	GameState.accessory_inventory.clear()
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NORMAL
	var dc: Node = _make_controller("whisperwood_2_5")
	var bonus: Dictionary = dc.apply_boss_legendary_loot(dc.current_stage_data)
	assert_eq(str(bonus["armor_id"]), "granvel_bark_plate")
	assert_eq(str(bonus["accessory_id"]), "silvaria_covenant_ring")

