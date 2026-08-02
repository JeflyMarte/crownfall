extends GutTest
## 敵トリッキー Phase1（P3-BAL-ENEMY-TRICKY-001）— T1/T2/T3 パイロット。


func test_spore_widow_t1_status_spread() -> void:
	var data: Resource = DataRegistry.get_enemy_data("spore_widow")
	assert_not_null(data)
	assert_true(data.skill_ids.has("enemy_spore_cloud"))
	var skill: Resource = DataRegistry.get_skill_data("enemy_spore_cloud")
	assert_not_null(skill)
	assert_eq(str(skill.effect_type), "damage")
	assert_eq(str(skill.target_type), "all_party")
	assert_eq(str(skill.apply_status_id), "poison")
	assert_lt(float(skill.power_multiplier), 0.25)
	assert_gte(float(skill.apply_status_chance), 0.5)


func test_moss_shell_t2_heal_skill() -> void:
	var data: Resource = DataRegistry.get_enemy_data("moss_shell")
	assert_not_null(data)
	assert_true(data.skill_ids.has("enemy_moss_mend"))
	assert_false(data.skill_ids.has("enemy_moss_spike"))
	var skill: Resource = DataRegistry.get_skill_data("enemy_moss_mend")
	assert_not_null(skill)
	assert_eq(str(skill.effect_type), "heal")
	assert_eq(str(skill.target_type), "ally")
	assert_gt(float(skill.power_multiplier), 0.0)


func test_rune_roach_t3_ally_buff() -> void:
	var data: Resource = DataRegistry.get_enemy_data("rune_roach")
	assert_not_null(data)
	assert_true(data.skill_ids.has("enemy_rune_ward"))
	assert_false(data.skill_ids.has("enemy_rune_carapace"))
	var skill: Resource = DataRegistry.get_skill_data("enemy_rune_ward")
	assert_not_null(skill)
	assert_eq(str(skill.effect_type), "buff")
	assert_eq(str(skill.target_type), "ally")
	assert_eq(str(skill.apply_status_id), "enrage")


func test_rune_carcinos_keeps_self_carapace() -> void:
	## 横展開禁止: カニは自己装甲のまま。
	var data: Resource = DataRegistry.get_enemy_data("rune_carcinos")
	assert_not_null(data)
	assert_true(data.skill_ids.has("enemy_rune_carapace"))
	var skill: Resource = DataRegistry.get_skill_data("enemy_rune_carapace")
	assert_eq(str(skill.target_type), "self")


func test_heal_enemy_slot_api() -> void:
	var cc: CombatController = CombatController.new()
	add_child_autofree(cc)
	cc.is_in_combat = true
	cc.swarm_hp = [40, 80] as Array[int]
	cc.swarm_max_hp = [100, 100] as Array[int]
	cc.active_enemy_index = 0
	cc.current_enemy_hp = 40
	assert_eq(cc.heal_enemy_slot(0, 25), 25)
	assert_eq(cc.get_enemy_hp_at(0), 65)
	## exclude 自身 → 残りの最負傷は slot1（deficit 20）。
	assert_eq(cc.get_most_injured_enemy_slot(0), 1)
	## 自分含む → slot0 のほうが削れている（deficit 35）。
	assert_eq(cc.get_most_injured_enemy_slot_including(0), 0)
