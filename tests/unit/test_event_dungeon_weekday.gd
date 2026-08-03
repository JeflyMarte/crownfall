extends GutTest

## P3-DG-EVENT-WEEKDAY-001 — イベントDG曜日開放。

const _EventDungeonSchedule := preload("res://scripts/dungeon/EventDungeonSchedule.gd")


func before_each() -> void:
	_EventDungeonSchedule.clear_debug_weekday_override()
	_EventDungeonSchedule.clear_debug_unix_override()
	GameState.debug_full_unlock = false
	GameState.event_dungeon_attempts.clear()


func after_each() -> void:
	_EventDungeonSchedule.clear_debug_weekday_override()
	_EventDungeonSchedule.clear_debug_unix_override()
	GameState.debug_full_unlock = false
	GameState.event_dungeon_attempts.clear()


func test_primary_weekday_assignment() -> void:
	assert_eq(_EventDungeonSchedule.primary_weekday("cosmic_rift"), _EventDungeonSchedule.WEEKDAY_MON)
	assert_eq(_EventDungeonSchedule.primary_weekday("crown_rookery"), _EventDungeonSchedule.WEEKDAY_TUE)
	assert_eq(_EventDungeonSchedule.primary_weekday("golden_nest"), _EventDungeonSchedule.WEEKDAY_WED)
	assert_eq(_EventDungeonSchedule.primary_weekday("shadow_hunt"), _EventDungeonSchedule.WEEKDAY_THU)
	assert_eq(_EventDungeonSchedule.primary_weekday("rock_stampede"), _EventDungeonSchedule.WEEKDAY_FRI)


func test_weekday_opens_only_assigned() -> void:
	_EventDungeonSchedule.set_debug_weekday_override(_EventDungeonSchedule.WEEKDAY_WED)
	assert_false(_EventDungeonSchedule.is_open_today("cosmic_rift"))
	assert_true(_EventDungeonSchedule.is_open_today("golden_nest"))
	assert_false(GameState.can_attempt_event_dungeon("cosmic_rift"))
	assert_true(GameState.can_attempt_event_dungeon("golden_nest"))


func test_weekend_opens_all() -> void:
	for wd in [_EventDungeonSchedule.WEEKDAY_SAT, _EventDungeonSchedule.WEEKDAY_SUN]:
		_EventDungeonSchedule.set_debug_weekday_override(wd)
		for dungeon_id in _EventDungeonSchedule.PRIMARY_WEEKDAY.keys():
			assert_true(_EventDungeonSchedule.is_open_today(str(dungeon_id)), "weekend %d %s" % [wd, dungeon_id])
			assert_true(GameState.can_attempt_event_dungeon(str(dungeon_id)))


func test_open_hourly_ids_and_list_sort_key() -> void:
	_EventDungeonSchedule.set_debug_unix_override(_unix_jst(2026, 7, 26, 0, 30))
	var open_ids: Array[String] = _EventDungeonSchedule.open_hourly_event_ids()
	assert_true(open_ids.has(Constants.CHRONOS_MAUSOLEUM_DUNGEON_ID), str(open_ids))
	assert_false(open_ids.has(Constants.VALGARD_BOUNDARY_DUNGEON_ID), str(open_ids))
	var chronos_key: int = _EventDungeonSchedule.list_sort_key(Constants.CHRONOS_MAUSOLEUM_DUNGEON_ID, 7)
	var weekday_key: int = _EventDungeonSchedule.list_sort_key("golden_nest", 3)
	assert_lt(chronos_key, weekday_key)


func test_closed_weekday_is_not_open_now() -> void:
	_EventDungeonSchedule.set_debug_weekday_override(_EventDungeonSchedule.WEEKDAY_WED)
	_EventDungeonSchedule.set_debug_unix_override(_unix_jst(2026, 7, 22, 14, 0)) ## 水曜想定＋降臨外
	assert_true(_EventDungeonSchedule.is_open_now("golden_nest"))
	assert_false(_EventDungeonSchedule.is_open_now("cosmic_rift"))
	assert_false(_EventDungeonSchedule.is_open_now(Constants.CHRONOS_MAUSOLEUM_DUNGEON_ID))


func test_is_weekday_event_excludes_descent() -> void:
	## P3-BAL-WEEKDAY-EVENT-REWARD-001: 曜日5種のみ。降臨は対象外。
	for dungeon_id in _EventDungeonSchedule.PRIMARY_WEEKDAY.keys():
		assert_true(_EventDungeonSchedule.is_weekday_event(str(dungeon_id)), str(dungeon_id))
	assert_false(_EventDungeonSchedule.is_weekday_event(Constants.CHRONOS_MAUSOLEUM_DUNGEON_ID))
	assert_false(_EventDungeonSchedule.is_weekday_event(Constants.VALGARD_BOUNDARY_DUNGEON_ID))
	assert_false(_EventDungeonSchedule.is_weekday_event("mourngate"))
	assert_false(_EventDungeonSchedule.is_weekday_event(""))


func test_weekday_event_reward_mult_constant() -> void:
	assert_eq(BalanceConfig.WEEKDAY_EVENT_REWARD_MULT, 2.0)
	## 撃破最終値: base × weekday_mult（他倍率1.0時）
	var base_exp: int = 100
	var base_gold: int = 40
	var final_exp: int = int(base_exp * BalanceConfig.WEEKDAY_EVENT_REWARD_MULT)
	var final_gold: int = int(base_gold * BalanceConfig.WEEKDAY_EVENT_REWARD_MULT)
	assert_eq(final_exp, 200)
	assert_eq(final_gold, 80)


func _unix_jst(year: int, month: int, day: int, hour: int, minute: int) -> int:
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
