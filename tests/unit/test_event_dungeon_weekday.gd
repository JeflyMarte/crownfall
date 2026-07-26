extends GutTest

## P3-DG-EVENT-WEEKDAY-001 — イベントDG曜日開放。

const _EventDungeonSchedule := preload("res://scripts/dungeon/EventDungeonSchedule.gd")


func before_each() -> void:
	_EventDungeonSchedule.clear_debug_weekday_override()
	GameState.debug_full_unlock = false
	GameState.event_dungeon_attempts.clear()


func after_each() -> void:
	_EventDungeonSchedule.clear_debug_weekday_override()
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
