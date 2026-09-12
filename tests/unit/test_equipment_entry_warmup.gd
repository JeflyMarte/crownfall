extends GutTest

## キャラ画面入場の A/B/C 対策回帰。


func test_hub_warmup_prioritizes_equipment_scene() -> void:
	var paths: PackedStringArray = SceneRouter.hub_warmup_paths()
	assert_gt(paths.size(), 2, "warmup paths exist")
	assert_eq(paths[0], SceneRouter.HOME_SCENE, "home first")
	assert_eq(
		paths[1],
		"res://scenes/equipment/EquipmentScene.tscn",
		"equipment is warmed early"
	)


func test_idle_prebaked_folders_skip_runtime_stabilize() -> void:
	const _ChrIdlePortrait := preload("res://scripts/ui/ChrIdlePortrait.gd")
	assert_true(_ChrIdlePortrait.PREBAKED_IDLE_FOLDERS.has("beast_tamer"))
	assert_true(_ChrIdlePortrait.PREBAKED_IDLE_FOLDERS.has("vanguard"))
	_ChrIdlePortrait._prepared_idle_cache.clear()
	var started: int = Time.get_ticks_usec()
	var textures: Array = _ChrIdlePortrait.load_idle_textures("vanguard")
	var elapsed_ms: float = float(Time.get_ticks_usec() - started) / 1000.0
	assert_eq(textures.size(), 9, "vanguard idle frames")
	## 焼き済みなら get_image 正規化をしないのでデスクトップでも十分速い。
	assert_lt(elapsed_ms, 50.0, "prebaked idle load should stay light (%.1f ms)" % elapsed_ms)


func test_equipment_entry_defers_inventory_grid() -> void:
	GameState.reset_for_new_game()
	GameState.seed_all_starters_unlocked()
	var packed: PackedScene = load("res://scenes/equipment/EquipmentScene.tscn")
	var scene: Control = packed.instantiate() as Control
	add_child_autofree(scene)
	## _ready の deferred refresh 直後: 所持はまだ pending。
	await get_tree().process_frame
	assert_true(
		bool(scene.get("_inventory_entry_pending")),
		"entry schedules inventory delay"
	)
	## 遅延後に一覧が載る。
	await get_tree().create_timer(0.2).timeout
	await get_tree().process_frame
	assert_false(
		bool(scene.get("_inventory_entry_pending")),
		"entry inventory flush completed"
	)
