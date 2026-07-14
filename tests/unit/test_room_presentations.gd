extends GutTest
## P3-UX-HEAL/TREASURE/LORE-001 — 非戦闘3段階演出パラメータ。

const _HealRoomPresentation = preload("res://scripts/dungeon/HealRoomPresentation.gd")
const _TreasureRoomPresentation = preload("res://scripts/dungeon/TreasureRoomPresentation.gd")
const _LoreRoomPresentation = preload("res://scripts/dungeon/LoreRoomPresentation.gd")


func test_all_rooms_use_half_success_chance() -> void:
	assert_almost_eq(_HealRoomPresentation.SUCCESS_CHANCE, 0.5, 0.001)
	assert_almost_eq(_TreasureRoomPresentation.SUCCESS_CHANCE, 0.5, 0.001)
	assert_almost_eq(_LoreRoomPresentation.SUCCESS_CHANCE, 0.5, 0.001)


func test_timings_match_trap_pattern() -> void:
	assert_eq(_HealRoomPresentation.timings(false)["setup_hold"], 2.0)
	assert_eq(_HealRoomPresentation.timings(true)["setup_hold"], 1.15)
	assert_eq(_TreasureRoomPresentation.timings(false)["setup_hold"], 2.0)
	assert_eq(_TreasureRoomPresentation.timings(true)["setup_hold"], 1.15)
	assert_eq(_LoreRoomPresentation.timings(false)["setup_hold"], 2.0)
	assert_eq(_LoreRoomPresentation.timings(true)["setup_hold"], 1.15)


func test_pick_lines_use_rng() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	assert_true(_HealRoomPresentation.pick_setup_line(rng) in _HealRoomPresentation.SETUP_LINES)
	rng.seed = 11
	assert_true(_TreasureRoomPresentation.pick_fail_line(rng) in _TreasureRoomPresentation.FAIL_LINES)
	rng.seed = 11
	assert_true(_LoreRoomPresentation.pick_setup_line(rng) in _LoreRoomPresentation.SETUP_LINES)


func test_success_roll_is_deterministic_with_rng() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var heal_ok: bool = _HealRoomPresentation.is_successful(rng)
	rng.seed = 42
	assert_eq(heal_ok, _HealRoomPresentation.is_successful(rng))
	rng.seed = 42
	var treasure_ok: bool = _TreasureRoomPresentation.is_successful(rng)
	rng.seed = 42
	assert_eq(treasure_ok, _TreasureRoomPresentation.is_successful(rng))
	rng.seed = 42
	var lore_ok: bool = _LoreRoomPresentation.is_deciphered(rng)
	rng.seed = 42
	assert_eq(lore_ok, _LoreRoomPresentation.is_deciphered(rng))


func test_heal_success_narrative_format() -> void:
	var text: String = _HealRoomPresentation.format_success_narrative("癒された。", 10)
	assert_eq(text, "癒された。\n生存メンバーを 10 回復した。")


func test_treasure_failure_gold_is_half() -> void:
	assert_eq(_TreasureRoomPresentation.failure_gold_amount(30), 15)
	assert_eq(_TreasureRoomPresentation.failure_gold_amount(1), 1)


func test_treasure_narrative_formats() -> void:
	var success: String = _TreasureRoomPresentation.format_success_narrative("開いた。", 30, "銀の指輪")
	assert_true("Gold +30" in success)
	assert_true("銀の指輪" in success)
	var fail: String = _TreasureRoomPresentation.format_fail_narrative("空だった。", 15)
	assert_eq(fail, "空だった。\nGold +15")


func test_room_bg_paths_exist() -> void:
	assert_true(ResourceLoader.exists(_HealRoomPresentation.ROOM_BG_SETUP_PATH))
	assert_true(ResourceLoader.exists(_HealRoomPresentation.ROOM_BG_SUCCESS_PATH))
	assert_true(ResourceLoader.exists(_HealRoomPresentation.ROOM_BG_FAIL_PATH))
	assert_true(ResourceLoader.exists(_TreasureRoomPresentation.ROOM_BG_SETUP_PATH))
	assert_true(ResourceLoader.exists(_TreasureRoomPresentation.ROOM_BG_SUCCESS_PATH))
	assert_true(ResourceLoader.exists(_TreasureRoomPresentation.ROOM_BG_FAIL_PATH))
	assert_true(ResourceLoader.exists(_LoreRoomPresentation.ROOM_BG_SETUP_PATH))
	assert_true(ResourceLoader.exists(_LoreRoomPresentation.ROOM_BG_SUCCESS_PATH))
	assert_true(ResourceLoader.exists(_LoreRoomPresentation.ROOM_BG_FAIL_PATH))


func test_bg_path_for_phase() -> void:
	assert_eq(_HealRoomPresentation.bg_path_for_phase("success"), _HealRoomPresentation.ROOM_BG_SUCCESS_PATH)
	assert_eq(_TreasureRoomPresentation.bg_path_for_phase("fail"), _TreasureRoomPresentation.ROOM_BG_FAIL_PATH)
	assert_eq(_LoreRoomPresentation.bg_path_for_phase("setup"), _LoreRoomPresentation.ROOM_BG_SETUP_PATH)
