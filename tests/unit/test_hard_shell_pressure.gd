extends GutTest
## 硬殻圧力スキル（P3-BAL-HARD-SHELL-PRESSURE-001）。


func test_skull_tomb_quake() -> void:
	var sk: Resource = DataRegistry.get_skill_data("enemy_skull_tomb_quake")
	assert_not_null(sk)
	assert_eq(str(sk.effect_type), "damage")
	assert_eq(str(sk.target_type), "all_party")
	assert_almost_eq(float(sk.cast_time), 1.0, 0.001)
	assert_gt(float(sk.power_multiplier), 2.0)
	var enm: Resource = DataRegistry.get_enemy_data("skull_turtle")
	assert_true(enm.skill_ids.has("enemy_skull_tomb_quake"))
	assert_gt(float(enm.skill_use_chance), 0.3)


func test_ship_moss_oldrex_pressure() -> void:
	var hull: Resource = DataRegistry.get_skill_data("enemy_hull_broadside")
	assert_eq(str(hull.target_type), "all_party")
	assert_almost_eq(float(hull.cast_time), 1.0, 0.001)
	var spore: Resource = DataRegistry.get_skill_data("enemy_moss_spore_burst")
	assert_eq(str(spore.apply_status_id), "poison")
	assert_eq(str(spore.target_type), "party_front")
	var ruin: Resource = DataRegistry.get_skill_data("enemy_ancient_ruin_stomp")
	assert_eq(str(ruin.target_type), "all_party")
	assert_true(DataRegistry.get_enemy_data("ship_eater_crab").skill_ids.has("enemy_hull_broadside"))
	assert_true(DataRegistry.get_enemy_data("moss_shell").skill_ids.has("enemy_moss_spore_burst"))
	assert_true(DataRegistry.get_enemy_data("oldrex").skill_ids.has("enemy_ancient_ruin_stomp"))
