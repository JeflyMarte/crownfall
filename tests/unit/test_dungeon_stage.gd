extends GutTest

## P3-DG-STG Phase 2 — サブステージ部屋列・章クリア分岐。

const _DungeonController = preload("res://scripts/dungeon/DungeonController.gd")

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

func _make_controller() -> Node:
	var dc: Node = _DungeonController.new()
	add_child_autofree(dc)
	return dc

func _stage_seq(stage_id: String) -> Array[int]:
	var dc: Node = _make_controller()
	dc.start_stage(stage_id)
	return dc.room_sequence.duplicate()

func test_stage_1_4_has_no_boss() -> void:
	var seq: Array[int] = _stage_seq("mourngate_1_4")
	assert_false(Enums.RoomType.BOSS in seq, "1-4 は Boss なし")
	assert_eq(seq[-1], Enums.RoomType.EXIT, "EXIT 締め")

func test_stage_1_5_has_boss_before_exit() -> void:
	var seq: Array[int] = _stage_seq("mourngate_1_5")
	assert_true(Enums.RoomType.BOSS in seq, "1-5 は Boss あり")
	assert_eq(seq[seq.size() - 2], Enums.RoomType.BOSS, "Boss は EXIT 直前")
	assert_eq(seq[-1], Enums.RoomType.EXIT)

func test_stage_1_4_requires_elite() -> void:
	seed(42)
	var seq: Array[int] = _stage_seq("mourngate_1_4")
	assert_true(Enums.RoomType.ELITE in seq, "1-4 は ELITE 必須")

func test_stage_enemy_level_overrides_biome() -> void:
	var dc: Node = _make_controller()
	dc.start_stage("mourngate_1_3")
	assert_eq(dc.get_enemy_level(), 3)

func test_first_stage_unlocked() -> void:
	assert_true(GameState.is_stage_unlocked("mourngate_1_1"))
	assert_false(GameState.is_stage_unlocked("mourngate_1_2"))

func test_stage_unlock_chain() -> void:
	GameState.mark_stage_cleared("mourngate_1_1")
	assert_true(GameState.is_stage_unlocked("mourngate_1_2"))
	assert_false(GameState.is_stage_unlocked("mourngate_1_3"))

func test_resolve_stage_picks_first_uncleared() -> void:
	GameState.current_stage_id = ""
	assert_eq(GameState.resolve_stage_for_run("mourngate"), "mourngate_1_1")
	GameState.mark_stage_cleared("mourngate_1_1")
	assert_eq(GameState.resolve_stage_for_run("mourngate"), "mourngate_1_2")

func test_stage_floor_count_matches_ssot() -> void:
	var dc: Node = _make_controller()
	dc.start_stage("mourngate_1_1")
	assert_eq(dc.room_sequence.size(), 6, "1-1 = 6F（EXIT 締め・Boss なし）")
	dc.start_stage("mourngate_1_5")
	assert_eq(dc.room_sequence.size(), 11, "1-5 = 10F + EXIT")

func test_display_floor_text() -> void:
	var dc: Node = _make_controller()
	dc.start_stage("mourngate_1_1")
	assert_eq(dc.get_display_floor_text(), "F1/6")
	dc.current_room_index = 2
	dc.current_room_type = dc.room_sequence[2]
	assert_eq(dc.get_display_floor_text(), "F3/6")
	dc.start_stage("mourngate_1_5")
	dc.current_room_index = dc.room_sequence.size() - 1
	dc.current_room_type = Enums.RoomType.EXIT
	assert_eq(dc.get_display_floor_text(), "EXIT")

func test_run_display_name_includes_chapter() -> void:
	var dc: Node = _make_controller()
	dc.start_stage("mourngate_1_3")
	assert_eq(dc.get_run_display_name(), "1-3 王墓の回廊")
	assert_eq(dc.get_run_recommended_level(), 5)

func _unlock_whisperwood() -> void:
	GameState.mark_stage_cleared("mourngate_1_5")

func test_whisperwood_2_4_has_no_boss() -> void:
	var seq: Array[int] = _stage_seq("whisperwood_2_4")
	assert_false(Enums.RoomType.BOSS in seq, "2-4 は Boss なし")
	assert_eq(seq[-1], Enums.RoomType.EXIT, "EXIT 締め")

func test_whisperwood_2_5_has_boss_before_exit() -> void:
	var seq: Array[int] = _stage_seq("whisperwood_2_5")
	assert_true(Enums.RoomType.BOSS in seq, "2-5 は Boss あり")
	assert_eq(seq[seq.size() - 2], Enums.RoomType.BOSS, "Boss は EXIT 直前")
	assert_eq(seq[-1], Enums.RoomType.EXIT)

func test_whisperwood_2_4_requires_elite() -> void:
	seed(42)
	var seq: Array[int] = _stage_seq("whisperwood_2_4")
	assert_true(Enums.RoomType.ELITE in seq, "2-4 は ELITE 必須")

func test_whisperwood_stage_enemy_level_overrides_biome() -> void:
	var dc: Node = _make_controller()
	dc.start_stage("whisperwood_2_3")
	assert_eq(dc.get_enemy_level(), 12)

func test_whisperwood_first_stage_locked_until_mourngate_cleared() -> void:
	assert_false(GameState.is_stage_unlocked("whisperwood_2_1"))
	_unlock_whisperwood()
	assert_true(GameState.is_stage_unlocked("whisperwood_2_1"))
	assert_false(GameState.is_stage_unlocked("whisperwood_2_2"))

func test_whisperwood_stage_unlock_chain() -> void:
	_unlock_whisperwood()
	GameState.mark_stage_cleared("whisperwood_2_1")
	assert_true(GameState.is_stage_unlocked("whisperwood_2_2"))
	assert_false(GameState.is_stage_unlocked("whisperwood_2_3"))

func test_whisperwood_floor_count_matches_ssot() -> void:
	var dc: Node = _make_controller()
	dc.start_stage("whisperwood_2_1")
	assert_eq(dc.room_sequence.size(), 6, "2-1 = 6F")
	dc.start_stage("whisperwood_2_5")
	assert_eq(dc.room_sequence.size(), 11, "2-5 = 10F + EXIT")

func test_whisperwood_run_display_name_includes_chapter() -> void:
	var dc: Node = _make_controller()
	dc.start_stage("whisperwood_2_3")
	assert_eq(dc.get_run_display_name(), "2-3 花蔓帯")
	assert_eq(dc.get_run_recommended_level(), 14)

func test_is_on_last_floor_before_exit() -> void:
	var dc: Node = _make_controller()
	dc.start_stage("mourngate_1_1")
	dc.current_room_index = 0
	dc.current_room_type = dc.room_sequence[0]
	assert_false(dc.is_on_last_floor_before_exit(), "F1 は最終フロアではない")
	dc.current_room_index = dc.room_sequence.size() - 2
	dc.current_room_type = dc.room_sequence[dc.current_room_index]
	assert_true(dc.is_on_last_floor_before_exit(), "EXIT 直前は最終フロア")
	dc.current_room_type = Enums.RoomType.EXIT
	assert_false(dc.is_on_last_floor_before_exit(), "EXIT 自身は対象外")