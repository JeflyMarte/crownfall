extends GutTest

## P3-TRAP-PCT-001 — 罠ダメージは最大HP割合・単体/全体。
## ハード帯（tier=1）で旧 NONCOMBAT 数値を検証。P3-BAL-TRAP-TIER-001。


func test_trap_damage_scales_with_max_hp() -> void:
	var dmg_800: int = ExplorationSkills.trap_damage_for_max_hp(800, false, false, 1)
	var dmg_1600: int = ExplorationSkills.trap_damage_for_max_hp(1600, false, false, 1)
	# ハード: 探索単体 15%
	assert_eq(dmg_800, 120)
	assert_eq(dmg_1600, 240)


func test_room_single_higher_than_combat_single() -> void:
	var combat: int = ExplorationSkills.trap_damage_for_max_hp(1000, false, false, 1)
	var room: int = ExplorationSkills.trap_damage_for_max_hp(1000, true, false, 1)
	assert_eq(combat, 150)
	assert_eq(room, 250)


func test_aoe_lower_than_single() -> void:
	var single: int = ExplorationSkills.trap_damage_for_max_hp(1000, true, false, 1)
	var aoe: int = ExplorationSkills.trap_damage_for_max_hp(1000, true, true, 1)
	assert_eq(single, 250)
	assert_eq(aoe, 120)
	assert_lt(aoe, single)


func test_minimum_damage_is_one() -> void:
	assert_eq(ExplorationSkills.trap_damage_for_max_hp(1, false, true, 1), 1)


func test_aoe_roll_uses_chance() -> void:
	assert_almost_eq(BalanceConfig.TRAP_AOE_CHANCE, 0.35, 0.0001)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var saw_true: bool = false
	var saw_false: bool = false
	for _i in 80:
		if ExplorationSkills.roll_trap_aoe(rng, 1):
			saw_true = true
		else:
			saw_false = true
	assert_true(saw_true)
	assert_true(saw_false)
