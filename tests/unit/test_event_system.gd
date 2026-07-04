extends GutTest

## P3-EVT-HUB — 端末日付ベースの期間バフイベント。

const EventScheduleHelperScript = preload("res://scripts/event/EventScheduleHelper.gd")

func after_each() -> void:
	EventSystem.clear_debug_unix_for_tests()

func test_schedule_helper_jst_range() -> void:
	var start_unix: int = EventScheduleHelperScript.jst_day_start_unix("2026-07-01")
	var inside: int = start_unix + 3600
	assert_true(EventScheduleHelperScript.is_in_range(inside, "2026-07-01", "2026-07-08"))
	assert_false(EventScheduleHelperScript.is_in_range(inside, "2026-07-08", "2026-07-15"))

func test_exp_event_active_on_july_3() -> void:
	# 2026-07-03 12:00 JST ≈ 2026-07-03 03:00 UTC
	EventSystem.set_debug_unix_for_tests(1783076400)
	assert_true(EventSystem.is_event_running())
	var event_data: Resource = EventSystem.get_active_event()
	assert_not_null(event_data)
	assert_eq(str(event_data.id), "evt_week_exp")
	assert_eq(EventSystem.get_modifier_mult(EventSystem.MOD_EXP), 1.5)
	assert_eq(EventSystem.get_modifier_mult(EventSystem.MOD_GOLD), 1.0)

func test_gold_event_active_on_july_10() -> void:
	# 2026-07-10 12:00 JST
	EventSystem.set_debug_unix_for_tests(1783681200)
	var event_data: Resource = EventSystem.get_active_event()
	assert_eq(str(event_data.id), "evt_week_gold")
	assert_eq(EventSystem.get_modifier_mult(EventSystem.MOD_GOLD), 1.5)

func test_weapon_drop_event_active_on_july_17() -> void:
	# 2026-07-17 12:00 JST
	EventSystem.set_debug_unix_for_tests(1784286000)
	var event_data: Resource = EventSystem.get_active_event()
	assert_eq(str(event_data.id), "evt_week_weapon")
	assert_eq(EventSystem.get_modifier_mult(EventSystem.MOD_WEAPON_DROP), 1.5)

func test_no_event_outside_schedule() -> void:
	EventSystem.set_debug_unix_for_tests(1784890800) # 2026-07-24 12:00 JST
	assert_false(EventSystem.is_event_running())
	assert_eq(EventSystem.get_modifier_mult(EventSystem.MOD_EXP), 1.0)
