extends GutTest

## P3-EVT-HUB — 端末日付ベースの期間バフイベント（現在は EventSystem.PERIODIC_EVENTS_ENABLED=false でオミット）。

const EventScheduleHelperScript = preload("res://scripts/event/EventScheduleHelper.gd")

func after_each() -> void:
	EventSystem.clear_debug_unix_for_tests()

func test_schedule_helper_jst_range() -> void:
	var start_unix: int = EventScheduleHelperScript.jst_day_start_unix("2026-07-01")
	var inside: int = start_unix + 3600
	assert_true(EventScheduleHelperScript.is_in_range(inside, "2026-07-01", "2026-07-08"))
	assert_false(EventScheduleHelperScript.is_in_range(inside, "2026-07-08", "2026-07-15"))

func test_periodic_events_disabled_even_in_schedule() -> void:
	EventSystem.set_debug_unix_for_tests(1783076400)
	assert_false(EventSystem.is_event_running())
	assert_null(EventSystem.get_active_event())
	assert_eq(EventSystem.get_modifier_mult(EventSystem.MOD_EXP), 1.0)
	assert_eq(EventSystem.get_modifier_mult(EventSystem.MOD_GOLD), 1.0)
	assert_eq(EventSystem.get_modifier_mult(EventSystem.MOD_WEAPON_DROP), 1.0)
