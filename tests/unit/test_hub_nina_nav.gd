extends GutTest
## P3-UI-NINA-NAV-001 — ニーナ拠点ナビ文案。

const _Helper = preload("res://scripts/ui/HubNinaNavHelper.gd")
const _Navigator = preload("res://scripts/ui/HubNinaNavigator.gd")


func before_each() -> void:
	GameState.reset_for_new_game()
	EventSystem.set_debug_unix_for_tests(-1)


func after_each() -> void:
	EventSystem.set_debug_unix_for_tests(-1)


func test_rotate_interval_is_ten_seconds() -> void:
	assert_eq(_Navigator.ROTATE_SEC, 10.0)


func test_build_rotation_has_recommend_then_field() -> void:
	var rot: Array[Dictionary] = _Helper.build_rotation()
	assert_gte(rot.size(), 2 + _Helper.CHAT_IN_ROTATION)
	assert_eq(str(rot[0].get("kind", "")), _Helper.KIND_RECOMMEND)
	assert_eq(str(rot[1].get("kind", "")), _Helper.KIND_FIELD)
	assert_true(not str(rot[0].get("text", "")).is_empty())
	assert_true(not str(rot[1].get("text", "")).is_empty())
	for i in range(2, rot.size()):
		assert_eq(str(rot[i].get("kind", "")), _Helper.KIND_CHAT)
		assert_true(not str(rot[i].get("text", "")).is_empty())


func test_chat_pool_is_large() -> void:
	assert_gte(_Helper.CHAT_LINES.size(), 30)


func test_pick_chat_lines_unique() -> void:
	var picked: Array[String] = _Helper.pick_chat_lines(_Helper.CHAT_IN_ROTATION)
	assert_eq(picked.size(), _Helper.CHAT_IN_ROTATION)
	var seen: Dictionary = {}
	for line in picked:
		assert_true(_Helper.CHAT_LINES.has(line), line)
		assert_false(seen.has(line), line)
		seen[line] = true


func test_recommend_claimable_daily() -> void:
	DailyMissionSystem.ensure_refreshed()
	var entries: Array = GameState.daily_mission_state.get("entries", [])
	assert_gt(entries.size(), 0)
	var entry: Dictionary = entries[0]
	entry["progress"] = 99
	entry["claimed"] = false
	GameState.daily_mission_state["entries"] = entries
	var line: String = _Helper.recommend_line()
	assert_true(line.contains("報酬") or line.contains("受け取"), line)


func test_recommend_incomplete_daily() -> void:
	DailyMissionSystem.ensure_refreshed()
	var entries: Array = GameState.daily_mission_state.get("entries", [])
	assert_gt(entries.size(), 0)
	for raw in entries:
		if raw is Dictionary:
			raw["progress"] = 0
			raw["claimed"] = false
	GameState.daily_mission_state["entries"] = entries
	var line: String = _Helper.recommend_line()
	assert_true(line.contains("日課"), line)


func test_field_line_calm_when_no_event_weather() -> void:
	GameState.set_weather("")
	## イベントが走っていても文は空でないこと（週次は環境依存）。
	var line: String = _Helper.field_or_weather_line()
	assert_true(not line.is_empty(), line)


func test_weather_tip_rain_junior_voice() -> void:
	var tip: String = _Helper._weather_tip(CombatWeather.RAIN)
	assert_true(tip.contains("雨"), tip)


func test_chat_line_from_pool() -> void:
	var line: String = _Helper.chat_line()
	assert_true(_Helper.CHAT_LINES.has(line), line)


func test_nina_panel_sits_below_top_bar_gap() -> void:
	assert_eq(_Navigator.GAP_BELOW_TOP, 48.0)
	assert_eq(_Navigator.PANEL_H, 148.0)


func test_nina_portrait_asset_exists() -> void:
	assert_true(FileAccess.file_exists("res://assets/npc/ART_NPC_Nina.png"))
	assert_true(FileAccess.file_exists("res://assets/npc/ICO_NPC_Nina.png"))
