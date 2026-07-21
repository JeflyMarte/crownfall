extends Node

## ギルド日課ミッション（P3-DAILY / P3-DAILY-002）。
## プールから毎日3件を day_key シードで決定的抽選。5:00 JST リセット。

signal missions_updated

const JST_OFFSET_SEC: int = 9 * 3600
const DAY_START_HOUR_JST: int = 5
const DAILY_PICK_COUNT: int = 3

## 抽選プール（P3-DAILY-002-4）
const DAILY_POOL: Array[String] = [
	"daily_clear_run",
	"daily_kill_enemies",
	"daily_kill_elite",
	"daily_kill_boss",
	"daily_craft_item",
	"daily_enhance_item",
	"daily_alchemy_item",
	"daily_dismantle_item",
	"daily_gacha_pull",
]

func ensure_refreshed() -> void:
	var day_key: String = _current_day_key()
	var state: Dictionary = GameState.daily_mission_state
	if str(state.get("day_key", "")) == day_key and _entries_valid(state.get("entries", [])):
		return
	_reset_for_day(day_key)

func report_progress(objective_type: String, param: String = "", amount: int = 1) -> void:
	if amount <= 0 or objective_type.is_empty():
		return
	ensure_refreshed()
	var changed: bool = false
	var entries: Array = GameState.daily_mission_state.get("entries", [])
	for raw in entries:
		if not raw is Dictionary:
			continue
		var entry: Dictionary = raw
		if bool(entry.get("claimed", false)):
			continue
		var mission: Resource = _get_mission_data(str(entry.get("mission_id", "")))
		if mission == null:
			continue
		if str(mission.objective_type) != objective_type:
			continue
		if not _param_matches(mission, param):
			continue
		var target: int = maxi(1, int(mission.target_count))
		var before: int = int(entry.get("progress", 0))
		entry["progress"] = mini(target, before + amount)
		if int(entry["progress"]) != before:
			changed = true
	if changed:
		missions_updated.emit()

func get_entries() -> Array[Dictionary]:
	ensure_refreshed()
	var out: Array[Dictionary] = []
	for raw in GameState.daily_mission_state.get("entries", []):
		if not raw is Dictionary:
			continue
		var entry: Dictionary = (raw as Dictionary).duplicate()
		var mission: Resource = _get_mission_data(str(entry.get("mission_id", "")))
		if mission == null:
			continue
		var target: int = maxi(1, int(mission.target_count))
		var progress: int = int(entry.get("progress", 0))
		entry["title"] = str(mission.title)
		entry["description"] = str(mission.description)
		entry["target_count"] = target
		entry["progress"] = progress
		entry["claimed"] = bool(entry.get("claimed", false))
		entry["complete"] = progress >= target
		entry["can_claim"] = entry["complete"] and not entry["claimed"]
		entry["reward_gold"] = int(mission.reward_gold)
		entry["reward_gacha_token"] = int(mission.reward_gacha_token)
		entry["reward_material_id"] = str(mission.reward_material_id)
		entry["reward_material_qty"] = int(mission.reward_material_qty)
		out.append(entry)
	return out

func claim(index: int) -> Dictionary:
	ensure_refreshed()
	var entries: Array = GameState.daily_mission_state.get("entries", [])
	if index < 0 or index >= entries.size():
		return {"ok": false, "reason": "invalid_index"}
	var entry: Dictionary = entries[index]
	if bool(entry.get("claimed", false)):
		return {"ok": false, "reason": "already_claimed"}
	var mission: Resource = _get_mission_data(str(entry.get("mission_id", "")))
	if mission == null:
		return {"ok": false, "reason": "missing_mission"}
	var target: int = maxi(1, int(mission.target_count))
	if int(entry.get("progress", 0)) < target:
		return {"ok": false, "reason": "not_complete"}
	_apply_rewards(mission)
	entry["claimed"] = true
	missions_updated.emit()
	return {
		"ok": true,
		"gold": int(mission.reward_gold),
		"gacha_token": int(mission.reward_gacha_token),
		"material_id": str(mission.reward_material_id),
		"material_qty": int(mission.reward_material_qty),
	}

func has_claimable() -> bool:
	for entry in get_entries():
		if bool(entry.get("can_claim", false)):
			return true
	return false

func reset_countdown_text() -> String:
	var now_utc: int = int(Time.get_unix_time_from_system())
	var jst_now: int = now_utc + JST_OFFSET_SEC
	var dt: Dictionary = Time.get_datetime_dict_from_unix_time(jst_now)
	var next_jst: int = jst_now
	if dt.hour >= DAY_START_HOUR_JST:
		next_jst += 86400
	var next_dt: Dictionary = Time.get_datetime_dict_from_unix_time(next_jst)
	var next_reset_jst: int = int(
		Time.get_unix_time_from_datetime_dict({
			"year": next_dt.year,
			"month": next_dt.month,
			"day": next_dt.day,
			"hour": DAY_START_HOUR_JST,
			"minute": 0,
			"second": 0,
		})
	) - JST_OFFSET_SEC
	var remain: int = maxi(0, next_reset_jst - now_utc)
	var hours: int = remain / 3600
	var mins: int = (remain % 3600) / 60
	return "%d:%02d" % [hours, mins]

func _reset_for_day(day_key: String) -> void:
	var picked: Array[String] = pick_missions_for_day(day_key)
	var entries: Array = []
	for mission_id in picked:
		entries.append({
			"mission_id": mission_id,
			"progress": 0,
			"claimed": false,
		})
	GameState.daily_mission_state = {"day_key": day_key, "entries": entries}
	missions_updated.emit()

## テスト／デバッグ用。day_key から決定的に3件を返す。
func pick_missions_for_day(day_key: String) -> Array[String]:
	var pool: Array[String] = DAILY_POOL.duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed_from_day_key(day_key)
	for i in range(pool.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: String = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	var out: Array[String] = []
	for i in mini(DAILY_PICK_COUNT, pool.size()):
		out.append(pool[i])
	return out

func current_day_key() -> String:
	return _current_day_key()


func _current_day_key() -> String:
	var jst_now: int = int(Time.get_unix_time_from_system()) + JST_OFFSET_SEC
	var dt: Dictionary = Time.get_datetime_dict_from_unix_time(jst_now)
	if int(dt.hour) < DAY_START_HOUR_JST:
		jst_now -= 86400
		dt = Time.get_datetime_dict_from_unix_time(jst_now)
	return "%04d-%02d-%02d" % [int(dt.year), int(dt.month), int(dt.day)]

func _seed_from_day_key(day_key: String) -> int:
	## 同じ日は同じ3件。hash() は実行間で変わることがあるので文字列から自前ハッシュ。
	var h: int = 2166136261
	for i in day_key.length():
		h = int((h ^ day_key.unicode_at(i)) * 16777619) & 0x7fffffff
	return h

func _entries_valid(entries: Variant) -> bool:
	if not entries is Array:
		return false
	var arr: Array = entries
	if arr.size() != DAILY_PICK_COUNT:
		return false
	for raw in arr:
		if not raw is Dictionary:
			return false
		var mid: String = str((raw as Dictionary).get("mission_id", ""))
		if _get_mission_data(mid) == null:
			return false
	return true

func _get_mission_data(mission_id: String) -> Resource:
	if mission_id.is_empty():
		return null
	var path: String = Constants.RESOURCE_DAILY_MISSIONS_PATH + mission_id + ".tres"
	if not ResourceLoader.exists(path):
		return null
	return load(path)

func _param_matches(mission: Resource, param: String) -> bool:
	var required: String = str(mission.target_param)
	if required.is_empty():
		return true
	return required == param

func _apply_rewards(mission: Resource) -> void:
	var gold: int = int(mission.reward_gold)
	if gold > 0:
		GameState.gold += gold
	var tokens: int = int(mission.reward_gacha_token)
	if tokens > 0:
		GameState.gacha_token += tokens
	var mat_id: String = str(mission.reward_material_id)
	var mat_qty: int = int(mission.reward_material_qty)
	if not mat_id.is_empty() and mat_qty > 0:
		GameState.add_material(mat_id, mat_qty)
