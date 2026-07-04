extends GutTest

## P3-DG-TIER — 同一DG危険度ティア（ノーマル/ハード/ナイトメア）。

const _DungeonTierConfig = preload("res://scripts/dungeon/DungeonTierConfig.gd")

func before_each() -> void:
	GameState.dungeon_tier_cleared = {}
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NORMAL

func test_normal_tier_always_unlocked() -> void:
	assert_true(GameState.is_dungeon_tier_unlocked("mourngate", _DungeonTierConfig.TIER_NORMAL))
	assert_false(GameState.is_dungeon_tier_unlocked("mourngate", _DungeonTierConfig.TIER_HARD))

func test_clear_normal_unlocks_hard() -> void:
	GameState.mark_dungeon_tier_cleared("mourngate", _DungeonTierConfig.TIER_NORMAL)
	assert_true(GameState.is_dungeon_tier_unlocked("mourngate", _DungeonTierConfig.TIER_HARD))
	assert_false(GameState.is_dungeon_tier_unlocked("mourngate", _DungeonTierConfig.TIER_NIGHTMARE))

func test_clear_hard_unlocks_nightmare() -> void:
	GameState.mark_dungeon_tier_cleared("mourngate", _DungeonTierConfig.TIER_NORMAL)
	GameState.mark_dungeon_tier_cleared("mourngate", _DungeonTierConfig.TIER_HARD)
	assert_true(GameState.is_dungeon_tier_unlocked("mourngate", _DungeonTierConfig.TIER_NIGHTMARE))

func test_enemy_level_bonus_by_tier() -> void:
	assert_eq(_DungeonTierConfig.enemy_level_bonus(_DungeonTierConfig.TIER_HARD), 3)
	assert_eq(_DungeonTierConfig.enemy_level_bonus(_DungeonTierConfig.TIER_NIGHTMARE), 6)

func test_tier_rarity_weight_scales() -> void:
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.current_dungeon_data = DataRegistry.get_dungeon_data("mourngate")
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NIGHTMARE
	assert_eq(dc.get_tier_rarity_weight(10), 16)
