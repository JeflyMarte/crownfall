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
	var scarab: Array = DataRegistry.get_stages_for_biome("golden_nest")
	var stalker: Array = DataRegistry.get_stages_for_biome("shadow_hunt")
	assert_eq(duck.size(), 1)
	assert_eq(raven.size(), 1)
	assert_eq(scarab.size(), 1)
	assert_eq(stalker.size(), 1)
	assert_eq(str(duck[0].id), "cosmic_rift_1_1")
	assert_eq(str(raven[0].id), "crown_rookery_1_1")
	assert_eq(str(scarab[0].id), "golden_nest_1_1")
	assert_eq(str(stalker[0].id), "shadow_hunt_1_1")


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
	assert_eq(
		IconPaths.stage_icon_path("golden_nest_1_1"),
		"res://assets/dungeon/event/stages/ICO_DG_GoldenNest_1_1.png"
	)
	assert_eq(
		IconPaths.stage_icon_path("shadow_hunt_1_1"),
		"res://assets/dungeon/event/stages/ICO_DG_ShadowHunt_1_1.png"
	)
	assert_true(FileAccess.file_exists("res://assets/dungeon/event/stages/ICO_DG_CosmicRift_1_1.png"))
	assert_true(FileAccess.file_exists("res://assets/dungeon/event/stages/ICO_DG_CrownRookery_1_1.png"))
	assert_true(FileAccess.file_exists("res://assets/dungeon/event/stages/ICO_DG_GoldenNest_1_1.png"))
	assert_true(FileAccess.file_exists("res://assets/dungeon/event/stages/ICO_DG_ShadowHunt_1_1.png"))


func test_event_biome_banners_are_unique() -> void:
	## イベント4種は mourngate 流用ではなく専用 BAN_DG_* を持つ。
	var expected: Dictionary = {
		"cosmic_rift": "res://assets/ui/dungeon/BAN_DG_CosmicRift.png",
		"crown_rookery": "res://assets/ui/dungeon/BAN_DG_CrownRookery.png",
		"golden_nest": "res://assets/ui/dungeon/BAN_DG_GoldenNest.png",
		"shadow_hunt": "res://assets/ui/dungeon/BAN_DG_ShadowHunt.png",
	}
	for dungeon_id in expected.keys():
		var path: String = str(expected[dungeon_id])
		assert_true(FileAccess.file_exists(path), path)
		var tex: Texture2D = load(path) as Texture2D
		assert_not_null(tex, path)
		assert_gt(tex.get_width(), 0, path)


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
	dc.start_stage("golden_nest_1_1")
	assert_eq(dc.room_sequence.size(), 5)
	assert_false(Enums.RoomType.BOSS in dc.room_sequence)
	assert_eq(dc.get_enemy_level(), 4)
	assert_eq(dc.get_run_display_name(), "1-1 砂金の巣穴")
	dc.start_stage("shadow_hunt_1_1")
	assert_eq(dc.room_sequence.size(), 5)
	assert_false(Enums.RoomType.BOSS in dc.room_sequence)
	assert_eq(dc.get_enemy_level(), 14)
	assert_eq(dc.get_run_display_name(), "1-1 影狩りの狩場")
