class_name EventDungeonSchedule
extends RefCounted

## イベントDGの曜日開放（P3-DG-EVENT-WEEKDAY-001）＋時間帯開放（P3-DG-CHRONOS-DESCENT-001）。
## 曜日: JST 5:00 境界の「今日」。土日は曜日枠を全開放。
## 時間帯: 暦 JST の時（0–23）。5:00 日境界は使わない。

const _Schedule := preload("res://scripts/event/EventScheduleHelper.gd")

## Godot `weekday`: 0=日 … 6=土
const WEEKDAY_SUN: int = 0
const WEEKDAY_MON: int = 1
const WEEKDAY_TUE: int = 2
const WEEKDAY_WED: int = 3
const WEEKDAY_THU: int = 4
const WEEKDAY_FRI: int = 5
const WEEKDAY_SAT: int = 6

## 平日の主担当（土日は全IDが開放）。
const PRIMARY_WEEKDAY: Dictionary = {
	"cosmic_rift": WEEKDAY_MON,
	"crown_rookery": WEEKDAY_TUE,
	"golden_nest": WEEKDAY_WED,
	"shadow_hunt": WEEKDAY_THU,
	"rock_stampede": WEEKDAY_FRI,
}

## 時間帯イベント（開始時 JST → 継続時間時間）。例: 0/3/6/9 時から各1時間。
const HOURLY_OPEN_START_HOURS: Dictionary = {
	"chronos_mausoleum": [0, 3, 6, 9],
}
const HOURLY_WINDOW_HOURS: int = 1

const WEEKDAY_LABEL_JA: Dictionary = {
	WEEKDAY_SUN: "日",
	WEEKDAY_MON: "月",
	WEEKDAY_TUE: "火",
	WEEKDAY_WED: "水",
	WEEKDAY_THU: "木",
	WEEKDAY_FRI: "金",
	WEEKDAY_SAT: "土",
}

## -1=実時刻 / 0〜6=その曜日に固定 / -2=テスト用に常時開放
static var debug_weekday_override: int = -1
## -1=実時刻 / >=0=その unix（UTC）を「いま」として使う
static var debug_unix_override: int = -1


static func set_debug_weekday_override(weekday: int) -> void:
	debug_weekday_override = weekday


static func clear_debug_weekday_override() -> void:
	debug_weekday_override = -1


static func set_debug_unix_override(unix_utc: int) -> void:
	debug_unix_override = unix_utc


static func clear_debug_unix_override() -> void:
	debug_unix_override = -1


static func is_weekend(weekday: int) -> bool:
	return weekday == WEEKDAY_SAT or weekday == WEEKDAY_SUN


static func primary_weekday(dungeon_id: String) -> int:
	return int(PRIMARY_WEEKDAY.get(dungeon_id, -1))


static func uses_hourly_windows(dungeon_id: String) -> bool:
	return HOURLY_OPEN_START_HOURS.has(dungeon_id)


static func weekday_label(weekday: int) -> String:
	return str(WEEKDAY_LABEL_JA.get(weekday, "?"))


static func _now_unix_utc() -> int:
	if debug_unix_override >= 0:
		return debug_unix_override
	return int(Time.get_unix_time_from_system())


static func current_jst_datetime() -> Dictionary:
	var jst_now: int = _now_unix_utc() + _Schedule.JST_OFFSET_SEC
	return Time.get_datetime_dict_from_unix_time(jst_now)


static func current_jst_weekday() -> int:
	if debug_weekday_override == -2:
		return WEEKDAY_MON
	if debug_weekday_override >= WEEKDAY_SUN and debug_weekday_override <= WEEKDAY_SAT:
		return debug_weekday_override
	var jst_now: int = _now_unix_utc() + _Schedule.JST_OFFSET_SEC
	var dt: Dictionary = Time.get_datetime_dict_from_unix_time(jst_now)
	if int(dt.hour) < _Schedule.DAY_START_HOUR_JST:
		jst_now -= 86400
		dt = Time.get_datetime_dict_from_unix_time(jst_now)
	return int(dt.weekday)


static func is_open_today(dungeon_id: String) -> bool:
	if dungeon_id.is_empty():
		return false
	if _force_open_for_debug():
		return true
	if uses_hourly_windows(dungeon_id):
		## 時間帯イベントは「今日ある」ではなく is_open_now で判定。
		return is_open_now(dungeon_id)
	if not PRIMARY_WEEKDAY.has(dungeon_id):
		## 未登録イベントは従来どおり毎日。
		return true
	var today: int = current_jst_weekday()
	if is_weekend(today):
		return true
	return today == primary_weekday(dungeon_id)


## 挑戦可否の正（曜日枠／時間帯枠の統合入口）。
static func is_open_now(dungeon_id: String) -> bool:
	if dungeon_id.is_empty():
		return false
	if _force_open_for_debug():
		return true
	if uses_hourly_windows(dungeon_id):
		return _is_in_hourly_window(dungeon_id)
	return is_open_today(dungeon_id)


## タイトル「デバッグ」フル所持、またはテスト用 override=-2。
static func _force_open_for_debug() -> bool:
	if debug_weekday_override == -2:
		return true
	## Autoload。debug_full_unlock 中は曜日／時間帯を無視して常時開放。
	return GameState != null and GameState.debug_full_unlock


static func open_schedule_label(dungeon_id: String) -> String:
	if _force_open_for_debug():
		return "デバッグ常時開放"
	if uses_hourly_windows(dungeon_id):
		return "毎日 0/3/6/9時〜各1時間"
	var primary: int = primary_weekday(dungeon_id)
	if primary < 0:
		return "毎日"
	return "%s曜・土日" % weekday_label(primary)


static func _is_in_hourly_window(dungeon_id: String) -> bool:
	var starts: Variant = HOURLY_OPEN_START_HOURS.get(dungeon_id, [])
	if not starts is Array or (starts as Array).is_empty():
		return false
	var hour: int = int(current_jst_datetime().get("hour", -1))
	if hour < 0:
		return false
	for start_v in starts as Array:
		var start_h: int = int(start_v)
		if hour >= start_h and hour < start_h + HOURLY_WINDOW_HOURS:
			return true
	return false


## 「次の出現 HH:00」（出現中は空文字）。
static func next_open_label(dungeon_id: String) -> String:
	if not uses_hourly_windows(dungeon_id):
		return ""
	if is_open_now(dungeon_id):
		return ""
	var starts: Array = HOURLY_OPEN_START_HOURS.get(dungeon_id, []) as Array
	if starts.is_empty():
		return ""
	var hour: int = int(current_jst_datetime().get("hour", 0))
	var sorted_starts: Array = starts.duplicate()
	sorted_starts.sort()
	for start_v in sorted_starts:
		var start_h: int = int(start_v)
		if hour < start_h:
			return "次の出現 %d:00" % start_h
	## 本日の枠は終了 → 翌日最初
	return "次の出現 %d:00" % int(sorted_starts[0])
