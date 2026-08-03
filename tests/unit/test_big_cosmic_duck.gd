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
