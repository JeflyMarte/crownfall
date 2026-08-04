extends GutTest

## P3-BAL-GROWTH-H1-001 — キャラ別成長倍率＋DEF成長。

const _Growth = preload("res://scripts/roster/CharacterGrowthRates.gd")


func test_base_defense_per_level_constant() -> void:
	assert_eq(BalanceConfig.DEFENSE_PER_LEVEL, BalanceConfig.STAT_SCALE)
	assert_eq(BalanceConfig.DEFENSE_PER_LEVEL_MASTER, BalanceConfig.STAT_SCALE / 2)


func test_default_level_defense_bonus_matches_base_curve() -> void:
	assert_eq(LevelSystem.level_defense_bonus(1), 0)
	assert_eq(LevelSystem.level_defense_bonus(50), 49 * BalanceConfig.DEFENSE_PER_LEVEL)
	assert_eq(
		LevelSystem.level_defense_bonus(51),
		49 * BalanceConfig.DEFENSE_PER_LEVEL + BalanceConfig.DEFENSE_PER_LEVEL_MASTER
	)


func test_character_growth_rates_for_roster() -> void:
	var aldo: Dictionary = _Growth.for_adventurer_id("adventurer_0")
	assert_almost_eq(float(aldo["attack"]), 1.05, 0.001)
	var hodaka: Dictionary = _Growth.for_adventurer_id("gacha_helper_p")
	assert_almost_eq(float(hodaka["attack"]), 1.25, 0.001)
	assert_almost_eq(float(hodaka["defense"]), 0.85, 0.001)
	var neri: Dictionary = _Growth.for_helper_id("helper_o")
	assert_almost_eq(float(neri["attack"]), 0.85, 0.001)
	var unknown: Dictionary = _Growth.for_adventurer_id("pet_jack")
	assert_almost_eq(float(unknown["hp"]), 1.0, 0.001)


func test_member_growth_scales_attack_and_defense() -> void:
	var glass: Resource = Adventurer.new()
	glass.id = "gacha_helper_f" ## カイダ ATK 1.20 / DEF 0.85
	glass.level = 50
	var tank: Resource = Adventurer.new()
	tank.id = "adventurer_3" ## ガレン ATK 0.85 / DEF 1.20
	tank.level = 50
	var glass_atk: int = LevelSystem.level_attack_bonus(50, glass)
	var tank_atk: int = LevelSystem.level_attack_bonus(50, tank)
	var glass_def: int = LevelSystem.level_defense_bonus(50, glass)
	var tank_def: int = LevelSystem.level_defense_bonus(50, tank)
	assert_gt(glass_atk, tank_atk, "火力型のATK成長がタンクより高い")
	assert_gt(tank_def, glass_def, "タンクのDEF成長が火力型より高い")
	assert_eq(glass_atk, int(round(49.0 * float(BalanceConfig.ATTACK_PER_LEVEL) * 1.20)))
	assert_eq(tank_def, int(round(49.0 * float(BalanceConfig.DEFENSE_PER_LEVEL) * 1.20)))


func test_null_member_keeps_legacy_attack_curve() -> void:
	assert_eq(LevelSystem.level_attack_bonus(50), 49 * BalanceConfig.ATTACK_PER_LEVEL)
	assert_eq(LevelSystem.level_hp_bonus(50), 49 * BalanceConfig.HP_PER_LEVEL)
