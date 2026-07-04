extends Node

## 拠点期間限定バフイベント（P3-EVT-HUB）。端末日付・JST 5:00 境界。DailyMission とは独立。

signal event_updated

const _Schedule = preload("res://scripts/event/EventScheduleHelper.gd")

const MOD_EXP: String = "exp"
const MOD_GOLD: String = "gold"
const MOD_WEAPON_DROP: String = "weapon_drop"

var _cached_active_id: String = ""
var _debug_unix_override: int = -1

func ensure_active() -> void:
	var active: Resource = _resolve_active_event()
	var active_id: String = str(active.id) if active != null else ""
	if active_id != _cached_active_id:
		_cached_active_id = active_id
		event_updated.emit()

func is_event_running() -> bool:
	return get_active_event() != null

func get_active_event() -> Resource:
	ensure_active()
	return _resolve_active_event()

func get_modifier_mult(modifier_type: String) -> float:
	var event_data: Resource = get_active_event()
	if event_data == null:
		return 1.0
	if str(event_data.modifier_type) != modifier_type:
		return 1.0
	return maxf(1.0, float(event_data.modifier_mult))

func modifier_label(modifier_type: String) -> String:
	match modifier_type:
		MOD_EXP:
			return "経験値"
		MOD_GOLD:
			return "ゴールド"
		MOD_WEAPON_DROP:
			return "武器ドロップ率"
		_:
			return modifier_type

func active_modifier_summary() -> String:
	var event_data: Resource = get_active_event()
	if event_data == null:
		return ""
	var mult: float = maxf(1.0, float(event_data.modifier_mult))
	return "%s ×%.1f" % [
		modifier_label(str(event_data.modifier_type)),
		mult,
	]

func countdown_text() -> String:
	var event_data: Resource = get_active_event()
	if event_data == null:
		return "—"
	var remain: int = _Schedule.seconds_until_end(
		_current_unix(), str(event_data.end_date_jst)
	)
	return _Schedule.format_countdown(remain)

func schedule_text(event_data: Resource) -> String:
	if event_data == null:
		return ""
	return "%s 〜 %s（5:00 JST）" % [
		str(event_data.start_date_jst),
		str(event_data.end_date_jst),
	]

func set_debug_unix_for_tests(unix: int) -> void:
	_debug_unix_override = unix
	_cached_active_id = ""
	ensure_active()

func clear_debug_unix_for_tests() -> void:
	_debug_unix_override = -1
	_cached_active_id = ""
	ensure_active()

func _current_unix() -> int:
	if _debug_unix_override >= 0:
		return _debug_unix_override
	return int(Time.get_unix_time_from_system())

func _resolve_active_event() -> Resource:
	var now_unix: int = _current_unix()
	var best: Resource = null
	for event_id in _list_event_ids():
		var event_data: Resource = _load_event(event_id)
		if event_data == null:
			continue
		if not _Schedule.is_in_range(
			now_unix,
			str(event_data.start_date_jst),
			str(event_data.end_date_jst),
		):
			continue
		if best == null:
			best = event_data
			continue
		if _Schedule.jst_day_start_unix(str(event_data.start_date_jst)) > \
				_Schedule.jst_day_start_unix(str(best.start_date_jst)):
			best = event_data
	return best

func _list_event_ids() -> Array[String]:
	var out: Array[String] = []
	var dir: DirAccess = DirAccess.open(Constants.RESOURCE_EVENTS_PATH)
	if dir == null:
		return out
	dir.list_dir_begin()
	var name: String = dir.get_next()
	while not name.is_empty():
		if not name.begins_with(".") and name.ends_with(".tres"):
			out.append(name.get_basename())
		name = dir.get_next()
	dir.list_dir_end()
	out.sort()
	return out

func _load_event(event_id: String) -> Resource:
	if event_id.is_empty():
		return null
	var path: String = Constants.RESOURCE_EVENTS_PATH + event_id + ".tres"
	if not ResourceLoader.exists(path):
		return null
	return load(path)
