extends GutTest

## ダンジョン／章解放のポップアップ用キュー検知。

const _ContentUnlockNotice := preload("res://scripts/ui/ContentUnlockNotice.gd")
const _SurveyConfig := preload("res://scripts/survey/SurveyConfig.gd")

var _saved_progress: Dictionary = {}
var _saved_survey: Dictionary = {}
var _saved_stage: Dictionary = {}
var _saved_notices: Array = []
var _saved_debug: bool = false


func before_each() -> void:
	_saved_progress = GameState.dungeon_progress.duplicate(true)
	_saved_survey = GameState.hub_survey_progress.duplicate(true)
	_saved_stage = GameState.stage_progress.duplicate(true)
	_saved_notices = GameState.pending_content_unlock_notices.duplicate(true)
	_saved_debug = GameState.debug_full_unlock
	GameState.dungeon_progress = {}
	GameState.hub_survey_progress = {}
	GameState.stage_progress = {}
	GameState.pending_content_unlock_notices = []
	GameState.debug_full_unlock = false


func after_each() -> void:
	GameState.dungeon_progress = _saved_progress
	GameState.hub_survey_progress = _saved_survey
	GameState.stage_progress = _saved_stage
	GameState.pending_content_unlock_notices = _saved_notices
	GameState.debug_full_unlock = _saved_debug


func test_clearing_stage_queues_next_stage_notice() -> void:
	if not Constants.SUB_STAGES_PLAYABLE:
		pass_test("sub stages off")
		return
	var first: Resource = DataRegistry.get_stage_by_chapter(Constants.MOURNGATE_DUNGEON_ID, 1)
	var second: Resource = DataRegistry.get_stage_by_chapter(Constants.MOURNGATE_DUNGEON_ID, 2)
	assert_ne(first, null)
	assert_ne(second, null)
	assert_true(GameState.is_stage_unlocked(str(first.id)))
	assert_false(GameState.is_stage_unlocked(str(second.id)))
	GameState.mark_stage_cleared(str(first.id), 0)
	assert_true(GameState.is_stage_unlocked(str(second.id)))
	assert_gt(GameState.pending_content_unlock_notices.size(), 0)
	var found: bool = false
	for raw in GameState.pending_content_unlock_notices:
		if not raw is Dictionary:
			continue
		var entry: Dictionary = raw
		if str(entry.get("id", "")) == str(second.id):
			found = true
			assert_gt(str(entry.get("display_name", "")).length(), 0)
			break
	assert_true(found, "次章の解放通知がキューに入ること")


func test_survey_clear_queues_whisperwood_when_mourngate_cleared() -> void:
	GameState.mark_dungeon_cleared(Constants.MOURNGATE_DUNGEON_ID)
	## mark_dungeon_cleared は SUB_STAGES 時は通知しない。章経路以外の SURVEY 解放を検証。
	GameState.pending_content_unlock_notices = []
	assert_false(GameState.is_dungeon_unlocked(Constants.WHISPERWOOD_DUNGEON_ID))
	GameState.hub_survey_progress[Constants.MOURNGATE_DUNGEON_ID] = (
		_SurveyConfig.SURVEY_CLEAR_PERCENT - 1.0
	)
	const _SurveySystem := preload("res://scripts/survey/SurveySystem.gd")
	_SurveySystem.add_survey_percent(Constants.MOURNGATE_DUNGEON_ID, 5.0, false)
	assert_true(GameState.is_dungeon_unlocked(Constants.WHISPERWOOD_DUNGEON_ID))
	var found: bool = false
	for raw in GameState.pending_content_unlock_notices:
		if not raw is Dictionary:
			continue
		var entry: Dictionary = raw
		if str(entry.get("id", "")) == Constants.WHISPERWOOD_DUNGEON_ID:
			found = true
			assert_eq(str(entry.get("kind", "")), "dungeon")
			break
	assert_true(found, "②解放通知がキューに入ること")
