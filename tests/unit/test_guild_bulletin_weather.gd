extends GutTest


func test_weather_effect_bullets_match_combat_math() -> void:
	var rain: PackedStringArray = CombatWeather.effect_bullet_lines(CombatWeather.RAIN)
	assert_gte(rain.size(), 2)
	assert_true("雷" in "\n".join(rain))
	assert_true("炎" in "\n".join(rain))
	assert_eq(CombatWeather.element_multiplier(CombatWeather.RAIN, "thunder"), 1.15)
	assert_eq(CombatWeather.element_multiplier(CombatWeather.RAIN, "fire"), 0.90)

	var night: PackedStringArray = CombatWeather.effect_bullet_lines(CombatWeather.NIGHT)
	assert_true("闇" in "\n".join(night))
	assert_true("聖" in "\n".join(night))

	var fog: PackedStringArray = CombatWeather.effect_bullet_lines(CombatWeather.FOG)
	assert_true("0.95" in "\n".join(fog))
	assert_eq(CombatWeather.outgoing_multiplier(CombatWeather.FOG), 0.95)
	assert_eq(CombatWeather.incoming_multiplier(CombatWeather.FOG), 0.95)


func test_field_event_effect_summary_includes_combat() -> void:
	var summary: String = CombatWeather.field_event_effect_summary(CombatWeather.RAIN)
	assert_true(summary.begins_with("・"))
	assert_true("固定" in summary)
	assert_true("雷" in summary)


func test_bulletin_reference_lists_all_weathers() -> void:
	var text: String = CombatWeather.bulletin_reference_text()
	for term: String in ["晴れ", "雨", "夜", "霧", "天候の効果"]:
		assert_true(term in text, term)


func test_weather_slot_event_gets_combat_effect_summary() -> void:
	var _WeekRotation = preload("res://scripts/event/EventWeekRotation.gd")
	var _Schedule = preload("res://scripts/event/EventScheduleHelper.gd")
	var fog_slot: int = -1
	for slot: int in range(0, 4000):
		var idx: int = _WeekRotation.definition_index_for_slot(slot)
		if str(_WeekRotation.SLOT_DEFINITIONS[idx].get("id", "")) == "weather_fog":
			fog_slot = slot
			break
	assert_gte(fog_slot, 0)
	var unix: int = (
		_Schedule.jst_day_start_unix(_WeekRotation.ANCHOR_DATE_JST)
		+ fog_slot * _WeekRotation.SLOT_SECONDS
		+ 30
	)
	EventSystem.set_debug_unix_for_tests(unix)
	var event: Resource = EventSystem.get_active_event()
	assert_not_null(event)
	assert_eq(str(event.modifier_type), "weather")
	assert_true("0.95" in str(event.effect_summary), str(event.effect_summary))
	EventSystem.clear_debug_unix_for_tests()
