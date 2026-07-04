extends GutTest

## P3-WANDER-001 — 遍在希少種（遠旅スズメ / 聖遺甲虫）。

const _WanderingEnemyConfig = preload("res://scripts/dungeon/WanderingEnemyConfig.gd")

func test_roll_wayfarer_at_low_roll() -> void:
	assert_eq(_WanderingEnemyConfig.wandering_id_for_roll(0.01), _WanderingEnemyConfig.ID_WAYFARER_SPARROW)

func test_roll_reliquary_in_mid_band() -> void:
	assert_eq(_WanderingEnemyConfig.wandering_id_for_roll(0.03), _WanderingEnemyConfig.ID_RELIQUARY_BEETLE)

func test_roll_empty_above_threshold() -> void:
	assert_eq(_WanderingEnemyConfig.wandering_id_for_roll(0.99), "")

func test_wayfarer_has_flee_and_no_weapon() -> void:
	var data: Resource = DataRegistry.get_enemy_data("wayfarer_sparrow")
	assert_not_null(data)
	assert_true(data.is_wandering)
	assert_eq(data.wander_flee_after_turns, 3)
	assert_eq(data.weapon_drop_chance, 0.0)

func test_reliquary_weapon_drop_and_weights() -> void:
	var data: Resource = DataRegistry.get_enemy_data("reliquary_beetle")
	assert_not_null(data)
	assert_true(data.is_wandering)
	assert_eq(data.wander_flee_after_turns, 0)
	assert_eq(data.weapon_drop_chance, 0.85)
	assert_false(data.weapon_rarity_weights.is_empty())

func test_pick_wandering_replaces_combat_pool() -> void:
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.current_dungeon_data = DataRegistry.get_dungeon_data("mourngate")
	dc.current_room_type = Enums.RoomType.COMBAT
	# pick_combat_enemy_group は内部 randf を使うため、複数回試行して放浪が出ることを確認。
	var saw_wander: bool = false
	for seed_val: int in range(200):
		seed(seed_val)
		var group: Array = dc.pick_combat_enemy_group()
		if group.size() == 1 and group[0].id == "wayfarer_sparrow":
			saw_wander = true
			break
		if group.size() == 1 and group[0].id == "reliquary_beetle":
			saw_wander = true
			break
	assert_true(saw_wander, "200 trials should hit wandering spawn")

func test_weapon_drop_chance_override() -> void:
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	var sparrow: Resource = DataRegistry.get_enemy_data("wayfarer_sparrow")
	assert_eq(dc._resolve_weapon_drop_chance(Enums.RoomType.COMBAT, sparrow), 0.0)
	var beetle: Resource = DataRegistry.get_enemy_data("reliquary_beetle")
	assert_eq(dc._resolve_weapon_drop_chance(Enums.RoomType.COMBAT, beetle), 0.85)

func test_rarity_weight_override_for_beetle() -> void:
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	var beetle: Resource = DataRegistry.get_enemy_data("reliquary_beetle")
	assert_eq(dc._rarity_drop_weight_for(Enums.Rarity.EPIC, beetle), 45)
