extends GutTest
## P3-EVT-HUB / P3-EVT-WEEK-002 — 野外の変化スケジュール。

const EventScheduleHelperScript = preload("res://scripts/event/EventScheduleHelper.gd")

func after_each() -> void:
	EventSystem.clear_debug_unix_for_tests()

func test_schedule_helper_jst_range() -> void:
	var start_unix: int = EventScheduleHelperScript.jst_day_start_unix("2026-07-01")
	var inside: int = start_unix + 3600
	assert_true(EventScheduleHelperScript.is_in_range(inside, "2026-07-01", "2026-07-08"))
	assert_false(EventScheduleHelperScript.is_in_range(inside, "2026-07-08", "2026-07-15"))

func test_elite_material_amount_mult() -> void:
	var elite_week_unix: int = (
		EventScheduleHelperScript.jst_day_start_unix("2026-07-01")
		+ 5 * 7 * 86400
		+ 3600
	)
	EventSystem.set_debug_unix_for_tests(elite_week_unix)
	assert_eq(str(EventSystem.get_active_event().modifier_type), EventSystem.MOD_ELITE_MATERIAL)
	assert_eq(EventSystem.get_elite_material_amount(1), 2)
