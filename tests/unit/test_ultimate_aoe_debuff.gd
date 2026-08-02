extends GutTest
## P3-BAL-ULTIMATE-AOE-001 — タイタンロア全体／ドミニオン多デバフ。


func test_titan_roar_is_all_enemies() -> void:
	var skill: Resource = DataRegistry.get_skill_data("titan_roar")
	assert_not_null(skill)
	assert_eq(str(skill.target_type), "all_enemies")
	assert_eq(str(skill.slot_type), "ultimate")
	assert_true(skill.tags.has("aoe"))
	assert_eq(str(skill.apply_status_id), "stun")
	assert_eq(str(skill.apply_status_id2), "fear")


func test_beast_dominion_multi_debuff_aoe() -> void:
	var skill: Resource = DataRegistry.get_skill_data("beast_dominion")
	assert_not_null(skill)
	assert_eq(str(skill.target_type), "all_enemies")
	assert_eq(str(skill.slot_type), "ultimate")
	assert_eq(str(skill.apply_status_id), "mark")
	assert_almost_eq(float(skill.apply_status_chance), 1.0, 0.001)
	assert_eq(str(skill.apply_status_id2), "slow")
	assert_almost_eq(float(skill.apply_status_chance2), 1.0, 0.001)
	assert_eq(str(skill.apply_status_id3), "poison")
	assert_gte(float(skill.apply_status_chance3), 0.8)
	assert_lte(float(skill.power_multiplier), 1.5)


func test_band_styles_for_new_aoe_ults() -> void:
	var titan: Resource = DataRegistry.get_skill_data("titan_roar")
	var beast: Resource = DataRegistry.get_skill_data("beast_dominion")
	assert_eq(CombatBandVfx.classify_ally_aoe_skill(titan), CombatBandVfx.STYLE_QUAKE)
	assert_eq(CombatBandVfx.classify_ally_aoe_skill(beast), CombatBandVfx.STYLE_MIST)
	assert_eq(CombatBandVfx.classify_ultimate(titan), CombatBandVfx.STYLE_ROAR)
	assert_eq(CombatBandVfx.classify_ultimate(beast), CombatBandVfx.STYLE_ROAR)
