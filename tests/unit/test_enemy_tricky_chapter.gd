extends GutTest
## 敵トリッキー章展開（ミストフェン／フロストリッジ）。


func test_blood_leech_blood_wound() -> void:
	var data: Resource = DataRegistry.get_enemy_data("blood_leech")
	assert_not_null(data)
	assert_true(data.skill_ids.has("enemy_blood_wound"))
	assert_false(data.skill_ids.has("enemy_mire_mend"))
	assert_false(data.skill_ids.has("enemy_leech_swarm"))
	var skill: Resource = DataRegistry.get_skill_data("enemy_blood_wound")
	assert_not_null(skill)
	assert_eq(str(skill.effect_type), "damage")
	assert_eq(str(skill.apply_status_id), "heal_block")
	assert_eq(str(skill.target_type), "party_back")


func test_mist_mantis_skill_resist() -> void:
	var data: Resource = DataRegistry.get_enemy_data("mist_mantis")
	assert_not_null(data)
	assert_almost_eq(float(data.incoming_skill_mult), 0.2, 0.001)
	assert_almost_eq(float(data.incoming_basic_mult), 1.0, 0.001)


func test_wind_ripper_rift_flee() -> void:
	var data: Resource = DataRegistry.get_enemy_data("wind_ripper")
	assert_not_null(data)
	assert_true(data.skill_ids.has("enemy_rift_flee"))
	assert_false(data.skill_ids.has("enemy_wind_slash"))
	var skill: Resource = DataRegistry.get_skill_data("enemy_rift_flee")
	assert_eq(str(skill.effect_type), "flee")


func test_glacier_warden_basic_resist() -> void:
	var data: Resource = DataRegistry.get_enemy_data("glacier_warden")
	assert_not_null(data)
	assert_almost_eq(float(data.incoming_basic_mult), 0.2, 0.001)
	assert_almost_eq(float(data.incoming_skill_mult), 1.0, 0.001)
