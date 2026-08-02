extends GutTest
## 敵トリッキー Phase2/3（逃走・自爆・被ダメ軽減）。


func test_grave_bell_bat_flee_skill() -> void:
	var data: Resource = DataRegistry.get_enemy_data("grave_bell_bat")
	assert_not_null(data)
	assert_true(data.skill_ids.has("enemy_grave_flee"))
	assert_false(data.skill_ids.has("enemy_grave_swoop"))
	var skill: Resource = DataRegistry.get_skill_data("enemy_grave_flee")
	assert_eq(str(skill.effect_type), "flee")


func test_crystal_hedgehog_explode_skill() -> void:
	var skill: Resource = DataRegistry.get_skill_data("enemy_crystal_burst")
	assert_not_null(skill)
	assert_eq(str(skill.effect_type), "explode")
	assert_eq(str(skill.target_type), "party_front")


func test_skull_turtle_basic_resist() -> void:
	var data: Resource = DataRegistry.get_enemy_data("skull_turtle")
	assert_not_null(data)
	assert_almost_eq(float(data.incoming_basic_mult), 0.2, 0.001)
	assert_almost_eq(float(data.incoming_skill_mult), 1.0, 0.001)


func test_mirror_boa_skill_resist() -> void:
	var data: Resource = DataRegistry.get_enemy_data("mirror_boa")
	assert_not_null(data)
	assert_almost_eq(float(data.incoming_skill_mult), 0.2, 0.001)
	assert_almost_eq(float(data.incoming_basic_mult), 1.0, 0.001)


func test_incoming_attack_mult_api() -> void:
	var cc: CombatController = CombatController.new()
	add_child_autofree(cc)
	var turtle: Resource = DataRegistry.get_enemy_data("skull_turtle")
	var boa: Resource = DataRegistry.get_enemy_data("mirror_boa")
	cc.is_in_combat = true
	cc.swarm_data = [turtle, boa]
	cc.swarm_hp = [100, 100] as Array[int]
	cc.swarm_max_hp = [100, 100] as Array[int]
	assert_almost_eq(cc.get_enemy_incoming_attack_mult(0, true), 0.2, 0.001)
	assert_almost_eq(cc.get_enemy_incoming_attack_mult(0, false), 1.0, 0.001)
	assert_almost_eq(cc.get_enemy_incoming_attack_mult(1, false), 0.2, 0.001)
	assert_almost_eq(cc.get_enemy_incoming_attack_mult(1, true), 1.0, 0.001)
