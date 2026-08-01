extends GutTest

## P3-UX-002 — CombatGambit.condition_summary

func test_condition_summary_always() -> void:
	assert_eq(CombatGambit.condition_summary({"condition": "always"}), "常時")

func test_condition_summary_self_hp_below() -> void:
	assert_eq(
		CombatGambit.condition_summary({"condition": "self_hp_below", "value": 0.30}),
		"自HPが30%未満"
	)

func test_condition_summary_enemy_count_gte() -> void:
	assert_eq(
		CombatGambit.condition_summary({"condition": "enemy_count_gte", "value": 2}),
		"敵数≧2"
	)

func test_condition_summary_self_range() -> void:
	assert_eq(
		CombatGambit.condition_summary({"condition": "self_range", "value": "long"}),
		"射程が遠距離"
	)

func test_rule_preview() -> void:
	assert_eq(
		CombatGambit.rule_preview({"slot": "ultimate", "condition": "ultimate_ready"}),
		"必殺準備完了 → 必殺技"
	)

func test_action_key_roundtrip() -> void:
	var rule: Dictionary = {"slot": "skill", "skill_index": 1, "condition": "always"}
	assert_eq(CombatGambit.action_key_from_rule(rule), "skill_1")
	var restored: Dictionary = CombatGambit.rule_from_action_key("skill_1")
	assert_eq(restored.get("slot"), "skill")
	assert_eq(int(restored.get("skill_index")), 1)

func test_assign_skill_indices_for_copy() -> void:
	var raw: Array = [
		{"slot": "skill", "condition": "enemy_has_mark"},
		{"slot": "skill", "condition": "always"},
	]
	var expanded: Array = CombatGambit.assign_skill_indices_for_copy(raw)
	assert_eq(int((expanded[0] as Dictionary).get("skill_index")), 0)
	assert_eq(int((expanded[1] as Dictionary).get("skill_index")), 1)

func test_range_label() -> void:
	assert_eq(CombatGambit.range_label("melee"), "近距離")

func test_hp_percent_helpers() -> void:
	assert_eq(CombatGambit.hp_percent_display(0.30), "30")
	assert_almost_eq(CombatGambit.hp_percent_storage("30"), 0.30, 0.001)

func test_preset_summary_line() -> void:
	var summary: String = CombatGambit.preset_summary_line("balanced", 2)
	assert_true(summary.contains("→"))
	## 代表プランが短い方針もあるため、省略記号は必須にしない
	assert_false(summary.is_empty())

func test_plan_from_member_ignores_custom() -> void:
	var adv_script: Script = load("res://scripts/domain/Adventurer.gd") as Script
	assert_not_null(adv_script)
	var member: Resource = adv_script.new()
	member.tactics_id = "attack_only"
	member.tactics_custom_enabled = true
	member.tactics_custom_plan = [
		{"slot": "ultimate", "condition": "always"},
	]
	var plan: Array = CombatGambit.plan_from_member(member)
	assert_eq(plan.size(), 1)
	assert_eq(str((plan[0] as Dictionary).get("slot")), "attack")
