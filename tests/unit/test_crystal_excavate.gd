extends GutTest

## P3-UX-CRYSTAL-EXCAVATE-001 — 魔晶石発掘。

const _Excavate := preload("res://scripts/excavate/CrystalExcavateSystem.gd")
const _DamageHelper := preload("res://scripts/excavate/CrystalExcavateDamageHelper.gd")

var _saved_state: Dictionary = {}
var _saved_session: Dictionary = {}
var _saved_history: Array = []
var _saved_token: int = 0
var _saved_debug: bool = false


func before_each() -> void:
	_saved_state = GameState.crystal_excavate_state.duplicate(true)
	_saved_session = GameState.crystal_excavate_session.duplicate(true)
	_saved_history = GameState.crystal_excavate_history.duplicate(true)
	_saved_token = GameState.gacha_token
	_saved_debug = GameState.debug_full_unlock
	GameState.crystal_excavate_state = {}
	GameState.crystal_excavate_session = {}
	GameState.crystal_excavate_history = []
	GameState.gacha_token = 0


func after_each() -> void:
	GameState.crystal_excavate_state = _saved_state
	GameState.crystal_excavate_session = _saved_session
	GameState.crystal_excavate_history = _saved_history
	GameState.gacha_token = _saved_token
	GameState.debug_full_unlock = _saved_debug


func test_damage_to_tokens_caps_at_300() -> void:
	assert_eq(_Excavate.damage_to_tokens(0), 0)
	assert_eq(_Excavate.damage_to_tokens(100), 8)
	assert_eq(_Excavate.damage_to_tokens(4000), 300)
	assert_eq(_Excavate.damage_to_tokens(99999), 300)


func test_daily_once_blocks_second_begin() -> void:
	GameState.crystal_excavate_state = {
		"day_key": DailyMissionSystem.current_day_key(),
		"used": true,
	}
	assert_true(_Excavate.is_used_today())
	assert_eq(_Excavate.remaining_today(), 0)
	var blocked: Dictionary = _Excavate.begin_excavate("dummy", "dummy")
	assert_false(bool(blocked.get("ok", false)))


func test_debug_full_unlock_ignores_daily_limit() -> void:
	var saved_debug: bool = GameState.debug_full_unlock
	GameState.debug_full_unlock = true
	GameState.crystal_excavate_state = {
		"day_key": DailyMissionSystem.current_day_key(),
		"used": true,
	}
	assert_false(_Excavate.is_used_today())
	assert_eq(_Excavate.remaining_today(), 99)
	assert_eq(_Excavate.entry_status_label(), "デバッグ無制限")
	GameState.debug_full_unlock = saved_debug


func test_nina_guide_flag_key_is_stable() -> void:
	## 選択画面の初回ガイド。キー変更はセーブ互換を壊す。
	var src: String = FileAccess.get_file_as_string(
		"res://scripts/excavate/CrystalExcavateSelectScene.gd"
	)
	assert_true(src.contains("crystal_excavate_nina_guide_done"))
	assert_true(src.contains("GUIDE_LINES"))
	assert_true(src.contains("_on_help_pressed"))


func test_day_key_mismatch_resets_used() -> void:
	GameState.crystal_excavate_state = {
		"day_key": "1999-01-01",
		"used": true,
		"last_tokens": 50,
	}
	_Excavate.ensure_refreshed()
	assert_false(bool(GameState.crystal_excavate_state.get("used", true)))
	assert_eq(
		str(GameState.crystal_excavate_state.get("day_key", "")),
		DailyMissionSystem.current_day_key()
	)


func test_skill_candidates_exclude_ultimate() -> void:
	for member: Resource in GameState.roster:
		if member == null or PetSystem.is_pet_member(member):
			continue
		for row: Dictionary in _Excavate.skill_candidates_for_member(member):
			var skill: Resource = row.get("skill") as Resource
			assert_ne(str(skill.slot_type), "ultimate")
			assert_eq(str(skill.effect_type), "damage")
		return
	pass_test("empty roster in test env")


func test_begin_grants_tokens_to_gacha_token() -> void:
	var before: int = GameState.gacha_token
	for member: Resource in GameState.roster:
		if member == null or PetSystem.is_pet_member(member):
			continue
		var candidates: Array[Dictionary] = _Excavate.skill_candidates_for_member(member)
		if candidates.is_empty():
			continue
		var sid: String = str(candidates[0].get("id", ""))
		var base: int = _DamageHelper.preview_damage(member, candidates[0]["skill"])
		var bounds: Vector2i = _DamageHelper.variance_bounds(base)
		var result: Dictionary = _Excavate.begin_excavate(str(member.id), sid)
		assert_true(bool(result.get("ok", false)), str(result))
		var dealt: int = int(result.get("dealt_damage", -1))
		assert_gte(dealt, bounds.x)
		assert_lte(dealt, bounds.y)
		var expected: int = _Excavate.damage_to_tokens(dealt)
		assert_eq(int(result.get("tokens", -1)), expected)
		assert_eq(GameState.gacha_token, before + expected)
		assert_lte(expected, 300)
		return
	pass_test("no eligible roster member")


func test_damage_variance_bounds_are_pm_15_percent() -> void:
	assert_eq(_DamageHelper.DAMAGE_VARIANCE, 0.15)
	assert_eq(_DamageHelper.apply_variance(0, 1.15), 0)
	assert_eq(_DamageHelper.apply_variance(1000, 1.0), 1000)
	assert_eq(_DamageHelper.apply_variance(1000, 0.85), 850)
	assert_eq(_DamageHelper.apply_variance(1000, 1.15), 1150)
	var b: Vector2i = _DamageHelper.variance_bounds(1000)
	assert_eq(b.x, 850)
	assert_eq(b.y, 1150)


func test_pending_hub_fx_tokens_consumed_once() -> void:
	GameState.debug_full_unlock = true
	GameState.crystal_excavate_state = {
		"day_key": DailyMissionSystem.current_day_key(),
		"used": false,
	}
	for member: Resource in GameState.roster:
		if member == null or PetSystem.is_pet_member(member):
			continue
		var candidates: Array[Dictionary] = _Excavate.skill_candidates_for_member(member)
		if candidates.is_empty():
			continue
		var sid: String = str(candidates[0].get("id", ""))
		var result: Dictionary = _Excavate.begin_excavate(str(member.id), sid)
		assert_true(bool(result.get("ok", false)), str(result))
		var tokens: int = int(result.get("tokens", 0))
		assert_eq(int(GameState.crystal_excavate_state.get("pending_hub_fx_tokens", -1)), tokens)
		var first: int = _Excavate.consume_pending_hub_fx_tokens()
		assert_eq(first, tokens)
		assert_eq(_Excavate.consume_pending_hub_fx_tokens(), 0)
		return
	pass_test("no eligible roster member")


func test_new_record_flag_when_damage_beats_history() -> void:
	GameState.debug_full_unlock = true
	GameState.crystal_excavate_history = []
	GameState.crystal_excavate_state = {
		"day_key": DailyMissionSystem.current_day_key(),
		"used": false,
	}
	assert_eq(_Excavate.best_damage_on_record(), 0)
	for member: Resource in GameState.roster:
		if member == null or PetSystem.is_pet_member(member):
			continue
		var candidates: Array[Dictionary] = _Excavate.skill_candidates_for_member(member)
		if candidates.is_empty():
			continue
		var sid: String = str(candidates[0].get("id", ""))
		var r1: Dictionary = _Excavate.begin_excavate(str(member.id), sid)
		assert_true(bool(r1.get("ok", false)), str(r1))
		assert_true(bool(GameState.crystal_excavate_state.get("last_was_record", false)))
		assert_true(bool(_Excavate.last_result().get("was_record", false)))
		## 2回目は履歴があるので、前回超えのみ記録更新。
		GameState.crystal_excavate_state["used"] = false
		var prev_best: int = _Excavate.best_damage_on_record()
		var r2: Dictionary = _Excavate.begin_excavate(str(member.id), sid)
		assert_true(bool(r2.get("ok", false)), str(r2))
		var dealt2: int = int(r2.get("dealt_damage", 0))
		assert_eq(
			bool(GameState.crystal_excavate_state.get("last_was_record", false)),
			dealt2 > prev_best
		)
		return
	pass_test("no eligible roster member")


func test_history_ranks_by_damage_desc() -> void:
	GameState.crystal_excavate_history = []
	GameState.debug_full_unlock = true
	GameState.crystal_excavate_state = {
		"day_key": DailyMissionSystem.current_day_key(),
		"used": false,
	}
	var wrote: int = 0
	for member: Resource in GameState.roster:
		if member == null or PetSystem.is_pet_member(member):
			continue
		var candidates: Array[Dictionary] = _Excavate.skill_candidates_for_member(member)
		if candidates.is_empty():
			continue
		var sid: String = str(candidates[0].get("id", ""))
		var r: Dictionary = _Excavate.begin_excavate(str(member.id), sid)
		assert_true(bool(r.get("ok", false)), str(r))
		wrote += 1
		GameState.crystal_excavate_state["used"] = false
		if wrote >= 2:
			break
	if wrote < 1:
		pass_test("no eligible roster member")
		return
	var ranked: Array[Dictionary] = _Excavate.ranked_history()
	assert_gte(ranked.size(), 1)
	for i: int in range(1, ranked.size()):
		assert_gte(
			int(ranked[i - 1].get("dealt_damage", 0)),
			int(ranked[i].get("dealt_damage", 0))
		)
	assert_true(
		FileAccess.file_exists("res://scenes/excavate/CrystalExcavateRankingScene.tscn")
	)
