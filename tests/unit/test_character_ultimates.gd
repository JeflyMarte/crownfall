extends GutTest

## キャラ別必殺（P3-BAL-CHAR-ULTIMATE-001 / Decision 138）。

const _UltimateSkillResolver = preload("res://scripts/combat/UltimateSkillResolver.gd")


func test_starter_ultimate_resolution() -> void:
	var expected: Dictionary = {
		"adventurer_0": ["ouga_retsudan", "王炎断"],
		"adventurer_1": ["mark_shot", "マークショット"],
		"adventurer_2": ["elemental_boost", "エレメンタルブースト"],
		"adventurer_3": ["titan_roar", "聖盾咆哮"],
		"adventurer_4": ["beast_dominion", "毒牙の嵐"],
	}
	for adv_id: String in expected.keys():
		var member: Resource = Adventurer.new()
		member.id = adv_id
		member.job_id = "swordsman"
		var pair: Array = expected[adv_id]
		assert_eq(_UltimateSkillResolver.resolve_ultimate_skill_id(member), str(pair[0]), adv_id)
		var skill: Resource = _UltimateSkillResolver.resolve_ultimate_skill(member)
		assert_not_null(skill, adv_id)
		assert_eq(str(skill.display_name), str(pair[1]), adv_id)


func test_helper_ultimate_overrides_job() -> void:
	var cases: Dictionary = {
		"helper_f": "break_edge",
		"helper_p": "critical_storm",
		"helper_m": "silence_web",
		"helper_b": "dead_eye",
		"helper_a": "iron_aura",
		"helper_n": "vg_gate_counter",
		"helper_i": "heartbeat",
		"helper_k": "curse_burst",
		"helper_c": "grand_elixir",
		"helper_o": "pet_command",
		"helper_e": "blood_drain",
		"helper_q": "eng_full_arm_cascade",
		"helper_r": "eng_blaze_overload",
		"helper_s": "eng_armor_gekigeki",
	}
	for helper_id: String in cases.keys():
		var helper: Resource = DataRegistry.get_gacha_helper_data(helper_id)
		assert_not_null(helper, helper_id)
		assert_eq(str(helper.ultimate_skill_id), str(cases[helper_id]), helper_id)
		var member: Resource = Adventurer.new()
		member.id = "gacha_%s" % helper_id
		member.job_id = str(helper.job_id)
		assert_eq(
			_UltimateSkillResolver.resolve_ultimate_skill_id(member),
			str(cases[helper_id]),
			helper_id
		)


func test_kanji_ultimate_names_are_five() -> void:
	var kanji_ids: Array[String] = [
		"ouga_retsudan",
		"titan_roar",
		"vg_gate_counter",
		"beast_dominion",
		"eng_armor_gekigeki",
	]
	var names: PackedStringArray = PackedStringArray()
	for sid: String in kanji_ids:
		var skill: Resource = DataRegistry.get_skill_data(sid)
		assert_not_null(skill, sid)
		names.append(str(skill.display_name))
	assert_eq(names[0], "王炎断")
	assert_eq(names[1], "聖盾咆哮")
	assert_eq(names[2], "門前応撃")
	assert_eq(names[3], "毒牙の嵐")
	assert_eq(names[4], "穿甲の極撃")


func test_new_ultimate_skills_exist() -> void:
	for sid: String in [
		"break_edge",
		"critical_storm",
		"mark_shot",
		"silence_web",
		"iron_aura",
		"vg_gate_counter",
		"heartbeat",
		"curse_burst",
		"elemental_boost",
		"pet_command",
		"blood_drain",
	]:
		var skill: Resource = DataRegistry.get_skill_data(sid)
		assert_not_null(skill, sid)
		assert_eq(str(skill.slot_type), "ultimate", sid)


func test_status_effects_for_character_ults() -> void:
	assert_not_null(DataRegistry.get_status_effect("crit_surge"))
	assert_not_null(DataRegistry.get_status_effect("blood_drain"))
	assert_not_null(DataRegistry.get_status_effect("status_ward"))
	assert_not_null(DataRegistry.get_status_effect("elemental_attune"))
	var crit: Resource = DataRegistry.get_status_effect("crit_surge")
	assert_gt(float(crit.crit_rate_add), 0.0)
	var drain: Resource = DataRegistry.get_status_effect("blood_drain")
	assert_gt(float(drain.lifesteal_ratio), 0.0)
	var ward: Resource = DataRegistry.get_status_effect("status_ward")
	assert_lt(float(ward.incoming_status_chance_mult), 1.0)
	var attune: Resource = DataRegistry.get_status_effect("elemental_attune")
	assert_gt(float(attune.elemental_outgoing_mult), 1.0)


func test_hotaka_critical_storm_has_no_recoil_tag() -> void:
	var skill: Resource = DataRegistry.get_skill_data("critical_storm")
	assert_not_null(skill)
	assert_false(skill.tags.has("self_damage"))
	assert_false(skill.tags.has("recoil"))
	assert_true(skill.tags.has("self_status_crit_surge"))
