extends GutTest

## P3-DG-EVENT-STG-001 — イベントDGもバナー下にサブ章。


var _saved_stage_progress: Dictionary = {}
var _saved_stage_id: String = ""
var _saved_dungeon_progress: Dictionary = {}


func before_each() -> void:
	_saved_stage_progress = GameState.stage_progress.duplicate(true)
	_saved_stage_id = GameState.current_stage_id
	_saved_dungeon_progress = GameState.dungeon_progress.duplicate(true)
	GameState.stage_progress = {}
	GameState.current_stage_id = ""
	GameState.dungeon_progress = {}
	GameState.event_dungeon_attempts.clear()


func after_each() -> void:
	GameState.stage_progress = _saved_stage_progress
	GameState.current_stage_id = _saved_stage_id
	GameState.dungeon_progress = _saved_dungeon_progress
	GameState.event_dungeon_attempts.clear()


func test_event_biomes_have_five_stages() -> void:
	var duck: Array = DataRegistry.get_stages_for_biome("cosmic_rift")
	var raven: Array = DataRegistry.get_stages_for_biome("crown_rookery")
	assert_eq(duck.size(), 5)
	assert_eq(raven.size(), 5)
	assert_eq(str(duck[0].id), "cosmic_rift_1_1")
	assert_eq(str(raven[4].id), "crown_rookery_1_5")


func test_uses_stage_cards_is_route_agnostic() -> void:
	## 章データがあれば main / event ともサブ章 UI 対象。
	assert_true(Constants.SUB_STAGES_PLAYABLE)
	assert_false(DataRegistry.get_stages_for_biome("cosmic_rift").is_empty())
	assert_false(DataRegistry.get_stages_for_biome("crown_rookery").is_empty())
	assert_false(DataRegistry.get_stages_for_biome("mourngate").is_empty())


func test_event_stage_unlock_chain() -> void:
	assert_true(GameState.is_stage_unlocked("cosmic_rift_1_1"))
	assert_false(GameState.is_stage_unlocked("cosmic_rift_1_2"))
	GameState.mark_stage_cleared("cosmic_rift_1_1")
	assert_true(GameState.is_stage_unlocked("cosmic_rift_1_2"))
	assert_false(GameState.is_stage_unlocked("cosmic_rift_1_3"))


func test_event_final_stage_marks_biome_cleared() -> void:
	for chapter: int in range(1, 6):
		GameState.mark_stage_cleared("cosmic_rift_1_%d" % chapter)
	assert_true(GameState.is_dungeon_cleared("cosmic_rift"))


func test_resolve_stage_for_event_biome() -> void:
	GameState.current_stage_id = ""
	assert_eq(GameState.resolve_stage_for_run("cosmic_rift"), "cosmic_rift_1_1")
	GameState.mark_stage_cleared("cosmic_rift_1_1")
	assert_eq(GameState.resolve_stage_for_run("cosmic_rift"), "cosmic_rift_1_2")


func test_start_event_stage_builds_sequence_without_boss() -> void:
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.start_stage("cosmic_rift_1_1")
	assert_eq(dc.room_sequence.size(), 4)
	assert_false(Enums.RoomType.BOSS in dc.room_sequence)
	assert_eq(dc.get_enemy_level(), 2)
	assert_eq(dc.get_run_display_name(), "1-1 星屑の浅瀬")
	dc.start_stage("crown_rookery_1_5")
	assert_eq(dc.room_sequence.size(), 6)
	assert_false(Enums.RoomType.BOSS in dc.room_sequence)
	assert_eq(dc.get_enemy_level(), 12)
