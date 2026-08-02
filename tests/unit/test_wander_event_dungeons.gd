extends GutTest

## P3-DG-WANDER-EVENT-002 — 砂金の巣穴 / 影狩りの狩場。

const _EventDungeonSchedule := preload("res://scripts/dungeon/EventDungeonSchedule.gd")


func before_each() -> void:
	_EventDungeonSchedule.set_debug_weekday_override(-2)


func after_each() -> void:
	GameState.event_dungeon_attempts.clear()
	_EventDungeonSchedule.clear_debug_weekday_override()


func test_golden_nest_data_shape() -> void:
	var data: Resource = DataRegistry.get_dungeon_data("golden_nest")
	assert_not_null(data)
	assert_eq(str(data.route_type), "event")
	assert_eq(int(data.floor_count), 5)
	assert_eq(int(data.daily_attempt_limit), 1)
	assert_true(bool(data.disable_wandering))
	assert_almost_eq(float(data.forced_swarm_chance), 0.32, 0.0001)
	assert_eq(data.enemy_pool, ["golden_scarab"])
	assert_true(str(data.boss_id).is_empty())
	assert_eq(int(data.room_weight_overrides.get("treasure", 0)), 30)
	assert_eq(int(data.room_weight_overrides.get("elite", -1)), 0)


func test_shadow_hunt_data_shape() -> void:
	var data: Resource = DataRegistry.get_dungeon_data("shadow_hunt")
	assert_not_null(data)
	assert_eq(str(data.route_type), "event")
	assert_eq(int(data.floor_count), 5)
	assert_eq(int(data.daily_attempt_limit), 1)
	assert_true(bool(data.disable_wandering))
	assert_almost_eq(float(data.forced_swarm_chance), 0.05, 0.0001)
	assert_eq(data.enemy_pool, ["shadow_stalker"])
	assert_true(str(data.boss_id).is_empty())
	assert_eq(int(data.room_weight_overrides.get("combat", 0)), 55)
	assert_eq(int(data.room_weight_overrides.get("elite", -1)), 0)
	assert_false(data.weapon_pool.is_empty())


func test_event_unlocked_and_daily_separate() -> void:
	assert_true(Constants.is_playable_dungeon_route("event"))
	assert_true(GameState.is_dungeon_unlocked("golden_nest"))
	assert_true(GameState.is_dungeon_unlocked("shadow_hunt"))
	GameState.event_dungeon_attempts.clear()
	assert_true(GameState.consume_event_dungeon_attempt("golden_nest"))
	assert_eq(GameState.event_dungeon_attempts_remaining("golden_nest"), 0)
	assert_eq(GameState.event_dungeon_attempts_remaining("shadow_hunt"), 1)
	assert_true(GameState.can_attempt_event_dungeon("shadow_hunt"))
	assert_eq(GameState.event_dungeon_attempts_remaining("cosmic_rift"), 1)
	assert_eq(GameState.event_dungeon_attempts_remaining("crown_rookery"), 1)


func test_sequences_have_no_boss() -> void:
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	for dungeon_id: String in ["golden_nest", "shadow_hunt"]:
		var data: Resource = DataRegistry.get_dungeon_data(dungeon_id)
		dc.current_dungeon_data = data
		var seq: Array = dc._build_room_sequence(data)
		assert_eq(seq.size(), 5)
		assert_false(Enums.RoomType.BOSS in seq)
		assert_false(Enums.RoomType.ELITE in seq)


func test_wandering_disabled() -> void:
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	for dungeon_id: String in ["golden_nest", "shadow_hunt"]:
		dc.current_dungeon_data = DataRegistry.get_dungeon_data(dungeon_id)
		dc.current_room_type = Enums.RoomType.COMBAT
		for seed_val: int in range(30):
			seed(seed_val)
			assert_null(dc.try_pick_wandering_enemy())


func test_forced_swarm_only_own_enemy() -> void:
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.current_dungeon_data = DataRegistry.get_dungeon_data("golden_nest")
	dc.current_room_type = Enums.RoomType.COMBAT
	var saw_scarab_multi: bool = false
	for seed_val: int in range(140):
		seed(seed_val)
		var group: Array = dc.pick_combat_enemy_group()
		if group.size() >= 2:
			saw_scarab_multi = true
			for ed: Resource in group:
				assert_eq(str(ed.id), "golden_scarab")
			break
	assert_true(saw_scarab_multi, "稀にスカラベ複数")

	dc.current_dungeon_data = DataRegistry.get_dungeon_data("shadow_hunt")
	var saw_stalker: bool = false
	for seed_val: int in range(80):
		seed(seed_val)
		var group2: Array = dc.pick_combat_enemy_group()
		assert_gt(group2.size(), 0)
		for ed2: Resource in group2:
			assert_eq(str(ed2.id), "shadow_stalker")
		saw_stalker = true
		break
	assert_true(saw_stalker)


func test_cosmic_rift_advance_past_last_floor_completes_without_reenter_combat() -> void:
	## 最終Fで逃走→advance すると completed のまま COMBAT タイプが残り、再入場でループする既往。
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.start_dungeon("cosmic_rift")
	assert_eq(dc.room_sequence.size(), 5)
	dc.current_room_index = dc.room_sequence.size() - 1
	dc.current_room_type = dc.room_sequence[dc.current_room_index]
	assert_true(dc.is_on_last_floor_before_exit())
	assert_true(dc.is_combat_room())
	var last_type: int = int(dc.current_room_type)
	dc.advance_room()
	assert_true(dc.is_completed)
	assert_eq(int(dc.current_room_type), last_type)
	## Scene 側は is_completed なら _enter_current_room 禁止（逃走クリア経路）。
	assert_true(dc.is_combat_room(), "タイプは残るが再入場してはいけない")
