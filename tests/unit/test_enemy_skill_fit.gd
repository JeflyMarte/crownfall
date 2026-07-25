extends GutTest

## 敵スキル適合パス（バランス点検フォロー）— ②〜④最低1スキル／専用技／属性整合。


func test_mirror_boa_has_dedicated_fang() -> void:
	var data: Resource = DataRegistry.get_enemy_data("mirror_boa")
	assert_not_null(data)
	assert_eq(data.skill_ids.size(), 1)
	assert_eq(str(data.skill_ids[0]), "enemy_mirror_fang")
	var skill: Resource = DataRegistry.get_skill_data("enemy_mirror_fang")
	assert_not_null(skill)
	assert_eq(str(skill.target_type), "party_back")
	assert_eq(str(skill.apply_status_id), "poison")


func test_golden_scarab_uses_gold_dust_not_crystal_sting() -> void:
	var data: Resource = DataRegistry.get_enemy_data("golden_scarab")
	assert_not_null(data)
	assert_eq(str(data.skill_ids[0]), "enemy_gold_dust_scatter")
	assert_false(data.skill_ids.has("enemy_crystal_sting"))
	var skill: Resource = DataRegistry.get_skill_data("enemy_gold_dust_scatter")
	assert_not_null(skill)
	assert_eq(str(skill.apply_status_id), "slow")


func test_main_biome_2_to_4_trash_have_skills() -> void:
	## ロックバイソンは横断フィラーのため除外。
	var pools: Dictionary = {
		"whisperwood": ["moss_boar", "moss_shell", "spore_widow", "iron_horn", "blood_bloom", "rune_carcinos"],
		"mistfen": ["blood_leech", "dead_poison_frog", "mist_mantis", "marsh_king", "bone_picker", "mire_strider_spider", "spore_needle_wasp"],
		"blackshore": ["ship_eater_crab", "skull_turtle", "undertaker_shark", "samurai_fish", "black_tide_shark", "abyssal_squid", "tide_lamp"],
	}
	for biome_id: String in pools.keys():
		for enemy_id: String in pools[biome_id]:
			var data: Resource = DataRegistry.get_enemy_data(enemy_id)
			assert_not_null(data, "missing enemy %s" % enemy_id)
			assert_gt(data.skill_ids.size(), 0, "%s (%s) needs >=1 skill" % [enemy_id, biome_id])
			assert_gt(float(data.skill_use_chance), 0.0, "%s skill_use_chance" % enemy_id)
			for sid: String in data.skill_ids:
				assert_not_null(DataRegistry.get_skill_data(str(sid)), "missing skill %s" % sid)


func test_element_status_alignment_fixes() -> void:
	var chronos: Resource = DataRegistry.get_skill_data("enemy_chronos_wave_resonance")
	assert_eq(str(chronos.element), "thunder")
	assert_eq(str(chronos.apply_status_id), "shock")
	var karna: Resource = DataRegistry.get_skill_data("enemy_karna_ash_veil")
	assert_eq(str(karna.element), "fire")
	assert_eq(str(karna.apply_status_id), "ignite")


func test_frostridge_enemies_are_fire_weak() -> void:
	## オーナー指示: フロストリッジ敵は基本 fire 弱点（氷弱点の砕氷方針は撤回）。
	var frost_ids: Array[String] = [
		"frost_claw_raptor", "vergaron", "storm_joe", "oldrex", "greios",
		"glacier_warden", "wind_ripper", "polar_tricera", "eldion", "albark",
		"ice_tail_fox",
	]
	for eid: String in frost_ids:
		var data: Resource = DataRegistry.get_enemy_data(eid)
		assert_not_null(data)
		assert_true(data.element_weakness.has("fire"), "%s should be fire-weak" % eid)
		assert_false(data.element_weakness.has("ice"), "%s should not be ice-weak" % eid)
