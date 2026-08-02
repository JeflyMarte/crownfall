extends GutTest

## P3-BAL-ALLY-FIX-001-4 — タイタンロア強化／野戦調合20%。


func test_titan_roar_recommended_buff() -> void:
	var skill: Resource = DataRegistry.get_skill_data("titan_roar")
	assert_not_null(skill)
	assert_eq(str(skill.target_type), "all_enemies")
	assert_almost_eq(float(skill.power_multiplier), 1.8, 0.001)
	assert_almost_eq(float(skill.cooldown), 30.0, 0.001)
	assert_eq(str(skill.apply_status_id), "stun")
	assert_almost_eq(float(skill.apply_status_chance), 0.4, 0.001)


func test_elias_field_elixir_heal_fraction_20() -> void:
	var elias: Dictionary = CombatPassives.get_def("elias_field_elixir")
	assert_eq(str(elias.get("trigger", "")), "on_combat_start")
	assert_almost_eq(float(elias.get("heal_max_hp_fraction", 0.0)), 0.20, 0.001)
