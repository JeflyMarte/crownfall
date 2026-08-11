extends GutTest

## 前列空きの陣形保存／調査派遣中の拒否文言／入れ替え下書き。


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
	## pressed 経路は deferred。直接 deferred 本体を呼ぶ。
	scene._toggle_selection_deferred(b)
	assert_false(scene._selected.has(b))
	assert_true(str(scene._label_status.text).contains("調査中"))


func test_recommend_skips_dispatched_members() -> void:
	assert_gte(GameState.roster.size(), 3)
	var a: Resource = GameState.roster[0]
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
	scene._on_recommend_pressed()
	assert_false(scene._selected.has(a))
	assert_false(GameState.active_party_reject_reason(scene._ordered_party_from_formation()).contains("調査中"))


func test_swap_list_then_party_is_draft_until_save() -> void:
	assert_gte(GameState.roster.size(), 3)
	var a: Resource = GameState.roster[0]
	var b: Resource = GameState.roster[1]
	var c: Resource = GameState.roster[2]
	GameState.set_active_party([a, b])
	GameState.set_member_formation_slot(a, 0)
	GameState.set_member_formation_row(a, GameState.FORMATION_FRONT)
	GameState.set_member_formation_slot(b, 1)
	GameState.set_member_formation_row(b, GameState.FORMATION_FRONT)
	var scene: Node = load("res://scenes/roster/RosterScene.tscn").instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	scene._selected = [a, b]
	scene._formation_slots = [a, b, null, null]
	## 一覧先行: c を選び → slot0 の a と入れ替え
	scene._roster_pick_member = c
	scene._apply_roster_pick_to_slot(0)
	assert_eq(scene._formation_slots[0], c)
	assert_true(scene._selected.has(c))
	assert_false(scene._selected.has(a))
	## 未保存なので GameState の本編成はまだ a,b
	assert_eq(GameState.party_members[0], a)
	assert_eq(GameState.get_member_formation_slot(a), 0)
	scene._on_save_pressed()
	assert_eq(str(scene._label_status.text), "編成を保存しました")
	assert_true(GameState.party_members.has(c))
	assert_false(GameState.party_members.has(a))
	assert_eq(GameState.get_member_formation_slot(c), 0)


func test_formation_overlay_dim_cancels_draft() -> void:
	assert_gte(GameState.roster.size(), 2)
	var a: Resource = GameState.roster[0]
	var b: Resource = GameState.roster[1]
	var scene: Node = load("res://scenes/roster/RosterScene.tscn").instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	scene._selected = [a, b]
	scene._formation_slots = [a, b, null, null]
	scene._open_formation_overlay()
	scene._formation_slots = [b, a, null, null]
	scene._cancel_formation_overlay()
	assert_eq(scene._formation_slots[0], a)
	assert_eq(scene._formation_slots[1], b)


func test_detail_does_not_commit_draft_party() -> void:
	assert_gte(GameState.roster.size(), 3)
	var a: Resource = GameState.roster[0]
	var b: Resource = GameState.roster[1]
	var c: Resource = GameState.roster[2]
	GameState.set_active_party([a, b])
	var scene: Node = load("res://scenes/roster/RosterScene.tscn").instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	scene._selected = [a, c]
	scene._formation_slots = [a, c, null, null]
	var before0: Resource = GameState.party_members[0]
	var before1: Resource = GameState.party_members[1]
	## 詳細は focus id のみ。遷移は起こるが本編成は変えない。
	scene._on_detail_pressed(c)
	assert_eq(GameState.party_members[0], before0)
	assert_eq(GameState.party_members[1], before1)
	assert_false(GameState.party_members.has(c))
	assert_eq(str(GameState.equipment_focus_member_id), str(c.id))
	assert_eq(GameState.equipment_focus_member_index, -1)


func test_swap_party_then_list_is_draft_until_save() -> void:
	assert_gte(GameState.roster.size(), 3)
	var a: Resource = GameState.roster[0]
	var b: Resource = GameState.roster[1]
	var c: Resource = GameState.roster[2]
	GameState.set_active_party([a, b])
	var scene: Node = load("res://scenes/roster/RosterScene.tscn").instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	scene._selected = [a, b]
	scene._formation_slots = [a, b, null, null]
	## パーティ枠先行: slot0 を選んでから一覧の c で入れ替え
	scene._active_pick_slot = 0
	scene._apply_active_pick_with_roster(c)
	assert_eq(scene._formation_slots[0], c)
	assert_true(scene._selected.has(c))
	assert_false(scene._selected.has(a))
	assert_eq(GameState.party_members[0], a)
	scene._on_save_pressed()
	assert_eq(str(scene._label_status.text), "編成を保存しました")
	assert_true(GameState.party_members.has(c))
	assert_false(GameState.party_members.has(a))
