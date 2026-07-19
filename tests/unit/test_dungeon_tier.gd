extends GutTest

## P3-DG-TIER / P3-DG-TIER-002 — キャンペーン周回帯の危険度ティア。

const _DungeonTierConfig = preload("res://scripts/dungeon/DungeonTierConfig.gd")


func before_each() -> void:
	GameState.dungeon_tier_cleared = {}
	GameState.dungeon_progress = {}
	GameState.stage_progress = {}
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NORMAL
	_DungeonTierConfig.clear_cap_cache()


func _clear_all_main_normal() -> void:
	for biome_id: String in _DungeonTierConfig.MAIN_BIOME_IDS:
		GameState.mark_dungeon_cleared(biome_id)
		GameState.mark_dungeon_tier_cleared(biome_id, _DungeonTierConfig.TIER_NORMAL)


func _clear_all_main_hard() -> void:
	_clear_all_main_normal()
	for biome_id: String in _DungeonTierConfig.MAIN_BIOME_IDS:
		GameState.mark_dungeon_tier_cleared(biome_id, _DungeonTierConfig.TIER_HARD)


func test_normal_tier_always_unlocked() -> void:
	assert_true(GameState.is_dungeon_tier_unlocked("mourngate", _DungeonTierConfig.TIER_NORMAL))
	assert_false(GameState.is_dungeon_tier_unlocked("mourngate", _DungeonTierConfig.TIER_HARD))


func test_hard_requires_all_main_normal_cleared() -> void:
	GameState.mark_dungeon_cleared("mourngate")
	GameState.mark_dungeon_tier_cleared("mourngate", _DungeonTierConfig.TIER_NORMAL)
	assert_false(GameState.is_dungeon_tier_unlocked("mourngate", _DungeonTierConfig.TIER_HARD))
	_clear_all_main_normal()
	assert_true(GameState.is_dungeon_tier_unlocked("mourngate", _DungeonTierConfig.TIER_HARD))
	assert_true(GameState.is_dungeon_tier_unlocked("frostridge", _DungeonTierConfig.TIER_HARD))
	assert_false(GameState.is_dungeon_tier_unlocked("mourngate", _DungeonTierConfig.TIER_NIGHTMARE))


func test_nightmare_requires_all_main_hard_cleared() -> void:
	_clear_all_main_normal()
	assert_false(GameState.is_dungeon_tier_unlocked("mourngate", _DungeonTierConfig.TIER_NIGHTMARE))
	GameState.mark_dungeon_tier_cleared("mourngate", _DungeonTierConfig.TIER_HARD)
	assert_false(GameState.is_dungeon_tier_unlocked("mourngate", _DungeonTierConfig.TIER_NIGHTMARE))
	_clear_all_main_hard()
	assert_true(GameState.is_dungeon_tier_unlocked("mourngate", _DungeonTierConfig.TIER_NIGHTMARE))


func test_enemy_level_band_h11_gt_n55_and_nm11_gt_h55() -> void:
	var cap: int = _DungeonTierConfig.main_normal_cap_level()
	assert_eq(cap, 49, "N5-5 (frostridge_5_5) should define cap")
	assert_eq(_DungeonTierConfig.enemy_level_bonus(_DungeonTierConfig.TIER_HARD), cap)
	assert_eq(_DungeonTierConfig.enemy_level_bonus(_DungeonTierConfig.TIER_NIGHTMARE), cap * 2)
	var n55: int = 49
	var h11: int = 1 + _DungeonTierConfig.enemy_level_bonus(_DungeonTierConfig.TIER_HARD)
	var h55: int = 49 + _DungeonTierConfig.enemy_level_bonus(_DungeonTierConfig.TIER_HARD)
	var nm11: int = 1 + _DungeonTierConfig.enemy_level_bonus(_DungeonTierConfig.TIER_NIGHTMARE)
	assert_gt(h11, n55)
	assert_gt(nm11, h55)


func test_recommended_level_follows_tier_enemy_bonus() -> void:
	var cap: int = _DungeonTierConfig.main_normal_cap_level()
	assert_eq(_DungeonTierConfig.apply_tier_level(3, _DungeonTierConfig.TIER_NORMAL), 3)
	assert_eq(_DungeonTierConfig.apply_tier_level(3, _DungeonTierConfig.TIER_HARD), 3 + cap)
	assert_eq(_DungeonTierConfig.apply_tier_level(3, _DungeonTierConfig.TIER_NIGHTMARE), 3 + cap * 2)
	assert_eq(_DungeonTierConfig.apply_tier_level(0, _DungeonTierConfig.TIER_HARD), 0)
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.current_stage_data = DataRegistry.get_stage_data("mourngate_1_1")
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NORMAL
	assert_eq(dc.get_run_recommended_level(), 3)
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_HARD
	assert_eq(dc.get_run_recommended_level(), 3 + cap)


func test_tier_rarity_weight_scales() -> void:
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.current_dungeon_data = DataRegistry.get_dungeon_data("mourngate")
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NIGHTMARE
	assert_eq(dc.get_tier_rarity_weight(10), 16)
