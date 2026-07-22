extends GutTest

## P3-BAL-SWARM-001 — 群れ率↑・雑魚群れ拡大・護衛付き強敵。


func test_swarm_chance_raised() -> void:
	assert_almost_eq(BalanceConfig.SWARM_CHANCE, 0.45, 0.001)


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
	for eid: String in ["skullface_mantis", "crystal_scorpion"]:
		var ed: Resource = DataRegistry.get_enemy_data(eid)
		assert_not_null(ed, eid)
		assert_true(bool(ed.can_swarm), eid)
		assert_true(bool(ed.escorts_minions), eid)
		assert_gte(int(ed.swarm_max), 3, eid)


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
