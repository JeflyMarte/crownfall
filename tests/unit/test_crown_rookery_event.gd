extends GutTest

## P3-DG-RAVEN-EVENT-001 — 宝冠レイヴンの巣。


func after_each() -> void:
	GameState.event_dungeon_attempts.clear()


func test_crown_rookery_data_shape() -> void:
	var data: Resource = DataRegistry.get_dungeon_data("crown_rookery")
	assert_not_null(data)
	assert_eq(str(data.route_type), "event")
	assert_eq(int(data.floor_count), 5)
	assert_eq(int(data.daily_attempt_limit), 1)
	assert_true(bool(data.disable_wandering))
	assert_almost_eq(float(data.forced_swarm_chance), 0.08, 0.0001)
	assert_eq(data.enemy_pool, ["crown_raven"])
	assert_true(str(data.boss_id).is_empty())
	assert_eq(int(data.room_weight_overrides.get("combat", 0)), 50)
	assert_eq(int(data.room_weight_overrides.get("trap", 0)), 20)
	assert_eq(int(data.room_weight_overrides.get("elite", -1)), 0)
	assert_false(data.weapon_pool.is_empty())


func test_rookery_unlocked_and_daily_separate_from_rift() -> void:
	assert_true(GameState.is_dungeon_unlocked("crown_rookery"))
	GameState.event_dungeon_attempts.clear()
	assert_true(GameState.consume_event_dungeon_attempt("cosmic_rift"))
	assert_eq(GameState.event_dungeon_attempts_remaining("cosmic_rift"), 0)
	assert_eq(GameState.event_dungeon_attempts_remaining("crown_rookery"), 1)
	assert_true(GameState.can_attempt_event_dungeon("crown_rookery"))


func test_rookery_sequence_no_boss_combat_heavy() -> void:
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	var data: Resource = DataRegistry.get_dungeon_data("crown_rookery")
	dc.current_dungeon_data = data
	var weights: Dictionary = dc._resolve_room_weights(data)
	assert_eq(int(weights["combat"]), 50)
	assert_eq(int(weights["elite"]), 0)
	var seq: Array = dc._build_room_sequence(data)
	assert_eq(seq.size(), 5)
	assert_false(Enums.RoomType.BOSS in seq)


func test_wandering_disabled_in_rookery() -> void:
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.current_dungeon_data = DataRegistry.get_dungeon_data("crown_rookery")
	dc.current_room_type = Enums.RoomType.COMBAT
	for seed_val: int in range(40):
		seed(seed_val)
		assert_null(dc.try_pick_wandering_enemy())


func test_forced_swarm_can_yield_multiple_ravens() -> void:
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.current_dungeon_data = DataRegistry.get_dungeon_data("crown_rookery")
	dc.current_room_type = Enums.RoomType.COMBAT
	var saw_multi: bool = false
	for seed_val: int in range(160):
		seed(seed_val)
		var group: Array = dc.pick_combat_enemy_group()
		if group.size() >= 2:
			saw_multi = true
			for ed: Resource in group:
				assert_eq(str(ed.id), "crown_raven")
			break
	assert_true(saw_multi, "稀にレイヴン複数が出る")
