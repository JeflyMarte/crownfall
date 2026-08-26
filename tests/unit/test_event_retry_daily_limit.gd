extends GutTest
## P3-BUG-EVENT-RETRY-001 — 結果「再挑戦」も日次枠を踏む。

const _EventDungeonSchedule := preload("res://scripts/dungeon/EventDungeonSchedule.gd")


func before_each() -> void:
	_EventDungeonSchedule.set_debug_weekday_override(-2)
	GameState.event_dungeon_attempts.clear()


func after_each() -> void:
	GameState.event_dungeon_attempts.clear()
	_EventDungeonSchedule.clear_debug_weekday_override()
	GameState.current_dungeon_id = Constants.DEFAULT_DUNGEON_ID


func test_weekday_event_blocks_retry_after_select_consume() -> void:
	## 選択入場で1回消費済み → 結果時点では再挑戦不可（すり抜け防止）。
	assert_true(GameState.consume_event_dungeon_attempt("cosmic_rift"))
	GameState.current_dungeon_id = "cosmic_rift"
	assert_eq(GameState.event_dungeon_attempts_remaining("cosmic_rift"), 0)
	assert_false(GameState.can_attempt_event_dungeon("cosmic_rift"))
	assert_false(GameState.consume_event_dungeon_attempt("cosmic_rift"))


func test_descent_allows_retry_while_open() -> void:
	## 降臨は limit=0。出現中（デバッグ常時開放）なら消費しても再挑戦可。
	assert_eq(int(DataRegistry.get_dungeon_data("chronos_mausoleum").daily_attempt_limit), 0)
	assert_true(GameState.consume_event_dungeon_attempt("chronos_mausoleum"))
	GameState.current_dungeon_id = "chronos_mausoleum"
	assert_true(GameState.can_attempt_event_dungeon("chronos_mausoleum"))
	assert_true(GameState.consume_event_dungeon_attempt("chronos_mausoleum"))


func test_main_dungeon_retry_unlimited() -> void:
	GameState.current_dungeon_id = "mourngate"
	assert_true(GameState.can_attempt_event_dungeon("mourngate"))
	assert_true(GameState.consume_event_dungeon_attempt("mourngate"))
	assert_true(GameState.can_attempt_event_dungeon("mourngate"))


func test_result_scene_retry_gates_match_select() -> void:
	## ResultScene が選択入場と同じ API を使うこと（ソース契約）。
	var src: String = FileAccess.get_file_as_string("res://scripts/result/ResultScene.gd")
	assert_true(src.contains("consume_event_dungeon_attempt"), "retry must consume daily attempt")
	assert_true(src.contains("_can_retry_current_run"), "retry visibility gated")
	assert_true(src.contains("can_attempt_event_dungeon"), "retry uses can_attempt")
	assert_true(
		src.contains("_button_retry.visible = _can_retry_current_run()"),
		"MVP end gates retry visibility"
	)
