class_name CrystalExcavateSystem
extends RefCounted

const _DamageHelper := preload("res://scripts/excavate/CrystalExcavateDamageHelper.gd")
const _SkillProgression := preload("res://scripts/systems/SkillProgression.gd")

const TOKEN_DAMAGE_MULT: float = 0.08
const TOKEN_MIN: int = 1
const TOKEN_CAP: int = 300
const HISTORY_CAP: int = 50

const SELECT_SCENE: String = "res://scenes/excavate/CrystalExcavateSelectScene.tscn"
const COMBAT_SCENE: String = "res://scenes/excavate/CrystalExcavateCombatScene.tscn"
const RESULT_SCENE: String = "res://scenes/excavate/CrystalExcavateResultScene.tscn"
const RANKING_SCENE: String = "res://scenes/excavate/CrystalExcavateRankingScene.tscn"

## ランキング画面の戻り先（非永続）。
static var ranking_return_scene: String = SELECT_SCENE


static func ensure_refreshed() -> void:
	var day_key: String = DailyMissionSystem.current_day_key()
	var state: Dictionary = GameState.crystal_excavate_state
	if state.is_empty() or str(state.get("day_key", "")) != day_key:
		GameState.crystal_excavate_state = {"day_key": day_key, "used": false}


static func is_used_today() -> bool:
	ensure_refreshed()
	## デバッグ全解放中は日次制限を無視（何度でも発掘可）。
	if GameState.debug_full_unlock:
		return false
	return bool(GameState.crystal_excavate_state.get("used", false))


static func remaining_today() -> int:
	if GameState.debug_full_unlock:
		return 99
	return 0 if is_used_today() else 1


static func entry_status_label() -> String:
	ensure_refreshed()
	if GameState.debug_full_unlock:
		return "デバッグ無制限"
	if bool(GameState.crystal_excavate_state.get("used", false)):
		return "本日済"
	return "残り1回"


static func damage_to_tokens(dealt_damage: int) -> int:
	if dealt_damage <= 0:
		return 0
	return clampi(int(round(float(dealt_damage) * TOKEN_DAMAGE_MULT)), TOKEN_MIN, TOKEN_CAP)


static func list_adventurers() -> Array[Resource]:
	var out: Array[Resource] = []
	for member: Resource in GameState.roster:
		if member == null:
			continue
		if PetSystem.is_pet_member(member) or Constants.is_pet_id(str(member.id)):
			continue
		out.append(member)
	return out


static func is_valid_excavate_skill(skill_data: Resource) -> bool:
	if skill_data == null:
		return false
	if str(skill_data.slot_type) == "ultimate":
		return false
	return str(skill_data.effect_type) == "damage"


static func skill_candidates_for_member(member: Resource) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if member == null:
		return out
	var seen: Dictionary = {}
	var equipped: Array[String] = GameState.get_equipped_skill_ids(member)
	for sid: String in equipped:
		var skill: Resource = DataRegistry.get_skill_data(sid)
		if not is_valid_excavate_skill(skill):
			continue
		out.append({"id": sid, "skill": skill, "equipped": true})
		seen[sid] = true
	var job_data: Resource = DataRegistry.get_job_data(str(member.job_id))
	if job_data != null:
		for entry: Variant in _SkillProgression.get_unlock_entries(job_data):
			if entry is not Dictionary:
				continue
			var sid2: String = str((entry as Dictionary).get("skill_id", ""))
			if sid2.is_empty() or seen.has(sid2):
				continue
			if not _SkillProgression.is_job_skill_unlocked(member, sid2):
				continue
			var skill2: Resource = DataRegistry.get_skill_data(sid2)
			if not is_valid_excavate_skill(skill2):
				continue
			out.append({"id": sid2, "skill": skill2, "equipped": false})
			seen[sid2] = true
	return out


static func begin_excavate(member_id: String, skill_id: String) -> Dictionary:
	ensure_refreshed()
	if is_used_today():
		return {"ok": false, "reason": "used"}
	var member: Resource = GameState.find_roster_member_by_id(member_id)
	var skill: Resource = DataRegistry.get_skill_data(skill_id)
	if member == null or not is_valid_excavate_skill(skill):
		return {"ok": false, "reason": "invalid"}
	var candidates: Array[Dictionary] = skill_candidates_for_member(member)
	var allowed: bool = false
	for row: Dictionary in candidates:
		if str(row.get("id", "")) == skill_id:
			allowed = true
			break
	if not allowed:
		return {"ok": false, "reason": "skill_not_allowed"}
	## 選択画面の見込みは中央値。確定時のみ ±15% 乱数。
	var dealt: int = _DamageHelper.roll_damage(member, skill)
	var tokens: int = damage_to_tokens(dealt)
	var day_key: String = DailyMissionSystem.current_day_key()
	var prev_best: int = best_damage_on_record()
	var is_record: bool = dealt > prev_best
	GameState.crystal_excavate_state = {
		"day_key": day_key,
		"used": true,
		"last_tokens": tokens,
		"last_dealt_damage": dealt,
		"last_member_id": member_id,
		"last_skill_id": skill_id,
		"last_was_record": is_record,
		"pending_hub_fx_tokens": tokens,
	}
	GameState.crystal_excavate_session = {
		"member_id": member_id,
		"skill_id": skill_id,
		"dealt_damage": dealt,
		"tokens": tokens,
	}
	_record_history(member, skill_id, dealt, tokens, day_key)
	if tokens > 0:
		GameState.gacha_token += tokens
	SaveManager.request_save()
	return {"ok": true, "tokens": tokens, "dealt_damage": dealt}


static func consume_pending_hub_fx_tokens() -> int:
	ensure_refreshed()
	var state: Dictionary = GameState.crystal_excavate_state.duplicate(true)
	var amount: int = maxi(0, int(state.get("pending_hub_fx_tokens", 0)))
	if amount <= 0:
		return 0
	state["pending_hub_fx_tokens"] = 0
	GameState.crystal_excavate_state = state
	SaveManager.request_save()
	return amount


static func _record_history(
	member: Resource, skill_id: String, dealt: int, tokens: int, day_key: String
) -> void:
	if member == null:
		return
	var entry: Dictionary = {
		"member_id": str(member.id),
		"display_name": str(member.display_name),
		"job_id": str(member.job_id),
		"skill_id": skill_id,
		"dealt_damage": dealt,
		"tokens": tokens,
		"day_key": day_key,
	}
	var hist: Array = GameState.crystal_excavate_history.duplicate(true)
	hist.append(entry)
	hist.sort_custom(_cmp_history_damage_desc)
	if hist.size() > HISTORY_CAP:
		hist.resize(HISTORY_CAP)
	GameState.crystal_excavate_history = hist


static func _cmp_history_damage_desc(a: Variant, b: Variant) -> bool:
	var da: int = int((a as Dictionary).get("dealt_damage", 0)) if a is Dictionary else 0
	var db: int = int((b as Dictionary).get("dealt_damage", 0)) if b is Dictionary else 0
	if da == db:
		var day_a: String = str((a as Dictionary).get("day_key", "")) if a is Dictionary else ""
		var day_b: String = str((b as Dictionary).get("day_key", "")) if b is Dictionary else ""
		return day_a > day_b
	return da > db


static func ranked_history() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for row: Variant in GameState.crystal_excavate_history:
		if row is Dictionary:
			out.append((row as Dictionary).duplicate(true))
	out.sort_custom(_cmp_history_damage_desc)
	return out


static func open_ranking(from_scene: String) -> void:
	if from_scene.is_empty():
		ranking_return_scene = SELECT_SCENE
	else:
		ranking_return_scene = from_scene
	SceneRouter.change_scene(RANKING_SCENE)


static func ranking_back_scene() -> String:
	if ranking_return_scene.is_empty():
		return SELECT_SCENE
	return ranking_return_scene


static func best_damage_on_record() -> int:
	var best: int = 0
	for row: Variant in GameState.crystal_excavate_history:
		if row is not Dictionary:
			continue
		best = maxi(best, int((row as Dictionary).get("dealt_damage", 0)))
	return best


static func last_result() -> Dictionary:
	ensure_refreshed()
	var state: Dictionary = GameState.crystal_excavate_state
	return {
		"tokens": int(state.get("last_tokens", 0)),
		"dealt_damage": int(state.get("last_dealt_damage", 0)),
		"member_id": str(state.get("last_member_id", "")),
		"skill_id": str(state.get("last_skill_id", "")),
		"used": bool(state.get("used", false)),
		"was_record": bool(state.get("last_was_record", false)),
	}


static func session() -> Dictionary:
	return GameState.crystal_excavate_session.duplicate(true)
