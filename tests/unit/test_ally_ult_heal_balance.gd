extends GutTest

## タイタンロア強化。エリアス固有は戦闘終了時パーティ中回復（E-K）。セリンは予備瓶。


func test_titan_roar_recommended_buff() -> void:
	var skill: Resource = DataRegistry.get_skill_data("titan_roar")
	assert_not_null(skill)
	assert_eq(str(skill.target_type), "all_party")
	assert_eq(str(skill.effect_type), "buff")
	assert_almost_eq(float(skill.cooldown), 30.0, 0.001)
	assert_eq(str(skill.apply_status_id), "guard")
	assert_almost_eq(float(skill.apply_status_chance), 1.0, 0.001)
	assert_true(skill.tags.has("taunt"))


func test_elias_field_elixir_combat_end_party_20() -> void:
	var elias: Dictionary = CombatPassives.get_def("elias_field_elixir")
	assert_eq(str(elias.get("display_name", "")), "野営の残り香")
	assert_eq(str(elias.get("trigger", "")), "on_combat_end")
	assert_eq(str(elias.get("target", "")), "party")
	assert_almost_eq(float(elias.get("heal_max_hp_fraction", 0.0)), 0.20, 0.001)


func test_serin_spare_vial_combat_heal() -> void:
	var serin: Dictionary = CombatPassives.get_def("serin_quick_mend")
	assert_eq(str(serin.get("display_name", "")), "予備瓶")
	assert_eq(str(serin.get("trigger", "")), "on_action_start")
	assert_eq(str(serin.get("condition", "")), "ally_hp_below")
	assert_eq(str(serin.get("target", "")), "most_injured")
	assert_almost_eq(float(serin.get("heal_max_hp_fraction", 0.0)), 0.25, 0.001)
	assert_true(bool(serin.get("once_per_combat", false)))
