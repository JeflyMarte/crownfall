extends GutTest

## P3-DG-ROCK-STAMPEDE-001 — 岩角の群れ道（ロックバイソン日次イベント）。


func after_each() -> void:
	GameState.event_dungeon_attempts.clear()


func test_rock_stampede_data_shape() -> void:
	var data: Resource = DataRegistry.get_dungeon_data("rock_stampede")
	assert_not_null(data)
	assert_eq(str(data.route_type), "event")
	assert_eq(str(data.display_name), "岩角の群れ道")
	assert_eq(int(data.floor_count), 5)
	assert_eq(int(data.daily_attempt_limit), 1)
	assert_true(bool(data.disable_wandering))
	assert_almost_eq(float(data.forced_swarm_chance), 0.15, 0.0001)
	assert_eq(data.enemy_pool, ["rock_bison"])
	assert_true(str(data.boss_id).is_empty())
	assert_eq(int(data.room_weight_overrides.get("combat", 0)), 40)
	assert_eq(int(data.room_weight_overrides.get("treasure", 0)), 25)
	assert_eq(int(data.room_weight_overrides.get("elite", -1)), 0)
	assert_true(data.weapon_pool.is_empty())


func test_rock_stampede_stage() -> void:
	var stages: Array = DataRegistry.get_stages_for_biome("rock_stampede")
	assert_eq(stages.size(), 1)
	assert_eq(str(stages[0].id), "rock_stampede_1_1")
	assert_eq(str(stages[0].closing_type), "exit")
	assert_eq(int(stages[0].spawn_weights.get("2", 0)), 100)


func test_daily_separate_from_other_events() -> void:
	assert_true(GameState.is_dungeon_unlocked("rock_stampede"))
	GameState.event_dungeon_attempts.clear()
	assert_true(GameState.consume_event_dungeon_attempt("rock_stampede"))
	assert_eq(GameState.event_dungeon_attempts_remaining("rock_stampede"), 0)
	assert_eq(GameState.event_dungeon_attempts_remaining("golden_nest"), 1)
	assert_eq(GameState.event_dungeon_attempts_remaining("shadow_hunt"), 1)
	assert_eq(GameState.event_dungeon_attempts_remaining("cosmic_rift"), 1)
	assert_eq(GameState.event_dungeon_attempts_remaining("crown_rookery"), 1)


func test_sequence_no_boss_and_no_wandering() -> void:
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	var data: Resource = DataRegistry.get_dungeon_data("rock_stampede")
	dc.current_dungeon_data = data
	var seq: Array = dc._build_room_sequence(data)
	assert_eq(seq.size(), 5)
	assert_false(Enums.RoomType.BOSS in seq)
	assert_false(Enums.RoomType.ELITE in seq)
	dc.current_room_type = Enums.RoomType.COMBAT
	for seed_val: int in range(30):
		seed(seed_val)
		assert_null(dc.try_pick_wandering_enemy())


func test_forced_swarm_only_bison() -> void:
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.current_dungeon_data = DataRegistry.get_dungeon_data("rock_stampede")
	dc.current_room_type = Enums.RoomType.COMBAT
	var saw_multi: bool = false
	for seed_val: int in range(140):
		seed(seed_val)
		var group: Array = dc.pick_combat_enemy_group()
		assert_gt(group.size(), 0)
		for ed: Resource in group:
			assert_eq(str(ed.id), "rock_bison")
		if group.size() >= 2:
			saw_multi = true
			break
	assert_true(saw_multi, "稀にロックバイソン複数")


func test_art_wired() -> void:
	assert_eq(
		IconPaths.stage_icon_path("rock_stampede_1_1"),
		"res://assets/dungeon/event/stages/ICO_DG_RockStampede_1_1.png"
	)
	assert_eq(
		str(IconPaths.ICON_MAP.get("dungeon:rock_stampede", "")),
		"res://assets/dungeon/event/stages/ICO_DG_RockStampede_1_1.png"
	)
	assert_true(FileAccess.file_exists("res://assets/dungeon/event/stages/ICO_DG_RockStampede_1_1.png"))
	assert_true(FileAccess.file_exists("res://assets/ui/dungeon/BAN_DG_RockStampede.png"))
