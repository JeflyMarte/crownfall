extends GutTest

## 前列空きの陣形保存／調査派遣中の拒否文言。


func before_each() -> void:
	GameState.reset_for_new_game()
	GameState.seed_all_starters_unlocked()
	GameState.hub_survey_cycle = {}


func test_save_party_with_empty_front_slot_succeeds() -> void:
	assert_gte(GameState.roster.size(), 3)
	var a: Resource = GameState.roster[0]
	var b: Resource = GameState.roster[1]
	var c: Resource = GameState.roster[2]
	var scene: Node = load("res://scenes/roster/RosterScene.tscn").instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	scene._selected = [a, b, c]
	## 画面スクショと同型: 左前空き / 右前1 / 後列2
	scene._formation_slots = [null, a, b, c]
	scene._on_save_pressed()
	assert_eq(str(scene._label_status.text), "編成を保存しました")
	assert_eq(GameState.party_members.size(), 3)
	assert_eq(GameState.party_members[0], a)
	assert_eq(GameState.get_member_formation_slot(a), 1)
	assert_eq(GameState.get_member_formation_row(a), GameState.FORMATION_FRONT)
	assert_eq(GameState.get_member_formation_row(b), GameState.FORMATION_BACK)


func test_save_fails_with_survey_dispatched_message() -> void:
	assert_gte(GameState.roster.size(), 2)
	var a: Resource = GameState.roster[0]
	var b: Resource = GameState.roster[1]
	GameState.hub_survey_cycle = {
		"dungeon_id": "mourngate",
		"preset": "standard",
		"start_unix": Time.get_unix_time_from_system(),
		"duration_sec": 3600.0,
		"speed_bonus": 0.0,
		"assignees": [{"member_id": str(a.id), "role_id": "scout"}],
	}
	var scene: Node = load("res://scenes/roster/RosterScene.tscn").instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	scene._selected = [a, b]
	scene._formation_slots = [a, b, null, null]
	scene._on_save_pressed()
	assert_eq(
		str(scene._label_status.text),
		"%sは調査中のため編成できません" % str(a.display_name)
	)
	assert_true(GameState.active_party_reject_reason([a, b]).contains("調査中"))


func test_toggle_blocks_adding_dispatched_member() -> void:
	assert_gte(GameState.roster.size(), 2)
	var a: Resource = GameState.roster[0]
	var b: Resource = GameState.roster[1]
	GameState.hub_survey_cycle = {
		"dungeon_id": "mourngate",
		"preset": "standard",
		"start_unix": Time.get_unix_time_from_system(),
		"duration_sec": 3600.0,
		"speed_bonus": 0.0,
		"assignees": [{"member_id": str(b.id), "role_id": "scout"}],
	}
	var scene: Node = load("res://scenes/roster/RosterScene.tscn").instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	scene._selected = [a]
	scene._formation_slots = [a, null, null, null]
	scene._toggle_selection(b)
	assert_false(scene._selected.has(b))
	assert_true(str(scene._label_status.text).contains("調査中"))
