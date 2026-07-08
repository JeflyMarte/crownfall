extends GutTest

## P3-DG-STG Phase 5 — 章選択 UI 向け GameState 連携。

var _saved_stage_progress: Dictionary = {}
var _saved_stage_id: String = ""

func before_each() -> void:
	_saved_stage_progress = GameState.stage_progress
	_saved_stage_id = GameState.current_stage_id
	GameState.stage_progress = {}
	GameState.current_stage_id = ""

func after_each() -> void:
	GameState.stage_progress = _saved_stage_progress
	GameState.current_stage_id = _saved_stage_id

func test_resolve_respects_explicit_stage_selection() -> void:
	GameState.mark_stage_cleared("mourngate_1_1")
	GameState.mark_stage_cleared("mourngate_1_2")
	GameState.current_stage_id = "mourngate_1_1"
	assert_eq(GameState.resolve_stage_for_run("mourngate"), "mourngate_1_1")

func test_resolve_skips_locked_explicit_stage() -> void:
	GameState.current_stage_id = "mourngate_1_3"
	assert_eq(GameState.resolve_stage_for_run("mourngate"), "mourngate_1_1")

func test_stage_display_format_fields_exist() -> void:
	var stage: Resource = DataRegistry.get_stage_data("mourngate_1_3")
	assert_not_null(stage)
	assert_eq(int(stage.biome_index), 1)
	assert_eq(int(stage.chapter_index), 3)
	assert_eq(str(stage.display_name), "王墓の回廊")
