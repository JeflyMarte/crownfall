extends GutTest

## P3-BAL-BOSS-SUMMON-REGEN-001 — ボス召喚／エルディオン再生。


func test_boss_summon_skills_are_once_designated() -> void:
	var cases := {
		"moldgar": {"skill": "enemy_moldgar_call_marsh", "enemy": "marsh_king", "count": 1},
		"nereion": {"skill": "enemy_nereion_call_dread", "enemy": "black_tide_shark", "count": 2},
		"chronos_wave": {"skill": "enemy_chronos_wave_call_moth", "enemy": "clock_moth", "count": 1},
	}
	for boss_id: String in cases.keys():
		var boss: Resource = DataRegistry.get_enemy_data(boss_id)
		assert_not_null(boss, boss_id)
		var sid: String = str(cases[boss_id]["skill"])
		assert_true(sid in boss.skill_ids, "%s has %s" % [boss_id, sid])
		var skill: Resource = DataRegistry.get_skill_data(sid)
		assert_not_null(skill, sid)
		assert_eq(str(skill.effect_type), "summon", sid)
		assert_eq(str(skill.summon_enemy_id), str(cases[boss_id]["enemy"]), sid)
		assert_eq(int(skill.summon_count), int(cases[boss_id]["count"]), sid)
		assert_true(skill.tags.has("once_per_combat"), sid)
		assert_gte(float(skill.cooldown), 9999.0, sid)
		assert_true(DataRegistry.get_enemy_data(str(cases[boss_id]["enemy"])) != null, sid)


func test_granvel_no_longer_has_summon() -> void:
	var boss: Resource = DataRegistry.get_enemy_data("granvel")
	assert_not_null(boss)
	assert_false("enemy_granvel_call_mirror" in boss.skill_ids)
	var phase0: Dictionary = CombatBossPhases.phase_def("granvel", 0)
	var weights: Dictionary = phase0.get("skill_weight", {})
	assert_false(weights.has("enemy_granvel_call_mirror"))


func test_eldion_glacial_regen_applies_hot() -> void:
	var boss: Resource = DataRegistry.get_enemy_data("eldion")
	assert_not_null(boss)
	assert_true("enemy_eldion_glacial_regen" in boss.skill_ids)
	var skill: Resource = DataRegistry.get_skill_data("enemy_eldion_glacial_regen")
	assert_not_null(skill)
	assert_eq(str(skill.effect_type), "buff")
	assert_eq(str(skill.target_type), "self")
	assert_eq(str(skill.apply_status_id), "regen")
	var status: Resource = DataRegistry.get_status_effect("regen")
	assert_not_null(status)
	assert_eq(str(status.effect_type), "hot")
	assert_gt(float(status.hot_percent_of_max), 0.0)
	assert_gte(int(status.duration_ticks), 4)


func test_status_resolver_hot_emits_heal_percent() -> void:
	var resolver := StatusResolver.new()
	assert_true(resolver.apply_status("enemy_0", "regen", 1, 0))
	var ticks: Array[Dictionary] = resolver.tick_unit("enemy_0")
	assert_eq(ticks.size(), 1)
	assert_gt(float(ticks[0].get("heal_percent_max", 0.0)), 0.0)
	assert_eq(int(ticks[0].get("damage", 0)), 0)


func test_phase_weights_include_new_skills() -> void:
	## granvel は仲間呼び削除済み（P3-BAL-GRANVEL-NO-SUMMON-001）。他ボスは call_/regen。
	for boss_id: String in ["moldgar", "nereion", "chronos_wave", "eldion"]:
		var phase0: Dictionary = CombatBossPhases.phase_def(boss_id, 0)
		var weights: Dictionary = phase0.get("skill_weight", {})
		assert_false(weights.is_empty(), boss_id)
		var found := false
		for k: Variant in weights.keys():
			var key: String = str(k)
			if key.contains("call_") or key.contains("glacial_regen"):
				found = true
				break
		assert_true(found, "phase weight for %s" % boss_id)
	var g0: Dictionary = CombatBossPhases.phase_def("granvel", 0)
	assert_false(g0.get("skill_weight", {}).is_empty())
	assert_false(str(g0.get("skill_weight", {})).contains("call_mirror"))
