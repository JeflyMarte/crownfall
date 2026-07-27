extends GutTest

const _WipeCause = preload("res://scripts/result/WipeCauseHelper.gd")


func test_summary_trap() -> void:
	var snap: Dictionary = {
		"floor_text": "F3/5",
		"cause_kind": "trap",
	}
	assert_eq(_WipeCause.summary_line(snap), "F3/5・罠で全滅")


func test_summary_elite_combat() -> void:
	var snap: Dictionary = {
		"floor_text": "F4",
		"cause_kind": "combat",
		"room_type": Enums.RoomType.ELITE,
	}
	assert_eq(_WipeCause.summary_line(snap), "F4・エリート戦で全滅")


func test_detail_prefers_enemy_name() -> void:
	var snap: Dictionary = {
		"cause_kind": "combat",
		"enemy_name": "霧のワイバーン",
	}
	assert_eq(
		_WipeCause.detail_line(snap, {}),
		"主因: 霧のワイバーン"
	)


func test_hint_focus_fire() -> void:
	GameState.reset_for_new_game()
	GameState.seed_all_starters_unlocked()
	var member_id: String = str(GameState.party_members[0].id)
	var other_id: String = str(GameState.party_members[1].id)
	var stats: Dictionary = {
		member_id: {"damage_taken": 900, "heal_total": 50},
		other_id: {"damage_taken": 100, "heal_total": 0},
	}
	var hint: String = _WipeCause.hint_line(stats)
	assert_true(
		hint.contains("集中攻撃"),
		"被ダメ偏りで集中攻撃ヒント: %s" % hint
	)


func test_hint_low_heal() -> void:
	var stats: Dictionary = {
		"a": {"damage_taken": 200, "heal_total": 0},
		"b": {"damage_taken": 180, "heal_total": 5},
	}
	assert_eq(_WipeCause.hint_line(stats), "回復が追いつかなかった")
