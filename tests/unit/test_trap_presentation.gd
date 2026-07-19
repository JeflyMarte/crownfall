extends GutTest
## P3-UX-TRAP-001 / P3-UX-TRAP-002 — 罠部屋演出パラメータ。

const _TrapPresentation = preload("res://scripts/dungeon/TrapPresentation.gd")


func test_trap_room_has_more_pulses_than_explore() -> void:
	assert_eq(_TrapPresentation.pulse_count(true, false), 3)
	assert_eq(_TrapPresentation.pulse_count(false, false), 2)


func test_fast_run_reduces_pulses() -> void:
	assert_eq(_TrapPresentation.pulse_count(true, true), 2)
	assert_eq(_TrapPresentation.pulse_count(false, true), 2)


func test_damage_scale_room_larger_than_explore() -> void:
	assert_gt(_TrapPresentation.damage_scale(true), _TrapPresentation.damage_scale(false))


func test_room_bg_paths_exist() -> void:
	assert_true(ResourceLoader.exists(_TrapPresentation.ROOM_BG_SETUP_PATH))
	assert_true(ResourceLoader.exists(_TrapPresentation.ROOM_BG_HIT_PATH))
	assert_true(ResourceLoader.exists(_TrapPresentation.ROOM_BG_AVOID_PATH))


func test_bg_path_for_phase() -> void:
	assert_eq(_TrapPresentation.bg_path_for_phase("setup"), _TrapPresentation.ROOM_BG_SETUP_PATH)
	assert_eq(_TrapPresentation.bg_path_for_phase("hit"), _TrapPresentation.ROOM_BG_HIT_PATH)
	assert_eq(_TrapPresentation.bg_path_for_phase("avoid"), _TrapPresentation.ROOM_BG_AVOID_PATH)


func test_trigger_chance_is_half() -> void:
	assert_almost_eq(_TrapPresentation.TRIGGER_CHANCE, 0.5, 0.001)


func test_is_triggered_is_deterministic_with_rng() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var first: bool = _TrapPresentation.is_triggered(rng)
	rng.seed = 12345
	assert_eq(first, _TrapPresentation.is_triggered(rng))


func test_pick_lines_use_rng() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var setup: String = _TrapPresentation.pick_setup_line(rng)
	var hit: String = _TrapPresentation.pick_hit_line(rng)
	var avoid: String = _TrapPresentation.pick_avoid_line(rng)
	assert_true(setup in _TrapPresentation.SETUP_LINES)
	assert_true(hit in _TrapPresentation.HIT_LINES)
	assert_true(avoid in _TrapPresentation.AVOID_LINES)


func test_format_hit_narrative() -> void:
	var text: String = _TrapPresentation.format_hit_narrative("棘が跳ねた！", "アリア", 12)
	assert_eq(text, "棘が跳ねた！\nアリア に 12 ダメージ！")


func test_format_aoe_hit_narrative() -> void:
	var text: String = _TrapPresentation.format_aoe_hit_narrative("通路が崩れた！", 4)
	assert_eq(text, "通路が崩れた！\nパーティ全体に罠ダメージ！（4人）")


func test_aoe_hit_lines_exist() -> void:
	assert_gt(_TrapPresentation.HIT_LINES_AOE.size(), 0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var line: String = _TrapPresentation.pick_hit_line_aoe(rng)
	assert_true(line in _TrapPresentation.HIT_LINES_AOE)
