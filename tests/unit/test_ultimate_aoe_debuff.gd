extends GutTest
## P3-BAL-ULTIMATE-AOE-001 / ROLE-001 — 職別必殺の全体役割。


func test_titan_roar_party_guard_taunt() -> void:
	var skill: Resource = DataRegistry.get_skill_data("titan_roar")
	assert_not_null(skill)
	assert_eq(str(skill.target_type), "all_party")
	assert_eq(str(skill.effect_type), "buff")
	assert_eq(str(skill.apply_status_id), "guard")
	assert_almost_eq(float(skill.apply_status_chance), 1.0, 0.001)
	assert_true(skill.tags.has("taunt"))


func test_ouga_retsudan_all_enemies() -> void:
	var skill: Resource = DataRegistry.get_skill_data("ouga_retsudan")
	assert_not_null(skill)
	assert_eq(str(skill.target_type), "all_enemies")
	assert_eq(str(skill.slot_type), "ultimate")
	assert_almost_eq(float(skill.power_multiplier), 1.9, 0.001)
	assert_eq(str(skill.apply_status_id), "vulnerable")
	assert_gte(float(skill.apply_status_chance), 0.6)


func test_grand_elixir_party_heal() -> void:
	var skill: Resource = DataRegistry.get_skill_data("grand_elixir")
	assert_not_null(skill)
	assert_eq(str(skill.target_type), "all_party")
	assert_eq(str(skill.effect_type), "heal")
	assert_almost_eq(float(skill.power_multiplier), BalanceConfig.HEAL_FRAC_GRAND_ELIXIR, 0.001)
	assert_almost_eq(float(skill.power_multiplier), 0.20, 0.001)
	assert_lte(float(skill.cast_time), 0.0)
	assert_true(skill.tags.has("cleanse"))


func test_dead_eye_instant_cast() -> void:
	var skill: Resource = DataRegistry.get_skill_data("dead_eye")
	assert_not_null(skill)
	assert_lte(float(skill.cast_time), 0.0)


func test_beast_dominion_multi_debuff_aoe() -> void:
	var skill: Resource = DataRegistry.get_skill_data("beast_dominion")
	assert_not_null(skill)
	assert_eq(str(skill.target_type), "all_enemies")
	assert_eq(str(skill.apply_status_id), "mark")
	assert_eq(str(skill.apply_status_id2), "slow")
	assert_eq(str(skill.apply_status_id3), "poison")


func test_band_styles_for_role_ults() -> void:
	var ouga: Resource = DataRegistry.get_skill_data("ouga_retsudan")
	var beast: Resource = DataRegistry.get_skill_data("beast_dominion")
	var titan: Resource = DataRegistry.get_skill_data("titan_roar")
	assert_eq(CombatBandVfx.classify_ally_aoe_skill(ouga), CombatBandVfx.STYLE_FAN)
	assert_eq(CombatBandVfx.classify_ally_aoe_skill(beast), CombatBandVfx.STYLE_MIST)
	assert_eq(CombatBandVfx.classify_ultimate(ouga), CombatBandVfx.STYLE_SLASH)
	assert_eq(CombatBandVfx.classify_ultimate(beast), CombatBandVfx.STYLE_ROAR)
	assert_eq(CombatBandVfx.classify_ultimate(titan), "")
