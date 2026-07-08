extends GutTest
## P3-UX-EVENT-001 — イベント部屋テロップ演出パラメータ。

const _EventPresentation = preload("res://scripts/dungeon/EventPresentation.gd")


func test_heal_and_damage_colors_are_green_and_red() -> void:
	assert_eq(_EventPresentation.outcome_color("heal"), _EventPresentation.COLOR_HEAL)
	assert_eq(_EventPresentation.outcome_color("damage"), _EventPresentation.COLOR_DAMAGE)


func test_format_result_line_for_core_outcomes() -> void:
	assert_eq(
		_EventPresentation.format_result_line({"type": "heal", "amount": 10}),
		"HP +10"
	)
	assert_eq(
		_EventPresentation.format_result_line({"type": "damage", "amount": 7}),
		"HP -7"
	)
	assert_eq(
		_EventPresentation.format_result_line({"type": "gold", "amount": 24}),
		"Gold +24"
	)
	assert_eq(
		_EventPresentation.format_result_line({"type": "lore", "label": "ルーンの甲殻"}),
		"【碑文】ルーンの甲殻"
	)


func test_fast_run_shortens_timings() -> void:
	var normal: Dictionary = _EventPresentation.timings(false)
	var fast: Dictionary = _EventPresentation.timings(true)
	assert_lt(float(fast["scene_hold"]), float(normal["scene_hold"]))
	assert_lt(float(fast["shake"]), float(normal["shake"]))


func test_scene_line_truncates_long_text() -> void:
	var long_text: String = "あ".repeat(60)
	var formatted: String = _EventPresentation.format_scene_line(long_text)
	assert_eq(formatted.length(), _EventPresentation.SCENE_MAX_CHARS)


func test_background_path_maps_outcome_types() -> void:
	assert_string_contains(
		_EventPresentation.background_path("heal"),
		"BG_Event_Heal.png"
	)
	assert_string_contains(
		_EventPresentation.background_path("damage"),
		"BG_Event_Damage.png"
	)
	assert_string_contains(
		_EventPresentation.background_path("unknown"),
		"BG_Event_Lore.png"
	)
