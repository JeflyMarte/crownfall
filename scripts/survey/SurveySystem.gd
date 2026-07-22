class_name SurveySystem
extends RefCounted

## P3-HUB-SURVEY-001 — SURVEY／派遣サイクル／実績のロジック。

const _SurveyConfig := preload("res://scripts/survey/SurveyConfig.gd")
const _WeaponStatResolver := preload("res://scripts/equipment/WeaponStatResolver.gd")
const _EquipmentEnhancer := preload("res://scripts/equipment/EquipmentEnhancer.gd")
const _RosterUiHelper := preload("res://scripts/roster/RosterUiHelper.gd")


static func get_survey_percent(dungeon_id: String) -> float:
	return clampf(float(GameState.hub_survey_progress.get(dungeon_id, 0.0)), 0.0, _SurveyConfig.SURVEY_COMPLETE_PERCENT)


static func is_survey_clear(dungeon_id: String) -> bool:
	return get_survey_percent(dungeon_id) + 0.001 >= _SurveyConfig.SURVEY_CLEAR_PERCENT


static func add_survey_percent(dungeon_id: String, amount: float, from_room: bool = false) -> float:
	if dungeon_id.is_empty() or amount <= 0.0:
		return get_survey_percent(dungeon_id)
	if from_room:
		amount = _clamp_room_daily(amount)
		if amount <= 0.0:
			return get_survey_percent(dungeon_id)
	var cur: float = get_survey_percent(dungeon_id)
	var nxt: float = clampf(cur + amount, 0.0, _SurveyConfig.SURVEY_COMPLETE_PERCENT)
	GameState.hub_survey_progress[dungeon_id] = nxt
	return nxt


static func _clamp_room_daily(amount: float) -> float:
	_refresh_room_daily()
	var used: float = float(GameState.hub_survey_room_daily.get("used", 0.0))
	var remain: float = maxf(0.0, _SurveyConfig.SURVEY_ROOM_DAILY_CAP - used)
	var grant: float = minf(amount, remain)
	GameState.hub_survey_room_daily["used"] = used + grant
	return grant


static func _refresh_room_daily() -> void:
	var day_key: String = DailyMissionSystem.current_day_key()
	if str(GameState.hub_survey_room_daily.get("day_key", "")) == day_key:
		return
	GameState.hub_survey_room_daily = {"day_key": day_key, "used": 0.0}


static func on_stage_cleared(stage_id: String, first_clear: bool, has_boss_floor: bool) -> void:
	if stage_id.is_empty():
		return
	var stage: Resource = DataRegistry.get_stage_data(stage_id)
	if stage == null:
		return
	var biome_id: String = str(stage.biome_id)
	if biome_id.is_empty():
		return
	var add: float = _SurveyConfig.SURVEY_ADD_CLEAR
	if first_clear and has_boss_floor:
		add = _SurveyConfig.SURVEY_ADD_BOSS_FIRST
	add_survey_percent(biome_id, add, false)


static func on_codex_stage_up(enemy_id: String) -> void:
	## 撃破で段階が上がったとき（呼び出し側で上昇検知）。①調査に加算。
	if enemy_id.is_empty():
		return
	add_survey_percent(Constants.MOURNGATE_DUNGEON_ID, _SurveyConfig.SURVEY_ADD_CODEX_STAGE, false)


## 装備込みの総合戦闘力（ATK+DEF+HP）。調査速度ボーナスの比例元。
static func investigator_combat_power(member_id: String) -> int:
	var adv: Resource = GameState.find_roster_member_by_id(member_id)
	if adv == null:
		return 0
	var stats: Dictionary = _RosterUiHelper.compute_member_stats(adv, -1)
	return int(stats.get("attack", 0)) + int(stats.get("defense", 0)) + int(stats.get("hp", 0))


static func investigator_speed_bonus(member_id: String, role_id: String) -> float:
	var power: float = float(investigator_combat_power(member_id))
	if power <= 0.0:
		return 0.0
	var span: float = _SurveyConfig.SPEED_POWER_REF_HIGH - _SurveyConfig.SPEED_POWER_REF_LOW
	var t: float = 0.0
	if span > 0.0:
		t = clampf((power - _SurveyConfig.SPEED_POWER_REF_LOW) / span, 0.0, 1.0)
	var base: float = lerpf(_SurveyConfig.SPEED_BONUS_MIN, _SurveyConfig.SPEED_BONUS_MAX, t)
	## 担当一致でわずかに上乗せ（表示用ロールは固定割当でも可）
	if not role_id.is_empty():
		base += _SurveyConfig.SPEED_BONUS_ROLE
	var cap: float = _SurveyConfig.SPEED_BONUS_MAX + _SurveyConfig.SPEED_BONUS_ROLE
	return clampf(base, _SurveyConfig.SPEED_BONUS_MIN, cap)


static func total_speed_bonus(assignees: Array) -> float:
	var total: float = 0.0
	var i: int = 0
	for entry in assignees:
		if entry == null:
			continue
		var mid: String = str(entry) if entry is String else str(entry.get("member_id", ""))
		var role: String = _SurveyConfig.ROLE_IDS[mini(i, _SurveyConfig.ROLE_IDS.size() - 1)]
		if entry is Dictionary:
			mid = str(entry.get("member_id", ""))
			role = str(entry.get("role_id", role))
		if mid.is_empty():
			continue
		total += investigator_speed_bonus(mid, role)
		i += 1
	return clampf(total, 0.0, _SurveyConfig.MAX_SPEED_BONUS)


static func has_active_cycle() -> bool:
	return not GameState.hub_survey_cycle.is_empty() and str(GameState.hub_survey_cycle.get("dungeon_id", "")) != ""


static func cycle_progress_01(now_unix: float = -1.0) -> float:
	if not has_active_cycle():
		return 0.0
	var start: float = float(GameState.hub_survey_cycle.get("start_unix", 0.0))
	var dur: float = float(GameState.hub_survey_cycle.get("duration_sec", 1.0))
	var speed: float = 1.0 + float(GameState.hub_survey_cycle.get("speed_bonus", 0.0))
	var now: float = now_unix if now_unix >= 0.0 else Time.get_unix_time_from_system()
	if dur <= 0.0:
		return 1.0
	return clampf(((now - start) * speed) / dur, 0.0, 1.0)


static func cycle_remaining_sec(now_unix: float = -1.0) -> float:
	if not has_active_cycle():
		return 0.0
	var start: float = float(GameState.hub_survey_cycle.get("start_unix", 0.0))
	var dur: float = float(GameState.hub_survey_cycle.get("duration_sec", 1.0))
	var speed: float = 1.0 + float(GameState.hub_survey_cycle.get("speed_bonus", 0.0))
	var now: float = now_unix if now_unix >= 0.0 else Time.get_unix_time_from_system()
	var effective: float = dur / maxf(speed, 0.01)
	return maxf(0.0, effective - (now - start))


static func is_cycle_complete(now_unix: float = -1.0) -> bool:
	return has_active_cycle() and cycle_progress_01(now_unix) >= 1.0


static func dispatched_member_ids() -> Array[String]:
	var out: Array[String] = []
	if not has_active_cycle():
		return out
	var assignees: Array = GameState.hub_survey_cycle.get("assignees", [])
	for entry in assignees:
		var mid: String = ""
		if entry is String:
			mid = str(entry)
		elif entry is Dictionary:
			mid = str(entry.get("member_id", ""))
		if not mid.is_empty() and not out.has(mid):
			out.append(mid)
	return out


static func is_member_dispatched(member_id: String) -> bool:
	return dispatched_member_ids().has(member_id)


static func start_cycle(dungeon_id: String, preset: String, member_ids: Array[String]) -> Dictionary:
	if dungeon_id.is_empty():
		return {"ok": false, "reason": "ダンジョン未選択"}
	if has_active_cycle() and not is_cycle_complete():
		return {"ok": false, "reason": "調査中の案件があります"}
	if has_active_cycle() and is_cycle_complete():
		return {"ok": false, "reason": "完了報酬を受け取ってください"}
	var assignees: Array = []
	var i: int = 0
	for mid in member_ids:
		if mid.is_empty():
			continue
		if GameState.find_roster_member_by_id(mid) == null:
			continue
		var role: String = _SurveyConfig.ROLE_IDS[mini(i, _SurveyConfig.ROLE_IDS.size() - 1)]
		assignees.append({"member_id": mid, "role_id": role})
		i += 1
		if assignees.size() >= _SurveyConfig.INVESTIGATOR_SLOTS:
			break
	var speed: float = total_speed_bonus(assignees)
	var p: String = preset if preset == _SurveyConfig.PRESET_SHORT else _SurveyConfig.PRESET_STANDARD
	GameState.hub_survey_cycle = {
		"dungeon_id": dungeon_id,
		"preset": p,
		"start_unix": Time.get_unix_time_from_system(),
		"duration_sec": _SurveyConfig.duration_sec(p),
		"speed_bonus": speed,
		"assignees": assignees,
	}
	## 派遣中メンバーを編成から外す
	_remove_dispatched_from_party()
	return {"ok": true}


static func _remove_dispatched_from_party() -> void:
	var ids: Array[String] = dispatched_member_ids()
	if ids.is_empty():
		return
	var kept: Array = []
	for adv in GameState.party_members:
		if adv == null:
			continue
		if ids.has(str(adv.id)):
			continue
		kept.append(adv)
	if kept.is_empty() and not GameState.roster.is_empty():
		## 最低1人は残す（派遣以外の先頭）
		for adv in GameState.roster:
			if adv != null and not ids.has(str(adv.id)):
				kept.append(adv)
				break
	if not kept.is_empty():
		GameState.set_active_party(kept)


static func auto_assign_members() -> Array[String]:
	## 総合戦闘力の高い順に埋める（調査速度＝ステ比例と整合）。
	var scored: Array[Dictionary] = []
	for adv in GameState.roster:
		if adv == null:
			continue
		var mid: String = str(adv.id)
		if mid.is_empty():
			continue
		scored.append({"id": mid, "power": investigator_combat_power(mid)})
	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("power", 0)) > int(b.get("power", 0))
	)
	var ids: Array[String] = []
	for row: Dictionary in scored:
		ids.append(str(row.get("id", "")))
		if ids.size() >= _SurveyConfig.INVESTIGATOR_SLOTS:
			break
	return ids


static func claim_cycle() -> Dictionary:
	if not has_active_cycle():
		return {"ok": false, "reason": "進行中の調査がありません"}
	if not is_cycle_complete():
		return {"ok": false, "reason": "まだ調査が完了していません"}
	var dungeon_id: String = str(GameState.hub_survey_cycle.get("dungeon_id", ""))
	var preset: String = str(GameState.hub_survey_cycle.get("preset", _SurveyConfig.PRESET_STANDARD))
	var rewards: Dictionary = _roll_rewards(preset)
	## 付与
	GameState.gacha_token += int(rewards.get("token", 0))
	GameState.gold += int(rewards.get("gold", 0))
	var mat_id: String = str(rewards.get("material_id", _EquipmentEnhancer.BASE_ORE_ID))
	var mat_qty: int = int(rewards.get("material_qty", 0))
	if mat_qty > 0:
		GameState.add_material(mat_id, mat_qty)
	var weapon_id: String = str(rewards.get("weapon_id", ""))
	if not weapon_id.is_empty():
		_grant_weapon(weapon_id)
	add_survey_percent(dungeon_id, _SurveyConfig.cycle_survey_add(preset), true)
	GameState.hub_survey_cycle = {}
	rewards["ok"] = true
	rewards["dungeon_id"] = dungeon_id
	SaveManager.save_game()
	return rewards


static func _roll_rewards(preset: String) -> Dictionary:
	var short: bool = preset == _SurveyConfig.PRESET_SHORT
	var token: int = randi_range(
		_SurveyConfig.TOKEN_SHORT_MIN if short else _SurveyConfig.TOKEN_STANDARD_MIN,
		_SurveyConfig.TOKEN_SHORT_MAX if short else _SurveyConfig.TOKEN_STANDARD_MAX
	)
	var mat_qty: int = randi_range(
		_SurveyConfig.MATERIAL_SHORT_MIN if short else _SurveyConfig.MATERIAL_STANDARD_MIN,
		_SurveyConfig.MATERIAL_SHORT_MAX if short else _SurveyConfig.MATERIAL_STANDARD_MAX
	)
	var weapon_id: String = ""
	var roll: float = randf()
	if roll < _SurveyConfig.WEAPON_P_STAR3:
		weapon_id = _pick_weapon_id(2) ## rarity 2 = ★3表示系（ゲーム rarity 0-based）
	elif roll < _SurveyConfig.WEAPON_P_STAR3 + _SurveyConfig.WEAPON_P_STAR2:
		weapon_id = _pick_weapon_id(1)
	elif roll < _SurveyConfig.WEAPON_P_STAR3 + _SurveyConfig.WEAPON_P_STAR2 + _SurveyConfig.WEAPON_P_STAR1:
		weapon_id = _pick_weapon_id(0)
	return {
		"token": token,
		"gold": token * 5,
		"material_id": _EquipmentEnhancer.BASE_ORE_ID,
		"material_qty": mat_qty,
		"weapon_id": weapon_id,
	}


static func _pick_weapon_id(rarity: int) -> String:
	var pool: Array[String] = []
	var dungeon: Resource = DataRegistry.get_dungeon_data(Constants.MOURNGATE_DUNGEON_ID)
	if dungeon != null and "weapon_pool" in dungeon and not dungeon.weapon_pool.is_empty():
		for wid in dungeon.weapon_pool:
			var data: Resource = DataRegistry.get_weapon_data(str(wid))
			if data != null and int(data.rarity) == rarity:
				pool.append(str(wid))
	if pool.is_empty():
		for data in DataRegistry.get_all_weapon_data():
			if data == null:
				continue
			if int(data.rarity) != rarity:
				continue
			var wid: String = str(data.id)
			if not wid.is_empty():
				pool.append(wid)
	if pool.is_empty():
		return ""
	return pool[randi() % pool.size()]


static func _grant_weapon(weapon_id: String) -> void:
	var weapon_data: Resource = DataRegistry.get_weapon_data(weapon_id)
	if weapon_data == null:
		return
	var instance: Resource = WeaponInstance.new()
	instance.instance_id = "survey_%d_%d" % [Time.get_ticks_msec(), randi() % 100000]
	instance.weapon_id = weapon_id
	_WeaponStatResolver.apply_drop_stats(instance, weapon_data)
	instance.is_appraised = true
	GameState.inventory.append(instance)


static func enemy_codex_fill_percent() -> float:
	var total: int = 0
	var filled: int = 0
	for data in DataRegistry.get_all_enemy_data():
		if data == null:
			continue
		total += 1
		var eid: String = str(data.id)
		if GameState.get_enemy_stage(eid) >= 5:
			filled += 1
	if total <= 0:
		return 0.0
	return 100.0 * float(filled) / float(total)


static func achieve_entries() -> Array[Dictionary]:
	var fill: float = enemy_codex_fill_percent()
	var out: Array[Dictionary] = []
	for m in _SurveyConfig.ACHIEVE_MILESTONES:
		var mid: String = str(m.get("id", ""))
		var need: float = float(m.get("need_pct", 100.0))
		var claimed: bool = GameState.hub_survey_achievements_claimed.has(mid)
		var unlocked: bool = fill + 0.001 >= need
		out.append({
			"id": mid,
			"title": str(m.get("title", mid)),
			"need_pct": need,
			"fill_pct": fill,
			"unlocked": unlocked,
			"claimed": claimed,
			"gold": int(m.get("gold", 0)),
			"token": int(m.get("token", 0)),
			"display_name": str(m.get("title", mid)),
			"category": "achieve",
		})
	return out


static func claim_achievement(achieve_id: String) -> Dictionary:
	for entry in achieve_entries():
		if str(entry.get("id", "")) != achieve_id:
			continue
		if not bool(entry.get("unlocked", false)):
			return {"ok": false, "reason": "条件未達成"}
		if bool(entry.get("claimed", false)):
			return {"ok": false, "reason": "受取済み"}
		GameState.hub_survey_achievements_claimed[achieve_id] = true
		GameState.gold += int(entry.get("gold", 0))
		GameState.gacha_token += int(entry.get("token", 0))
		SaveManager.save_game()
		return {"ok": true, "gold": int(entry.get("gold", 0)), "token": int(entry.get("token", 0))}
	return {"ok": false, "reason": "不明な実績"}
