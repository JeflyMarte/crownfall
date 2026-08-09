extends GutTest

## P3-BAL-ELDION-OPENING-001 — 開幕ストームジョー×1＋異常耐性＋解呪＋本体補強。


func test_eldion_opening_companions_and_resist() -> void:
	var boss: Resource = DataRegistry.get_enemy_data("eldion")
	assert_not_null(boss)
	assert_eq(boss.opening_companion_ids.size(), 1)
	assert_eq(str(boss.opening_companion_ids[0]), "storm_joe")
	assert_almost_eq(float(boss.incoming_status_chance_mult), 0.55, 0.001)
	assert_true("boss_buff_break_all" in boss.skill_ids)
	assert_eq(int(boss.max_hp), 2550)
	assert_eq(int(boss.attack), 195)
	assert_almost_eq(float(boss.skill_use_chance), 0.6, 0.001)
	assert_not_null(DataRegistry.get_enemy_data("storm_joe"))
	assert_eq(str(DataRegistry.get_enemy_data("storm_joe").display_name), "ストームジョー")
	assert_eq(str(DataRegistry.get_enemy_data("wind_ripper").display_name), "スノーストーム")


func test_eldion_opening_group_is_one_storm_joe() -> void:
	## pick 経路でもスノーストームが混ざらないこと。
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.current_dungeon_data = DataRegistry.get_dungeon_data("frostridge")
	dc.current_stage_data = DataRegistry.get_stage_data("frostridge_5_5")
	dc.current_room_type = Enums.RoomType.BOSS
	GameState.current_dungeon_tier = 0
	var group: Array = dc.pick_combat_enemy_group()
	assert_eq(group.size(), 2)
	assert_eq(str(group[0].id), "eldion")
	assert_eq(str(group[1].id), "storm_joe")


func test_eldion_glacial_breath_power() -> void:
	var skill: Resource = DataRegistry.get_skill_data("enemy_eldion_glacial_breath")
	assert_not_null(skill)
	assert_almost_eq(float(skill.power_multiplier), 0.7, 0.001)


func test_eldion_phase_weights_include_buff_break() -> void:
	for phase_i: int in [0, 1, 2]:
		var phase: Dictionary = CombatBossPhases.phase_def("eldion", phase_i)
		var weights: Dictionary = phase.get("skill_weight", {})
		assert_true(weights.has("boss_buff_break_all"), "phase %d" % phase_i)
		assert_gt(float(weights["boss_buff_break_all"]), 0.0)
