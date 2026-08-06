extends GutTest

## P3-BAL-ALLY-AOE-07-001 — 味方全体ダメージ 0.7（必殺除く）


func test_non_ultimate_ally_aoe_skills_are_0_7() -> void:
	var ids: Array[String] = [
		"blade_tempest",
		"blood_mist_slash",
		"volley_shot",
		"menace_strike",
		"miasma_cloud",
		"hunting_ground_mark",
		"venom_spray",
		"shield_quake",
	]
	for sid: String in ids:
		var skill: Resource = DataRegistry.get_skill_data(sid)
		if skill == null:
			continue
		assert_eq(str(skill.target_type), "all_enemies", sid)
		assert_ne(str(skill.slot_type), "ultimate", sid)
		assert_almost_eq(
			BalanceConfig.effective_skill_power_multiplier(skill),
			0.7,
			0.001,
			sid
		)
		assert_almost_eq(float(skill.power_multiplier), 0.7, 0.001, sid)


func test_ultimate_aoe_keeps_own_power() -> void:
	var ouga: Resource = DataRegistry.get_skill_data("ouga_retsudan")
	assert_not_null(ouga)
	assert_eq(str(ouga.slot_type), "ultimate")
	assert_almost_eq(
		BalanceConfig.effective_skill_power_multiplier(ouga),
		float(ouga.power_multiplier),
		0.001
	)
	assert_gt(float(ouga.power_multiplier), 0.7)
	var dominion: Resource = DataRegistry.get_skill_data("beast_dominion")
	assert_not_null(dominion)
	assert_almost_eq(
		BalanceConfig.effective_skill_power_multiplier(dominion),
		float(dominion.power_multiplier),
		0.001
	)


func test_skill_executor_uses_aoe_cap() -> void:
	var ex := SkillExecutor.new()
	var skill: Resource = DataRegistry.get_skill_data("volley_shot")
	assert_not_null(skill)
	var dmg: int = ex.calculate_damage(skill, 1000, false, 1.5, 1.0)
	assert_eq(dmg, 700)
