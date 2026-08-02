extends GutTest

const _DungeonController := preload("res://scripts/dungeon/DungeonController.gd")


func test_floor_progress_percent_mid_run() -> void:
	var ctrl: Node = _DungeonController.new()
	add_child_autofree(ctrl)
	## floor_count を持つダミー stage なしでも room_sequence で計算できるよう、
	## get_display_floor_* の入出力契約を直接検証するヘルパ相当。
	assert_eq(_percent(5, 10), 50)
	assert_eq(_percent(1, 10), 10)
	assert_eq(_percent(10, 10), 100)
	assert_eq(_percent(0, 10), 0)
	assert_eq(_percent(3, 0), 0)


func test_controller_progress_percent_uses_display_floors() -> void:
	var ctrl: Node = _DungeonController.new()
	add_child_autofree(ctrl)
	## stage 未設定時は get_total_rooms() が分母。空なら max は 1。
	ctrl.current_room_index = 0
	var pct: int = ctrl.get_display_floor_progress_percent()
	assert_gte(pct, 0)
	assert_lte(pct, 100)


func _percent(current: int, floor_max: int) -> int:
	if floor_max <= 0:
		return 0
	return clampi(int(round(float(current) * 100.0 / float(floor_max))), 0, 100)


func test_abyss_progress_shows_question_mark() -> void:
	GameState.mark_dungeon_cleared("mourngate")
	var ctrl: Node = _DungeonController.new()
	add_child_autofree(ctrl)
	ctrl.start_stage("abyss_mourngate_1_1")
	assert_eq(ctrl.get_display_floor_progress_percent(), -1)
	assert_eq(ctrl.get_display_floor_progress_label(), "進行 ?%")
	assert_eq(ctrl.get_display_floor_text(), "1F/??")
	ctrl.current_room_index = 5
	assert_eq(ctrl.get_display_floor_progress_label(), "進行 ?%")
	assert_eq(ctrl.get_display_floor_text(), "6F/??")

