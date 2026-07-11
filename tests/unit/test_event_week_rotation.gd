extends GutTest
## P3-EVT-WEEK-002 — 6 週ローテ「野外の変化」。

const _WeekRotation = preload("res://scripts/event/EventWeekRotation.gd")
const _Schedule = preload("res://scripts/event/EventScheduleHelper.gd")

const ANCHOR_UNIX: int = 1783076400  # 2026-07-01 05:00 JST


func after_each() -> void:
	EventSystem.clear_debug_unix_for_tests()


func test_week_rotation_exp_week() -> void:
	EventSystem.set_debug_unix_for_tests(ANCHOR_UNIX + 3600)
	assert_eq(_WeekRotation.week_in_cycle(ANCHOR_UNIX), 0)
	var event: Resource = EventSystem.get_active_event()
	assert_not_null(event)
	assert_eq(str(event.modifier_type), EventSystem.MOD_EXP)
	assert_eq(EventSystem.get_modifier_mult(EventSystem.MOD_EXP), 1.5)


func test_codex_week_grants_extra_kill() -> void:
	var codex_week_unix: int = ANCHOR_UNIX + _WeekRotation.WEEK_SECONDS * 3 + 3600
	EventSystem.set_debug_unix_for_tests(codex_week_unix)
	assert_eq(str(EventSystem.get_active_event().modifier_type), EventSystem.MOD_CODEX)
	assert_eq(EventSystem.get_codex_kill_extra_count(), 1)


func test_featured_biome_week_scoped_to_biome() -> void:
	var featured_unix: int = ANCHOR_UNIX + _WeekRotation.WEEK_SECONDS * 4 + 3600
	EventSystem.set_debug_unix_for_tests(featured_unix)
	GameState.current_dungeon_id = Constants.MOURNGATE_DUNGEON_ID
	assert_eq(EventSystem.get_featured_biome_id(), Constants.MOURNGATE_DUNGEON_ID)
	assert_eq(EventSystem.get_modifier_mult(EventSystem.MOD_EXP), 1.5)
	GameState.current_dungeon_id = "whisperwood"
	assert_eq(EventSystem.get_modifier_mult(EventSystem.MOD_EXP), 1.0)


func test_featured_biome_rotates_each_cycle() -> void:
	var week4_cycle0: int = ANCHOR_UNIX + _WeekRotation.WEEK_SECONDS * 4
	var week4_cycle1: int = ANCHOR_UNIX + _WeekRotation.WEEK_SECONDS * (4 + 6)
	assert_eq(_WeekRotation.featured_biome_id(week4_cycle0), Constants.MOURNGATE_DUNGEON_ID)
	assert_eq(_WeekRotation.featured_biome_id(week4_cycle1), "whisperwood")


func test_periodic_events_disabled() -> void:
	var enabled: bool = EventSystem.PERIODIC_EVENTS_ENABLED
	if not enabled:
		pass_test("flag off in build")
		return
	EventSystem.set_debug_unix_for_tests(ANCHOR_UNIX)
	assert_true(EventSystem.is_event_running())
