extends GutTest

## P3-BAL-ELDION-OPENING-001 — 開幕同席なし＋半減時全回復＋火力／耐性。


func test_eldion_no_opening_companions_and_resist() -> void:
	var boss: Resource = DataRegistry.get_enemy_data("eldion")
	assert_not_null(boss)
	assert_eq(boss.opening_companion_ids.size(), 0)
	assert_almost_eq(float(boss.incoming_status_chance_mult), 0.55, 0.001)
	assert_true("boss_buff_break_all" in boss.skill_ids)
	assert_eq(int(boss.max_hp), 2550)
	assert_eq(int(boss.attack), 220)
	assert_almost_eq(float(boss.skill_use_chance), 0.65, 0.001)


func test_eldion_boss_group_is_solo() -> void:
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.current_dungeon_data = DataRegistry.get_dungeon_data("frostridge")
	dc.current_stage_data = DataRegistry.get_stage_data("frostridge_5_5")
	dc.current_room_type = Enums.RoomType.BOSS
	GameState.current_dungeon_tier = 0
	var group: Array = dc.pick_combat_enemy_group()
	assert_eq(group.size(), 1)
	assert_eq(str(group[0].id), "eldion")


func test_eldion_phase2_full_heal_flag() -> void:
	var p1: Dictionary = CombatBossPhases.phase_def("eldion", 1)
	assert_true(bool(p1.get("full_heal_on_enter", false)))
	var p2: Dictionary = CombatBossPhases.phase_def("eldion", 2)
	assert_false(bool(p2.get("full_heal_on_enter", false)))


func test_eldion_firepower_skills() -> void:
	assert_almost_eq(
		float(DataRegistry.get_skill_data("enemy_eldion_basic_single").power_multiplier), 1.85, 0.001
	)
	assert_almost_eq(
		float(DataRegistry.get_skill_data("enemy_eldion_basic_cleave").power_multiplier), 1.15, 0.001
	)
	assert_almost_eq(
		float(DataRegistry.get_skill_data("enemy_eldion_crevasse").power_multiplier), 2.2, 0.001
	)
	assert_almost_eq(
		float(DataRegistry.get_skill_data("enemy_eldion_glacial_breath").power_multiplier), 0.85, 0.001
	)
	var p2: Dictionary = CombatBossPhases.phase_def("eldion", 2)
	assert_almost_eq(float(p2.get("attack_mult", 0.0)), 1.30, 0.001)


func test_eldion_phase_weights_include_buff_break() -> void:
	for phase_i: int in [0, 1, 2]:
		var phase: Dictionary = CombatBossPhases.phase_def("eldion", phase_i)
		var weights: Dictionary = phase.get("skill_weight", {})
		assert_true(weights.has("boss_buff_break_all"), "phase %d" % phase_i)
		assert_gt(float(weights["boss_buff_break_all"]), 0.0)
