extends GutTest

## P3-DG-CHRONOS-DESCENT-001 — 時王の霊廟（時間帯イベント）

const _Sched := preload("res://scripts/dungeon/EventDungeonSchedule.gd")
const DID := "chronos_mausoleum"


func before_each() -> void:
	_Sched.clear_debug_weekday_override()
	_Sched.clear_debug_unix_override()


func after_each() -> void:
	_Sched.clear_debug_weekday_override()
	_Sched.clear_debug_unix_override()


func test_tres_shape() -> void:
	var data: Resource = DataRegistry.get_dungeon_data(DID)
	assert_not_null(data, "chronos_mausoleum.tres")
	assert_eq(str(data.id), DID)
	assert_eq(str(data.route_type), "event")
	assert_eq(str(data.boss_id), "chronos_wave")
	assert_eq(str(data.display_name), "時環の共鳴龍　降臨")
	assert_eq(int(data.daily_attempt_limit), 0)
	assert_true(bool(data.disable_wandering))
	assert_eq(str(data.unlock_after_dungeon_id), "")
	var moth_n: int = 0
	for raw in data.enemy_pool:
		if str(raw) == "clock_moth":
			moth_n += 1
	assert_gte(moth_n, 2, "クロックモス多め")


func test_unlocked_from_start() -> void:
	GameState.dungeon_progress = {}
	assert_true(GameState.is_dungeon_unlocked(DID), "進行解放なし")


func test_hourly_windows_jst() -> void:
	## JST 0:30 → UTC 前日 15:30
	_Sched.set_debug_unix_override(_unix_for_jst(2026, 7, 26, 0, 30))
	assert_true(_Sched.is_open_now(DID), "0時台は開放")
	_Sched.set_debug_unix_override(_unix_for_jst(2026, 7, 26, 1, 0))
	assert_false(_Sched.is_open_now(DID), "1時は閉鎖")
	_Sched.set_debug_unix_override(_unix_for_jst(2026, 7, 26, 3, 0))
	assert_true(_Sched.is_open_now(DID), "3時台は開放")
	_Sched.set_debug_unix_override(_unix_for_jst(2026, 7, 26, 5, 0))
	assert_false(_Sched.is_open_now(DID), "5時は閉鎖")
	_Sched.set_debug_unix_override(_unix_for_jst(2026, 7, 26, 9, 59))
	assert_true(_Sched.is_open_now(DID), "9時台は開放")
	_Sched.set_debug_unix_override(_unix_for_jst(2026, 7, 26, 10, 0))
	assert_false(_Sched.is_open_now(DID), "10時は閉鎖")


func test_can_attempt_follows_window() -> void:
	_Sched.set_debug_unix_override(_unix_for_jst(2026, 7, 26, 6, 15))
	assert_true(GameState.can_attempt_event_dungeon(DID))
	_Sched.set_debug_unix_override(_unix_for_jst(2026, 7, 26, 2, 0))
	assert_false(GameState.can_attempt_event_dungeon(DID))


func test_next_open_label() -> void:
	_Sched.set_debug_unix_override(_unix_for_jst(2026, 7, 26, 2, 0))
	assert_eq(_Sched.next_open_label(DID), "次の出現 3:00")
	_Sched.set_debug_unix_override(_unix_for_jst(2026, 7, 26, 0, 10))
	assert_eq(_Sched.next_open_label(DID), "")
	_Sched.set_debug_unix_override(_unix_for_jst(2026, 7, 26, 11, 0))
	assert_eq(_Sched.next_open_label(DID), "次の出現 0:00")


func test_debug_always_open() -> void:
	_Sched.set_debug_weekday_override(-2)
	_Sched.set_debug_unix_override(_unix_for_jst(2026, 7, 26, 14, 0))
	assert_true(_Sched.is_open_now(DID))


func _unix_for_jst(year: int, month: int, day: int, hour: int, minute: int) -> int:
	## datetime_dict はローカル扱いではなく「その壁時計を UTC として解釈」するので、
	## JST 壁時計 → UTC unix は -9h。
	var as_utc_like: int = int(
		Time.get_unix_time_from_datetime_dict({
			"year": year,
			"month": month,
			"day": day,
			"hour": hour,
			"minute": minute,
			"second": 0,
		})
	)
	return as_utc_like - (9 * 3600)
