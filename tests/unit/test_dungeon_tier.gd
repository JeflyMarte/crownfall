extends GutTest

## P3-DG-TIER-STG-001 — 全局解禁 + 章×ティア進行。

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

func test_hard_locked_at_mourngate_1_2_before_global_gate() -> void:
	GameState.mark_stage_cleared("mourngate_1_1")
	assert_false(
		GameState.is_dungeon_tier_unlocked("mourngate", _DungeonTierConfig.TIER_HARD),
		"1-1 クリアだけではハード解禁しない",
	)

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

func test_clearing_mourngate_normal_does_not_unlock_hard() -> void:
	GameState.mark_dungeon_tier_cleared("mourngate", _DungeonTierConfig.TIER_NORMAL)
	assert_false(
		GameState.is_dungeon_tier_unlocked("mourngate", _DungeonTierConfig.TIER_HARD),
		"Biome ノーマル完走だけではハード解禁しない",
	)

func test_tier_rarity_weight_scales() -> void:
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.current_dungeon_data = DataRegistry.get_dungeon_data("mourngate")
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NIGHTMARE
	assert_eq(dc.get_tier_rarity_weight(10), 16)
