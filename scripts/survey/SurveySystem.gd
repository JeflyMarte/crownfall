class_name SurveySystem
extends RefCounted

## P3-HUB-SURVEY-001 — SURVEY／派遣サイクル／実績のロジック。

const _SurveyConfig := preload("res://scripts/survey/SurveyConfig.gd")
const _SurveyStaff := preload("res://scripts/survey/SurveyStaff.gd")
const _WeaponStatResolver := preload("res://scripts/equipment/WeaponStatResolver.gd")
const _EquipmentEnhancer := preload("res://scripts/equipment/EquipmentEnhancer.gd")
const _RosterUiHelper := preload("res://scripts/roster/RosterUiHelper.gd")


static func is_survey_staff(member_id: String) -> bool:
	return _SurveyStaff.is_staff_id(member_id)


static func can_assign_investigator(member_id: String) -> bool:
	if member_id.is_empty():
		return false
	if is_survey_staff(member_id):
		return GameState.is_survey_staff_unlocked(member_id)
	return GameState.find_roster_member_by_id(member_id) != null


## 戦闘ロスター（調査スタッフ以外）の ID 一覧。
static func combat_roster_ids() -> Array[String]:
	var out: Array[String] = []
	for adv in GameState.roster:
		if adv == null:
			continue
		var mid: String = str(adv.id)
		if mid.is_empty() or is_survey_staff(mid):
			continue
		out.append(mid)
	return out


## 配置案のうち戦闘メンバー数（スタッフ除外・重複除外）。
static func assigned_combat_count(member_ids: Array) -> int:
	var seen: Dictionary = {}
	var n: int = 0
	for mid_v in member_ids:
		var mid: String = ""
		if mid_v is Dictionary:
			mid = str((mid_v as Dictionary).get("member_id", ""))
		else:
			mid = str(mid_v)
		if mid.is_empty() or is_survey_staff(mid) or seen.has(mid):
			continue
		if GameState.find_roster_member_by_id(mid) == null:
			continue
		seen[mid] = true
		n += 1
	return n


## 配置後も編成用に戦闘メンバーが1人以上残るか（ロスター0人なら常に true）。
static func leaves_combat_for_party(member_ids: Array) -> bool:
	var combat_total: int = combat_roster_ids().size()
	if combat_total <= 0:
		return true
	return assigned_combat_count(member_ids) < combat_total


## スロットに cand を入れた仮想配置でも、編成用に1人残せるか。
static func can_place_without_emptying_party(
	pending_ids: Array,
	slot_index: int,
	cand_id: String
) -> bool:
	if cand_id.is_empty() or is_survey_staff(cand_id):
		return true
	var sim: Array[String] = []
	for mid_v in pending_ids:
		sim.append(str(mid_v))
	while sim.size() <= slot_index:
		sim.append("")
	sim[slot_index] = cand_id
	return leaves_combat_for_party(sim)


static func investigator_candidate_ids() -> Array[String]:
	## 解放済みスタッフ先頭＋戦闘ロスター（調査室候補リスト）。
	var out: Array[String] = []
	for sid: String in _SurveyStaff.all_ids():
		if not can_assign_investigator(sid):
			continue
		out.append(sid)
	for adv in GameState.roster:
		if adv == null:
			continue
		var mid: String = str(adv.id)
		if mid.is_empty() or out.has(mid):
			continue
		out.append(mid)
	return out


static func investigator_display_name(member_id: String) -> String:
	if is_survey_staff(member_id):
		return _SurveyStaff.display_name(member_id)
	var adv: Resource = GameState.find_roster_member_by_id(member_id)
	if adv != null:
		return str(adv.display_name)
	return member_id


static func investigator_portrait_texture(member_id: String) -> Texture2D:
	if is_survey_staff(member_id):
		return _SurveyStaff.load_icon_texture(member_id)
	var adv: Resource = GameState.find_roster_member_by_id(member_id)
	if adv != null:
		return _RosterUiHelper.get_member_portrait_texture(adv)
	return null


static func role_for_assignee(member_id: String, slot_index: int) -> String:
	if is_survey_staff(member_id):
		return _SurveyStaff.preferred_role(member_id)
	return _SurveyConfig.ROLE_IDS[mini(slot_index, _SurveyConfig.ROLE_IDS.size() - 1)]


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
	const _ContentUnlockNotice := preload("res://scripts/ui/ContentUnlockNotice.gd")
	## 解放通知の dedupe 用スナップショット（章クリア経由でも共有）。
	var unlock_before: Dictionary = _ContentUnlockNotice.snapshot_unlocked()
	var cur: float = get_survey_percent(dungeon_id)
	var nxt: float = clampf(cur + amount, 0.0, _SurveyConfig.SURVEY_COMPLETE_PERCENT)
	GameState.hub_survey_progress[dungeon_id] = nxt
	## 完全調査（100%）: 景品付与 → 0% リセット（案A）。ペットは try_claim 内で未所持時のみ。
	const _SurveyCompleteRewards := preload("res://scripts/survey/SurveyCompleteRewards.gd")
	if nxt + 0.001 >= _SurveyConfig.SURVEY_COMPLETE_PERCENT:
		_SurveyCompleteRewards.try_claim(dungeon_id, true)
	_ContentUnlockNotice.queue_newly_unlocked(unlock_before)
	return get_survey_percent(dungeon_id)


static func _clamp_room_daily(amount: float) -> float:
	_refresh_room_daily()
	var used: float = float(GameState.hub_survey_room_daily.get("used", 0.0))
	var remain: float = maxf(0.0, _SurveyConfig.SURVEY_ROOM_DAILY_CAP - used)
	var grant: float = minf(amount, remain)
	GameState.hub_survey_room_daily["used"] = used + grant
	return grant


static func room_daily_remaining() -> float:
	_refresh_room_daily()
	var used: float = float(GameState.hub_survey_room_daily.get("used", 0.0))
	return maxf(0.0, _SurveyConfig.SURVEY_ROOM_DAILY_CAP - used)


static func is_room_daily_capped() -> bool:
	return room_daily_remaining() <= 0.001


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


static func on_codex_stage_up(enemy_id: String, stages_gained: int = 1) -> void:
	## 図鑑段階が上がったとき（GameState から呼ぶ）。① SURVEY に加算。
	if enemy_id.is_empty() or stages_gained <= 0:
		return
	var add: float = _SurveyConfig.SURVEY_ADD_CODEX_STAGE * float(stages_gained)
	add_survey_percent(Constants.MOURNGATE_DUNGEON_ID, add, false)


## 装備込みの総合戦闘力（P3-UI-COMBAT-POWER-001）。調査速度ボーナスの比例元。
static func investigator_combat_power(member_id: String) -> int:
	var adv: Resource = GameState.find_roster_member_by_id(member_id)
	if adv == null:
		return 0
	return _RosterUiHelper.compute_member_combat_power(adv)

static func investigator_speed_bonus(member_id: String, role_id: String) -> float:
	## 調査スタッフは研究力固定（P3-SURVEY-STAFF-001）。戦闘員は装備込みステ比例。
	if is_survey_staff(member_id):
		var staff_base: float = _SurveyStaff.STAFF_SPEED_BASE
		if not role_id.is_empty():
			staff_base += _SurveyConfig.SPEED_BONUS_ROLE
		var staff_cap: float = _SurveyConfig.SPEED_BONUS_MAX + _SurveyConfig.SPEED_BONUS_ROLE
		return clampf(staff_base, _SurveyConfig.SPEED_BONUS_MIN, staff_cap)
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
		var mid: String = ""
		if entry is String:
			mid = str(entry)
		elif entry is Dictionary:
			mid = str(entry.get("member_id", ""))
		if mid.is_empty():
			continue
		var role: String = role_for_assignee(mid, i)
		if entry is Dictionary and not str(entry.get("role_id", "")).is_empty():
			role = str(entry.get("role_id", role))
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
		if not can_assign_investigator(mid):
			continue
		var role: String = role_for_assignee(mid, i)
		assignees.append({"member_id": mid, "role_id": role})
		i += 1
		if assignees.size() >= _SurveyConfig.INVESTIGATOR_SLOTS:
			break
	if not leaves_combat_for_party(assignees):
		return {"ok": false, "reason": "編成用に最低1人は残してください"}
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
	## 派遣中の戦闘メンバーのみ編成から外す（調査スタッフはロスター外のため無影響）。
	_remove_dispatched_from_party()
	return {"ok": true}


static func _remove_dispatched_from_party() -> void:
	var ids: Array[String] = []
	for mid: String in dispatched_member_ids():
		## 調査スタッフは編成対象外。
		if is_survey_staff(mid):
			continue
		ids.append(mid)
	if ids.is_empty():
		return
	var kept: Array = []
	for adv in GameState.party_members:
		if adv == null:
			continue
		if ids.has(str(adv.id)):
			continue
		kept.append(adv)
	if kept.is_empty():
		## 編成が空にならないよう、未派遣の戦闘メンバーを補充。
		for adv in GameState.roster:
			if adv == null or ids.has(str(adv.id)):
				continue
			kept.append(adv)
			break
	if kept.is_empty():
		## 全員派遣は start_cycle で拒否済み。万一ここまで来たら編成を触らない。
		return
	GameState.set_active_party(kept)


static func auto_assign_members() -> Array[String]:
	## スタッフ優先1人＋戦闘力上位で残りを埋める。戦闘は最低1人残す。
	var ids: Array[String] = []
	for sid: String in _SurveyStaff.AUTO_PRIORITY:
		if can_assign_investigator(sid):
			ids.append(sid)
			break
	var combat_total: int = combat_roster_ids().size()
	var combat_taken: int = 0
	var scored: Array[Dictionary] = []
	for adv in GameState.roster:
		if adv == null:
			continue
		var mid: String = str(adv.id)
		if mid.is_empty() or ids.has(mid):
			continue
		scored.append({"id": mid, "power": investigator_combat_power(mid)})
	scored.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("power", 0)) > int(b.get("power", 0))
	)
	for row: Dictionary in scored:
		if combat_total > 0 and combat_taken + 1 >= combat_total:
			break
		ids.append(str(row.get("id", "")))
		combat_taken += 1
		if ids.size() >= _SurveyConfig.INVESTIGATOR_SLOTS:
			break
	## ロスターが空でも解放済みスタッフのみで開始可能にする。
	if ids.is_empty():
		for sid: String in _SurveyStaff.all_ids():
			if not can_assign_investigator(sid):
				continue
			ids.append(sid)
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
	## 日次 SURVEY 上限到達後は魔晶石を半減（放置石稼ぎ抑制）。
	var over_cap: bool = is_room_daily_capped()
	var rewards: Dictionary = _roll_rewards(preset, over_cap)
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
	rewards["token_over_cap"] = over_cap
	SaveManager.save_game()
	return rewards


## 進行中の調査サイクルを中止（報酬・SURVEY加算なし）。完了済みは受け取りを促す。
static func cancel_cycle() -> Dictionary:
	if not has_active_cycle():
		return {"ok": false, "reason": "進行中の調査がありません"}
	if is_cycle_complete():
		return {"ok": false, "reason": "完了報酬を受け取ってください"}
	GameState.hub_survey_cycle = {}
	SaveManager.save_game()
	return {"ok": true}


static func _roll_rewards(preset: String, over_cap: bool = false) -> Dictionary:
	var short: bool = preset == _SurveyConfig.PRESET_SHORT
	var token: int = 0
	if randf() < _SurveyConfig.TOKEN_GRANT_CHANCE:
		token = randi_range(
			_SurveyConfig.TOKEN_SHORT_MIN if short else _SurveyConfig.TOKEN_STANDARD_MIN,
			_SurveyConfig.TOKEN_SHORT_MAX if short else _SurveyConfig.TOKEN_STANDARD_MAX
		)
		if over_cap:
			token = maxi(1, int(floor(float(token) * _SurveyConfig.ROOM_OVER_CAP_TOKEN_MULT)))
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
	GameState.note_equipment_obtained(instance)


static func enemy_codex_fill_percent() -> float:
	var total: int = 0
	var filled: int = 0
	var playable: Dictionary = CatalogHelper.playable_enemy_id_set()
	for data in DataRegistry.get_all_enemy_data():
		if data == null:
			continue
		var eid: String = str(data.id)
		if not playable.has(eid):
			continue
		total += 1
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
