extends GutTest

## P3-ENEMY-BIG-COSMIC-DUCK-001 — ビッグコズミックダック（裂け目最終F）。


func test_big_cosmic_duck_data() -> void:
	var boss: Resource = DataRegistry.get_enemy_data("big_cosmic_duck")
	assert_not_null(boss)
	assert_eq(str(boss.display_name), "ビッグコズミックダック")
	assert_eq(int(boss.enemy_type), Enums.EnemyType.BOSS)
	assert_eq(int(boss.wander_flee_after_turns), 0)
	assert_false(bool(boss.is_wandering))
	assert_true("enemy_big_cosmic_duck_call" in boss.skill_ids)
	assert_true("enemy_big_cosmic_duck_nova" in boss.skill_ids)
	var call: Resource = DataRegistry.get_skill_data("enemy_big_cosmic_duck_call")
	assert_not_null(call)
	assert_eq(str(call.effect_type), "summon")
	assert_eq(str(call.summon_enemy_id), "cosmic_duck")
	assert_eq(int(call.summon_count), 2)
	assert_true(call.tags.has("once_per_combat"))


func test_cosmic_rift_ends_with_big_duck_boss() -> void:
	var data: Resource = DataRegistry.get_dungeon_data("cosmic_rift")
	assert_eq(str(data.boss_id), "big_cosmic_duck")
	var stage: Resource = DataRegistry.get_stage_data("cosmic_rift_1_1")
	assert_not_null(stage)
	assert_eq(str(stage.closing_type), "boss")
	assert_eq(str(stage.boss_id), "big_cosmic_duck")
	assert_true(stage.has_boss_floor())
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.current_dungeon_data = data
	dc.current_stage_data = stage
	var seq: Array = dc._build_room_sequence_for_stage(stage)
	assert_eq(seq.size(), 5)
	assert_eq(seq[seq.size() - 1], Enums.RoomType.BOSS)
	var boss: Resource = dc.pick_boss_enemy_data()
	assert_not_null(boss)
	assert_eq(str(boss.id), "big_cosmic_duck")


func test_big_duck_sprite_frames_exist() -> void:
	var frames: Resource = load("res://resources/animation/ENM_BigCosmicDuck.tres")
	assert_not_null(frames)
	assert_true(frames.has_animation("idle"))
	assert_true(frames.has_animation("attack"))
	var tex: Texture2D = frames.get_frame_texture("idle", 0)
	assert_not_null(tex)
	assert_eq(tex.get_width(), 192)
	assert_eq(tex.get_height(), 192)


## P3-ENEMY-BIG-COSMIC-DUCK-002 — Hard+ 放浪昇格／裂け目 COMBAT 複数。

const _WanderingEnemyConfig := preload("res://scripts/dungeon/WanderingEnemyConfig.gd")
const _DungeonTierConfig := preload("res://scripts/dungeon/DungeonTierConfig.gd")


func after_each() -> void:
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NORMAL


func test_upgrade_to_big_chances() -> void:
	assert_eq(_WanderingEnemyConfig.upgrade_to_big_chance(_DungeonTierConfig.TIER_NORMAL), 0.0)
	assert_eq(_WanderingEnemyConfig.upgrade_to_big_chance(_DungeonTierConfig.TIER_HARD), 0.25)
	assert_eq(_WanderingEnemyConfig.upgrade_to_big_chance(_DungeonTierConfig.TIER_NIGHTMARE), 0.40)
	assert_eq(_WanderingEnemyConfig.rift_big_combat_chance(_DungeonTierConfig.TIER_NORMAL), 0.0)
	assert_eq(_WanderingEnemyConfig.rift_big_combat_chance(_DungeonTierConfig.TIER_HARD), 0.20)
	assert_eq(_WanderingEnemyConfig.rift_big_combat_chance(_DungeonTierConfig.TIER_NIGHTMARE), 0.30)


func test_promote_never_on_normal_tier() -> void:
	for seed_val: int in range(200):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_val
		var out: String = _WanderingEnemyConfig.maybe_promote_cosmic_duck_to_big(
			_WanderingEnemyConfig.ID_COSMIC_DUCK, _DungeonTierConfig.TIER_NORMAL, rng
		)
		assert_eq(out, _WanderingEnemyConfig.ID_COSMIC_DUCK)


func test_promote_can_happen_on_hard() -> void:
	var saw_big: bool = false
	for seed_val: int in range(400):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_val
		var out: String = _WanderingEnemyConfig.maybe_promote_cosmic_duck_to_big(
			_WanderingEnemyConfig.ID_COSMIC_DUCK, _DungeonTierConfig.TIER_HARD, rng
		)
		if out == _WanderingEnemyConfig.ID_BIG_COSMIC_DUCK:
			saw_big = true
			break
	assert_true(saw_big, "Hard でダック→ビッグ昇格が起きうる")


func test_rift_normal_combat_stays_ducks_only() -> void:
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NORMAL
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.current_dungeon_data = DataRegistry.get_dungeon_data("cosmic_rift")
	dc.current_room_type = Enums.RoomType.COMBAT
	for seed_val: int in range(80):
		seed(seed_val)
		var group: Array = dc.pick_combat_enemy_group()
		for ed: Resource in group:
			assert_eq(str(ed.id), "cosmic_duck")


func test_rift_hard_combat_can_spawn_big_one_or_two() -> void:
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_HARD
	var dc_script: Script = preload("res://scripts/dungeon/DungeonController.gd")
	var dc: Node = dc_script.new()
	add_child_autofree(dc)
	dc.current_dungeon_data = DataRegistry.get_dungeon_data("cosmic_rift")
	dc.current_room_type = Enums.RoomType.COMBAT
	var saw_big: bool = false
	var saw_two: bool = false
	for seed_val: int in range(300):
		seed(seed_val)
		var group: Array = dc.pick_combat_enemy_group()
		if group.is_empty():
			continue
		var all_big: bool = true
		for ed: Resource in group:
			if str(ed.id) != "big_cosmic_duck":
				all_big = false
				break
		if all_big:
			saw_big = true
			if group.size() == 2:
				saw_two = true
		if saw_big and saw_two:
			break
	assert_true(saw_big, "Hard 裂け目 COMBAT でビッグが出うる")
	assert_true(saw_two, "Hard 裂け目 COMBAT でビッグ2体が出うる")
	## ボスは据置1体
	dc.current_room_type = Enums.RoomType.BOSS
	var boss: Resource = dc.pick_boss_enemy_data()
	assert_eq(str(boss.id), "big_cosmic_duck")
	var boss_group: Array = dc.pick_combat_enemy_group()
	assert_eq(boss_group.size(), 1)
	assert_eq(str(boss_group[0].id), "big_cosmic_duck")
