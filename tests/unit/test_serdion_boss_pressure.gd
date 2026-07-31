extends GutTest
## P3-BAL-BOSS-PRESSURE-001 — セルディオン F1/F2（即時全体＋スキル率寄せ）。


func test_serdion_roar_is_instant_aoe() -> void:
	var roar: Resource = DataRegistry.get_skill_data("enemy_serdion_roar")
	assert_not_null(roar)
	assert_eq(str(roar.target_type), "all_party")
	assert_lte(float(roar.cast_time), 0.0)
	assert_gte(float(roar.power_multiplier), 0.5)
	assert_lte(float(roar.cooldown), 6.0)


func test_decree_wave_keeps_cast_spectacle() -> void:
	var decree: Resource = DataRegistry.get_skill_data("boss_decree_wave")
	assert_not_null(decree)
	assert_eq(str(decree.target_type), "all_party")
	assert_gte(float(decree.cast_time), 1.0)


func test_serdion_base_skill_use_raised() -> void:
	var enemy: Resource = DataRegistry.get_enemy_data("serdion")
	assert_not_null(enemy)
	assert_gte(float(enemy.skill_use_chance), 0.55)


func test_serdion_phase1_weights_favor_aoe_over_enrage() -> void:
	var def: Dictionary = CombatBossPhases.phase_def("serdion", 0)
	assert_gte(float(def.get("skill_use_chance", 0.0)), 0.55)
	var weights: Dictionary = def.get("skill_weight", {})
	assert_gt(float(weights.get("enemy_serdion_roar", 0.0)), float(weights.get("boss_enrage", 0.0)))
	assert_gt(float(weights.get("boss_decree_wave", 0.0)), float(weights.get("boss_enrage", 0.0)))
