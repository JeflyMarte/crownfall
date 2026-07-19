extends GutTest

## P3-TRAP-PCT-001 — 罠ダメージは最大HP割合・単体/全体。


func test_trap_damage_scales_with_max_hp() -> void:
	var dmg_800: int = ExplorationSkills.trap_damage_for_max_hp(800, false, false)
	var dmg_1600: int = ExplorationSkills.trap_damage_for_max_hp(1600, false, false)
	assert_eq(dmg_800, 80)
	assert_eq(dmg_1600, 160)


func test_room_single_higher_than_combat_single() -> void:
	var combat: int = ExplorationSkills.trap_damage_for_max_hp(1000, false, false)
	var room: int = ExplorationSkills.trap_damage_for_max_hp(1000, true, false)
	assert_eq(combat, 100)
	assert_eq(room, 150)


func test_aoe_lower_than_single() -> void:
	var single: int = ExplorationSkills.trap_damage_for_max_hp(1000, true, false)
	var aoe: int = ExplorationSkills.trap_damage_for_max_hp(1000, true, true)
	assert_eq(single, 150)
	assert_eq(aoe, 80)
	assert_lt(aoe, single)


func test_minimum_damage_is_one() -> void:
	assert_eq(ExplorationSkills.trap_damage_for_max_hp(1, false, true), 1)


func test_aoe_roll_uses_chance() -> void:
	assert_almost_eq(BalanceConfig.TRAP_AOE_CHANCE, 0.35, 0.0001)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var saw_true: bool = false
	var saw_false: bool = false
	for _i in 80:
		if ExplorationSkills.roll_trap_aoe(rng):
			saw_true = true
		else:
			saw_false = true
	assert_true(saw_true)
	assert_true(saw_false)
