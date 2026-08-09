extends GutTest

## P3-BAL-ELDION-OPENING-001 — 開幕ストームジョー＋異常耐性＋解呪。


func test_eldion_opening_companions_and_resist() -> void:
	var boss: Resource = DataRegistry.get_enemy_data("eldion")
	assert_not_null(boss)
	assert_eq(boss.opening_companion_ids.size(), 2)
	assert_eq(str(boss.opening_companion_ids[0]), "storm_joe")
	assert_eq(str(boss.opening_companion_ids[1]), "storm_joe")
	assert_almost_eq(float(boss.incoming_status_chance_mult), 0.55, 0.001)
	assert_true("boss_buff_break_all" in boss.skill_ids)
	assert_not_null(DataRegistry.get_enemy_data("storm_joe"))


func test_eldion_phase_weights_include_buff_break() -> void:
	for phase_i: int in [0, 1, 2]:
		var phase: Dictionary = CombatBossPhases.phase_def("eldion", phase_i)
		var weights: Dictionary = phase.get("skill_weight", {})
		assert_true(weights.has("boss_buff_break_all"), "phase %d" % phase_i)
		assert_gt(float(weights["boss_buff_break_all"]), 0.0)
