extends GutTest
## P3-BAL-SUMMON-ONCE-001 — 招集スキルは戦闘中1回。


func test_all_summon_skills_are_once_per_combat() -> void:
	var ids: Array[String] = [
		"enemy_crown_call",
		"enemy_boar_call",
		"enemy_granvel_call_mirror",
		"enemy_moldgar_call_marsh",
		"enemy_nereion_call_dread",
		"enemy_chronos_wave_call_moth",
		"enemy_big_cosmic_duck_call",
	]
	for sid: String in ids:
		var skill: Resource = DataRegistry.get_skill_data(sid)
		assert_not_null(skill, sid)
		assert_eq(str(skill.effect_type), "summon", sid)
		assert_true(skill.tags.has("once_per_combat"), sid)
		assert_gte(float(skill.cooldown), 9999.0, sid)
