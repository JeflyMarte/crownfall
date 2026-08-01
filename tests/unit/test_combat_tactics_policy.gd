extends GutTest

## 行動方針 7択＋重み付きルーレット


func test_tactics_list_has_seven_policies() -> void:
	var list: Array = CombatTactics.tactics_list()
	assert_eq(list.size(), 7)
	var ids: Array[String] = []
	for entry in list:
		ids.append(str((entry as Dictionary).get("id")))
	assert_true(ids.has("balanced"))
	assert_true(ids.has("conserve_ultimate"))
	assert_true(ids.has("defend_focus"))
	assert_true(ids.has("fodder_focus"))
	assert_true(ids.has("boss_focus"))
	assert_true(ids.has("support_focus"))
	assert_true(ids.has("attack_only"))


func test_legacy_ids_normalize() -> void:
	assert_eq(CombatTactics.normalize_id("aggressive"), "fodder_focus")
	assert_eq(CombatTactics.normalize_id("survival"), "defend_focus")
	assert_eq(CombatTactics.normalize_id("sweep"), "fodder_focus")
	assert_eq(CombatTactics.normalize_id("balanced"), "balanced")


func test_attack_only_roll_is_only_attack() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var plan: Array = CombatTactics.roll_turn_plan(
		"attack_only", {"self_hp_ratio": 0.1, "enemy_is_boss": true}, null, rng
	)
	assert_gte(plan.size(), 1)
	for rule in plan:
		assert_eq(str((rule as Dictionary).get("slot")), "attack")


func test_display_names_are_short_policy_labels() -> void:
	assert_eq(CombatTactics.display_name("balanced"), "バランス")
	assert_eq(CombatTactics.display_name("conserve_ultimate"), "必殺温存")
	assert_eq(CombatTactics.display_name("fodder_focus"), "雑魚優先")


func test_targets_for_focus_policies() -> void:
	assert_eq(CombatTactics.get_target_rule("fodder_focus"), "lowest_hp")
	assert_eq(CombatTactics.get_target_rule("boss_focus"), "highest_hp")
