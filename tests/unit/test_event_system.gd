extends GutTest
## P3-EVT-HUB / P3-EVT-FIELD-001 — 野外速報スケジュール。

const EventScheduleHelperScript = preload("res://scripts/event/EventScheduleHelper.gd")
const _WeekRotation = preload("res://scripts/event/EventWeekRotation.gd")

func after_each() -> void:
	EventSystem.clear_debug_unix_for_tests()

func test_schedule_helper_jst_range() -> void:
	var start_unix: int = EventScheduleHelperScript.jst_day_start_unix("2026-07-01")
	var inside: int = start_unix + 3600
	assert_true(EventScheduleHelperScript.is_in_range(inside, "2026-07-01", "2026-07-08"))
	assert_false(EventScheduleHelperScript.is_in_range(inside, "2026-07-08", "2026-07-15"))

func test_elite_material_amount_mult() -> void:
	var elite_slot: int = -1
	for slot: int in range(0, 800):
		var idx: int = _WeekRotation.definition_index_for_slot(slot)
		if str(_WeekRotation.SLOT_DEFINITIONS[idx].get("modifier_type", "")) == "elite_material":
			elite_slot = slot
			break
	assert_gte(elite_slot, 0)
	var anchor: int = EventScheduleHelperScript.jst_day_start_unix("2026-07-01")
	EventSystem.set_debug_unix_for_tests(anchor + elite_slot * _WeekRotation.SLOT_SECONDS + 30)
	assert_eq(str(EventSystem.get_active_event().modifier_type), EventSystem.MOD_ELITE_MATERIAL)
	assert_eq(EventSystem.get_elite_material_amount(1), 1)  # ×1.2 → round 1
	assert_eq(EventSystem.get_elite_material_amount(5), 6)  # 5*1.2=6
