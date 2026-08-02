extends GutTest
## P3-UI-NINA-NAV-001 — ニーナ拠点ナビ文案。

const _Helper = preload("res://scripts/ui/HubNinaNavHelper.gd")
const _Navigator = preload("res://scripts/ui/HubNinaNavigator.gd")
const _EventDungeonSchedule = preload("res://scripts/dungeon/EventDungeonSchedule.gd")


func before_each() -> void:
	GameState.reset_for_new_game()
	EventSystem.set_debug_unix_for_tests(-1)
	## 降臨ウィンドウ外（JST 14:00）に固定し、通常おすすめ文案を安定させる。
	_EventDungeonSchedule.set_debug_unix_override(_unix_jst(2026, 7, 26, 14, 0))
	_EventDungeonSchedule.clear_debug_weekday_override()
	GameState.debug_full_unlock = false


func after_each() -> void:
	EventSystem.set_debug_unix_for_tests(-1)
	_EventDungeonSchedule.clear_debug_unix_override()
	_EventDungeonSchedule.clear_debug_weekday_override()
	GameState.debug_full_unlock = false


func _unix_jst(year: int, month: int, day: int, hour: int, minute: int) -> int:
	var dt := {
		"year": year, "month": month, "day": day,
		"hour": hour, "minute": minute, "second": 0,
	}
	return int(Time.get_unix_time_from_datetime_dict(dt)) - 9 * 3600


func test_rotate_interval_is_ten_seconds() -> void:
	assert_eq(_Navigator.ROTATE_SEC, 10.0)


func test_build_rotation_has_recommend_then_field() -> void:
	var rot: Array[Dictionary] = _Helper.build_rotation()
	assert_gte(rot.size(), 2 + _Helper.CHAT_IN_ROTATION)
	assert_eq(str(rot[0].get("kind", "")), _Helper.KIND_RECOMMEND)
	## 開始直後は招待状＋調査室の2件が先に並ぶ。
	assert_eq(str(rot[1].get("kind", "")), _Helper.KIND_RECOMMEND)
	assert_eq(str(rot[2].get("kind", "")), _Helper.KIND_FIELD)
	assert_true(not str(rot[0].get("text", "")).is_empty())
	assert_true(not str(rot[1].get("text", "")).is_empty())
	assert_true(not str(rot[2].get("text", "")).is_empty())
	for i in range(3, rot.size()):
		assert_eq(str(rot[i].get("kind", "")), _Helper.KIND_CHAT)
		assert_true(not str(rot[i].get("text", "")).is_empty())


func test_early_hub_tips_on_new_game() -> void:
	var tips: Array[String] = _Helper.early_hub_tips()
	assert_eq(tips.size(), 2)
	assert_eq(tips[0], _Helper.START_GACHA_TIP)
	assert_eq(tips[1], _Helper.START_SURVEY_TIP)
	var line: String = _Helper.recommend_line()
	assert_eq(line, _Helper.START_GACHA_TIP)


func test_chat_pool_is_large() -> void:
	assert_gte(_Helper.CHAT_LINES.size(), 100)
	assert_eq(_Helper.CHAT_IN_ROTATION, 5)


func test_chat_pool_has_no_empty_or_duplicate() -> void:
	var seen: Dictionary = {}
	for line in _Helper.CHAT_LINES:
		var text: String = str(line).strip_edges()
		assert_false(text.is_empty(), "空セリフ禁止")
		assert_false(seen.has(text), "重複: %s" % text)
		seen[text] = true


func test_recommend_pools_are_expanded() -> void:
	assert_gte(_Helper.CLAIMABLE_LINES.size(), 6)
	assert_gte(_Helper.INCOMPLETE_DAILY_LINES.size(), 6)
	assert_gte(_Helper.PARTY_VACANCY_LINES.size(), 6)
	assert_gte(_Helper.FALLBACK_RECOMMEND_LINES.size(), 8)
	assert_gte(_Helper.CALM_FIELD_LINES.size(), 8)


func test_early_gacha_tip_clears_after_helper_owned() -> void:
	GameState.owned_helpers["kaida"] = 1
	var tips: Array[String] = _Helper.early_hub_tips()
	assert_eq(tips.size(), 1)
	assert_eq(tips[0], _Helper.START_SURVEY_TIP)


func test_early_survey_tip_clears_after_progress() -> void:
	GameState.hub_survey_progress[Constants.DEFAULT_DUNGEON_ID] = 3.0
	var tips: Array[String] = _Helper.early_hub_tips()
	assert_eq(tips.size(), 1)
	assert_eq(tips[0], _Helper.START_GACHA_TIP)


func test_recommend_claimable_daily() -> void:
	## 開始案内を消してから日課受取優先を確認。
	GameState.owned_helpers["kaida"] = 1
	GameState.hub_survey_progress[Constants.DEFAULT_DUNGEON_ID] = 1.0
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
	GameState.owned_helpers["kaida"] = 1
	GameState.hub_survey_progress[Constants.DEFAULT_DUNGEON_ID] = 1.0
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


func test_pick_chat_lines_unique() -> void:
	var picked: Array[String] = _Helper.pick_chat_lines(_Helper.CHAT_IN_ROTATION)
	assert_eq(picked.size(), _Helper.CHAT_IN_ROTATION)
	var seen: Dictionary = {}
	for line in picked:
		assert_true(_Helper.CHAT_LINES.has(line), line)
		assert_false(seen.has(line), line)
		seen[line] = true


func test_nina_panel_sits_below_top_bar_gap() -> void:
	assert_eq(_Navigator.GAP_BELOW_TOP, 48.0)
	assert_eq(_Navigator.PANEL_H, 160.0)


func test_nina_portrait_asset_exists() -> void:
	assert_true(FileAccess.file_exists("res://assets/npc/ART_NPC_Nina.png"))
	assert_true(FileAccess.file_exists("res://assets/npc/ICO_NPC_Nina.png"))
	assert_true(FileAccess.file_exists("res://assets/npc/ICO_NPC_Nina_Dot.png"))
	## 調査室用 ICO は Downloads ニーナアイコン（角は透過・本体は不透明）。
	var tex: Texture2D = load("res://assets/npc/ICO_NPC_Nina.png") as Texture2D
	assert_true(tex != null)
	assert_gte(tex.get_width(), 256)
	assert_gte(tex.get_height(), 256)
	assert_eq(tex.get_width(), tex.get_height())
	## 手引き羊皮紙に透けないよう、顔中心〜中央帯は完全不透明であること。
	var img: Image = tex.get_image()
	assert_true(img != null)
	var center: Color = img.get_pixel(img.get_width() / 2, img.get_height() / 2)
	assert_gte(center.a, 0.99, "Nina ICO center alpha should be opaque")
	var semi_in_core: int = 0
	var x0: int = int(float(img.get_width()) * 0.35)
	var x1: int = int(float(img.get_width()) * 0.65)
	var y0: int = int(float(img.get_height()) * 0.35)
	var y1: int = int(float(img.get_height()) * 0.65)
	for y in range(y0, y1):
		for x in range(x0, x1):
			var a: float = img.get_pixel(x, y).a
			if a > 0.04 and a < 0.99:
				semi_in_core += 1
	assert_eq(semi_in_core, 0, "Nina ICO core must not be semi-transparent")
	## 拠点ナビは旧 128px ドット。
	var dot: Texture2D = load("res://assets/npc/ICO_NPC_Nina_Dot.png") as Texture2D
	assert_true(dot != null)
	assert_eq(dot.get_width(), 128)
	assert_eq(dot.get_height(), 128)
	const _IntroUiAssets := preload("res://scripts/intro/IntroUiAssets.gd")
	assert_eq(_IntroUiAssets.NINA_ICON_DOT, "res://assets/npc/ICO_NPC_Nina_Dot.png")


func test_survey_staff_nina_uses_portrait_icon() -> void:
	const _SurveyStaff := preload("res://scripts/survey/SurveyStaff.gd")
	assert_eq(_SurveyStaff.icon_path(_SurveyStaff.ID_NINA), "res://assets/npc/ICO_NPC_Nina.png")
	var tex: Texture2D = _SurveyStaff.load_icon_texture(_SurveyStaff.ID_NINA)
	assert_true(tex != null)
	assert_gte(tex.get_width(), 256)

func test_descent_event_line_when_chronos_open() -> void:
	GameState.owned_helpers["kaida"] = 1
	GameState.hub_survey_progress[Constants.DEFAULT_DUNGEON_ID] = 1.0
	_EventDungeonSchedule.set_debug_unix_override(_unix_jst(2026, 7, 26, 0, 30))
	var line: String = _Helper.descent_event_line()
	assert_eq(
		line,
		"速報です！\n「時環の共鳴龍」が降臨中です！\nイベントから確認してください！"
	)
	var rec: String = _Helper.recommend_line()
	assert_eq(rec, line)
	## 野外枠は降臨を重複しない。
	var field: String = _Helper.field_or_weather_line()
	assert_false(field.contains("降臨中"), field)


func test_descent_short_label_strips_suffix() -> void:
	assert_eq(_Helper.descent_short_label("時環の共鳴龍　降臨"), "時環の共鳴龍")
	assert_eq(_Helper.descent_short_label("境界の番　降臨"), "境界の番")


func test_descent_event_line_empty_when_closed() -> void:
	_EventDungeonSchedule.set_debug_unix_override(_unix_jst(2026, 7, 26, 14, 0))
	assert_eq(_Helper.descent_event_line(), "")


func test_survey_complete_shows_alert_on_hub_icon() -> void:
	const _SurveySystem := preload("res://scripts/survey/SurveySystem.gd")
	const _SurveyConfig := preload("res://scripts/survey/SurveyConfig.gd")
	const _SurveyStaff := preload("res://scripts/survey/SurveyStaff.gd")
	GameState.hub_survey_cycle = {}
	var nav: Control = _Navigator.new()
	add_child_autofree(nav)
	await get_tree().process_frame
	var alert: Label = nav.get_node_or_null("SurveyFrame/SurveyStack/SurveyCompleteAlert") as Label
	assert_not_null(alert)
	assert_false(alert.visible, "未完了では ❗️ 非表示")
	## ニーナは常時配置可（ノノカ解放不要）。
	var ids: Array[String] = [_SurveyStaff.ID_NINA]
	var started: Dictionary = _SurveySystem.start_cycle(
		Constants.MOURNGATE_DUNGEON_ID, _SurveyConfig.PRESET_SHORT, ids
	)
	assert_true(bool(started.get("ok", false)), str(started))
	GameState.hub_survey_cycle["start_unix"] = Time.get_unix_time_from_system() - (
		_SurveyConfig.SHORT_DURATION_SEC + 10.0
	)
	assert_true(_SurveySystem.is_cycle_complete())
	nav.call("refresh_survey_alert")
	assert_true(alert.visible, "完了時は ❗️ 表示")
	var claimed: Dictionary = _SurveySystem.claim_cycle()
	assert_true(bool(claimed.get("ok", false)), str(claimed))
	nav.call("refresh_survey_alert")
	assert_false(alert.visible, "受取後は ❗️ 消える")
