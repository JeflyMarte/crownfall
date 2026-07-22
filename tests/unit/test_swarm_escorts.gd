extends GutTest

## P3-BAL-SWARM-001/002 — 群れ率・護衛・全Biome展開・ティア別率/質。

const _DungeonTierConfig = preload("res://scripts/dungeon/DungeonTierConfig.gd")


func test_swarm_chance_raised() -> void:
	assert_almost_eq(BalanceConfig.SWARM_CHANCE, 0.45, 0.001)


func test_tier_swarm_scalars() -> void:
	assert_almost_eq(_DungeonTierConfig.swarm_chance_mult(_DungeonTierConfig.TIER_NORMAL), 1.0, 0.001)
	assert_almost_eq(_DungeonTierConfig.swarm_chance_mult(_DungeonTierConfig.TIER_HARD), 1.25, 0.001)
	assert_almost_eq(_DungeonTierConfig.swarm_chance_mult(_DungeonTierConfig.TIER_NIGHTMARE), 1.50, 0.001)
	assert_eq(_DungeonTierConfig.swarm_size_bonus(_DungeonTierConfig.TIER_NORMAL), 0)
	assert_eq(_DungeonTierConfig.swarm_size_bonus(_DungeonTierConfig.TIER_HARD), 1)
	assert_eq(_DungeonTierConfig.swarm_size_bonus(_DungeonTierConfig.TIER_NIGHTMARE), 2)
	assert_almost_eq(_DungeonTierConfig.swarm_mixed_chance(_DungeonTierConfig.TIER_NORMAL), 0.50, 0.001)
	assert_almost_eq(_DungeonTierConfig.swarm_mixed_chance(_DungeonTierConfig.TIER_HARD), 0.65, 0.001)
	assert_almost_eq(_DungeonTierConfig.swarm_mixed_chance(_DungeonTierConfig.TIER_NIGHTMARE), 0.80, 0.001)
	assert_eq(_DungeonTierConfig.swarm_size_cap(), 5)


func test_mourngate_trash_can_swarm() -> void:
	for eid: String in [
		"sepia_hound",
		"crown_eater_rat",
		"grave_bell_bat",
		"crystal_hedgehog",
		"rune_roach",
	]:
		var ed: Resource = DataRegistry.get_enemy_data(eid)
		assert_not_null(ed, eid)
		assert_true(bool(ed.can_swarm), eid)
		assert_false(bool(ed.escorts_minions), eid)
		assert_gte(int(ed.swarm_max), 3, eid)


func test_strong_enemies_escort_minions() -> void:
	for eid: String in [
		"skullface_mantis",
		"crystal_scorpion",
		"rune_carcinos",
		"marsh_king",
		"abyssal_squid",
		"storm_joe",
	]:
		var ed: Resource = DataRegistry.get_enemy_data(eid)
		assert_not_null(ed, eid)
		assert_true(bool(ed.can_swarm), eid)
		assert_true(bool(ed.escorts_minions), eid)
		assert_gte(int(ed.swarm_max), 3, eid)


func test_main_and_side_biomes_have_swarm_coverage() -> void:
	## メイン／サブ各 Biome に雑魚群れ＋護衛リーダーが少なくとも1体ずつ。
	var expected: Dictionary = {
		"mourngate": {"trash": "sepia_hound", "leader": "skullface_mantis"},
		"whisperwood": {"trash": "moss_boar", "leader": "rune_carcinos"},
		"mistfen": {"trash": "blood_leech", "leader": "marsh_king"},
		"blackshore": {"trash": "ship_eater_crab", "leader": "abyssal_squid"},
		"frostridge": {"trash": "frost_claw_raptor", "leader": "storm_joe"},
		"astoria_ruins": {"trash": "sepia_hound", "leader": ""},
		"green_hollow": {"trash": "moss_boar", "leader": ""},
		"broken_marsh": {"trash": "blood_leech", "leader": ""},
		"westbay_flats": {"trash": "ship_eater_crab", "leader": ""},
		"frostwall_path": {"trash": "frost_claw_raptor", "leader": ""},
	}
	for biome_id: Variant in expected.keys():
		var data: Resource = DataRegistry.get_dungeon_data(str(biome_id))
		assert_not_null(data, str(biome_id))
		var route: String = str(data.route_type)
		assert_true(route == "main" or route == "side", str(biome_id))
		var trash_id: String = str(expected[biome_id]["trash"])
		var leader_id: String = str(expected[biome_id]["leader"])
		assert_true(trash_id in data.enemy_pool, "%s missing trash %s" % [biome_id, trash_id])
		var trash: Resource = DataRegistry.get_enemy_data(trash_id)
		assert_true(bool(trash.can_swarm), trash_id)
		if not leader_id.is_empty():
			assert_true(leader_id in data.enemy_pool, "%s missing leader %s" % [biome_id, leader_id])
			var lead: Resource = DataRegistry.get_enemy_data(leader_id)
			assert_true(bool(lead.escorts_minions), leader_id)


func test_minion_pool_excludes_escort_leaders() -> void:
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.current_dungeon_data = DataRegistry.get_dungeon_data("mourngate")
	var minions: Array = dc._swarm_minion_enemies()
	assert_gt(minions.size(), 0)
	var ids: Dictionary = {}
	for ed: Resource in minions:
		assert_true(bool(ed.can_swarm), str(ed.id))
		assert_false(bool(ed.escorts_minions), str(ed.id))
		ids[str(ed.id)] = true
	assert_false(ids.has("skullface_mantis"))
	assert_false(ids.has("crystal_scorpion"))
	assert_true(ids.has("sepia_hound") or ids.has("grave_bell_bat"))


func test_whisperwood_minion_pool_has_trash() -> void:
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.current_dungeon_data = DataRegistry.get_dungeon_data("whisperwood")
	var minions: Array = dc._swarm_minion_enemies()
	assert_gt(minions.size(), 0)
	for ed: Resource in minions:
		assert_false(bool(ed.escorts_minions), str(ed.id))
	var capable: Array = dc._swarm_capable_enemies()
	for ed: Resource in capable:
		assert_false(bool(ed.escorts_minions), str(ed.id))
