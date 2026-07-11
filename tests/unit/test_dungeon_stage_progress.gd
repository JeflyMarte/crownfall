extends GutTest

## P3-DG-STG Phase 4 — 章解放・Biome 直列・セーブ同期。

const _DungeonTierConfig = preload("res://scripts/dungeon/DungeonTierConfig.gd")

var _saved_dungeon_progress: Dictionary = {}
var _saved_stage_progress: Dictionary = {}
var _saved_dungeon_tier: int = 0

func before_each() -> void:
	_saved_dungeon_progress = GameState.dungeon_progress
	_saved_stage_progress = GameState.stage_progress
	_saved_dungeon_tier = GameState.current_dungeon_tier
	GameState.dungeon_progress = {}
	GameState.stage_progress = {}
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NORMAL

func after_each() -> void:
	GameState.dungeon_progress = _saved_dungeon_progress
	GameState.stage_progress = _saved_stage_progress
	GameState.current_dungeon_tier = _saved_dungeon_tier

func test_chapter_clear_does_not_unlock_next_biome() -> void:
	if not Constants.SUB_STAGES_PLAYABLE:
		pass_test("SUB_STAGES off")
		return
	for chapter in range(1, 5):
		GameState.mark_stage_cleared("mourngate_1_%d" % chapter)
	assert_false(GameState.is_dungeon_cleared("mourngate"))
	assert_false(GameState.is_dungeon_unlocked("whisperwood"))

func test_final_chapter_unlocks_next_biome() -> void:
	if not Constants.SUB_STAGES_PLAYABLE:
		pass_test("SUB_STAGES off")
		return
	GameState.mark_stage_cleared("mourngate_1_5")
	assert_true(GameState.is_dungeon_cleared("mourngate"))
	assert_true(GameState.is_dungeon_unlocked("whisperwood"))

func test_mid_chapter_unlocks_next_chapter_only() -> void:
	GameState.mark_stage_cleared("mourngate_1_2")
	assert_true(GameState.is_stage_unlocked("mourngate_1_3"))
	assert_false(GameState.is_stage_unlocked("mourngate_1_4"))

func test_hard_boss_does_not_count_as_biome_clear() -> void:
	GameState.mark_stage_cleared("mourngate_1_5", _DungeonTierConfig.TIER_HARD)
	assert_false(GameState.is_dungeon_cleared("mourngate"))
	assert_false(GameState.is_dungeon_unlocked("whisperwood"))
	assert_true(GameState.is_dungeon_tier_cleared("mourngate", _DungeonTierConfig.TIER_HARD))

func test_sync_progress_from_stages() -> void:
	GameState.stage_progress = {
		"mourngate_1_5": {
			"cleared": true,
			"tiers": {str(_DungeonTierConfig.TIER_NORMAL): true},
		},
	}
	GameState.dungeon_progress = {}
	GameState.sync_progress_from_stages()
	assert_true(GameState.is_dungeon_cleared("mourngate"))

func test_stage_progress_label() -> void:
	GameState.mark_stage_cleared("mourngate_1_1")
	GameState.mark_stage_cleared("mourngate_1_2")
	assert_eq(GameState.get_stage_progress_label("mourngate"), "章 2/5")

func test_whisperwood_final_chapter_unlocks_next_biome() -> void:
	if not Constants.SUB_STAGES_PLAYABLE:
		pass_test("SUB_STAGES off")
		return
	GameState.mark_stage_cleared("mourngate_1_5")
	GameState.mark_stage_cleared("whisperwood_2_5")
	assert_true(GameState.is_dungeon_cleared("whisperwood"))
	assert_true(GameState.is_dungeon_unlocked("mistfen"))

func test_whisperwood_mid_chapter_does_not_unlock_mistfen() -> void:
	if not Constants.SUB_STAGES_PLAYABLE:
		pass_test("SUB_STAGES off")
		return
	GameState.mark_stage_cleared("mourngate_1_5")
	for chapter in range(1, 5):
		GameState.mark_stage_cleared("whisperwood_2_%d" % chapter)
	assert_false(GameState.is_dungeon_cleared("whisperwood"))
	assert_false(GameState.is_dungeon_unlocked("mistfen"))
