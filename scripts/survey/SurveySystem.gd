class_name SurveySystem
extends RefCounted

## P3-HUB-SURVEY-001 — SURVEY／派遣サイクル／実績のロジック。

const _SurveyConfig := preload("res://scripts/survey/SurveyConfig.gd")
const _SurveyStaff := preload("res://scripts/survey/SurveyStaff.gd")
const _WeaponStatResolver := preload("res://scripts/equipment/WeaponStatResolver.gd")
const _EquipmentEnhancer := preload("res://scripts/equipment/EquipmentEnhancer.gd")
const _RosterUiHelper := preload("res://scripts/roster/RosterUiHelper.gd")
const _LevelSystem := preload("res://scripts/systems/LevelSystem.gd")
const _BalanceConfig := preload("res://scripts/combat/BalanceConfig.gd")


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
	## 進行中のみ編成ロック。完了（受取待ち）はロック解除済み（party_restored）。
	var out: Array[String] = []
	if not has_active_cycle() or is_cycle_complete():
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


## タイマー完了（受取待ち）／受取後の欠員を派遣前編成へ戻す。
## 拠点ポーリング／入室／ロード／編成／結果入室・退出／ダンジョン入場／調査対象変更で呼ぶ。
## save_after=false はロード・結果途中用。ensure は欠け補完のみ（丸ごと置換で人数を減らさない）。
static func ensure_party_restored_if_awaiting_claim(save_after: bool = true) -> bool:
	var ids_before: Array = _party_backup_ids()
	## 受取済みでサイクル無しでも、バックアップが残っていれば欠員修復する。
	var awaiting: bool = has_active_cycle() and is_cycle_complete()
	var orphan_backup: bool = (not has_active_cycle()) and not ids_before.is_empty()
	if not awaiting and not orphan_backup:
		return false
	## 空の party_ids_before では「完全」とみなさない（フラグだけ立って欠員の事故を防ぐ）。
	if (
		awaiting
		and bool(GameState.hub_survey_cycle.get("party_restored", false))
		and not ids_before.is_empty()
		and _party_contains_all_ids(ids_before)
	):
		return false
	if orphan_backup and _party_contains_all_ids(ids_before):
		_clear_party_backup()
		if save_after:
			SaveManager.save_game()
		return false
	## 欠けている ID だけ戻す。現行より少ない backup で編成を潰さない。
	var ok: bool = _heal_party_from_backup(ids_before)
	if ok and awaiting:
		GameState.hub_survey_cycle["party_restored"] = true
	if ok and (orphan_backup or not has_active_cycle()):
		_clear_party_backup()
	if save_after and ok:
		SaveManager.save_game()
	return ok


## JSON／型ゆれに耐える ID 配列読み取り。
static func _read_id_array(raw: Variant) -> Array:
	var out: Array = []
	if raw == null:
		return out
	var as_list: Array = []
	if raw is PackedStringArray:
		for i: int in (raw as PackedStringArray).size():
			as_list.append(str((raw as PackedStringArray)[i]))
	elif raw is Array:
		as_list = raw as Array
	else:
		return out
	for mid_v: Variant in as_list:
		var mid: String = str(mid_v).strip_edges()
		if mid.is_empty() or out.has(mid):
			continue
		out.append(mid)
	return out


static func _read_variant_array(raw: Variant) -> Array:
	if raw is Array:
		return (raw as Array).duplicate()
	return []


## cycle 内 party_ids_before を優先し、無ければ独立バックアップ。
static func _party_backup_ids() -> Array:
	var from_cycle: Array = _read_id_array(GameState.hub_survey_cycle.get("party_ids_before", []))
	if not from_cycle.is_empty():
		return from_cycle
	return _read_id_array(GameState.hub_survey_party_backup_ids)


static func _store_party_backup(ids: Array) -> void:
	GameState.hub_survey_party_backup_ids = _read_id_array(ids)


static func _clear_party_backup() -> void:
	GameState.hub_survey_party_backup_ids = []


## 現編成が指定 ID をすべて含むか（順序不問）。空配列は「検証不可」＝ false。
static func _party_contains_all_ids(member_ids: Array) -> bool:
	return _members_contain_all_ids(GameState.party_members, member_ids)


## members 配列が指定 ID をすべて含むか（順序不問）。空 ids は false。
static func _members_contain_all_ids(members: Array, member_ids: Array) -> bool:
	var ids: Array = _read_id_array(member_ids)
	if ids.is_empty():
		return false
	var have: Dictionary = {}
	for adv: Variant in members:
		if adv == null:
			continue
		have[str((adv as Resource).id)] = true
	for mid_v: Variant in ids:
		var mid: String = str(mid_v).strip_edges()
		if mid.is_empty():
			continue
		if not have.has(mid):
			return false
	return true


## a の全 ID が b に含まれるか（空 a は false）。
static func _ids_subset_of(a: Array, b: Array) -> bool:
	var left: Array = _read_id_array(a)
	var right: Array = _read_id_array(b)
	if left.is_empty() or right.is_empty():
		return false
	var have: Dictionary = {}
	for mid_v: Variant in right:
		have[str(mid_v)] = true
	for mid_v2: Variant in left:
		if not have.has(str(mid_v2)):
			return false
	return true


static func _current_party_ids() -> Array:
	var out: Array = []
	for adv_before: Variant in GameState.party_members:
		if adv_before == null:
			continue
		var mid: String = str((adv_before as Resource).id).strip_edges()
		if mid.is_empty() or out.has(mid):
			continue
		out.append(mid)
	return out


## バックアップにいるが編成にいないメンバーだけ戻す。人数を減らさない。
## 全員揃ったときだけ true（途中欠員の true 禁止）。
static func _heal_party_from_backup(party_ids_before: Array) -> bool:
	var ids: Array = _read_id_array(party_ids_before)
	if ids.is_empty():
		ids = _party_backup_ids()
	if ids.is_empty():
		return false
	if _party_contains_all_ids(ids):
		return true
	var party: Array = GameState.party_members.duplicate()
	var have: Dictionary = {}
	for adv: Variant in party:
		if adv == null:
			continue
		have[str((adv as Resource).id)] = true
	var changed: bool = false
	for mid_v: Variant in ids:
		var mid: String = str(mid_v).strip_edges()
		if mid.is_empty() or have.has(mid):
			continue
		if party.size() >= GameState.ACTIVE_PARTY_SIZE:
			break
		var adv2: Resource = GameState.find_roster_member_by_id(mid)
		if adv2 == null or party.has(adv2):
			continue
		party.append(adv2)
		have[mid] = true
		changed = true
	if not changed:
		return false
	if not GameState.set_active_party(party):
		push_warning("SurveySystem: heal 編成失敗 reason=%s" % GameState.active_party_reject_reason(party))
		return false
	if not _party_contains_all_ids(ids):
		push_warning("SurveySystem: heal 後も欠員 size=%d expect=%d" % [
			GameState.party_members.size(), ids.size()
		])
		return false
	return true


static func start_cycle(dungeon_id: String, preset: String, member_ids: Array[String]) -> Dictionary:
	if dungeon_id.is_empty():
		return {"ok": false, "reason": "ダンジョン未選択"}
	if has_active_cycle() and not is_cycle_complete():
		return {"ok": false, "reason": "調査中の案件があります"}
	if has_active_cycle() and is_cycle_complete():
		return {"ok": false, "reason": "完了報酬を受け取ってください"}
	## 欠員のまま開始して backup を上書きしないよう、先に orphan／受取待ちを癒す。
	ensure_party_restored_if_awaiting_claim(false)
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
	if assignees.is_empty():
		return {"ok": false, "reason": "調査員を1人以上配置してください"}
	if not leaves_combat_for_party(assignees):
		return {"ok": false, "reason": "編成用に最低1人は残してください"}
	var speed: float = total_speed_bonus(assignees)
	var p: String = preset if preset == _SurveyConfig.PRESET_SHORT else _SurveyConfig.PRESET_STANDARD
	## 受取／中止後に戻すため、派遣前の編成を保存する（cycle 内＋独立バックアップ）。
	var party_ids_before: Array = _current_party_ids()
	var existing_backup: Array = _read_id_array(GameState.hub_survey_party_backup_ids)
	## 現行が既存 backup の真部分集合（既に欠員）なら、大きい方を維持して上書き事故を防ぐ。
	if (
		not existing_backup.is_empty()
		and existing_backup.size() > party_ids_before.size()
		and _ids_subset_of(party_ids_before, existing_backup)
	):
		party_ids_before = existing_backup.duplicate()
	_store_party_backup(party_ids_before)
	GameState.hub_survey_cycle = {
		"dungeon_id": dungeon_id,
		"preset": p,
		"start_unix": Time.get_unix_time_from_system(),
		"duration_sec": _SurveyConfig.duration_sec(p),
		"speed_bonus": speed,
		"assignees": assignees,
		"party_ids_before": party_ids_before.duplicate(),
	}
	remember_last_member_ids(assignees)
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


## サイクル終了後に派遣前編成を復元。成功で true。
## ids_before がある場合、全員揃った配列だけ set（不完全置換で編成を潰さない）。
static func _restore_party_after_dispatch(party_ids_before: Array, assignees: Array) -> bool:
	var ids_before: Array = _read_id_array(party_ids_before)
	if ids_before.is_empty():
		ids_before = _party_backup_ids()
	var snapshot: Array = GameState.party_members.duplicate()
	if not ids_before.is_empty():
		var restored: Array = []
		var missing: bool = false
		for mid_v: Variant in ids_before:
			var mid: String = str(mid_v).strip_edges()
			if mid.is_empty():
				continue
			var adv: Resource = GameState.find_roster_member_by_id(mid)
			if adv == null:
				missing = true
				continue
			if restored.has(adv):
				continue
			restored.append(adv)
			if restored.size() >= GameState.ACTIVE_PARTY_SIZE:
				break
		## 全員揃ったときだけ置換する（途中配列で set しない）。
		if not missing and not restored.is_empty() and _members_contain_all_ids(restored, ids_before):
			if GameState.set_active_party(restored):
				return true
			push_warning("SurveySystem: party_ids_before 復元失敗 reason=%s" % GameState.active_party_reject_reason(restored))
		elif missing:
			push_warning("SurveySystem: party_ids_before にロスター欠落あり — 置換せずフォールバック")
	## 旧セーブ（party_ids_before 無し）／復元失敗: スナップショットへ派遣員を空き枠に戻す。
	var kept: Array = snapshot.duplicate()
	for mid: String in combat_assignee_ids(assignees):
		if kept.size() >= GameState.ACTIVE_PARTY_SIZE:
			break
		var adv2: Resource = GameState.find_roster_member_by_id(mid)
		if adv2 == null:
			continue
		var already: bool = false
		for m: Variant in kept:
			if m != null and str((m as Resource).id) == mid:
				already = true
				break
		if not already:
			kept.append(adv2)
	if kept.is_empty():
		## 最後の砦: ロスター先頭で空編成を避ける。
		for adv3 in GameState.roster:
			if adv3 == null:
				continue
			kept.append(adv3)
			break
	if kept.is_empty():
		return false
	## バックアップがあるなら、完全復帰できる配列のときだけ set。失敗時は現状維持。
	if not ids_before.is_empty() and not _members_contain_all_ids(kept, ids_before):
		push_warning("SurveySystem: フォールバックでも欠員 — 編成を変更しない expect=%d" % ids_before.size())
		return false
	if not GameState.set_active_party(kept):
		push_warning("SurveySystem: フォールバック編成復元失敗 reason=%s" % GameState.active_party_reject_reason(kept))
		return false
	return true


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


## サイクル assignees / ID 配列から配置 ID を正規化して覚える。
static func remember_last_member_ids(member_ids: Array) -> void:
	var out: Array = []
	for mid_v: Variant in member_ids:
		var mid: String = ""
		if mid_v is Dictionary:
			mid = str((mid_v as Dictionary).get("member_id", ""))
		else:
			mid = str(mid_v)
		mid = mid.strip_edges()
		if mid.is_empty() or out.has(mid):
			continue
		out.append(mid)
		if out.size() >= _SurveyConfig.INVESTIGATOR_SLOTS:
			break
	GameState.hub_survey_last_member_ids = out


## 配置可能な前回メンバー。初回（未記録）のみおまかせ相当を返す。
static func pending_members_for_ui() -> Array[String]:
	var last: Array[String] = []
	for mid_v: Variant in GameState.hub_survey_last_member_ids:
		var mid: String = str(mid_v).strip_edges()
		if mid.is_empty() or last.has(mid):
			continue
		if not can_assign_investigator(mid):
			continue
		last.append(mid)
		if last.size() >= _SurveyConfig.INVESTIGATOR_SLOTS:
			break
	if not GameState.hub_survey_last_member_ids.is_empty():
		## 記録あり（全員外れても空枠のまま。勝手におまかせしない）。
		return last
	return auto_assign_members()


static func claim_cycle() -> Dictionary:
	if not has_active_cycle():
		return {"ok": false, "reason": "進行中の調査がありません"}
	if not is_cycle_complete():
		return {"ok": false, "reason": "まだ調査が完了していません"}
	var dungeon_id: String = str(GameState.hub_survey_cycle.get("dungeon_id", ""))
	var preset: String = str(GameState.hub_survey_cycle.get("preset", _SurveyConfig.PRESET_STANDARD))
	var assignees: Array = _read_variant_array(GameState.hub_survey_cycle.get("assignees", []))
	var party_ids_before: Array = _party_backup_ids()
	## 日次 SURVEY 上限到達後は魔晶石を半減（放置石稼ぎ抑制）。
	var over_cap: bool = is_room_daily_capped()
	var rewards: Dictionary = _roll_rewards(preset, over_cap, dungeon_id)
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
	## 前回配置を残してからクリア（受取後に勝手なおまかせをしない）。
	remember_last_member_ids(assignees)
	## 復元してから cycle を消す。失敗時もバックアップを残し、編成画面／次回 ensure で再修復する。
	var restored_ok: bool = _restore_party_after_dispatch(party_ids_before, assignees)
	GameState.hub_survey_cycle = {}
	if restored_ok:
		_clear_party_backup()
	else:
		push_warning("SurveySystem: claim_cycle 編成復元失敗 — backup を残して再修復可能にする")
		_store_party_backup(party_ids_before)
	var exp_result: Dictionary = grant_dispatch_exp(dungeon_id, preset, assignees)
	rewards["exp_pool"] = int(exp_result.get("pool", 0))
	rewards["exp_entries"] = exp_result.get("entries", [])
	add_survey_percent(dungeon_id, _SurveyConfig.cycle_survey_add(preset), true)
	rewards["ok"] = true
	rewards["dungeon_id"] = dungeon_id
	rewards["token_over_cap"] = over_cap
	SaveManager.save_game()
	return rewards


## 対象 DG の雑魚クリア相当 EXP（ボス除外の推定）。
static func reference_trash_clear_exp(dungeon_id: String) -> int:
	var dungeon: Resource = DataRegistry.get_dungeon_data(dungeon_id)
	if dungeon == null:
		return 100
	var total: int = 0
	var n: int = 0
	for eid_v in dungeon.enemy_pool:
		var data: Resource = DataRegistry.get_enemy_data(str(eid_v))
		if data == null:
			continue
		total += maxi(0, int(data.exp_reward))
		n += 1
	var avg: float = 10.0 if n <= 0 else float(total) / float(n)
	var enemy_lv: int = maxi(1, int(dungeon.enemy_level))
	var lf: float = float(enemy_lv - 1)
	avg *= 1.0 + _BalanceConfig.ENEMY_LEVEL_EXP_K * lf
	var rooms: int = maxi(1, int(dungeon.room_count) - 1)
	return maxi(1, int(round(avg * float(rooms) * _SurveyConfig.EXP_TRASH_SWARM_AVG)))


## 対象 DG の完走相当 EXP（雑魚＋ボス・撃破倍率・クリアボーナス込み）。
static func reference_dungeon_clear_exp(dungeon_id: String) -> int:
	var dungeon: Resource = DataRegistry.get_dungeon_data(dungeon_id)
	if dungeon == null:
		return maxi(1, reference_trash_clear_exp(dungeon_id))
	var trash: float = float(reference_trash_clear_exp(dungeon_id))
	var boss_xp: float = 0.0
	var boss_id: String = str(dungeon.boss_id).strip_edges()
	if not boss_id.is_empty():
		var boss: Resource = DataRegistry.get_enemy_data(boss_id)
		if boss != null:
			var enemy_lv: int = maxi(1, int(dungeon.enemy_level))
			var lf: float = float(enemy_lv - 1)
			boss_xp = float(maxi(0, int(boss.exp_reward))) * (1.0 + _BalanceConfig.ENEMY_LEVEL_EXP_K * lf)
	var run_total: float = (trash + boss_xp) * _BalanceConfig.COMBAT_KILL_EXP_MULT
	run_total *= 1.0 + _BalanceConfig.CLEAR_EXP_BONUS_RATIO
	return maxi(1, int(round(run_total)))


static func dispatch_exp_pool(dungeon_id: String, preset: String) -> int:
	var ratio: float = (
		_SurveyConfig.EXP_RATIO_SHORT
		if preset == _SurveyConfig.PRESET_SHORT
		else _SurveyConfig.EXP_RATIO_STANDARD
	)
	return maxi(0, int(round(float(reference_dungeon_clear_exp(dungeon_id)) * ratio)))


## 配置のうち戦闘ロスターのみ（スタッフ除外・重複除外・順序維持）。
static func combat_assignee_ids(assignees: Array) -> Array[String]:
	var out: Array[String] = []
	var seen: Dictionary = {}
	for entry in assignees:
		var mid: String = ""
		if entry is String:
			mid = str(entry)
		elif entry is Dictionary:
			mid = str(entry.get("member_id", ""))
		if mid.is_empty() or is_survey_staff(mid) or seen.has(mid):
			continue
		if GameState.find_roster_member_by_id(mid) == null:
			continue
		seen[mid] = true
		out.append(mid)
	return out


## プール固定→均等割で付与。entries は UI 用。
static func grant_dispatch_exp(dungeon_id: String, preset: String, assignees: Array) -> Dictionary:
	var recipients: Array[String] = combat_assignee_ids(assignees)
	var pool: int = dispatch_exp_pool(dungeon_id, preset) if not recipients.is_empty() else 0
	var entries: Array = []
	if recipients.is_empty() or pool <= 0:
		return {"pool": 0, "entries": entries}
	var n: int = recipients.size()
	var base: int = int(pool / n)
	var rem: int = pool - base * n
	var exp_by: Dictionary = {}
	for i: int in n:
		var share: int = base + (1 if i < rem else 0)
		exp_by[recipients[i]] = share
	for mid: String in recipients:
		var adv: Resource = GameState.find_roster_member_by_id(mid)
		if adv == null:
			continue
		var amount: int = int(exp_by.get(mid, 0))
		var lv_before: int = int(adv.level)
		var exp_before: int = int(adv.exp)
		var levels: int = _LevelSystem.grant_exp(adv, amount)
		entries.append({
			"member_id": mid,
			"exp": amount,
			"levels_gained": levels,
			"level_before": lv_before,
			"level_after": int(adv.level),
			"exp_before": exp_before,
			"exp_after": int(adv.exp),
		})
	return {"pool": pool, "entries": entries}


## 進行中の調査サイクルを中止（報酬・SURVEY加算なし）。完了済みは受け取りを促す。
static func cancel_cycle() -> Dictionary:
	if not has_active_cycle():
		return {"ok": false, "reason": "進行中の調査がありません"}
	if is_cycle_complete():
		return {"ok": false, "reason": "完了報酬を受け取ってください"}
	var assignees: Array = _read_variant_array(GameState.hub_survey_cycle.get("assignees", []))
	var party_ids_before: Array = _party_backup_ids()
	remember_last_member_ids(assignees)
	## 先に cycle を消して派遣ロックを解除してから復元（ロック中は set_active_party が拒否される）。
	GameState.hub_survey_cycle = {}
	var restored_ok: bool = _restore_party_after_dispatch(party_ids_before, assignees)
	if restored_ok:
		_clear_party_backup()
	else:
		_store_party_backup(party_ids_before)
	SaveManager.save_game()
	return {"ok": true}


static func _roll_rewards(
	preset: String,
	over_cap: bool = false,
	dungeon_id: String = "",
) -> Dictionary:
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
	var mat_id: String = _SurveyConfig.roll_material_id(dungeon_id)
	var weapon_id: String = ""
	var roll: float = randf()
	if roll < _SurveyConfig.WEAPON_P_STAR3:
		weapon_id = _pick_weapon_id(2, dungeon_id) ## rarity 2 = ★3表示系（ゲーム rarity 0-based）
	elif roll < _SurveyConfig.WEAPON_P_STAR3 + _SurveyConfig.WEAPON_P_STAR2:
		weapon_id = _pick_weapon_id(1, dungeon_id)
	elif roll < _SurveyConfig.WEAPON_P_STAR3 + _SurveyConfig.WEAPON_P_STAR2 + _SurveyConfig.WEAPON_P_STAR1:
		weapon_id = _pick_weapon_id(0, dungeon_id)
	return {
		"token": token,
		"gold": token * 5,
		"material_id": mat_id,
		"material_qty": mat_qty,
		"weapon_id": weapon_id,
	}


## 派遣先 Biome の weapon_pool から rarity 一致を抽選。空なら武器なし（全カタログへ落とさない）。
static func _pick_weapon_id(rarity: int, dungeon_id: String = "") -> String:
	var pool: Array[String] = []
	var lookup_id: String = dungeon_id.strip_edges()
	if lookup_id.is_empty():
		lookup_id = Constants.MOURNGATE_DUNGEON_ID
	var dungeon: Resource = DataRegistry.get_dungeon_data(lookup_id)
	if dungeon != null and "weapon_pool" in dungeon and not dungeon.weapon_pool.is_empty():
		for wid in dungeon.weapon_pool:
			var data: Resource = DataRegistry.get_weapon_data(str(wid))
			if data != null and int(data.rarity) == rarity:
				pool.append(str(wid))
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
	if not GameState.try_add_weapon_instance(instance):
		return
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
