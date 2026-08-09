extends GutTest

## P3-BAL-ELITE-IDENTITY-001 — エリート1体1役割。


func test_elite_roles_and_signature_skills() -> void:
	var cases: Array = [
		["clock_moth", "enemy_chrono_haste", 3.5, 1.0, 0.55],
		["nightfen", "enemy_nightfen_mire_regen", 3.0, 0.18, 0.5],
		["great_claw", "enemy_claw_guillotine", 3.5, 1.0, 0.5],
		["mist_wyvern", "enemy_mist_breath", 4.0, 1.0, 0.55],
		["mirror_boa", "enemy_mirror_fang", 3.0, 0.2, 0.5],
		["greios", "enemy_greios_scale_storm", 3.5, 1.0, 0.55],
		["polar_tricera", "enemy_tricera_charge", 3.5, 0.2, 0.5],
		["ninja_octopus", "enemy_ink_seal", 3.5, 0.2, 0.5],
		["anchor_lord", "enemy_anchor_crush", 3.5, 0.2, 0.5],
	]
	for row in cases:
		var eid: String = str(row[0])
		var sig: String = str(row[1])
		var data: Resource = DataRegistry.get_enemy_data(eid)
		assert_not_null(data, eid)
		assert_eq(int(data.enemy_type), 1, eid + " elite")
		assert_true(data.skill_ids.has(sig), eid + " has " + sig)
		assert_gte(float(data.skill_weights.get(sig, 0.0)), float(row[2]) - 0.01, eid + " weight")
		assert_gte(float(data.skill_use_chance), float(row[4]) - 0.01, eid + " chance")
		match eid:
			"nightfen":
				assert_almost_eq(float(data.lifesteal_ratio), float(row[3]), 0.001)
			"mirror_boa", "ninja_octopus":
				assert_almost_eq(float(data.incoming_skill_mult), float(row[3]), 0.001)
			"polar_tricera", "anchor_lord":
				assert_almost_eq(float(data.incoming_basic_mult), float(row[3]), 0.001)
		for sid: String in data.skill_ids:
			assert_not_null(DataRegistry.get_skill_data(str(sid)), "skill " + str(sid))


func test_nightfen_regen_and_lifesteal() -> void:
	var data: Resource = DataRegistry.get_enemy_data("nightfen")
	assert_true(data.skill_ids.has("enemy_nightfen_mire_regen"))
	assert_false(data.skill_ids.has("enemy_nightfen_engulf"))
	assert_almost_eq(float(data.lifesteal_ratio), 0.18, 0.001)
	var regen: Resource = DataRegistry.get_skill_data("enemy_nightfen_mire_regen")
	assert_eq(str(regen.effect_type), "buff")
	assert_eq(str(regen.apply_status_id), "regen")
	assert_eq(str(regen.target_type), "self")


func test_ninja_octopus_silence_not_aoe_veil() -> void:
	var data: Resource = DataRegistry.get_enemy_data("ninja_octopus")
	assert_true(data.skill_ids.has("enemy_ink_seal"))
	assert_false(data.skill_ids.has("enemy_ink_veil"))
	var seal: Resource = DataRegistry.get_skill_data("enemy_ink_seal")
	assert_eq(str(seal.effect_type), "silence")
	assert_almost_eq(float(data.incoming_skill_mult), 0.2, 0.001)


func test_tank_elites_basic_resist() -> void:
	for eid in ["anchor_lord", "polar_tricera"]:
		var data: Resource = DataRegistry.get_enemy_data(eid)
		assert_almost_eq(float(data.incoming_basic_mult), 0.2, 0.001, eid)


func test_greios_wing_lance_targets_back() -> void:
	var skill: Resource = DataRegistry.get_skill_data("enemy_greios_wing_lance")
	assert_eq(str(skill.target_type), "party_back")


func test_frost_pools_include_polar_tricera() -> void:
	for did in ["frostridge", "abyss_frostridge", "north_reach"]:
		var dg: Resource = DataRegistry.get_dungeon_data(did)
		assert_not_null(dg, did)
		assert_true(dg.elite_pool.has("polar_tricera"), did)
		assert_true(dg.elite_pool.has("greios"), did)
