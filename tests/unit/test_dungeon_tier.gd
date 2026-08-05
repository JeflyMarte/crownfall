extends GutTest

## P3-DG-TIER / P3-DG-TIER-002 → P3-BAL-NM-CAP99-001 — キャンペーン周回帯の危険度ティア。

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


func test_enemy_level_targets_h55_75_nm55_99() -> void:
	_DungeonTierConfig.clear_cap_cache()
	var n_end: int = _DungeonTierConfig.main_normal_end_recommended_level()
	assert_eq(n_end, 51, "N5-5 recommended_level defines end rec")
	var h_bonus: int = _DungeonTierConfig.enemy_level_bonus(_DungeonTierConfig.TIER_HARD)
	var nm_bonus: int = _DungeonTierConfig.enemy_level_bonus(_DungeonTierConfig.TIER_NIGHTMARE)
	assert_eq(h_bonus, _DungeonTierConfig.TARGET_HARD_END_RECOMMENDED - n_end)
	assert_eq(nm_bonus, _DungeonTierConfig.TARGET_NIGHTMARE_END_RECOMMENDED - n_end)
	assert_eq(n_end + h_bonus, 75, "H5-5 recommended target")
	assert_eq(n_end + nm_bonus, 99, "NM5-5 recommended target")
	# Cap (enemy_level) still tracks N5-5; bonuses no longer equal +cap/+2cap.
	assert_eq(_DungeonTierConfig.main_normal_cap_level(), 49)
	assert_ne(h_bonus, 49)
	assert_ne(nm_bonus, 98)


func test_recommended_level_follows_tier_enemy_bonus() -> void:
	_DungeonTierConfig.clear_cap_cache()
	var h_bonus: int = _DungeonTierConfig.enemy_level_bonus(_DungeonTierConfig.TIER_HARD)
	var nm_bonus: int = _DungeonTierConfig.enemy_level_bonus(_DungeonTierConfig.TIER_NIGHTMARE)
	assert_eq(_DungeonTierConfig.apply_tier_level(3, _DungeonTierConfig.TIER_NORMAL), 3)
	assert_eq(_DungeonTierConfig.apply_tier_level(3, _DungeonTierConfig.TIER_HARD), 3 + h_bonus)
	assert_eq(_DungeonTierConfig.apply_tier_level(3, _DungeonTierConfig.TIER_NIGHTMARE), 3 + nm_bonus)
	assert_eq(_DungeonTierConfig.apply_tier_level(0, _DungeonTierConfig.TIER_HARD), 0)
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.current_stage_data = DataRegistry.get_stage_data("mourngate_1_1")
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NORMAL
	assert_eq(dc.get_run_recommended_level(), 1)
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_HARD
	assert_eq(dc.get_run_recommended_level(), 1 + h_bonus)
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NIGHTMARE
	assert_eq(dc.get_run_recommended_level(), 1 + nm_bonus)


func test_tier_rarity_weight_scales() -> void:
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.current_dungeon_data = DataRegistry.get_dungeon_data("mourngate")
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NIGHTMARE
	assert_eq(dc.get_tier_rarity_weight(10), 16)


func test_clear_token_reward_scales_with_tier() -> void:
	## P3-BAL-CLEAR-TOKEN-HALF-001: 基礎18–33 × H1.2 / NM1.4（切り上げ）
	assert_eq(_DungeonTierConfig.CLEAR_TOKEN_MIN, 18)
	assert_eq(_DungeonTierConfig.CLEAR_TOKEN_MAX, 33)
	seed(1)
	for _i in 30:
		var n: int = _DungeonTierConfig.clear_token_reward(_DungeonTierConfig.TIER_NORMAL)
		assert_true(n >= 18 and n <= 33, "Normal token %d" % n)
		var h: int = _DungeonTierConfig.clear_token_reward(_DungeonTierConfig.TIER_HARD)
		assert_true(h >= 22 and h <= 40, "Hard token %d" % h)
		var nm: int = _DungeonTierConfig.clear_token_reward(_DungeonTierConfig.TIER_NIGHTMARE)
		assert_true(nm >= 26 and nm <= 47, "NM token %d" % nm)
