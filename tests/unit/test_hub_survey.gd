extends GutTest

## P3-HUB-SURVEY-001 — 調査ゲージ／②解放／サイクル。

const _SurveySystem := preload("res://scripts/survey/SurveySystem.gd")
const _SurveyConfig := preload("res://scripts/survey/SurveyConfig.gd")

var _saved_progress: Dictionary = {}
var _saved_survey: Dictionary = {}
var _saved_cycle: Dictionary = {}
var _saved_room: Dictionary = {}
var _saved_achieve: Dictionary = {}


func before_each() -> void:
	_saved_progress = GameState.dungeon_progress.duplicate(true)
	_saved_survey = GameState.hub_survey_progress.duplicate(true)
	_saved_cycle = GameState.hub_survey_cycle.duplicate(true)
	_saved_room = GameState.hub_survey_room_daily.duplicate(true)
	_saved_achieve = GameState.hub_survey_achievements_claimed.duplicate(true)
	GameState.dungeon_progress = {}
	GameState.hub_survey_progress = {}
	GameState.hub_survey_cycle = {}
	GameState.hub_survey_room_daily = {}
	GameState.hub_survey_achievements_claimed = {}
	GameState.debug_full_unlock = false


func after_each() -> void:
	GameState.dungeon_progress = _saved_progress
	GameState.hub_survey_progress = _saved_survey
	GameState.hub_survey_cycle = _saved_cycle
	GameState.hub_survey_room_daily = _saved_room
	GameState.hub_survey_achievements_claimed = _saved_achieve
	GameState.debug_full_unlock = false


func test_whisperwood_needs_survey_clear() -> void:
	assert_false(GameState.is_dungeon_unlocked("whisperwood"))
	GameState.mark_dungeon_cleared("mourngate")
	assert_false(GameState.is_dungeon_unlocked("whisperwood"), "SURVEY未達では②ロック")
	GameState.hub_survey_progress["mourngate"] = _SurveyConfig.SURVEY_CLEAR_PERCENT
	assert_true(GameState.is_dungeon_unlocked("whisperwood"), "ボス相当クリア＋SURVEY70%で②解禁")


func test_later_mains_still_beta_locked() -> void:
	if not Constants.BETA_MOURNGATE_ONLY:
		pass_test("beta off")
		return
	GameState.mark_dungeon_cleared("mourngate")
	GameState.hub_survey_progress["mourngate"] = 100.0
	GameState.mark_dungeon_cleared("whisperwood")
	assert_false(GameState.is_dungeon_unlocked("mistfen"), "βは③以降ロック")


func test_survey_add_and_cap() -> void:
	_SurveySystem.add_survey_percent("mourngate", 10.0, false)
	assert_eq(_SurveySystem.get_survey_percent("mourngate"), 10.0)
	_SurveySystem.add_survey_percent("mourngate", 200.0, false)
	assert_eq(_SurveySystem.get_survey_percent("mourngate"), 100.0)


func test_cycle_completes_with_time() -> void:
	var ids: Array[String] = []
	if not GameState.roster.is_empty() and GameState.roster[0] != null:
		ids.append(str(GameState.roster[0].id))
	var started: Dictionary = _SurveySystem.start_cycle(
		Constants.MOURNGATE_DUNGEON_ID, _SurveyConfig.PRESET_SHORT, ids
	)
	assert_true(bool(started.get("ok", false)), str(started))
	assert_true(_SurveySystem.has_active_cycle())
	assert_false(_SurveySystem.is_cycle_complete())
	## 開始を過去にずらして完了扱い
	GameState.hub_survey_cycle["start_unix"] = Time.get_unix_time_from_system() - (
		_SurveyConfig.SHORT_DURATION_SEC + 10.0
	)
	assert_true(_SurveySystem.is_cycle_complete())
	var claimed: Dictionary = _SurveySystem.claim_cycle()
	assert_true(bool(claimed.get("ok", false)), str(claimed))
	assert_false(_SurveySystem.has_active_cycle())
	assert_gt(_SurveySystem.get_survey_percent(Constants.MOURNGATE_DUNGEON_ID), 0.0)


func test_achieve_entries_exist() -> void:
	var rows: Array[Dictionary] = _SurveySystem.achieve_entries()
	assert_gt(rows.size(), 0)
