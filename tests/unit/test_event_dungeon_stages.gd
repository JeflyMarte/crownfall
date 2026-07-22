extends GutTest

## P3-DG-EVENT-STG-001 — イベントDGもバナー下にサブ章（各1章）。


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


func test_event_biomes_have_one_stage() -> void:
	var duck: Array = DataRegistry.get_stages_for_biome("cosmic_rift")
	var raven: Array = DataRegistry.get_stages_for_biome("crown_rookery")
	assert_eq(duck.size(), 1)
	assert_eq(raven.size(), 1)
	assert_eq(str(duck[0].id), "cosmic_rift_1_1")
	assert_eq(str(raven[0].id), "crown_rookery_1_1")


func test_uses_stage_cards_is_route_agnostic() -> void:
	## 章データがあれば main / event ともサブ章 UI 対象。
	assert_true(Constants.SUB_STAGES_PLAYABLE)
	assert_false(DataRegistry.get_stages_for_biome("cosmic_rift").is_empty())
	assert_false(DataRegistry.get_stages_for_biome("crown_rookery").is_empty())
	assert_false(DataRegistry.get_stages_for_biome("mourngate").is_empty())


func test_event_single_stage_unlocked_and_clears_biome() -> void:
	assert_true(GameState.is_stage_unlocked("cosmic_rift_1_1"))
	assert_eq(DataRegistry.get_stage_by_chapter("cosmic_rift", 2), null)
	GameState.mark_stage_cleared("cosmic_rift_1_1")
	assert_true(GameState.is_dungeon_cleared("cosmic_rift"))


func test_resolve_stage_for_event_biome() -> void:
	GameState.current_stage_id = ""
	assert_eq(GameState.resolve_stage_for_run("cosmic_rift"), "cosmic_rift_1_1")
	GameState.mark_stage_cleared("cosmic_rift_1_1")
	## 唯一の章なのでクリア後も同じ章を周回候補に返す。
	assert_eq(GameState.resolve_stage_for_run("cosmic_rift"), "cosmic_rift_1_1")


func test_event_stage_icons_are_mapped() -> void:
	## イベント章もメイン同様に stage アイコンを持つ（パス配線＋ファイル実在）。
	assert_eq(
		IconPaths.stage_icon_path("cosmic_rift_1_1"),
		"res://assets/dungeon/event/stages/ICO_DG_CosmicRift_1_1.png"
	)
	assert_eq(
		IconPaths.stage_icon_path("crown_rookery_1_1"),
		"res://assets/dungeon/event/stages/ICO_DG_CrownRookery_1_1.png"
	)
	assert_true(FileAccess.file_exists("res://assets/dungeon/event/stages/ICO_DG_CosmicRift_1_1.png"))
	assert_true(FileAccess.file_exists("res://assets/dungeon/event/stages/ICO_DG_CrownRookery_1_1.png"))


func test_start_event_stage_builds_sequence_without_boss() -> void:
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.start_stage("cosmic_rift_1_1")
	assert_eq(dc.room_sequence.size(), 5)
	assert_false(Enums.RoomType.BOSS in dc.room_sequence)
	assert_eq(dc.get_enemy_level(), 3)
	assert_eq(dc.get_run_display_name(), "1-1 コズミックダックの裂け目")
	dc.start_stage("crown_rookery_1_1")
	assert_eq(dc.room_sequence.size(), 5)
	assert_false(Enums.RoomType.BOSS in dc.room_sequence)
	assert_eq(dc.get_enemy_level(), 10)
