extends GutTest


func test_weather_effect_bullets_match_combat_math() -> void:
	var rain: PackedStringArray = CombatWeather.effect_bullet_lines(CombatWeather.RAIN)
	assert_gte(rain.size(), 2)
	assert_true("雷" in "\n".join(rain))
	assert_true("炎" in "\n".join(rain))
	assert_eq(CombatWeather.element_multiplier(CombatWeather.RAIN, "thunder"), 1.10)
	assert_eq(CombatWeather.element_multiplier(CombatWeather.RAIN, "fire"), 0.95)

	var night: PackedStringArray = CombatWeather.effect_bullet_lines(CombatWeather.NIGHT)
	assert_true("闇" in "\n".join(night))
	assert_true("聖" in "\n".join(night))
	assert_eq(CombatWeather.element_multiplier(CombatWeather.NIGHT, "dark"), 1.10)
	assert_eq(CombatWeather.element_multiplier(CombatWeather.NIGHT, "holy"), 0.95)

	var fog: PackedStringArray = CombatWeather.effect_bullet_lines(CombatWeather.FOG)
	assert_true("0.97" in "\n".join(fog))
	assert_eq(CombatWeather.outgoing_multiplier(CombatWeather.FOG), 0.97)
	assert_eq(CombatWeather.incoming_multiplier(CombatWeather.FOG), 0.97)

	var heat: PackedStringArray = CombatWeather.effect_bullet_lines(CombatWeather.HEAT)
	assert_true("炎" in "\n".join(heat))
	assert_true("氷" in "\n".join(heat))
	assert_eq(CombatWeather.element_multiplier(CombatWeather.HEAT, "fire"), 1.10)
	assert_eq(CombatWeather.element_multiplier(CombatWeather.HEAT, "ice"), 0.95)

	var snow: PackedStringArray = CombatWeather.effect_bullet_lines(CombatWeather.SNOW)
	assert_true("氷" in "\n".join(snow))
	assert_true("炎" in "\n".join(snow))
	assert_eq(CombatWeather.element_multiplier(CombatWeather.SNOW, "ice"), 1.10)
	assert_eq(CombatWeather.element_multiplier(CombatWeather.SNOW, "fire"), 0.95)


func test_bulletin_active_weather_only() -> void:
	var rain: String = CombatWeather.bulletin_active_weather_text(CombatWeather.RAIN)
	assert_true(rain.begins_with("【天候の効果】"))
	assert_true("雨" in rain)
	assert_true("雷" in rain)
	assert_true("炎" in rain)
	assert_false("吹雪" in rain)
	assert_false("晴れ" in rain)
	assert_eq(CombatWeather.bulletin_active_weather_text(""), "")
	assert_eq(CombatWeather.bulletin_active_weather_text("clear"), "")


func test_weather_effect_one_line_for_legend() -> void:
	assert_eq(CombatWeather.effect_one_line(CombatWeather.CLEAR), "")
	assert_eq(CombatWeather.effect_one_line(""), "")
	assert_eq(CombatWeather.effect_one_line(CombatWeather.RAIN), "雨:雷与ダメ+10%／炎与ダメ−5%")
	assert_eq(CombatWeather.effect_one_line(CombatWeather.FOG), "霧:与ダメ・被ダメとも×0.97")
	assert_eq(CombatWeather.effect_one_line(CombatWeather.SNOW), "吹雪:氷与ダメ+10%／炎与ダメ−5%")
	var rain_def: Dictionary = CombatWeather.legend_icon_def(CombatWeather.RAIN)
	assert_eq(str(rain_def.get("abbrev", "")), "雨")


func test_weather_legend_icons_exist() -> void:
	for wid in [
		CombatWeather.RAIN,
		CombatWeather.NIGHT,
		CombatWeather.FOG,
		CombatWeather.HEAT,
		CombatWeather.SNOW,
		"clear",
	]:
		var tex: Texture2D = IconPaths.get_icon_texture(str(wid), "weather")
		assert_not_null(tex, wid)


func test_field_event_effect_summary_includes_combat() -> void:
	var summary: String = CombatWeather.field_event_effect_summary(CombatWeather.RAIN)
	assert_true(summary.begins_with("・"))
	assert_true("固定" in summary)
	assert_true("雷" in summary)


func test_biome_weather_bias_keys() -> void:
	assert_eq(CombatWeather.weather_biome_key("frostridge"), "frostridge")
	assert_eq(CombatWeather.weather_biome_key("abyss_frostridge"), "frostridge")
	assert_eq(CombatWeather.weather_biome_key("mistfen_depths"), "mistfen")
	assert_eq(CombatWeather.weather_biome_key("cosmic_rift"), "")
	var frost: Dictionary = CombatWeather.weights_for_dungeon("frostridge")
	var base: Dictionary = CombatWeather.weights_for_dungeon("")
	assert_gt(int(frost.get(CombatWeather.SNOW, 0)), int(base.get(CombatWeather.SNOW, 0)))
	var mist: Dictionary = CombatWeather.weights_for_dungeon("mistfen")
	assert_gt(int(mist.get(CombatWeather.FOG, 0)), int(base.get(CombatWeather.FOG, 0)))
	## 全天候が正の重み（案A＝禁止なし）。
	for w: String in [CombatWeather.CLEAR, CombatWeather.RAIN, CombatWeather.NIGHT, CombatWeather.FOG, CombatWeather.HEAT, CombatWeather.SNOW]:
		assert_gt(int(frost.get(w, 0)), 0, w)


func test_weather_slot_shows_active_weather_combat() -> void:
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
	assert_eq(EventSystem.forced_weather_id(), CombatWeather.FOG)
	assert_true("固定" in str(event.effect_summary), str(event.effect_summary))
	assert_false("0.97" in str(event.effect_summary), str(event.effect_summary))
	var guide: String = CombatWeather.bulletin_active_weather_text(EventSystem.forced_weather_id())
	assert_true("0.97" in guide, guide)
	assert_true("霧" in guide)
	assert_false("炎天" in guide)
	EventSystem.clear_debug_unix_for_tests()
