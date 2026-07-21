extends GutTest

## P3-DAILY-002 — プール抽選・撃破・1行 title


func before_each() -> void:
	GameState.daily_mission_state = {}


func test_pick_missions_is_deterministic_for_day_key() -> void:
	var a: Array[String] = DailyMissionSystem.pick_missions_for_day("2026-07-22")
	var b: Array[String] = DailyMissionSystem.pick_missions_for_day("2026-07-22")
	assert_eq(a.size(), DailyMissionSystem.DAILY_PICK_COUNT)
	assert_eq(a, b)
	var c: Array[String] = DailyMissionSystem.pick_missions_for_day("2026-07-23")
	## 別日は同じになることもあり得るが、シードが異なれば多くの場合変わる。
	## 最低限サイズとプール内 ID であることを見る。
	assert_eq(c.size(), DailyMissionSystem.DAILY_PICK_COUNT)
	for mid in a:
		assert_true(mid in DailyMissionSystem.DAILY_POOL)


func test_kill_enemy_mission_title_and_target() -> void:
	var mission: Resource = load("res://resources/daily_missions/daily_kill_enemies.tres")
	assert_not_null(mission)
	assert_eq(str(mission.objective_type), "kill_enemy")
	assert_eq(int(mission.target_count), 20)
	assert_true(str(mission.title).contains("20"))


func test_report_kill_progress() -> void:
	GameState.daily_mission_state = {
		"day_key": DailyMissionSystem.current_day_key(),
		"entries": [
			{"mission_id": "daily_kill_enemies", "progress": 0, "claimed": false},
			{"mission_id": "daily_craft_item", "progress": 0, "claimed": false},
			{"mission_id": "daily_clear_run", "progress": 0, "claimed": false},
		],
	}
	DailyMissionSystem.report_progress("kill_enemy", "", 5)
	var entries: Array[Dictionary] = DailyMissionSystem.get_entries()
	var kill_entry: Dictionary = {}
	for e in entries:
		if str(e.get("mission_id", "")) == "daily_kill_enemies":
			kill_entry = e
			break
	assert_false(kill_entry.is_empty())
	assert_eq(int(kill_entry.get("progress", 0)), 5)


func test_old_combat_win_entry_triggers_refresh() -> void:
	## 旧 mission_id が残っていても ensure で再抽選される。
	GameState.daily_mission_state = {
		"day_key": DailyMissionSystem.current_day_key(),
		"entries": [
			{"mission_id": "daily_combat_win", "progress": 2, "claimed": false},
			{"mission_id": "daily_craft_item", "progress": 0, "claimed": false},
			{"mission_id": "daily_clear_run", "progress": 0, "claimed": false},
		],
	}
	var entries: Array[Dictionary] = DailyMissionSystem.get_entries()
	assert_eq(entries.size(), DailyMissionSystem.DAILY_PICK_COUNT)
	for e in entries:
		assert_ne(str(e.get("mission_id", "")), "daily_combat_win")
		assert_true(str(e.get("mission_id", "")) in DailyMissionSystem.DAILY_POOL)
