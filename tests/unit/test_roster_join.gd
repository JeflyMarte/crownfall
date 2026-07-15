extends GutTest
## P3-JOIN-001 — 導入1人開始・章加入キュー・二重加入防止。

const _RosterJoin = preload("res://scripts/roster/RosterJoin.gd")
const _Content = preload("res://scripts/roster/RosterJoinContent.gd")


func before_each() -> void:
	GameState.reset_for_new_game()


func after_each() -> void:
	GameState.reset_for_new_game()


func test_select_intro_starter_keeps_only_one() -> void:
	assert_true(GameState.select_intro_starter("adventurer_0"))
	assert_eq(GameState.roster.size(), 1)
	assert_eq(str(GameState.roster[0].id), "adventurer_0")
	assert_eq(GameState.party_members.size(), 1)
	assert_true(GameState.starter_progression_v1)


func test_first_clear_queues_next_and_second_clear_does_not() -> void:
	assert_true(GameState.select_intro_starter("adventurer_0"))
	assert_eq(_Content.next_unjoined_id(), "adventurer_3")
	GameState.mark_stage_cleared("mourngate_1_1")
	assert_eq(GameState.pending_roster_join_id, "adventurer_3")
	assert_true(_RosterJoin.has_pending_join())
	assert_eq(_RosterJoin.resolve_home_scene(), _RosterJoin.JOIN_SCENE)
	# 再クリアでも pending を上書き／二重キューしない
	GameState.mark_stage_cleared("mourngate_1_1")
	assert_eq(GameState.pending_roster_join_id, "adventurer_3")
	assert_true(_RosterJoin.commit_pending_join())
	assert_eq(GameState.roster.size(), 2)
	assert_true(GameState.find_roster_member_by_id("adventurer_3") != null)
	assert_eq(GameState.pending_roster_join_id, "")
	# 周回クリアでは新規 pending なし
	GameState.mark_stage_cleared("mourngate_1_1")
	assert_eq(GameState.pending_roster_join_id, "")


func test_join_order_skips_selected_starter() -> void:
	assert_true(GameState.select_intro_starter("adventurer_3"))
	assert_eq(_Content.next_unjoined_id(), "adventurer_1")
	GameState.mark_stage_cleared("mourngate_1_1")
	assert_eq(GameState.pending_roster_join_id, "adventurer_1")
	assert_true(_RosterJoin.commit_pending_join())
	GameState.mark_stage_cleared("mourngate_1_2")
	assert_eq(GameState.pending_roster_join_id, "adventurer_2")


func test_old_mode_does_not_queue_join() -> void:
	# reset 直後は starter_progression_v1=false（旧モード）
	assert_false(GameState.starter_progression_v1)
	GameState.mark_stage_cleared("mourngate_1_1")
	assert_eq(GameState.pending_roster_join_id, "")


func test_renamed_starter_display_names() -> void:
	assert_eq(str(GameState.find_base_roster_def("adventurer_2")["name"]), "アイリス")
	assert_eq(str(GameState.find_base_roster_def("adventurer_4")["name"]), "ロアン")
	assert_true(ResourceLoader.exists(_Content.get_portrait_path("adventurer_2")))
	assert_true(ResourceLoader.exists(_Content.get_portrait_path("adventurer_4")))


func test_join_portraits_exist() -> void:
	for adv_id: String in _Content.JOIN_ORDER:
		var path: String = _Content.get_portrait_path(adv_id)
		assert_true(ResourceLoader.exists(path), path)
