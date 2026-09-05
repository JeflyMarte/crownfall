extends GutTest

## P3-JOB-ENGINEER-001 — 機巧士仕掛けトークン

const _EngineerTraps := preload("res://scripts/combat/EngineerTraps.gd")


func test_place_fire_and_expire() -> void:
	var traps: RefCounted = _EngineerTraps.new()
	var placed: Dictionary = traps.place(0, "spike", 1, 4, 0.55)
	assert_true(placed.get("ok", false))
	assert_true(traps.has_trap(0))
	assert_eq(traps.count(), 1)
	for i: int in 3:
		var fired: Dictionary = traps.fire(0)
		assert_false(fired.is_empty())
		assert_eq(str(fired.get("kind", "")), "spike")
		assert_eq(int(fired.get("fires_left", -1)), 3 - i)
		assert_true(traps.has_trap(0))
	var last: Dictionary = traps.fire(0)
	assert_eq(int(last.get("fires_left", -1)), 0)
	assert_false(traps.has_trap(0))
	assert_eq(traps.count(), 0)


func test_overwrite_same_slot() -> void:
	var traps: RefCounted = _EngineerTraps.new()
	traps.place(1, "spike", 0, 4, 0.55)
	traps.place(1, "snare", 0, 3, 0.25, "chill", 1.0)
	assert_eq(traps.count(), 1)
	var t: Dictionary = traps.get_trap(1)
	assert_eq(str(t.get("kind", "")), "snare")
	assert_eq(int(t.get("fires_left", 0)), 3)


func test_party_cap_evicts_oldest() -> void:
	var traps: RefCounted = _EngineerTraps.new()
	traps.place(0, "spike", 0, 4, 0.55)
	traps.place(1, "spike", 0, 4, 0.55)
	traps.place(2, "spike", 0, 4, 0.55)
	assert_eq(traps.count(), 3)
	traps.place(3, "break", 0, 3, 0.5, "armor_break", 1.0)
	assert_eq(traps.count(), 3)
	assert_false(traps.has_trap(0))
	assert_true(traps.has_trap(3))
	assert_eq(str(traps.get_trap(3).get("kind", "")), "break")


func test_kind_helpers_from_skill() -> void:
	var spike: Resource = DataRegistry.get_skill_data("eng_spike_trap")
	var snare: Resource = DataRegistry.get_skill_data("eng_snare_trap")
	var brk: Resource = DataRegistry.get_skill_data("eng_break_trap")
	assert_not_null(spike)
	assert_not_null(snare)
	assert_not_null(brk)
	assert_eq(_EngineerTraps.kind_from_skill(spike), "spike")
	assert_eq(_EngineerTraps.kind_from_skill(snare), "snare")
	assert_eq(_EngineerTraps.kind_from_skill(brk), "break")
	assert_eq(_EngineerTraps.fires_for_kind("spike"), 4)
	assert_eq(_EngineerTraps.fires_for_kind("snare"), 3)
	assert_eq(_EngineerTraps.fires_for_kind("break"), 3)
	assert_almost_eq(_EngineerTraps.power_for_kind("spike"), 0.65, 0.001)
	assert_almost_eq(_EngineerTraps.power_for_kind("snare"), 0.25, 0.001)
	assert_almost_eq(_EngineerTraps.power_for_kind("break"), 0.50, 0.001)
	assert_almost_eq(_EngineerTraps.fire_power_mult_vs_status(false), 1.0, 0.001)
	assert_almost_eq(_EngineerTraps.fire_power_mult_vs_status(true), 1.15, 0.001)
	assert_eq(str(_EngineerTraps.status_for_kind("snare").get("id", "")), "chill")
	assert_eq(str(_EngineerTraps.status_for_kind("break").get("id", "")), "armor_break")


func test_spike_skill_tres_matches_power_helper() -> void:
	var spike: Resource = DataRegistry.get_skill_data("eng_spike_trap")
	assert_not_null(spike)
	assert_almost_eq(float(spike.power_multiplier), _EngineerTraps.power_for_kind("spike"), 0.001)


func test_clear_slot_and_clear_all() -> void:
	var traps: RefCounted = _EngineerTraps.new()
	traps.place(0, "spike", 0, 4, 0.55)
	traps.place(1, "snare", 0, 3, 0.25, "chill", 1.0)
	traps.clear_slot(0)
	assert_false(traps.has_trap(0))
	assert_true(traps.has_trap(1))
	traps.clear()
	assert_eq(traps.count(), 0)
