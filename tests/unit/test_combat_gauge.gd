extends GutTest

## P3-COMBAT-GAUGE-001 / P3-BAL-ULTIMATE-TIME-001 / P3-BAL-SKILL-CD-TIME-001 — 装備1本・必殺／スキル時間。

const _SkillExecutor = preload("res://scripts/combat/SkillExecutor.gd")


func test_max_equipped_skills_is_one() -> void:
	assert_eq(Constants.MAX_EQUIPPED_SKILLS, 1)


func test_normalize_truncates_to_one() -> void:
	var adv: Resource = Adventurer.new()
	adv.id = "gauge_test_adv"
	adv.job_id = "swordsman"
	adv.level = 50
	adv.equipped_skill_ids = ["slash_attack", "rend_slash"] as Array[String]
	SkillProgression.normalize_equipped_skills(adv)
	assert_eq(adv.equipped_skill_ids.size(), 1)
	assert_eq(str(adv.equipped_skill_ids[0]), "slash_attack")


func test_toggle_replaces_when_full() -> void:
	var adv: Resource = Adventurer.new()
	adv.id = "gauge_test_adv2"
	adv.job_id = "swordsman"
	adv.level = 50
	adv.equipped_skill_ids = ["slash_attack"] as Array[String]
	GameState.toggle_member_skill(adv, "rend_slash")
	assert_eq(adv.equipped_skill_ids.size(), 1)
	assert_eq(str(adv.equipped_skill_ids[0]), "rend_slash")


func test_equipped_skill_cooldown_ticks_over_realtime() -> void:
	var ex = _SkillExecutor.new()
	var skill: Resource = DataRegistry.get_skill_data("slash_attack")
	if skill == null:
		skill = DataRegistry.get_skill_data("rend_slash")
	assert_not_null(skill, "sample equipped skill should exist")
	assert_ne(str(skill.slot_type), "ultimate")
	var key: String = "0:%s" % str(skill.id)
	var result: Dictionary = ex.execute_damage_skill(skill, 100, false, 1.5, 1.0, key, 1.0)
	assert_true(bool(result.get("executed", false)))
	var max_cd: float = float(skill.cooldown)
	assert_gt(max_cd, 0.0)
	assert_almost_eq(ex.get_cooldown_remaining(key), max_cd, 0.05)
	ex.tick(max_cd * 0.5)
	assert_almost_eq(ex.get_cooldown_remaining(key), max_cd * 0.5, 0.05)
	ex.tick(max_cd)
	assert_true(ex.can_cast(skill, key))


func test_ultimate_skill_executor_skips_cooldown() -> void:
	var ex = _SkillExecutor.new()
	var ult: Resource = DataRegistry.get_skill_data(Constants.DEFAULT_ULTIMATE_SKILL_ID)
	assert_not_null(ult)
	assert_eq(str(ult.slot_type), "ultimate")
	assert_true(ex.can_cast(ult, "0:ultimate_strike"))
	var result: Dictionary = ex.execute_damage_skill(ult, 100, false, 1.5, 1.0, "0:ultimate_strike")
	assert_true(bool(result.get("executed", false)))
	assert_eq(ex.get_cooldown_remaining("0:ultimate_strike"), 0.0)
	assert_true(ex.can_cast(ult, "0:ultimate_strike"))


func test_ultimate_charge_fills_over_time_not_damage() -> void:
	assert_almost_eq(Constants.ULTIMATE_CHARGE_FILL_SECONDS, 100.0, 0.001)
	var ctrl := CombatController.new()
	add_child_autofree(ctrl)
	ctrl.party_combat_hp = [100, 100]
	ctrl.party_max_hp = [100, 100]
	ctrl._init_member_ultimate_charge()
	ctrl.is_in_combat = true
	assert_eq(ctrl.get_ultimate_charge(0), 0.0)
	## 半分の時間で約半分。
	ctrl.tick_ultimate_charge_over_time(Constants.ULTIMATE_CHARGE_FILL_SECONDS * 0.5)
	assert_almost_eq(ctrl.get_ultimate_charge(0), Constants.ULTIMATE_CHARGE_MAX * 0.5, 0.05)
	ctrl.tick_ultimate_charge_over_time(Constants.ULTIMATE_CHARGE_FILL_SECONDS)
	assert_true(ctrl.is_ultimate_charge_ready(0))
	ctrl.consume_ultimate_charge(0)
	assert_eq(ctrl.get_ultimate_charge(0), 0.0)


func test_ultimate_charge_does_not_tick_outside_combat() -> void:
	var ctrl := CombatController.new()
	add_child_autofree(ctrl)
	ctrl.party_combat_hp = [100]
	ctrl.party_max_hp = [100]
	ctrl._init_member_ultimate_charge()
	ctrl.is_in_combat = false
	ctrl.tick_ultimate_charge_over_time(10.0)
	assert_eq(ctrl.get_ultimate_charge(0), 0.0)


func test_ultimate_charge_persists_across_ensure() -> void:
	var ctrl := CombatController.new()
	add_child_autofree(ctrl)
	ctrl.party_combat_hp = [100, 100]
	ctrl.party_max_hp = [100, 100]
	ctrl._init_member_ultimate_charge()
	ctrl.add_ultimate_charge(0, 40.0)
	ctrl._ensure_member_ultimate_charge()
	assert_almost_eq(ctrl.get_ultimate_charge(0), 40.0, 0.01)
	ctrl.party_combat_hp = [100, 100, 100]
	ctrl.party_max_hp = [100, 100, 100]
	ctrl._ensure_member_ultimate_charge()
	assert_almost_eq(ctrl.get_ultimate_charge(0), 40.0, 0.01)
	assert_eq(ctrl.get_ultimate_charge(2), 0.0)
