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
var _saved_stage: Dictionary = {}
var _saved_token: int = 0
var _saved_nonoka_unlocked: bool = false
var _saved_nonoka_pending: bool = false


func before_each() -> void:
	_saved_progress = GameState.dungeon_progress.duplicate(true)
	_saved_survey = GameState.hub_survey_progress.duplicate(true)
	_saved_cycle = GameState.hub_survey_cycle.duplicate(true)
	_saved_room = GameState.hub_survey_room_daily.duplicate(true)
	_saved_achieve = GameState.hub_survey_achievements_claimed.duplicate(true)
	_saved_codex = GameState.enemy_codex.duplicate(true)
	_saved_stage = GameState.stage_progress.duplicate(true)
	_saved_token = GameState.gacha_token
	_saved_nonoka_unlocked = GameState.survey_staff_nonoka_unlocked
	_saved_nonoka_pending = GameState.pending_nonoka_survey_join
	GameState.dungeon_progress = {}
	GameState.hub_survey_progress = {}
	GameState.hub_survey_cycle = {}
	GameState.hub_survey_room_daily = {}
	GameState.hub_survey_achievements_claimed = {}
	GameState.enemy_codex = {}
	GameState.debug_full_unlock = false
	## 既存サイクル系テストはノノカ解放済み前提。
	GameState.survey_staff_nonoka_unlocked = true
	GameState.pending_nonoka_survey_join = false


func after_each() -> void:
	GameState.dungeon_progress = _saved_progress
	GameState.hub_survey_progress = _saved_survey
	GameState.hub_survey_cycle = _saved_cycle
	GameState.hub_survey_room_daily = _saved_room
	GameState.hub_survey_achievements_claimed = _saved_achieve
	GameState.enemy_codex = _saved_codex
	GameState.stage_progress = _saved_stage
	GameState.gacha_token = _saved_token
	GameState.debug_full_unlock = false
	GameState.survey_staff_nonoka_unlocked = _saved_nonoka_unlocked
	GameState.pending_nonoka_survey_join = _saved_nonoka_pending


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
	const _SurveyStaff := preload("res://scripts/survey/SurveyStaff.gd")
	## スタッフのみ配置（戦闘編成を空にしない）。
	var ids: Array[String] = [_SurveyStaff.ID_NONOKA]
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


func test_cancel_cycle_aborts_without_rewards() -> void:
	const _SurveyStaff := preload("res://scripts/survey/SurveyStaff.gd")
	var survey_before: float = _SurveySystem.get_survey_percent(Constants.MOURNGATE_DUNGEON_ID)
	var gold_before: int = GameState.gold
	var token_before: int = GameState.gacha_token
	var ids: Array[String] = [_SurveyStaff.ID_NONOKA]
	var started: Dictionary = _SurveySystem.start_cycle(
		Constants.MOURNGATE_DUNGEON_ID, _SurveyConfig.PRESET_SHORT, ids
	)
	assert_true(bool(started.get("ok", false)), str(started))
	assert_true(_SurveySystem.has_active_cycle())
	assert_true(_SurveySystem.is_member_dispatched(_SurveyStaff.ID_NONOKA))
	var canceled: Dictionary = _SurveySystem.cancel_cycle()
	assert_true(bool(canceled.get("ok", false)), str(canceled))
	assert_false(_SurveySystem.has_active_cycle())
	assert_false(_SurveySystem.is_member_dispatched(_SurveyStaff.ID_NONOKA))
	assert_eq(_SurveySystem.get_survey_percent(Constants.MOURNGATE_DUNGEON_ID), survey_before)
	assert_eq(GameState.gold, gold_before)
	assert_eq(GameState.gacha_token, token_before)
	## 中止後は再開始できる
	var restarted: Dictionary = _SurveySystem.start_cycle(
		Constants.MOURNGATE_DUNGEON_ID, _SurveyConfig.PRESET_SHORT, ids
	)
	assert_true(bool(restarted.get("ok", false)), str(restarted))
	_SurveySystem.cancel_cycle()


func test_cancel_cycle_rejects_when_complete() -> void:
	const _SurveyStaff := preload("res://scripts/survey/SurveyStaff.gd")
	var ids: Array[String] = [_SurveyStaff.ID_NONOKA]
	assert_true(bool(_SurveySystem.start_cycle(
		Constants.MOURNGATE_DUNGEON_ID, _SurveyConfig.PRESET_SHORT, ids
	).get("ok", false)))
	GameState.hub_survey_cycle["start_unix"] = Time.get_unix_time_from_system() - (
		_SurveyConfig.SHORT_DURATION_SEC + 10.0
	)
	assert_true(_SurveySystem.is_cycle_complete())
	var rejected: Dictionary = _SurveySystem.cancel_cycle()
	assert_false(bool(rejected.get("ok", false)))
	assert_true(_SurveySystem.has_active_cycle(), "完了済みは受取まで残す")
	_SurveySystem.claim_cycle()


func test_survey_staff_can_start_cycle_without_roster() -> void:
	## P3-SURVEY-STAFF-001: ノノカ／ニーナはロスター外でも調査員として配置可。
	const _SurveyStaff := preload("res://scripts/survey/SurveyStaff.gd")
	GameState.survey_staff_nonoka_unlocked = true
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


func test_nonoka_locked_until_mistfen_join() -> void:
	## P3-SURVEY-NONOKA-JOIN-001: 未解放時はノノカ配置不可／ニーナのみ。
	const _SurveyStaff := preload("res://scripts/survey/SurveyStaff.gd")
	GameState.debug_full_unlock = false
	GameState.survey_staff_nonoka_unlocked = false
	GameState.pending_nonoka_survey_join = false
	assert_false(_SurveySystem.can_assign_investigator(_SurveyStaff.ID_NONOKA))
	assert_true(_SurveySystem.can_assign_investigator(_SurveyStaff.ID_NINA))
	var cands: Array[String] = _SurveySystem.investigator_candidate_ids()
	assert_false(cands.has(_SurveyStaff.ID_NONOKA))
	assert_true(cands.has(_SurveyStaff.ID_NINA))
	var auto_ids: Array[String] = _SurveySystem.auto_assign_members()
	assert_false(auto_ids.has(_SurveyStaff.ID_NONOKA))
	assert_true(auto_ids.has(_SurveyStaff.ID_NINA) or not auto_ids.is_empty())
	GameState.queue_nonoka_survey_join_if_needed()
	assert_true(GameState.pending_nonoka_survey_join)
	GameState.commit_nonoka_survey_join()
	assert_true(GameState.survey_staff_nonoka_unlocked)
	assert_false(GameState.pending_nonoka_survey_join)
	assert_true(_SurveySystem.can_assign_investigator(_SurveyStaff.ID_NONOKA))


func test_mistfen_clear_queues_nonoka_join() -> void:
	## ③ mistfen_3_5 Normal 初回クリアで合流待ちが立つ。
	GameState.debug_full_unlock = false
	GameState.survey_staff_nonoka_unlocked = false
	GameState.pending_nonoka_survey_join = false
	GameState.stage_progress.erase("mistfen_3_5")
	GameState.dungeon_progress.erase("mistfen")
	GameState.mark_stage_cleared("mistfen_3_5", 0)
	assert_true(GameState.pending_nonoka_survey_join)
	assert_false(GameState.survey_staff_nonoka_unlocked)
	## 二重クリアでは待ちのまま（解放は拠点会話後）。
	GameState.mark_stage_cleared("mistfen_3_5", 0)
	assert_true(GameState.pending_nonoka_survey_join)


func test_nonoka_join_lines_include_nonoka_speaker() -> void:
	const _ChapterClearNinaLines := preload("res://scripts/ui/ChapterClearNinaLines.gd")
	const _StarterJoinQuotes := preload("res://scripts/roster/StarterJoinQuotes.gd")
	const _SurveyStaff := preload("res://scripts/survey/SurveyStaff.gd")
	var lines: Array = _ChapterClearNinaLines.nonoka_survey_join_lines()
	assert_gte(lines.size(), 4)
	var has_nonoka: bool = false
	for raw in lines:
		assert_typeof(raw, TYPE_DICTIONARY)
		var speaker: String = str((raw as Dictionary).get("speaker", ""))
		var text: String = str((raw as Dictionary).get("text", "")).strip_edges()
		assert_false(text.is_empty())
		if speaker == "nonoka":
			has_nonoka = true
	assert_true(has_nonoka, "ノノカ本人のセリフが必要")
	var quote: String = _StarterJoinQuotes.line_for(_SurveyStaff.ID_NONOKA)
	assert_false(quote.is_empty())
	assert_true(quote.find("たぶん") >= 0 or quote.find("ノート") >= 0)


func test_investigator_slots_always_four() -> void:
	assert_eq(_SurveyConfig.INVESTIGATOR_SLOTS, 4)
	assert_eq(_SurveyConfig.INVESTIGATOR_UI_SLOTS, 4)


func test_cannot_dispatch_all_combat_roster() -> void:
	## 戦闘メンバー全員を調査へ出すと開始不可。編成用に1人残す。
	assert_true(not GameState.roster.is_empty(), "roster required")
	GameState.hub_survey_cycle = {}
	var combat_ids: Array[String] = _SurveySystem.combat_roster_ids()
	assert_gte(combat_ids.size(), 1)
	assert_false(
		_SurveySystem.leaves_combat_for_party(combat_ids),
		"全員配置の仮想案は編成用が残らない"
	)
	if combat_ids.size() <= _SurveyConfig.INVESTIGATOR_SLOTS:
		var rejected: Dictionary = _SurveySystem.start_cycle(
			Constants.MOURNGATE_DUNGEON_ID,
			_SurveyConfig.PRESET_SHORT,
			combat_ids
		)
		assert_false(bool(rejected.get("ok", true)), "全員派遣は拒否")
		assert_true(str(rejected.get("reason", "")).contains("編成"))
	if combat_ids.size() >= 2:
		GameState.hub_survey_cycle = {}
		var partial: Array[String] = [combat_ids[0]]
		var ok: Dictionary = _SurveySystem.start_cycle(
			Constants.MOURNGATE_DUNGEON_ID,
			_SurveyConfig.PRESET_SHORT,
			partial
		)
		assert_true(bool(ok.get("ok", false)), str(ok))
		assert_false(GameState.party_members.is_empty(), "編成が空にならない")
		GameState.hub_survey_cycle = {}
	var auto_ids: Array[String] = _SurveySystem.auto_assign_members()
	assert_true(_SurveySystem.leaves_combat_for_party(auto_ids), "おまかせも編成用を残す")
	if combat_ids.size() == 1:
		assert_false(
			_SurveySystem.can_place_without_emptying_party([], 0, combat_ids[0]),
			"唯一の戦闘メンバーは編成用に残す"
		)


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
	const _SurveyStaff := preload("res://scripts/survey/SurveyStaff.gd")
	GameState.hub_survey_room_daily = {
		"day_key": DailyMissionSystem.current_day_key(),
		"used": _SurveyConfig.SURVEY_ROOM_DAILY_CAP,
	}
	assert_true(_SurveySystem.is_room_daily_capped())
	var ids: Array[String] = [_SurveyStaff.ID_NONOKA]
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
