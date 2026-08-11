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
		"enemy_count": 1,
	}
	assert_eq(
		_WipeCause.detail_line(snap, {}),
		"主因: 霧のワイバーン"
	)


func test_detail_swarm_count() -> void:
	var snap: Dictionary = {
		"cause_kind": "combat",
		"enemy_name": "霧のワイバーン",
		"enemy_count": 3,
	}
	assert_eq(
		_WipeCause.primary_detail_line(snap),
		"主因: 霧のワイバーン（3体）"
	)


func test_detail_lines_primary_plus_hint() -> void:
	GameState.reset_for_new_game()
	GameState.seed_all_starters_unlocked()
	var member_id: String = str(GameState.party_members[0].id)
	var other_id: String = str(GameState.party_members[1].id)
	var snap: Dictionary = {
		"cause_kind": "combat",
		"enemy_name": "霧のワイバーン",
		"enemy_count": 3,
		"weather_id": "fog",
		"party_status_ids": ["poison"],
	}
	var stats: Dictionary = {
		member_id: {"damage_taken": 900, "heal_total": 50},
		other_id: {"damage_taken": 100, "heal_total": 0},
	}
	var lines: PackedStringArray = _WipeCause.detail_lines(snap, stats)
	assert_eq(lines.size(), 2, "主因＋ヒント行")
	assert_eq(lines[0], "主因: 霧のワイバーン（3体）")
	assert_true(lines[1].contains("集中攻撃"), "集中攻撃ヒント: %s" % lines[1])
	## 最大2ヒント。集中＋回復不足が優先され、状態／天候は落ちる場合あり
	assert_true(
		lines[1].contains("回復") or not lines[1].contains("／"),
		"ヒント結合または単一: %s" % lines[1]
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


func test_hint_status_and_weather() -> void:
	var snap: Dictionary = {
		"cause_kind": "combat",
		"enemy_name": "",
		"party_status_ids": ["poison", "bleed"],
		"weather_id": "fog",
	}
	var hints: PackedStringArray = _WipeCause.collect_hints(snap, {}, 2)
	assert_true(hints.size() >= 1, "状態 or 天候ヒント")
	assert_true(
		hints[0].contains("残っていた") or hints[0].contains("霧"),
		"ヒント文言: %s" % hints[0]
	)


func test_wipe_snapshot_does_not_use_stale_last_run_weather() -> void:
	## 前回ランが雨でも、今回晴れ（current_weather 空）なら weather_id は空のまま。
	GameState.last_run_weather = "rain"
	GameState.current_weather = ""
	var snap: Dictionary = _WipeCause.build_snapshot(null, null, "combat")
	assert_eq(str(snap.get("weather_id", "")), "")
	GameState.last_run_weather = ""
