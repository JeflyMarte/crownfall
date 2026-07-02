extends Node

## ギルド日課ミッション（P3-DAILY）。固定3件/日・5:00 JST リセット。

signal missions_updated

const JST_OFFSET_SEC: int = 9 * 3600
const DAY_START_HOUR_JST: int = 5

const DAILY_POOL: Array[String] = [
	"daily_clear_run",
	"daily_combat_win",
	"daily_craft_item",
]

func ensure_refreshed() -> void:
	var day_key: String = _current_day_key()
	var state: Dictionary = GameState.daily_mission_state
	if str(state.get("day_key", "")) == day_key:
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
	return {"ok": true}

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
	var entries: Array = []
	for mission_id in DAILY_POOL:
		entries.append({
			"mission_id": mission_id,
			"progress": 0,
			"claimed": false,
		})
	GameState.daily_mission_state = {"day_key": day_key, "entries": entries}
	missions_updated.emit()

func _current_day_key() -> String:
	var jst_now: int = int(Time.get_unix_time_from_system()) + JST_OFFSET_SEC
	var dt: Dictionary = Time.get_datetime_dict_from_unix_time(jst_now)
	if int(dt.hour) < DAY_START_HOUR_JST:
		jst_now -= 86400
		dt = Time.get_datetime_dict_from_unix_time(jst_now)
	return "%04d-%02d-%02d" % [int(dt.year), int(dt.month), int(dt.day)]

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
