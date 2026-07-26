extends GutTest

## P3-HUB-SURVEY-001 — 調査ゲージ／②解放／サイクル。

const _SurveySystem := preload("res://scripts/survey/SurveySystem.gd")
const _SurveyConfig := preload("res://scripts/survey/SurveyConfig.gd")
const _SurveyCompleteRewards := preload("res://scripts/survey/SurveyCompleteRewards.gd")

var _saved_progress: Dictionary = {}
var _saved_survey: Dictionary = {}
var _saved_cycle: Dictionary = {}
var _saved_room: Dictionary = {}
var _saved_achieve: Dictionary = {}
var _saved_codex: Dictionary = {}
var _saved_token: int = 0


func before_each() -> void:
	_saved_progress = GameState.dungeon_progress.duplicate(true)
	_saved_survey = GameState.hub_survey_progress.duplicate(true)
	_saved_cycle = GameState.hub_survey_cycle.duplicate(true)
	_saved_room = GameState.hub_survey_room_daily.duplicate(true)
	_saved_achieve = GameState.hub_survey_achievements_claimed.duplicate(true)
	_saved_codex = GameState.enemy_codex.duplicate(true)
	_saved_token = GameState.gacha_token
	GameState.dungeon_progress = {}
	GameState.hub_survey_progress = {}
	GameState.hub_survey_cycle = {}
	GameState.hub_survey_room_daily = {}
	GameState.hub_survey_achievements_claimed = {}
	GameState.enemy_codex = {}
	GameState.debug_full_unlock = false


func after_each() -> void:
	GameState.dungeon_progress = _saved_progress
	GameState.hub_survey_progress = _saved_survey
	GameState.hub_survey_cycle = _saved_cycle
	GameState.hub_survey_room_daily = _saved_room
	GameState.hub_survey_achievements_claimed = _saved_achieve
	GameState.enemy_codex = _saved_codex
	GameState.gacha_token = _saved_token
	GameState.debug_full_unlock = false


func test_whisperwood_unlocks_on_mourngate_clear() -> void:
	assert_false(GameState.is_dungeon_unlocked("whisperwood"))
	GameState.mark_dungeon_cleared("mourngate")
	assert_true(GameState.is_dungeon_unlocked("whisperwood"), "①クリアで②解禁（調査ゲージ条件なし）")


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
	## 100%到達で景品付与→0%リセット（案A）
	assert_eq(_SurveySystem.get_survey_percent("mourngate"), 0.0)
	assert_true(_SurveyCompleteRewards.is_claimed("mourngate"))


func test_whisperwood_complete_unlocks_ash() -> void:
	const _PetSystem := preload("res://scripts/pets/PetSystem.gd")
	GameState.owned_pet_ids = ["pet_jack"]
	GameState.hub_survey_progress["whisperwood"] = 99.0
	_SurveySystem.add_survey_percent("whisperwood", 2.0, false)
	assert_eq(_SurveySystem.get_survey_percent("whisperwood"), 0.0, "完全調査後は0%へ")
	assert_true(_PetSystem.owns_pet("pet_ash"))
	assert_false(_PetSystem.owns_pet("pet_ink"))


func test_blackshore_complete_unlocks_ink() -> void:
	const _PetSystem := preload("res://scripts/pets/PetSystem.gd")
	GameState.owned_pet_ids = ["pet_jack"]
	GameState.hub_survey_progress["blackshore"] = 100.0
	_PetSystem.sync_unlocks_from_survey_progress(false)
	assert_true(_PetSystem.owns_pet("pet_ink"))
	assert_eq(_PetSystem.complete_reward_pet_id("whisperwood"), "pet_ash")
	assert_eq(_PetSystem.complete_reward_pet_id("blackshore"), "pet_ink")
	assert_eq(_PetSystem.complete_reward_pet_id("mourngate"), "")


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


func test_survey_staff_can_start_cycle_without_roster() -> void:
	## P3-SURVEY-STAFF-001: ノノカ／ニーナはロスター外でも調査員として配置可。
	const _SurveyStaff := preload("res://scripts/survey/SurveyStaff.gd")
	assert_true(_SurveySystem.is_survey_staff(_SurveyStaff.ID_NONOKA))
	assert_true(_SurveySystem.is_survey_staff(_SurveyStaff.ID_NINA))
	assert_true(_SurveySystem.can_assign_investigator(_SurveyStaff.ID_NONOKA))
	var bonus: float = _SurveySystem.investigator_speed_bonus(
		_SurveyStaff.ID_NONOKA, _SurveyStaff.preferred_role(_SurveyStaff.ID_NONOKA)
	)
	assert_gt(bonus, 0.0)
	var auto_ids: Array[String] = _SurveySystem.auto_assign_members()
	assert_true(auto_ids.has(_SurveyStaff.ID_NONOKA), "おまかせはスタッフ優先1")
	var started: Dictionary = _SurveySystem.start_cycle(
		Constants.MOURNGATE_DUNGEON_ID,
		_SurveyConfig.PRESET_SHORT,
		[_SurveyStaff.ID_NONOKA, _SurveyStaff.ID_NINA] as Array[String]
	)
	assert_true(bool(started.get("ok", false)), str(started))
	assert_true(_SurveySystem.is_member_dispatched(_SurveyStaff.ID_NONOKA))
	## スタッフ派遣では編成人数を減らさない（ロスター外のため party 不変）。
	GameState.hub_survey_cycle = {}


func test_achieve_entries_exist() -> void:
	var rows: Array[Dictionary] = _SurveySystem.achieve_entries()
	assert_gt(rows.size(), 0)


func test_speed_bonus_scales_with_combat_power() -> void:
	## 案A: 総合戦闘力が高いほど調査速度ボーナスが大きい。
	assert_true(not GameState.roster.is_empty(), "roster required")
	var adv: Resource = GameState.roster[0]
	assert_ne(adv, null)
	var mid: String = str(adv.id)
	var saved_hp: int = 0
	if adv.base_stats != null:
		saved_hp = int(adv.base_stats.hp)
	var base_bonus: float = _SurveySystem.investigator_speed_bonus(mid, "")
	assert_gte(base_bonus, _SurveyConfig.SPEED_BONUS_MIN)
	assert_lte(base_bonus, _SurveyConfig.SPEED_BONUS_MAX + _SurveyConfig.SPEED_BONUS_ROLE)
	## HP を上げるとボーナスが増える（上限未満のとき）。
	var before_power: int = _SurveySystem.investigator_combat_power(mid)
	if adv.base_stats != null:
		adv.base_stats.hp = saved_hp + 2000
	var after_power: int = _SurveySystem.investigator_combat_power(mid)
	assert_gt(after_power, before_power)
	var boosted: float = _SurveySystem.investigator_speed_bonus(mid, "")
	assert_gte(boosted, base_bonus)
	## 担当ロールはわずかに上乗せ。
	var with_role: float = _SurveySystem.investigator_speed_bonus(mid, "archaeology")
	assert_gte(with_role, boosted)
	if adv.base_stats != null:
		adv.base_stats.hp = saved_hp


func test_bal_survey_token_ranges_below_clear() -> void:
	## P3-BAL-SURVEY-001: 調査室石は潜行クリア帯（35–65）より一段下。
	assert_lte(_SurveyConfig.TOKEN_SHORT_MAX, 30)
	assert_lte(_SurveyConfig.TOKEN_STANDARD_MAX, 70)
	assert_lt(_SurveyConfig.TOKEN_STANDARD_MAX, 80)
	assert_lt(_SurveyConfig.TOKEN_SHORT_MAX, 35)


func test_codex_stage_up_adds_mourngate_survey() -> void:
	## P3-BAL-SURVEY-001: 図鑑段階アップが① SURVEY に加算される。
	GameState.enemy_codex = {}
	GameState.hub_survey_progress = {}
	var eid: String = "sepia_hound"
	assert_eq(GameState.get_enemy_stage(eid), 1)
	GameState.mark_enemy_seen(eid)
	assert_eq(GameState.get_enemy_stage(eid), 2)
	assert_eq(_SurveySystem.get_survey_percent(Constants.MOURNGATE_DUNGEON_ID), _SurveyConfig.SURVEY_ADD_CODEX_STAGE)
	GameState.add_enemy_kill(eid)
	assert_eq(GameState.get_enemy_stage(eid), 3)
	assert_eq(
		_SurveySystem.get_survey_percent(Constants.MOURNGATE_DUNGEON_ID),
		_SurveyConfig.SURVEY_ADD_CODEX_STAGE * 2.0
	)


func test_claim_over_cap_halves_tokens() -> void:
	## 日次 SURVEY 上限到達後の受取は魔晶石半減（付与率があるので当たるまで再試行）。
	GameState.hub_survey_room_daily = {
		"day_key": DailyMissionSystem.current_day_key(),
		"used": _SurveyConfig.SURVEY_ROOM_DAILY_CAP,
	}
	assert_true(_SurveySystem.is_room_daily_capped())
	var ids: Array[String] = []
	if not GameState.roster.is_empty() and GameState.roster[0] != null:
		ids.append(str(GameState.roster[0].id))
	var gained: int = 0
	var before_token: int = 0
	var claimed: Dictionary = {}
	for _i in 48:
		GameState.hub_survey_cycle = {}
		var started: Dictionary = _SurveySystem.start_cycle(
			Constants.MOURNGATE_DUNGEON_ID, _SurveyConfig.PRESET_SHORT, ids
		)
		assert_true(bool(started.get("ok", false)), str(started))
		GameState.hub_survey_cycle["start_unix"] = Time.get_unix_time_from_system() - (
			_SurveyConfig.SHORT_DURATION_SEC + 10.0
		)
		before_token = GameState.gacha_token
		claimed = _SurveySystem.claim_cycle()
		assert_true(bool(claimed.get("ok", false)), str(claimed))
		assert_true(bool(claimed.get("token_over_cap", false)))
		gained = int(claimed.get("token", 0))
		if gained > 0:
			break
	assert_gte(gained, 1, "魔晶石付与が一度も出ないのは異常")
	assert_lte(gained, int(ceil(float(_SurveyConfig.TOKEN_SHORT_MAX) * _SurveyConfig.ROOM_OVER_CAP_TOKEN_MULT)))
	assert_eq(GameState.gacha_token, before_token + gained)
