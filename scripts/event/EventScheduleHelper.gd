class_name EventScheduleHelper
extends RefCounted

## 期間イベントの JST 日付境界（DailyMissionSystem と同じ 5:00）。

const JST_OFFSET_SEC: int = 9 * 3600
const DAY_START_HOUR_JST: int = 5

static func jst_day_start_unix(date_str: String) -> int:
	if date_str.is_empty():
		return 0
	var parts: PackedStringArray = date_str.split("-")
	if parts.size() != 3:
		return 0
	return int(
		Time.get_unix_time_from_datetime_dict({
			"year": int(parts[0]),
			"month": int(parts[1]),
			"day": int(parts[2]),
			"hour": DAY_START_HOUR_JST,
			"minute": 0,
			"second": 0,
		})
	) - JST_OFFSET_SEC

static func is_in_range(now_unix: int, start_date_jst: String, end_date_jst: String) -> bool:
	var start_unix: int = jst_day_start_unix(start_date_jst)
	var end_unix: int = jst_day_start_unix(end_date_jst)
	if start_unix <= 0 or end_unix <= 0:
		return false
	if end_unix <= start_unix:
		return false
	return now_unix >= start_unix and now_unix < end_unix

static func seconds_until_end(now_unix: int, end_date_jst: String) -> int:
	var end_unix: int = jst_day_start_unix(end_date_jst)
	if end_unix <= 0:
		return 0
	return maxi(0, end_unix - now_unix)

static func format_countdown(seconds: int) -> String:
	const SECONDS_PER_DAY: int = 86400
	var days: int = seconds / SECONDS_PER_DAY
	var hours: int = (seconds % SECONDS_PER_DAY) / 3600
	if days > 0:
		return "残り %d日 %d時間" % [days, hours]
	return "残り %d:%02d" % [hours, (seconds % 3600) / 60]
