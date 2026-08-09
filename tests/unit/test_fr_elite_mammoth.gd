extends GutTest
## 極冠トリケラ・オミット／氷晶マンモス・エリート化（P3-BAL-FR-ELITE-MAMMOTH-001）。


func test_polar_tricera_omitted_from_frost_pools() -> void:
	for did in ["frostridge", "abyss_frostridge", "north_reach"]:
		var dg: Resource = DataRegistry.get_dungeon_data(did)
		assert_not_null(dg, did)
		assert_false(dg.elite_pool.has("polar_tricera"), did)
		assert_false(dg.enemy_pool.has("polar_tricera"), did)


func test_glacier_warden_is_frost_elite() -> void:
	var data: Resource = DataRegistry.get_enemy_data("glacier_warden")
	assert_eq(int(data.enemy_type), 1)
	assert_almost_eq(float(data.incoming_basic_mult), 0.2, 0.001)
	assert_true(data.skill_ids.has("enemy_crystal_trampling"))
	assert_gte(float(data.skill_weights.get("enemy_crystal_trampling", 0.0)), 3.4)
	assert_gte(float(data.skill_use_chance), 0.49)
	for did in ["frostridge", "abyss_frostridge", "north_reach"]:
		var dg: Resource = DataRegistry.get_dungeon_data(did)
		assert_true(dg.elite_pool.has("glacier_warden"), did)
		assert_false(dg.enemy_pool.has("glacier_warden"), did)
	assert_false(CatalogHelper.playable_enemy_id_set().has("polar_tricera"))
	assert_true(CatalogHelper.playable_enemy_id_set().has("glacier_warden"))


func test_crystal_trampling_nerfed() -> void:
	var sk: Resource = DataRegistry.get_skill_data("enemy_crystal_trampling")
	assert_true(bool(sk.ignore_defense))
	assert_eq(str(sk.target_type), "all_party")
	assert_lt(float(sk.power_multiplier), 1.5)
	assert_gt(float(sk.power_multiplier), 1.2)
	assert_gte(float(sk.cooldown), 13.0)
