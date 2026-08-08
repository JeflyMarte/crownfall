extends GutTest

## 行動方針 6択＋重み付きルーレット


func test_tactics_list_has_six_policies() -> void:
	var list: Array = CombatTactics.tactics_list()
	assert_eq(list.size(), 6)
	var ids: Array[String] = []
	for entry in list:
		ids.append(str((entry as Dictionary).get("id")))
	assert_true(ids.has("balanced"))
	assert_true(ids.has("attack_focus"))
	assert_true(ids.has("conserve_ultimate"))
	assert_true(ids.has("ultimate_focus"))
	assert_true(ids.has("defend_focus"))
	assert_true(ids.has("support_focus"))
	assert_false(ids.has("attack_only"))
	assert_false(ids.has("fodder_focus"))
	assert_false(ids.has("boss_focus"))


func test_legacy_ids_normalize() -> void:
	assert_eq(CombatTactics.normalize_id("aggressive"), "attack_focus")
	assert_eq(CombatTactics.normalize_id("survival"), "defend_focus")
	assert_eq(CombatTactics.normalize_id("sweep"), "attack_focus")
	assert_eq(CombatTactics.normalize_id("fodder_focus"), "attack_focus")
	assert_eq(CombatTactics.normalize_id("boss_focus"), "attack_focus")
	assert_eq(CombatTactics.normalize_id("attack_only"), "ultimate_focus")
	assert_eq(CombatTactics.normalize_id("balanced"), "balanced")


func test_ultimate_focus_weights_prefer_ultimate() -> void:
	var weights: Dictionary = CombatTactics._slot_weights(
		"ultimate_focus", {"self_hp_ratio": 1.0, "enemy_is_boss": false}
	)
	assert_gt(float(weights.get("ultimate", 0.0)), float(weights.get("skill", 0.0)))
	assert_gt(float(weights.get("ultimate", 0.0)), float(weights.get("attack", 0.0)))
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var ult_picks := 0
	for i in 40:
		var plan: Array = CombatTactics.roll_turn_plan(
			"ultimate_focus",
			{"self_hp_ratio": 1.0, "enemy_is_boss": false, "enemy_count": 1},
			null,
			rng
		)
		if not plan.is_empty() and str((plan[0] as Dictionary).get("slot")) == "ultimate":
			ult_picks += 1
	assert_gt(ult_picks, 15)

func test_attack_focus_never_defends() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in 40:
		var plan: Array = CombatTactics.roll_turn_plan(
			"attack_focus",
			{"self_hp_ratio": 0.05, "enemy_is_boss": true, "enemy_count": 3},
			null,
			rng
		)
		for rule in plan:
			assert_ne(str((rule as Dictionary).get("slot")), "defend")
	var weights: Dictionary = CombatTactics._slot_weights(
		"attack_focus", {"self_hp_ratio": 0.05, "enemy_is_boss": true}
	)
	assert_almost_eq(float(weights.get("defend", -1.0)), 0.0, 0.01)


func test_display_names_are_short_policy_labels() -> void:
	assert_eq(CombatTactics.display_name("balanced"), "バランス")
	assert_eq(CombatTactics.display_name("attack_focus"), "攻撃特化")
	assert_eq(CombatTactics.display_name("conserve_ultimate"), "必殺温存")


func test_targets_for_focus_policies() -> void:
	assert_eq(CombatTactics.get_target_rule("attack_focus"), "lowest_hp")
	assert_eq(CombatTactics.get_target_rule("defend_focus"), "lowest_hp")
	assert_eq(CombatTactics.get_target_rule("balanced"), "front")


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


func test_heal_thresholds_by_tactics() -> void:
	## P3-BAL-TACTICS-SUPPORT-001
	assert_false(CombatTactics.heal_allowed("attack_focus", 0.90))
	assert_false(CombatTactics.heal_allowed("attack_focus", 0.50))
	assert_true(CombatTactics.heal_allowed("attack_focus", 0.40))
	assert_true(CombatTactics.heal_allowed("attack_focus", 0.30)) ## 緊急弁
	assert_true(CombatTactics.heal_allowed("balanced", 0.60))
	assert_false(CombatTactics.heal_allowed("balanced", 0.70))
	assert_true(CombatTactics.heal_allowed("support_focus", 0.75))
	assert_false(CombatTactics.heal_allowed("support_focus", 0.85))
	assert_true(CombatTactics.heal_allowed("ultimate_focus", 0.45))
	assert_false(CombatTactics.heal_allowed("ultimate_focus", 0.60))
	assert_eq(CombatTactics.display_name("ultimate_focus"), "必殺優先")


func test_buff_reapply_blocked_self_and_party() -> void:
	var stance: Resource = DataRegistry.get_skill_data("battle_spirit")
	assert_not_null(stance)
	var blocked_ctx := {
		"self_status": {"empower": true},
		"pet_status": {},
		"ally_buff_target_has": {},
		"status_holders": {"empower": 1},
		"living_ally_count": 3,
	}
	assert_true(CombatTactics.buff_reapply_blocked(stance, "balanced", blocked_ctx))
	var clear_ctx := {
		"self_status": {},
		"pet_status": {},
		"ally_buff_target_has": {},
		"status_holders": {},
		"living_ally_count": 3,
	}
	assert_false(CombatTactics.buff_reapply_blocked(stance, "balanced", clear_ctx))
	var aura: Resource = DataRegistry.get_skill_data("offensive_stance")
	assert_not_null(aura)
	## 過半（2/3）所持 → 温存
	var majority := {
		"self_status": {},
		"pet_status": {},
		"ally_buff_target_has": {},
		"status_holders": {"empower": 2},
		"living_ally_count": 3,
	}
	assert_true(CombatTactics.buff_reapply_blocked(aura, "balanced", majority))
	## support_focus は全員所持まで撃つ（2/3 では未ブロック）
	assert_false(CombatTactics.buff_reapply_blocked(aura, "support_focus", majority))
	var all_have := {
		"self_status": {},
		"pet_status": {},
		"ally_buff_target_has": {},
		"status_holders": {"empower": 3},
		"living_ally_count": 3,
	}
	assert_true(CombatTactics.buff_reapply_blocked(aura, "support_focus", all_have))


func test_attack_focus_skill_slot_weights_reduced() -> void:
	var weights: Dictionary = CombatTactics._slot_weights(
		"attack_focus", {"self_hp_ratio": 1.0, "enemy_is_boss": false}
	)
	assert_almost_eq(float(weights.get("skill", 0.0)), 36.0, 0.01)
	assert_almost_eq(float(weights.get("attack", 0.0)), 46.0, 0.01)


func test_skill_category_and_heal_reserve() -> void:
	assert_eq(CombatTactics.skill_category(DataRegistry.get_skill_data("mend")), "heal")
	assert_eq(CombatTactics.skill_category(DataRegistry.get_skill_data("empower")), "buff")
	assert_eq(CombatTactics.skill_category(DataRegistry.get_skill_data("keen_slash")), "damage")
	var light := {
		"tactics_id": "attack_focus",
		"ally_lowest_hp_ratio": 0.80,
		"ally_injured": true,
	}
	assert_false(CombatTactics.skill_reserve_met(DataRegistry.get_skill_data("mend"), light))
	var pinch := {
		"tactics_id": "attack_focus",
		"ally_lowest_hp_ratio": 0.40,
		"ally_injured": true,
	}
	assert_true(CombatTactics.skill_reserve_met(DataRegistry.get_skill_data("mend"), pinch))


func test_support_focus_roll_has_no_fixed_skill_index() -> void:
	var member: Resource = Adventurer.new()
	member.id = "sup"
	member.job_id = "alchemist"
	member.equipped_skill_ids = ["mend", "hex_bolt"] as Array[String]
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var plan: Array = CombatTactics.roll_turn_plan(
		"support_focus",
		{"self_hp_ratio": 1.0, "enemy_is_boss": false},
		member,
		rng
	)
	for rule in plan:
		assert_false((rule as Dictionary).has("skill_index"))

