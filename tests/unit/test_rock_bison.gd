extends GutTest

## P3-ENEMY-ROCK-BISON-001 — ロックバイソン（素材ドロップ率↑・全DG配置・専用アート）。


const _EVENT_ONLY: Array[String] = [
	"golden_nest",
	"shadow_hunt",
	"crown_rookery",
	"cosmic_rift",
	"rock_stampede",
]


func test_rock_bison_data_shape() -> void:
	var data: Resource = DataRegistry.get_enemy_data("rock_bison")
	assert_not_null(data)
	assert_eq(str(data.id), "rock_bison")
	assert_eq(str(data.display_name), "ロックバイソン")
	assert_true(bool(data.can_swarm))
	assert_eq(int(data.swarm_min), 2)
	assert_eq(int(data.swarm_max), 3)
	assert_eq(int(data.codex_danger), 2)
	assert_almost_eq(float(data.material_drop_chance_mult), 1.75, 0.0001)
	assert_true(data.codex_materials.is_empty())


func test_default_enemy_material_mult_is_one() -> void:
	var boar: Resource = DataRegistry.get_enemy_data("moss_boar")
	assert_not_null(boar)
	assert_almost_eq(float(boar.material_drop_chance_mult), 1.0, 0.0001)


func test_rock_bison_in_all_non_event_pools() -> void:
	var dungeons: Array = DataRegistry.get_all_dungeon_data()
	assert_gt(dungeons.size(), 0)
	for data in dungeons:
		assert_not_null(data)
		var dungeon_id: String = str(data.id)
		var pool: Array = data.enemy_pool
		if dungeon_id == "rock_stampede":
			assert_eq(pool, ["rock_bison"], "%s should be bison-only" % dungeon_id)
		elif dungeon_id in _EVENT_ONLY:
			assert_false("rock_bison" in pool, "%s should stay single-species" % dungeon_id)
		else:
			assert_true("rock_bison" in pool, "%s missing rock_bison" % dungeon_id)


func test_rock_bison_dedicated_art() -> void:
	assert_true(IconPaths.ICON_MAP.has("enemy:rock_bison"))
	assert_true(IconPaths.ICON_MAP.has("enemy_turn:rock_bison"))
	assert_eq(
		str(IconPaths.ICON_MAP["enemy:rock_bison"]),
		"res://assets/codex/enemies/ART_ENM_RockBison.png"
	)
	assert_eq(
		str(IconPaths.ICON_MAP["enemy_turn:rock_bison"]),
		"res://assets/ui/combat/enemy_icons/ICO_ENM_Turn_RockBison.png"
	)
	assert_true(ResourceLoader.exists("res://resources/animation/ENM_RockBison.tres"))
	assert_true(ResourceLoader.exists("res://assets/battle/enemies/ENM_RockBison_Sheet.png"))
	assert_true(ResourceLoader.exists("res://assets/codex/enemies/ART_ENM_RockBison.png"))
	assert_ne(
		str(IconPaths.ICON_MAP["enemy:rock_bison"]),
		str(IconPaths.ICON_MAP["enemy:moss_boar"])
	)
