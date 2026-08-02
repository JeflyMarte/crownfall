extends GutTest

## P3-BAL-ALLY-FIX-001-4 — タイタンロア強化。野戦調合／野営の調合は最傷1体30%。


func test_titan_roar_recommended_buff() -> void:
	var skill: Resource = DataRegistry.get_skill_data("titan_roar")
	assert_not_null(skill)
	assert_eq(str(skill.target_type), "all_party")
	assert_eq(str(skill.effect_type), "buff")
	assert_almost_eq(float(skill.cooldown), 30.0, 0.001)
	assert_eq(str(skill.apply_status_id), "guard")
	assert_almost_eq(float(skill.apply_status_chance), 1.0, 0.001)
	assert_true(skill.tags.has("taunt"))


func test_elias_field_elixir_most_injured_30() -> void:
	var elias: Dictionary = CombatPassives.get_def("elias_field_elixir")
	assert_eq(str(elias.get("trigger", "")), "on_combat_start")
	assert_eq(str(elias.get("target", "")), "most_injured")
	assert_almost_eq(float(elias.get("heal_max_hp_fraction", 0.0)), 0.30, 0.001)


func test_serin_quick_mend_most_injured_30() -> void:
	var serin: Dictionary = CombatPassives.get_def("serin_quick_mend")
	assert_eq(str(serin.get("trigger", "")), "on_noncombat_enter")
	assert_eq(str(serin.get("target", "")), "most_injured")
	assert_almost_eq(float(serin.get("heal_max_hp_fraction", 0.0)), 0.30, 0.001)
