extends GutTest
## 敵トリッキー第2波（T8/T10/T11/T14）。


func test_undertaker_lifesteal_ratio() -> void:
	var data: Resource = DataRegistry.get_enemy_data("undertaker_shark")
	assert_not_null(data)
	assert_almost_eq(float(data.lifesteal_ratio), 0.3, 0.001)


func test_clock_moth_haste_skill() -> void:
	var data: Resource = DataRegistry.get_enemy_data("clock_moth")
	assert_not_null(data)
	assert_true(data.skill_ids.has("enemy_chrono_haste"))
	assert_false(data.skill_ids.has("enemy_chrono_resonance"))
	var skill: Resource = DataRegistry.get_skill_data("enemy_chrono_haste")
	assert_eq(str(skill.effect_type), "haste")


func test_tide_lamp_silence_skill() -> void:
	var data: Resource = DataRegistry.get_enemy_data("tide_lamp")
	assert_not_null(data)
	assert_true(data.skill_ids.has("enemy_tide_silence"))
	var skill: Resource = DataRegistry.get_skill_data("enemy_tide_silence")
	assert_eq(str(skill.effect_type), "silence")


func test_crown_eater_summon_skill() -> void:
	var data: Resource = DataRegistry.get_enemy_data("crown_eater_rat")
	assert_not_null(data)
	assert_true(data.skill_ids.has("enemy_crown_call"))
	assert_false(data.skill_ids.has("enemy_crown_swarm"))
	var skill: Resource = DataRegistry.get_skill_data("enemy_crown_call")
	assert_eq(str(skill.effect_type), "summon")
	assert_true(skill.tags.has("once_per_combat"))
	assert_gte(float(skill.cooldown), 9999.0)


func test_append_enemy_to_swarm_and_refund_ct() -> void:
	var cc: CombatController = CombatController.new()
	add_child_autofree(cc)
	var rat: Resource = DataRegistry.get_enemy_data("crown_eater_rat")
	assert_not_null(rat)
	cc.start_combat_group([rat], 1)
	assert_eq(cc.swarm_data.size(), 1)
	var added: int = cc.append_enemy_to_swarm(rat, 5)
	assert_eq(added, 1)
	assert_eq(cc.swarm_data.size(), 2)
	assert_true(cc.is_enemy_slot_alive(1))
	cc.unit_ct["enemy_1"] = cc.get_unit_action_ct("enemy", 1)
	var before: float = float(cc.unit_ct["enemy_1"])
	cc.refund_enemy_ct(1, 0.5)
	assert_lt(float(cc.unit_ct["enemy_1"]), before)


func test_append_reuses_corpse_slot_at_cap() -> void:
	## 生存数に空きがあれば、死骸スロットを再利用して召集できる。
	var cc: CombatController = CombatController.new()
	add_child_autofree(cc)
	var rat: Resource = DataRegistry.get_enemy_data("crown_eater_rat")
	assert_not_null(rat)
	cc.start_combat_group([rat, rat, rat], 1)
	assert_eq(cc.swarm_data.size(), 3)
	cc.apply_damage_to_enemy_slot(1, 99999)
	assert_false(cc.is_enemy_slot_alive(1))
	assert_eq(cc.living_enemy_count(), 2)
	## cap=3・size=3 でも死体再利用で成功（旧実装は失敗）。
	var reused: int = cc.append_enemy_to_swarm(rat, 3)
	assert_eq(reused, 1)
	assert_true(cc.is_enemy_slot_alive(1))
	assert_eq(cc.swarm_data.size(), 3)
	assert_eq(cc.living_enemy_count(), 3)
	## 生存が cap に達したら拒否。
	assert_eq(cc.append_enemy_to_swarm(rat, 3), -1)

