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


func test_balanced_defend_weights_reduced() -> void:
	## P3-BAL-DEFEND-WEIGHT-001 案A: 通常5／ピンチ(HP&lt;20%)18。
	var full: Dictionary = CombatTactics._slot_weights(
		"balanced", {"self_hp_ratio": 1.0, "enemy_is_boss": false, "enemy_count": 1}
	)
	assert_almost_eq(float(full.get("defend", 0.0)), 5.0, 0.01)
	var mid_pinch: Dictionary = CombatTactics._slot_weights(
		"balanced", {"self_hp_ratio": 0.25, "enemy_is_boss": false, "enemy_count": 1}
	)
	## 旧閾値30%では42だった帯。20%超は通常扱い。
	assert_almost_eq(float(mid_pinch.get("defend", 0.0)), 5.0, 0.01)
	var low: Dictionary = CombatTactics._slot_weights(
		"balanced", {"self_hp_ratio": 0.15, "enemy_is_boss": false, "enemy_count": 1}
	)
	assert_almost_eq(float(low.get("defend", 0.0)), 18.0, 0.01)
	## 防御重視は据置。
	var focus: Dictionary = CombatTactics._slot_weights(
		"defend_focus", {"self_hp_ratio": 1.0, "enemy_is_boss": false, "enemy_count": 1}
	)
	assert_almost_eq(float(focus.get("defend", 0.0)), 48.0, 0.01)


func test_balanced_slot_plan_defend_threshold() -> void:
	var plan: Array = CombatTactics.get_slot_plan("balanced")
	var found := false
	for rule in plan:
		var r: Dictionary = rule as Dictionary
		if str(r.get("slot")) == "defend":
			assert_almost_eq(float(r.get("value", 0.0)), 0.20, 0.001)
			found = true
	assert_true(found)