extends GutTest
## 撃破報酬ゲート — 護衛／召喚は本体プレミアムなし（P3-FIX-KILL-REWARD-GATES-001）。

const _DungeonController = preload("res://scripts/dungeon/DungeonController.gd")


func test_is_run_elite_kill_by_entity_type() -> void:
	var dc: Node = _DungeonController.new()
	add_child_autofree(dc)
	assert_true(dc.is_run_elite_kill(DataRegistry.get_enemy_data("greios")))
	assert_false(dc.is_run_elite_kill(DataRegistry.get_enemy_data("bone_picker")))
	assert_false(dc.is_run_elite_kill(DataRegistry.get_enemy_data("nereion")))
	assert_false(dc.is_run_elite_kill(null))


func test_roll_kill_relic_skips_escort_and_summon() -> void:
	var dc: Node = _DungeonController.new()
	add_child_autofree(dc)
	dc.start_stage("blackshore_4_5")
	var escort: Resource = DataRegistry.get_enemy_data("bone_picker")
	var summon: Resource = DataRegistry.get_enemy_data("black_tide_shark")
	assert_eq(dc.roll_kill_relic_drop(Enums.RoomType.ELITE, escort), "")
	assert_eq(dc.roll_kill_relic_drop(Enums.RoomType.BOSS, summon), "")


func test_weapon_drop_chance_escort_uses_combat_rate() -> void:
	var dc: Node = _DungeonController.new()
	add_child_autofree(dc)
	var escort: Resource = DataRegistry.get_enemy_data("bone_picker")
	var elite: Resource = DataRegistry.get_enemy_data("greios")
	var escort_in_elite: float = dc.call("_resolve_weapon_drop_chance", Enums.RoomType.ELITE, escort)
	var escort_in_combat: float = dc.call("_resolve_weapon_drop_chance", Enums.RoomType.COMBAT, escort)
	var elite_in_elite: float = dc.call("_resolve_weapon_drop_chance", Enums.RoomType.ELITE, elite)
	assert_almost_eq(escort_in_elite, escort_in_combat, 0.001)
	assert_gt(elite_in_elite, escort_in_elite)


func test_boss_summon_weapon_drop_uses_combat_rate() -> void:
	var dc: Node = _DungeonController.new()
	add_child_autofree(dc)
	dc.start_stage("blackshore_4_5")
	var summon: Resource = DataRegistry.get_enemy_data("black_tide_shark")
	var boss: Resource = DataRegistry.get_enemy_data("nereion")
	var summon_in_boss: float = dc.call("_resolve_weapon_drop_chance", Enums.RoomType.BOSS, summon)
	var summon_in_combat: float = dc.call("_resolve_weapon_drop_chance", Enums.RoomType.COMBAT, summon)
	var boss_in_boss: float = dc.call("_resolve_weapon_drop_chance", Enums.RoomType.BOSS, boss)
	assert_almost_eq(summon_in_boss, summon_in_combat, 0.001)
	assert_gt(boss_in_boss, summon_in_boss)


func test_boss_type_outside_boss_room_no_boss_weapon_rate() -> void:
	## enemy_type==BOSS フォールバック廃止: 通常部屋では通常率。
	var dc: Node = _DungeonController.new()
	add_child_autofree(dc)
	var boss: Resource = DataRegistry.get_enemy_data("nereion")
	var trash: Resource = DataRegistry.get_enemy_data("bone_picker")
	var boss_in_combat: float = dc.call("_resolve_weapon_drop_chance", Enums.RoomType.COMBAT, boss)
	var trash_in_combat: float = dc.call("_resolve_weapon_drop_chance", Enums.RoomType.COMBAT, trash)
	assert_almost_eq(boss_in_combat, trash_in_combat, 0.001)


func test_roll_kill_relic_null_is_fail_closed() -> void:
	var dc: Node = _DungeonController.new()
	add_child_autofree(dc)
	assert_eq(dc.roll_kill_relic_drop(Enums.RoomType.BOSS, null), "")
	assert_eq(dc.roll_kill_relic_drop(Enums.RoomType.ELITE, null), "")

