extends GutTest

## 敵スキル適合パス（バランス点検フォロー）— ②〜④最低1スキル／専用技／属性整合。


func test_mirror_boa_has_dedicated_fang() -> void:
	var data: Resource = DataRegistry.get_enemy_data("mirror_boa")
	assert_not_null(data)
	assert_eq(data.skill_ids.size(), 2)
	assert_eq(str(data.skill_ids[0]), "enemy_mirror_fang")
	assert_true(data.skill_ids.has("enemy_mirror_glare"))
	var skill: Resource = DataRegistry.get_skill_data("enemy_mirror_fang")
	assert_not_null(skill)
	assert_eq(str(skill.target_type), "party_back")
	assert_eq(str(skill.apply_status_id), "poison")


func test_playable_elites_have_two_skills() -> void:
	## P3-BAL-ENEMY-SKILL-CA-001 Phase C: プレイ可能エリートは2本以上（clock_moth 既存含む）。
	## polar_tricera は FR 除外のため対象外。
	var elites: Array[String] = [
		"mist_wyvern", "mirror_boa", "greios", "great_claw",
		"nightfen", "ninja_octopus", "anchor_lord", "clock_moth",
	]
	for eid: String in elites:
		var data: Resource = DataRegistry.get_enemy_data(eid)
		assert_not_null(data, "missing elite %s" % eid)
		assert_eq(int(data.enemy_type), 1, "%s should be elite" % eid)
		assert_gte(data.skill_ids.size(), 2, "%s needs >=2 skills" % eid)
		for sid: String in data.skill_ids:
			assert_not_null(DataRegistry.get_skill_data(str(sid)), "missing skill %s" % sid)


func test_golden_scarab_uses_gold_dust_not_crystal_sting() -> void:
	var data: Resource = DataRegistry.get_enemy_data("golden_scarab")
	assert_not_null(data)
	assert_eq(str(data.skill_ids[0]), "enemy_gold_dust_scatter")
	assert_false(data.skill_ids.has("enemy_crystal_sting"))
	var skill: Resource = DataRegistry.get_skill_data("enemy_gold_dust_scatter")
	assert_not_null(skill)
	assert_eq(str(skill.apply_status_id), "slow")


func test_main_biome_trash_have_two_skills() -> void:
	## P3-BAL-ENEMY-SKILL-CA-001 Phase A: プレイ可能メイン雑魚は2本（嫌がらせ＋個性）。
	## ロックバイソンは横断フィラーのため除外。crystal_hedgehog は既存2本。
	var pools: Dictionary = {
		"mourngate": ["sepia_hound", "crown_eater_rat", "crystal_hedgehog", "grave_bell_bat", "rune_roach", "crystal_scorpion"],
		"whisperwood": ["moss_boar", "moss_shell", "spore_widow", "iron_horn", "blood_bloom", "rune_carcinos"],
		"mistfen": ["blood_leech", "dead_poison_frog", "mist_mantis", "marsh_king", "bone_picker", "mire_strider_spider", "spore_needle_wasp"],
		"blackshore": ["ship_eater_crab", "skull_turtle", "undertaker_shark", "samurai_fish", "black_tide_shark", "abyssal_squid", "tide_lamp"],
		"frostridge": ["frost_claw_raptor", "vergaron", "storm_joe", "oldrex", "glacier_warden", "wind_ripper"],
	}
	for biome_id: String in pools.keys():
		for enemy_id: String in pools[biome_id]:
			var data: Resource = DataRegistry.get_enemy_data(enemy_id)
			assert_not_null(data, "missing enemy %s" % enemy_id)
			assert_eq(int(data.enemy_type), 0, "%s should be normal trash" % enemy_id)
			assert_gte(data.skill_ids.size(), 2, "%s (%s) needs >=2 skills" % [enemy_id, biome_id])
			assert_gt(float(data.skill_use_chance), 0.0, "%s skill_use_chance" % enemy_id)
			for sid: String in data.skill_ids:
				assert_not_null(DataRegistry.get_skill_data(str(sid)), "missing skill %s" % sid)


func test_phase_a_second_skills_complement_first() -> void:
	## 代表: 単体寄り↔列／状態差になっていること。
	var hound: Resource = DataRegistry.get_enemy_data("sepia_hound")
	assert_eq(str(hound.skill_ids[0]), "enemy_memory_howl")
	assert_eq(str(hound.skill_ids[1]), "enemy_memory_bite")
	var bite: Resource = DataRegistry.get_skill_data("enemy_memory_bite")
	assert_eq(str(bite.target_type), "party")
	assert_eq(str(bite.apply_status_id), "bleed")
	var frog: Resource = DataRegistry.get_enemy_data("dead_poison_frog")
	assert_true(frog.skill_ids.has("enemy_bog_spray"))
	assert_true(frog.skill_ids.has("enemy_frog_tongue"))
	var tongue: Resource = DataRegistry.get_skill_data("enemy_frog_tongue")
	assert_eq(str(tongue.target_type), "party")
	assert_eq(str(tongue.apply_status_id), "poison")
	var joe: Resource = DataRegistry.get_enemy_data("storm_joe")
	assert_true(joe.skill_ids.has("enemy_blizzard_howl"))
	assert_true(joe.skill_ids.has("enemy_gale_cut"))
	var gale: Resource = DataRegistry.get_skill_data("enemy_gale_cut")
	assert_eq(str(gale.element), "thunder")
	assert_eq(str(gale.apply_status_id), "shock")


func test_greios_is_elite_only_in_frostridge_pool() -> void:
	var dg: Resource = DataRegistry.get_dungeon_data("frostridge")
	assert_false(dg.enemy_pool.has("greios"))
	assert_true(dg.elite_pool.has("greios"))


func test_element_status_alignment_fixes() -> void:
	var chronos: Resource = DataRegistry.get_skill_data("enemy_chronos_wave_resonance")
	assert_eq(str(chronos.element), "thunder")
	assert_eq(str(chronos.apply_status_id), "shock")
	var karna: Resource = DataRegistry.get_skill_data("enemy_karna_ash_veil")
	assert_eq(str(karna.element), "fire")
	assert_eq(str(karna.apply_status_id), "ignite")


func test_frostridge_enemies_are_fire_weak() -> void:
	## P3-BAL-FROST-WEAK-FIRE-001＋P3-BAL-ELEM-REBAL-001:
	## 霜敵は基本 fire。嵐系（storm_joe / wind_ripper）のみ thunder。
	var fire_ids: Array[String] = [
		"frost_claw_raptor", "vergaron", "oldrex", "greios",
		"glacier_warden", "polar_tricera", "eldion", "albark",
		"ice_tail_fox",
	]
	for eid: String in fire_ids:
		var data: Resource = DataRegistry.get_enemy_data(eid)
		assert_not_null(data)
		assert_true(data.element_weakness.has("fire"), "%s should be fire-weak" % eid)
		assert_false(data.element_weakness.has("ice"), "%s should not be ice-weak" % eid)
	for eid: String in ["storm_joe", "wind_ripper"]:
		var data: Resource = DataRegistry.get_enemy_data(eid)
		assert_not_null(data)
		assert_true(data.element_weakness.has("thunder"), "%s should be thunder-weak" % eid)
		assert_false(data.element_weakness.has("ice"), "%s should not be ice-weak" % eid)


func test_element_weakness_rebalance_mainline() -> void:
	## P3-BAL-ELEM-REBAL-001 — 既存敵の弱点付け替え（新キャラなし）。
	assert_true(DataRegistry.get_enemy_data("crown_eater_rat").element_weakness.has("dark"))
	assert_true(DataRegistry.get_enemy_data("sepia_hound").element_weakness.has("dark"))
	assert_true(DataRegistry.get_enemy_data("spore_widow").element_weakness.has("holy"))
	assert_true(DataRegistry.get_enemy_data("iron_horn").element_weakness.has("thunder"))
	assert_true(DataRegistry.get_enemy_data("bone_picker").element_weakness.has("dark"))
	assert_true(DataRegistry.get_enemy_data("ship_eater_crab").element_weakness.has("ice"))
	assert_true(DataRegistry.get_enemy_data("serdion").element_weakness.has("dark"))
	assert_false(DataRegistry.get_enemy_data("serdion").element_resist.has("dark"))
	assert_true(DataRegistry.get_enemy_data("chronos_wave").element_weakness.has("thunder"))
	assert_true(DataRegistry.get_enemy_data("valgard").element_weakness.has("holy"))
	assert_true(DataRegistry.get_enemy_data("nereion").element_weakness.has("ice"))
	assert_true(DataRegistry.get_enemy_data("moldgar").element_weakness.has("dark"))
	var fr: Resource = DataRegistry.get_dungeon_data("frostridge")
	assert_eq(str(fr.favored_element), "fire")
	var mg: Resource = DataRegistry.get_dungeon_data("mourngate")
	assert_eq(str(mg.favored_element), "dark")
