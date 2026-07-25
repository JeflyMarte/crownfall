class_name EventDungeonSchedule
extends RefCounted

## イベントDGの曜日開放（P3-DG-EVENT-WEEKDAY-001）。
## JST 5:00 境界の「今日」の曜日で判定。土日は全開放。

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


static func set_debug_weekday_override(weekday: int) -> void:
	debug_weekday_override = weekday


static func clear_debug_weekday_override() -> void:
	debug_weekday_override = -1


static func is_weekend(weekday: int) -> bool:
	return weekday == WEEKDAY_SAT or weekday == WEEKDAY_SUN


static func primary_weekday(dungeon_id: String) -> int:
	return int(PRIMARY_WEEKDAY.get(dungeon_id, -1))


static func weekday_label(weekday: int) -> String:
	return str(WEEKDAY_LABEL_JA.get(weekday, "?"))


static func open_schedule_label(dungeon_id: String) -> String:
	var primary: int = primary_weekday(dungeon_id)
	if primary < 0:
		return "毎日"
	return "%s曜・土日" % weekday_label(primary)


static func current_jst_weekday() -> int:
	if debug_weekday_override == -2:
		return WEEKDAY_MON
	if debug_weekday_override >= WEEKDAY_SUN and debug_weekday_override <= WEEKDAY_SAT:
		return debug_weekday_override
	var jst_now: int = int(Time.get_unix_time_from_system()) + _Schedule.JST_OFFSET_SEC
	var dt: Dictionary = Time.get_datetime_dict_from_unix_time(jst_now)
	if int(dt.hour) < _Schedule.DAY_START_HOUR_JST:
		jst_now -= 86400
		dt = Time.get_datetime_dict_from_unix_time(jst_now)
	return int(dt.weekday)


static func is_open_today(dungeon_id: String) -> bool:
	if dungeon_id.is_empty():
		return false
	if debug_weekday_override == -2:
		return true
	if not PRIMARY_WEEKDAY.has(dungeon_id):
		## 未登録イベントは従来どおり毎日。
		return true
	var today: int = current_jst_weekday()
	if is_weekend(today):
		return true
	return today == primary_weekday(dungeon_id)
