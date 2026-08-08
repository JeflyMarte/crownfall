extends GutTest

## P3-SKILL-KIT-001 / THEME-KIT-001 — 職キット7本＋テーマ再編

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


func test_theme_kit_unlock_ids() -> void:
	## P3-SKILL-THEME-KIT-001
	var sw: Resource = DataRegistry.get_job_data("swordsman")
	var rg: Resource = DataRegistry.get_job_data("ranger")
	var vg: Resource = DataRegistry.get_job_data("vanguard")
	var al: Resource = DataRegistry.get_job_data("alchemist")
	var bt: Resource = DataRegistry.get_job_data("beast_tamer")
	assert_true(sw.learnable_skill_ids.has("keen_slash"))
	assert_true(sw.learnable_skill_ids.has("battle_spirit"))
	assert_false(sw.learnable_skill_ids.has("blade_dance"))
	assert_true(rg.learnable_skill_ids.has("trail_ward"))
	assert_true(rg.learnable_skill_ids.has("snare_shot"))
	assert_true(rg.learnable_skill_ids.has("volley_shot"))
	assert_false(rg.learnable_skill_ids.has("piercing_shot"))
	assert_true(vg.learnable_skill_ids.has("riposte_stance"))
	assert_false(vg.learnable_skill_ids.has("shield_crush"))
	assert_true(al.learnable_skill_ids.has("attuned_bolt"))
	assert_false(al.learnable_skill_ids.has("frail_dust"))
	assert_true(bt.learnable_skill_ids.has("beast_vet_care"))
	assert_true(bt.learnable_skill_ids.has("herd_call"))


func test_rg_bt_heal_and_apex() -> void:
	var rg: Resource = DataRegistry.get_job_data("ranger")
	var bt: Resource = DataRegistry.get_job_data("beast_tamer")
	var rg_by: Dictionary = {}
	var bt_by: Dictionary = {}
	for entry: Variant in rg.skill_unlocks:
		rg_by[int(entry.get("level", 0))] = str(entry.get("skill_id", ""))
	for entry: Variant in bt.skill_unlocks:
		bt_by[int(entry.get("level", 0))] = str(entry.get("skill_id", ""))
	assert_eq(str(rg_by.get(8, "")), "snare_shot")
	assert_eq(str(rg_by.get(15, "")), "camp_draught")
	assert_eq(str(rg_by.get(30, "")), "trail_ward")
	assert_eq(str(rg_by.get(40, "")), "volley_shot")
	assert_eq(str(rg_by.get(50, "")), "apex_shot")
	assert_eq(str(bt_by.get(15, "")), "beast_vet_care")
	assert_eq(str(bt_by.get(50, "")), "apex_tame")
	assert_almost_eq(float(DataRegistry.get_skill_data("apex_shot").cooldown), 24.0, 0.001)
	assert_almost_eq(float(DataRegistry.get_skill_data("apex_tame").cooldown), 24.0, 0.001)


func test_new_aoe_and_party_skills_exist() -> void:
	var aoe_ids: Array[String] = [
		"blade_tempest", "blood_mist_slash", "volley_shot", "hunting_ground_mark",
		"menace_strike", "miasma_cloud", "venom_spray", "rally_vapors",
	]
	for sid in aoe_ids:
		var sk: Resource = DataRegistry.get_skill_data(sid)
		assert_not_null(sk, sid)
		assert_eq(str(sk.target_type), "all_enemies", sid)
		assert_eq(str(sk.effect_type), "damage", sid)
	var party_ids: Array[String] = ["bulwark_aura", "herd_call", "offensive_stance"]
	for sid in party_ids:
		var sk2: Resource = DataRegistry.get_skill_data(sid)
		assert_not_null(sk2, sid)
		assert_eq(str(sk2.target_type), "all_party", sid)
		assert_eq(str(sk2.effect_type), "buff", sid)


func test_keen_slash_crit_bonus() -> void:
	var keen: Resource = DataRegistry.get_skill_data("keen_slash")
	assert_not_null(keen)
	assert_almost_eq(float(keen.crit_rate_bonus), 0.4, 0.001)
	assert_gt(float(keen.power_multiplier), 1.2)


func test_riposte_stance_is_self_guard_counter() -> void:
	var rip: Resource = DataRegistry.get_skill_data("riposte_stance")
	assert_eq(str(rip.target_type), "self")
	assert_eq(str(rip.effect_type), "buff")
	assert_eq(str(rip.apply_status_id), "guard")
	assert_true(rip.tags.has("counter_charges_2"))


func test_trail_ward_exploration_tag() -> void:
	var ward: Resource = DataRegistry.get_skill_data("trail_ward")
	assert_true(ward.tags.has("exploration"))
	assert_true(ward.tags.has("equip_passive"))


func test_vg_theme_skills() -> void:
	var stance: Resource = DataRegistry.get_skill_data("offensive_stance")
	assert_eq(str(stance.target_type), "all_party")
	assert_eq(str(stance.apply_status_id), "empower")
	var shatter: Resource = DataRegistry.get_skill_data("assault_shatter")
	assert_almost_eq(float(shatter.power_multiplier), 3.0, 0.001)
	assert_true(shatter.tags.has("self_armor_break_on_hit"))
	var drain: Resource = DataRegistry.get_skill_data("drain_slash")
	assert_true(drain.tags.has("drain"))
	var menace: Resource = DataRegistry.get_skill_data("menace_strike")
	assert_true(menace.tags.has("taunt"))


func test_battle_spirit_is_self_empower() -> void:
	var spirit: Resource = DataRegistry.get_skill_data("battle_spirit")
	assert_not_null(spirit)
	assert_eq(str(spirit.target_type), "self")
	assert_eq(str(spirit.effect_type), "buff")
	assert_eq(str(spirit.apply_status_id), "empower")
	assert_eq(float(spirit.apply_status_chance), 1.0)
	assert_gte(float(spirit.cooldown), 6.0)


func test_equipped_skill_remap() -> void:
	assert_eq(SkillProgression.remap_equipped_skill_id("chain_slash"), "keen_slash")
	assert_eq(SkillProgression.remap_equipped_skill_id("blade_dance"), "keen_slash")
	assert_eq(SkillProgression.remap_equipped_skill_id("mark_pursuit"), "volley_shot")
	assert_eq(SkillProgression.remap_equipped_skill_id("piercing_shot"), "volley_shot")
	assert_eq(SkillProgression.remap_equipped_skill_id("momentum_slash"), "battle_spirit")
	assert_eq(SkillProgression.remap_equipped_skill_id("cover_guard"), "riposte_stance")
	assert_eq(SkillProgression.remap_equipped_skill_id("shield_crush"), "riposte_stance")
	assert_eq(SkillProgression.remap_equipped_skill_id("shield_quake"), "drain_slash")
	var adv: Resource = Adventurer.new()
	adv.id = "kit_remap_sw"
	adv.job_id = "swordsman"
	adv.level = 50
	adv.equipped_skill_ids = ["blade_dance"] as Array[String]
	SkillProgression.normalize_equipped_skills(adv)
	assert_eq(str(adv.equipped_skill_ids[0]), "keen_slash")
	var vg: Resource = Adventurer.new()
	vg.id = "kit_remap_vg"
	vg.job_id = "vanguard"
	vg.level = 50
	vg.equipped_skill_ids = ["shield_crush"] as Array[String]
	SkillProgression.normalize_equipped_skills(vg)
	assert_eq(str(vg.equipped_skill_ids[0]), "riposte_stance")


func test_aimed_shot_is_armor_break_only() -> void:
	var aimed: Resource = DataRegistry.get_skill_data("aimed_shot")
	assert_eq(str(aimed.apply_status_id), "armor_break")
	assert_true(str(aimed.apply_status_id2).is_empty())


func test_menace_is_taunt_not_fear() -> void:
	var menace: Resource = DataRegistry.get_skill_data("menace_strike")
	assert_true(menace.tags.has("taunt"))
	assert_true(str(menace.apply_status_id).is_empty())
	assert_eq(str(menace.target_type), "all_enemies")
	var guard: Resource = DataRegistry.get_skill_data("guard_strike")
	assert_eq(str(guard.apply_status_id), "stun")


func test_rend_is_bleed_applicator() -> void:
	var rend: Resource = DataRegistry.get_skill_data("rend_slash")
	assert_eq(str(rend.apply_status_id), "bleed")
	assert_gte(float(rend.apply_status_chance), 0.75)
	assert_lt(float(rend.power_multiplier), 1.25)


func test_pet_bond_and_herd_call_roles() -> void:
	var bond: Resource = DataRegistry.get_skill_data("pet_bond_rally")
	var herd: Resource = DataRegistry.get_skill_data("herd_call")
	assert_eq(str(bond.apply_status_id), "empower_pet")
	assert_true(bond.tags.has("pet_maxhp_heal"))
	assert_eq(str(herd.display_name), "群れ纏い")
	assert_eq(str(herd.apply_status_id), "guard_minor")
	assert_true(herd.tags.has("pet_maxhp_heal"))
	assert_gt(BalanceConfig.HEAL_FRAC_PET_HERD_CALL, BalanceConfig.HEAL_FRAC_PET_BOND_RALLY)
	var pet_emp: Resource = DataRegistry.get_status_effect("empower_pet")
	var emp: Resource = DataRegistry.get_status_effect("empower")
	assert_almost_eq(float(pet_emp.outgoing_damage_multiplier), float(emp.outgoing_damage_multiplier), 0.001)
	assert_lt(float(pet_emp.incoming_damage_multiplier), 1.0)


func test_corrosive_vapors_is_aoe_vulnerable() -> void:
	var vapor: Resource = DataRegistry.get_skill_data("rally_vapors")
	assert_eq(str(vapor.display_name), "腐食の煙")
	assert_eq(str(vapor.target_type), "all_enemies")
	assert_eq(str(vapor.apply_status_id), "vulnerable")
	assert_lt(float(vapor.power_multiplier), float(DataRegistry.get_skill_data("miasma_cloud").power_multiplier))


func test_curse_sigil_uses_major_curse() -> void:
	var sigil: Resource = DataRegistry.get_skill_data("curse_sigil")
	assert_eq(str(sigil.apply_status_id), "major_curse")


func test_hunter_mark_is_mark_specialist() -> void:
	var hunter: Resource = DataRegistry.get_skill_data("hunter_mark")
	assert_eq(float(hunter.apply_status_chance), 1.0)
	assert_lt(float(hunter.power_multiplier), 0.6)


func test_attuned_bolt_uses_weapon_element() -> void:
	var bolt: Resource = DataRegistry.get_skill_data("attuned_bolt")
	assert_eq(str(bolt.display_name), "属性共鳴")
	assert_true(str(bolt.element).is_empty())
	assert_true(bolt.tags.has("weapon_element"))
	assert_eq(str(bolt.effect_type), "damage")
	assert_almost_eq(float(bolt.power_multiplier), 1.5, 0.001)
	assert_almost_eq(float(bolt.apply_status_chance), 0.3, 0.001)
	assert_eq(SkillProgression.remap_equipped_skill_id("frail_dust"), "attuned_bolt")
	assert_eq(ElementResolver.status_id_for_element("fire"), "ignite")
	assert_eq(ElementResolver.status_id_for_element("ice"), "chill")
	assert_eq(ElementResolver.status_id_for_element("lightning"), "shock")
	assert_eq(ElementResolver.status_id_for_element("dark"), "curse")
	assert_eq(ElementResolver.status_id_for_element("holy"), "vulnerable")


func test_trail_ward_equip_passive_only() -> void:
	assert_almost_eq(CombatPassives.TRAIL_WARD_NONCOMBAT_HEAL_FRAC, 0.05, 0.001)
	assert_almost_eq(CombatPassives.TRAIL_WARD_TRAP_MULT, 0.75, 0.001)
	var ward: Resource = DataRegistry.get_skill_data("trail_ward")
	assert_true(ward.tags.has("equip_passive"))
	assert_eq(str(ward.effect_type), "none")
	assert_true(str(ward.apply_status_id).is_empty())
	assert_true(str(ward.description).contains("5%"))
	assert_true(str(ward.description).contains("罠"))


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


func test_counter_charge_grant_consume() -> void:
	CombatPassives.reset_combat_scoped()
	CombatPassives.grant_combat_counter_charges(0, 2)
	assert_true(CombatPassives.consume_combat_counter_charge(0))
	assert_true(CombatPassives.consume_combat_counter_charge(0))
	assert_false(CombatPassives.consume_combat_counter_charge(0))
	CombatPassives.reset_combat_scoped()


func test_swordsman_description_mentions_themes() -> void:
	var sw: Resource = DataRegistry.get_job_data("swordsman")
	assert_true(str(sw.description).contains("出血") or str(sw.description).contains("会心"))
