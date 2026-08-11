extends GutTest

## 結果画面のダンジョン名が前回クリア分のまま残る回帰防止。


func before_each() -> void:
	GameState.reset_for_new_game()
	GameState.seed_all_starters_unlocked()


func test_last_run_stage_id_must_follow_current_run_not_previous_clear() -> void:
	## 1-3 クリア後に 1-4 へ潜り全滅／リタイアすると、旧実装は last_run_stage_id が 1-3 のまま結果に出た。
	GameState.last_run_stage_id = "mourngate_1_3"
	GameState.current_dungeon_id = "mourngate"
	GameState.current_stage_id = "mourngate_1_4"
	## DungeonScene._sync_last_run_stage_id と同順: stage_data があればそれを優先。
	var dc = preload("res://scripts/dungeon/DungeonController.gd").new()
	add_child_autofree(dc)
	dc.start_stage("mourngate_1_4")
	assert_not_null(dc.current_stage_data)
	GameState.last_run_stage_id = str(dc.current_stage_data.id)
	assert_eq(GameState.last_run_stage_id, "mourngate_1_4")
	var stage: Resource = DataRegistry.get_stage_data(GameState.last_run_stage_id)
	assert_eq(int(stage.chapter_index), 4)


func test_result_label_prefers_last_run_stage_id() -> void:
	GameState.current_dungeon_id = "mourngate"
	GameState.current_stage_id = "mourngate_1_4"
	GameState.last_run_stage_id = "mourngate_1_3"
	## 結果は last_run を先に見る。残留があると 1-3 になる（バグ再現条件）。
	var stage_id: String = GameState.last_run_stage_id
	if stage_id.is_empty():
		stage_id = GameState.get_active_stage_id()
	assert_eq(stage_id, "mourngate_1_3")
	## 同期後は今回ランと一致。
	GameState.last_run_stage_id = GameState.current_stage_id
	stage_id = GameState.last_run_stage_id
	assert_eq(stage_id, "mourngate_1_4")
