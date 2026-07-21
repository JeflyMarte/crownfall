extends GutTest

## P3-COMBAT-GAUGE-001 — 装備1本・必殺チャージ。

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


func test_ultimate_charge_dealt_and_taken() -> void:
	var ctrl := CombatController.new()
	add_child_autofree(ctrl)
	ctrl.party_combat_hp = [100, 100]
	ctrl.party_max_hp = [100, 100]
	ctrl._init_member_ultimate_charge()
	assert_eq(ctrl.get_ultimate_charge(0), 0.0)
	ctrl.add_ultimate_charge_from_damage_dealt(0, 100)
	assert_almost_eq(ctrl.get_ultimate_charge(0), 10.0, 0.01)
	ctrl.add_ultimate_charge_from_damage_taken(0, 50)
	assert_almost_eq(ctrl.get_ultimate_charge(0), 20.0, 0.01)
	ctrl.add_ultimate_charge(0, 90.0)
	assert_true(ctrl.is_ultimate_charge_ready(0))
	ctrl.consume_ultimate_charge(0)
	assert_eq(ctrl.get_ultimate_charge(0), 0.0)
