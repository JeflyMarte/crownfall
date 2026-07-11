extends GutTest

## P3-DG-TIER-STG-001 — 全局解禁 + 章×ティア進行 + 敵Lv加算。

const _DungeonTierConfig = preload("res://scripts/dungeon/DungeonTierConfig.gd")

func before_each() -> void:
	GameState.dungeon_tier_cleared = {}
	GameState.stage_progress = {}
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NORMAL

func test_normal_tier_always_unlocked() -> void:
	assert_true(GameState.is_global_tier_unlocked(_DungeonTierConfig.TIER_NORMAL))
	assert_true(GameState.is_dungeon_tier_unlocked("mourngate", _DungeonTierConfig.TIER_NORMAL))

func test_hard_requires_normal_5_5_clear() -> void:
	assert_false(GameState.is_global_tier_unlocked(_DungeonTierConfig.TIER_HARD))
	assert_false(GameState.is_dungeon_tier_unlocked("mourngate", _DungeonTierConfig.TIER_HARD))
	GameState.mark_stage_cleared("frostridge_5_5", _DungeonTierConfig.TIER_NORMAL)
	assert_true(GameState.is_global_tier_unlocked(_DungeonTierConfig.TIER_HARD))
	assert_true(GameState.is_dungeon_tier_unlocked("mourngate", _DungeonTierConfig.TIER_HARD))

func test_nightmare_requires_hard_5_5_clear() -> void:
	GameState.mark_stage_cleared("frostridge_5_5", _DungeonTierConfig.TIER_NORMAL)
	assert_false(GameState.is_global_tier_unlocked(_DungeonTierConfig.TIER_NIGHTMARE))
	GameState.mark_stage_cleared("frostridge_5_5", _DungeonTierConfig.TIER_HARD)
	assert_true(GameState.is_global_tier_unlocked(_DungeonTierConfig.TIER_NIGHTMARE))

func test_hard_1_1_unlocked_after_global_hard_gate() -> void:
	GameState.mark_stage_cleared("frostridge_5_5", _DungeonTierConfig.TIER_NORMAL)
	assert_true(GameState.is_stage_unlocked("mourngate_1_1", _DungeonTierConfig.TIER_HARD))
	assert_false(GameState.is_stage_unlocked("mourngate_1_2", _DungeonTierConfig.TIER_HARD))

func test_hard_1_2_requires_hard_1_1() -> void:
	GameState.mark_stage_cleared("frostridge_5_5", _DungeonTierConfig.TIER_NORMAL)
	GameState.mark_stage_cleared("mourngate_1_1", _DungeonTierConfig.TIER_HARD)
	assert_true(GameState.is_stage_unlocked("mourngate_1_2", _DungeonTierConfig.TIER_HARD))

func test_hard_2_1_requires_hard_1_5() -> void:
	GameState.mark_stage_cleared("frostridge_5_5", _DungeonTierConfig.TIER_NORMAL)
	for chapter in range(1, 5):
		GameState.mark_stage_cleared("mourngate_1_%d" % chapter, _DungeonTierConfig.TIER_HARD)
	assert_false(GameState.is_stage_unlocked("whisperwood_2_1", _DungeonTierConfig.TIER_HARD))
	GameState.mark_stage_cleared("mourngate_1_5", _DungeonTierConfig.TIER_HARD)
	assert_true(GameState.is_stage_unlocked("whisperwood_2_1", _DungeonTierConfig.TIER_HARD))

func test_hard_1_1_enemy_level_beats_normal_5_5() -> void:
	var normal_final: Resource = DataRegistry.get_stage_data("frostridge_5_5")
	var hard_start: Resource = DataRegistry.get_stage_data("mourngate_1_1")
	var normal_lv: int = _DungeonTierConfig.scaled_enemy_level(int(normal_final.enemy_level), _DungeonTierConfig.TIER_NORMAL)
	var hard_lv: int = _DungeonTierConfig.scaled_enemy_level(int(hard_start.enemy_level), _DungeonTierConfig.TIER_HARD)
	assert_gt(hard_lv, normal_lv)

func test_mourngate_hard_pool_uses_variants() -> void:
	var data: Resource = DataRegistry.get_dungeon_data("mourngate")
	assert_true(data is DungeonData)
	var pool: Array = (data as DungeonData).combat_enemy_pool_for_tier(_DungeonTierConfig.TIER_HARD)
	assert_true("corrosion_death_hound" in pool)
	assert_false("sepia_hound" in pool)

func test_mourngate_normal_pool_uses_base_trash() -> void:
	var data: DungeonData = DataRegistry.get_dungeon_data("mourngate") as DungeonData
	var pool: Array = data.combat_enemy_pool_for_tier(_DungeonTierConfig.TIER_NORMAL)
	assert_true("sepia_hound" in pool)
	assert_false("corrosion_death_hound" in pool)

func test_tier_rarity_weight_scales() -> void:
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.current_dungeon_data = DataRegistry.get_dungeon_data("mourngate")
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NIGHTMARE
	assert_eq(dc.get_tier_rarity_weight(10), 16)
