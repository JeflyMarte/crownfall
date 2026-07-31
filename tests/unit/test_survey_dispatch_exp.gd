extends GutTest
## P3-SURVEY-DISPATCH-EXP-001 — 調査派遣の戦闘員 EXP（プール固定→均等）。

const _SurveySystem := preload("res://scripts/survey/SurveySystem.gd")
const _SurveyConfig := preload("res://scripts/survey/SurveyConfig.gd")
const _SurveyStaff := preload("res://scripts/survey/SurveyStaff.gd")


func before_each() -> void:
	GameState.reset_for_new_game()
	if Constants.STARTER_STORY_RECRUIT:
		GameState.select_starting_adventurer("adventurer_0")
	GameState.hub_survey_cycle = {}
	GameState.hub_survey_progress = {}
	GameState.survey_staff_nonoka_unlocked = true


func test_reference_trash_clear_exp_positive() -> void:
	var ref: int = _SurveySystem.reference_trash_clear_exp(Constants.MOURNGATE_DUNGEON_ID)
	assert_gt(ref, 0)


func test_short_pool_less_than_standard() -> void:
	var short_p: int = _SurveySystem.dispatch_exp_pool(
		Constants.MOURNGATE_DUNGEON_ID, _SurveyConfig.PRESET_SHORT
	)
	var std_p: int = _SurveySystem.dispatch_exp_pool(
		Constants.MOURNGATE_DUNGEON_ID, _SurveyConfig.PRESET_STANDARD
	)
	assert_gt(short_p, 0)
	assert_gt(std_p, short_p)
	assert_eq(
		short_p,
		int(round(float(_SurveySystem.reference_trash_clear_exp(Constants.MOURNGATE_DUNGEON_ID))
			* _SurveyConfig.EXP_RATIO_SHORT))
	)


func test_staff_only_grants_no_exp() -> void:
	var r: Dictionary = _SurveySystem.grant_dispatch_exp(
		Constants.MOURNGATE_DUNGEON_ID,
		_SurveyConfig.PRESET_SHORT,
		[{"member_id": _SurveyStaff.ID_NINA}, {"member_id": _SurveyStaff.ID_NONOKA}]
	)
	assert_eq(int(r.get("pool", -1)), 0)
	assert_eq((r.get("entries", []) as Array).size(), 0)


func test_pool_fixed_equal_split_among_combat() -> void:
	## ロスターに2人以上いる前提（スターター＋追加）。
	_ensure_two_combat_members()
	var ids: Array[String] = []
	for adv in GameState.roster:
		if adv == null:
			continue
		var mid: String = str(adv.id)
		if _SurveySystem.is_survey_staff(mid):
			continue
		ids.append(mid)
		if ids.size() >= 2:
			break
	assert_eq(ids.size(), 2)
	var assignees: Array = [
		{"member_id": _SurveyStaff.ID_NINA},
		{"member_id": ids[0]},
		{"member_id": ids[1]},
	]
	var pool: int = _SurveySystem.dispatch_exp_pool(
		Constants.MOURNGATE_DUNGEON_ID, _SurveyConfig.PRESET_STANDARD
	)
	var before0: int = int(GameState.find_roster_member_by_id(ids[0]).exp)
	var before1: int = int(GameState.find_roster_member_by_id(ids[1]).exp)
	var lv0: int = int(GameState.find_roster_member_by_id(ids[0]).level)
	var lv1: int = int(GameState.find_roster_member_by_id(ids[1]).level)
	var r: Dictionary = _SurveySystem.grant_dispatch_exp(
		Constants.MOURNGATE_DUNGEON_ID, _SurveyConfig.PRESET_STANDARD, assignees
	)
	assert_eq(int(r.get("pool", 0)), pool)
	var entries: Array = r.get("entries", []) as Array
	assert_eq(entries.size(), 2)
	var sum: int = 0
	for e in entries:
		sum += int((e as Dictionary).get("exp", 0))
		assert_false(_SurveySystem.is_survey_staff(str((e as Dictionary).get("member_id", ""))))
	assert_eq(sum, pool)
	## レベルが変わっていなければ所持 EXP 差分の合計＝プール。
	if (
		int(GameState.find_roster_member_by_id(ids[0]).level) == lv0
		and int(GameState.find_roster_member_by_id(ids[1]).level) == lv1
	):
		var gained: int = (
			int(GameState.find_roster_member_by_id(ids[0]).exp) - before0
			+ int(GameState.find_roster_member_by_id(ids[1]).exp) - before1
		)
		assert_eq(gained, pool)


func test_claim_cycle_includes_exp_entries() -> void:
	_ensure_two_combat_members()
	var combat_id: String = ""
	for adv in GameState.roster:
		if adv == null:
			continue
		var mid: String = str(adv.id)
		if not _SurveySystem.is_survey_staff(mid):
			combat_id = mid
			break
	assert_false(combat_id.is_empty())
	var started: Dictionary = _SurveySystem.start_cycle(
		Constants.MOURNGATE_DUNGEON_ID,
		_SurveyConfig.PRESET_SHORT,
		[_SurveyStaff.ID_NINA, combat_id] as Array[String]
	)
	assert_true(bool(started.get("ok", false)), str(started))
	GameState.hub_survey_cycle["start_unix"] = Time.get_unix_time_from_system() - (
		_SurveyConfig.SHORT_DURATION_SEC + 10.0
	)
	var claimed: Dictionary = _SurveySystem.claim_cycle()
	assert_true(bool(claimed.get("ok", false)), str(claimed))
	var entries: Array = claimed.get("exp_entries", []) as Array
	assert_eq(entries.size(), 1)
	assert_eq(str((entries[0] as Dictionary).get("member_id", "")), combat_id)
	assert_gt(int((entries[0] as Dictionary).get("exp", 0)), 0)


func _ensure_two_combat_members() -> void:
	var combat_n: int = 0
	for adv in GameState.roster:
		if adv != null and not _SurveySystem.is_survey_staff(str(adv.id)):
			combat_n += 1
	if combat_n >= 2:
		return
	GameState.unlock_starter_adventurer("adventurer_1")
