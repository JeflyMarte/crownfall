extends GutTest

## P3-DG-DUCK-EVENT-001 — コズミックダックの裂け目。


func after_each() -> void:
	GameState.event_dungeon_attempts.clear()


func test_cosmic_rift_data_shape() -> void:
	var data: Resource = DataRegistry.get_dungeon_data("cosmic_rift")
	assert_not_null(data)
	assert_eq(str(data.route_type), "event")
	assert_eq(int(data.floor_count), 5)
	assert_eq(int(data.daily_attempt_limit), 1)
	assert_true(bool(data.disable_wandering))
	assert_almost_eq(float(data.forced_swarm_chance), 0.12, 0.0001)
	assert_eq(data.enemy_pool, ["cosmic_duck"])
	assert_true(str(data.boss_id).is_empty())
	assert_eq(int(data.room_weight_overrides.get("trap", 0)), 45)
	assert_eq(int(data.room_weight_overrides.get("elite", -1)), 0)


func test_event_route_is_playable_and_unlocked() -> void:
	assert_true(Constants.is_playable_dungeon_route("event"))
	assert_true(GameState.is_dungeon_unlocked("cosmic_rift"))


func test_daily_attempt_consume_and_block() -> void:
	GameState.event_dungeon_attempts.clear()
	assert_eq(GameState.event_dungeon_attempts_remaining("cosmic_rift"), 1)
	assert_true(GameState.can_attempt_event_dungeon("cosmic_rift"))
	assert_true(GameState.consume_event_dungeon_attempt("cosmic_rift"))
	assert_eq(GameState.event_dungeon_attempts_remaining("cosmic_rift"), 0)
	assert_false(GameState.can_attempt_event_dungeon("cosmic_rift"))
	assert_false(GameState.consume_event_dungeon_attempt("cosmic_rift"))


func test_room_sequence_has_no_boss_and_uses_overrides() -> void:
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	var data: Resource = DataRegistry.get_dungeon_data("cosmic_rift")
	dc.current_dungeon_data = data
	var weights: Dictionary = dc._resolve_room_weights(data)
	assert_eq(int(weights["trap"]), 45)
	assert_eq(int(weights["elite"]), 0)
	var seq: Array = dc._build_room_sequence(data)
	assert_eq(seq.size(), 5)
	assert_false(Enums.RoomType.BOSS in seq)
	assert_false(Enums.RoomType.ELITE in seq)


func test_wandering_disabled_in_cosmic_rift() -> void:
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.current_dungeon_data = DataRegistry.get_dungeon_data("cosmic_rift")
	dc.current_room_type = Enums.RoomType.COMBAT
	for seed_val: int in range(40):
		seed(seed_val)
		assert_null(dc.try_pick_wandering_enemy())


func test_forced_swarm_can_yield_multiple_ducks() -> void:
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.current_dungeon_data = DataRegistry.get_dungeon_data("cosmic_rift")
	dc.current_room_type = Enums.RoomType.COMBAT
	var saw_multi: bool = false
	for seed_val: int in range(120):
		seed(seed_val)
		var group: Array = dc.pick_combat_enemy_group()
		if group.size() >= 2:
			saw_multi = true
			for ed: Resource in group:
				assert_eq(str(ed.id), "cosmic_duck")
			break
	assert_true(saw_multi, "稀にダック複数が出る")


func test_save_v7_to_v8_adds_event_attempts() -> void:
	var raw: Dictionary = {"save_version": 7}
	var migrated: Dictionary = SaveManager._migrate_save_v7_to_v8(raw.duplicate(true))
	assert_true(migrated.has("event_dungeon_attempts"))
	assert_true(migrated["event_dungeon_attempts"] is Dictionary)
