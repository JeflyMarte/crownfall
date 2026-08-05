extends GutTest

## P3-SKILL-KIT-001 / DIVERGE-001 — 職キット7本＋方向分化

func test_each_job_has_seven_unlocks() -> void:
	for job_id in ["swordsman", "ranger", "vanguard", "alchemist", "beast_tamer"]:
		var job: Resource = DataRegistry.get_job_data(job_id)
		assert_not_null(job, job_id)
		assert_eq(job.skill_unlocks.size(), 7, "%s unlocks" % job_id)
		assert_eq(job.learnable_skill_ids.size(), 7, "%s learnable" % job_id)
		var levels: Array = []
		for entry: Variant in job.skill_unlocks:
			levels.append(int(entry.get("level", 0)))
			var sid: String = str(entry.get("skill_id", ""))
			assert_false(sid.is_empty())
			assert_not_null(DataRegistry.get_skill_data(sid), sid)
		assert_eq(levels, [1, 8, 15, 22, 30, 40, 50], "%s levels" % job_id)


func test_new_aoe_and_party_skills_exist() -> void:
	var aoe_ids: Array[String] = [
		"blade_tempest", "blood_mist_slash", "volley_shot", "hunting_ground_mark",
		"shield_quake", "miasma_cloud", "venom_spray",
	]
	for sid in aoe_ids:
		var sk: Resource = DataRegistry.get_skill_data(sid)
		assert_not_null(sk, sid)
		assert_eq(str(sk.target_type), "all_enemies", sid)
		assert_eq(str(sk.effect_type), "damage", sid)
	var party_ids: Array[String] = ["bulwark_aura", "rally_vapors", "herd_call"]
	for sid in party_ids:
		var sk2: Resource = DataRegistry.get_skill_data(sid)
		assert_not_null(sk2, sid)
		assert_eq(str(sk2.target_type), "all_party", sid)
		assert_eq(str(sk2.effect_type), "buff", sid)


func test_diverge_replacement_skills() -> void:
	var dance: Resource = DataRegistry.get_skill_data("blade_dance")
	assert_not_null(dance)
	assert_true(dance.tags.has("multi_hit_3"))
	assert_true(str(dance.apply_status_id).is_empty())
	var momentum: Resource = DataRegistry.get_skill_data("momentum_slash")
	assert_true(momentum.tags.has("swarm_power"))
	var pierce: Resource = DataRegistry.get_skill_data("piercing_shot")
	assert_true(pierce.tags.has("pierce_secondary"))
	assert_true(str(pierce.apply_status_id).is_empty())
	var cover: Resource = DataRegistry.get_skill_data("cover_guard")
	assert_eq(str(cover.target_type), "ally")
	assert_eq(str(cover.effect_type), "buff")
	assert_eq(str(cover.apply_status_id), "guard")


func test_swordsman_ranger_vanguard_unlock_ids() -> void:
	var sw: Resource = DataRegistry.get_job_data("swordsman")
	assert_true(sw.learnable_skill_ids.has("blade_dance"))
	assert_true(sw.learnable_skill_ids.has("battle_spirit"))
	assert_false(sw.learnable_skill_ids.has("momentum_slash"))
	assert_false(sw.learnable_skill_ids.has("chain_slash"))
	assert_false(sw.learnable_skill_ids.has("armor_cleave"))
	var rg: Resource = DataRegistry.get_job_data("ranger")
	assert_true(rg.learnable_skill_ids.has("piercing_shot"))
	assert_false(rg.learnable_skill_ids.has("mark_pursuit"))
	var vg: Resource = DataRegistry.get_job_data("vanguard")
	assert_true(vg.learnable_skill_ids.has("cover_guard"))
	assert_false(vg.learnable_skill_ids.has("shield_ram"))


func test_battle_spirit_is_self_empower() -> void:
	var spirit: Resource = DataRegistry.get_skill_data("battle_spirit")
	assert_not_null(spirit)
	assert_eq(str(spirit.target_type), "self")
	assert_eq(str(spirit.effect_type), "buff")
	assert_eq(str(spirit.apply_status_id), "empower")
	assert_eq(float(spirit.apply_status_chance), 1.0)
	assert_gte(float(spirit.cooldown), 6.0)


func test_equipped_skill_remap() -> void:
	assert_eq(SkillProgression.remap_equipped_skill_id("chain_slash"), "blade_dance")
	assert_eq(SkillProgression.remap_equipped_skill_id("mark_pursuit"), "piercing_shot")
	assert_eq(SkillProgression.remap_equipped_skill_id("momentum_slash"), "battle_spirit")
	assert_eq(SkillProgression.remap_equipped_skill_id("armor_cleave"), "battle_spirit")
	var adv: Resource = Adventurer.new()
	adv.id = "kit_remap_sw"
	adv.job_id = "swordsman"
	adv.level = 50
	adv.equipped_skill_ids = ["chain_slash"] as Array[String]
	SkillProgression.normalize_equipped_skills(adv)
	assert_eq(str(adv.equipped_skill_ids[0]), "blade_dance")
	adv.equipped_skill_ids = ["momentum_slash"] as Array[String]
	SkillProgression.normalize_equipped_skills(adv)
	assert_eq(str(adv.equipped_skill_ids[0]), "battle_spirit")


func test_aimed_shot_is_armor_break_only() -> void:
	var aimed: Resource = DataRegistry.get_skill_data("aimed_shot")
	assert_eq(str(aimed.apply_status_id), "armor_break")
	assert_true(str(aimed.apply_status_id2).is_empty())


func test_menace_is_taunt_not_fear() -> void:
	var menace: Resource = DataRegistry.get_skill_data("menace_strike")
	assert_true(menace.tags.has("taunt"))
	assert_true(str(menace.apply_status_id).is_empty())
	assert_lt(float(menace.power_multiplier), 0.8)
	var guard: Resource = DataRegistry.get_skill_data("guard_strike")
	assert_eq(str(guard.apply_status_id), "stun")
	assert_true(str(guard.apply_status_id2).is_empty())


func test_rend_is_bleed_applicator() -> void:
	var rend: Resource = DataRegistry.get_skill_data("rend_slash")
	assert_eq(str(rend.apply_status_id), "bleed")
	assert_gte(float(rend.apply_status_chance), 0.75)
	assert_lt(float(rend.power_multiplier), 1.25)


func test_pet_bond_rally_stronger_than_herd() -> void:
	var bond: Resource = DataRegistry.get_skill_data("pet_bond_rally")
	var herd: Resource = DataRegistry.get_skill_data("herd_call")
	assert_eq(str(bond.apply_status_id), "empower_pet")
	assert_lt(float(bond.cooldown), float(herd.cooldown))
	var pet_emp: Resource = DataRegistry.get_status_effect("empower_pet")
	var emp: Resource = DataRegistry.get_status_effect("empower")
	## 与ダメは本鼓舞並み。持続と被ダメ軽減でペット特化。
	assert_almost_eq(float(pet_emp.outgoing_damage_multiplier), float(emp.outgoing_damage_multiplier), 0.001)
	assert_lt(float(pet_emp.incoming_damage_multiplier), 1.0)
	assert_gt(int(pet_emp.duration_ticks), int(emp.duration_ticks))


func test_curse_sigil_uses_major_curse() -> void:
	var sigil: Resource = DataRegistry.get_skill_data("curse_sigil")
	assert_eq(str(sigil.apply_status_id), "major_curse")
	var major: Resource = DataRegistry.get_status_effect("major_curse")
	var curse: Resource = DataRegistry.get_status_effect("curse")
	assert_lt(float(major.outgoing_damage_multiplier), float(curse.outgoing_damage_multiplier))
	assert_gt(int(major.duration_ticks), int(curse.duration_ticks))


func test_grave_bell_is_front_row_soft_stun() -> void:
	var bell: Resource = DataRegistry.get_skill_data("enemy_grave_bell_peal")
	assert_eq(str(bell.target_type), "party_front")
	assert_lte(float(bell.apply_status_chance), 0.15)


func test_decree_wave_power_softened() -> void:
	var decree: Resource = DataRegistry.get_skill_data("boss_decree_wave")
	assert_lte(float(decree.power_multiplier), 0.6)
	assert_gte(float(decree.cooldown), 8.0)


func test_hunter_mark_is_mark_specialist() -> void:
	var hunter: Resource = DataRegistry.get_skill_data("hunter_mark")
	assert_eq(float(hunter.apply_status_chance), 1.0)
	assert_lt(float(hunter.power_multiplier), 0.6)


func test_frail_dust_is_armor_break() -> void:
	var dust: Resource = DataRegistry.get_skill_data("frail_dust")
	assert_eq(str(dust.apply_status_id), "armor_break")


func test_salve_burst_is_party_heal() -> void:
	var salve: Resource = DataRegistry.get_skill_data("salve_burst")
	var mend: Resource = DataRegistry.get_skill_data("mend")
	assert_eq(str(salve.target_type), "all_party")
	assert_lt(float(salve.power_multiplier), float(mend.power_multiplier))
	assert_gt(float(salve.cooldown), float(mend.cooldown) + 2.0)


func test_snare_rg_slow_bt_chill() -> void:
	var snare: Resource = DataRegistry.get_skill_data("snare_shot")
	assert_eq(str(snare.apply_status_id), "slow")
	var hobble: Resource = DataRegistry.get_skill_data("beast_hobble")
	assert_eq(str(hobble.apply_status_id), "chill")
	var bt: Resource = DataRegistry.get_job_data("beast_tamer")
	assert_true(bt.learnable_skill_ids.has("beast_hobble"))
	assert_false(bt.learnable_skill_ids.has("snare_shot"))


func test_swordsman_description_is_offense_frontline() -> void:
	var job: Resource = DataRegistry.get_job_data("swordsman")
	assert_false(str(job.description).contains("被弾を引き受ける"))
	assert_true(str(job.description).contains("主火力") or str(job.description).contains("切れ味"))
