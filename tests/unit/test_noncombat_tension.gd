extends GutTest

## P3-BAL-NONCOMBAT-001 — 非戦闘緊張感の定数。

const _DungeonController = preload("res://scripts/dungeon/DungeonController.gd")
const _TrapPresentation = preload("res://scripts/dungeon/TrapPresentation.gd")


func test_trap_damage_fractions_raised() -> void:
	assert_almost_eq(BalanceConfig.TRAP_MAX_HP_FRAC_COMBAT_SINGLE, 0.15, 0.0001)
	assert_almost_eq(BalanceConfig.TRAP_MAX_HP_FRAC_ROOM_SINGLE, 0.25, 0.0001)
	assert_almost_eq(BalanceConfig.TRAP_MAX_HP_FRAC_COMBAT_AOE, 0.08, 0.0001)
	assert_almost_eq(BalanceConfig.TRAP_MAX_HP_FRAC_ROOM_AOE, 0.12, 0.0001)


func test_trap_room_damage_numbers() -> void:
	assert_eq(ExplorationSkills.trap_damage_for_max_hp(800, false, false), 120)
	assert_eq(ExplorationSkills.trap_damage_for_max_hp(800, true, false), 200)
	assert_eq(ExplorationSkills.trap_damage_for_max_hp(1000, true, true), 120)


func test_trap_trigger_chance_raised() -> void:
	assert_almost_eq(_TrapPresentation.TRIGGER_CHANCE, 0.7, 0.0001)


func test_treasure_success_rewards() -> void:
	assert_eq(_DungeonController.TREASURE_GOLD, 40)
	assert_almost_eq(_DungeonController.TREASURE_ACCESSORY_CHANCE, 0.35, 0.0001)
	assert_almost_eq(BalanceConfig.TREASURE_WEAPON_CHANCE, 0.12, 0.0001)


func test_heal_room_percent_floor() -> void:
	assert_almost_eq(BalanceConfig.ROOM_HEAL_MAX_HP_FRAC, 0.18, 0.0001)
	assert_eq(BalanceConfig.ROOM_HEAL_AMOUNT, 80)


func test_fail_penalty_fractions() -> void:
	assert_almost_eq(BalanceConfig.NONCOMBAT_FAIL_TREASURE_HP_FRAC, 0.12, 0.0001)
	assert_almost_eq(BalanceConfig.NONCOMBAT_FAIL_HEAL_HP_FRAC, 0.10, 0.0001)
	assert_almost_eq(BalanceConfig.NONCOMBAT_FAIL_LORE_HP_FRAC, 0.08, 0.0001)


func test_lore_bonus_gold() -> void:
	assert_eq(BalanceConfig.LORE_FIRST_GOLD, 20)
	assert_eq(BalanceConfig.LORE_REPEAT_GOLD, 10)
