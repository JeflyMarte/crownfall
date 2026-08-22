extends GutTest
## SceneRouter — 拠点キャッシュ／warmup パス。


func test_hub_warmup_paths_exist() -> void:
	var paths: PackedStringArray = SceneRouter.hub_warmup_paths()
	assert_gt(paths.size(), 0, "warmup paths")
	for path: String in paths:
		assert_true(ResourceLoader.exists(path), path)
	assert_true(
		paths.has("res://scenes/dungeon/DungeonScene.tscn"),
		"dungeon scene warmed for first dive"
	)
	assert_true(
		paths.has("res://scenes/result/ResultScene.tscn"),
		"result scene warmed"
	)


func test_warmup_fills_cache_for_home() -> void:
	var home: String = SceneRouter.HOME_SCENE
	assert_true(ResourceLoader.exists(home), home)
	## 直接 resolve 相当: load して cache に載ることを確認。
	var packed: PackedScene = load(home) as PackedScene
	assert_not_null(packed, home)
	SceneRouter._packed_cache[home] = packed
	assert_not_null(SceneRouter.cached_packed(home), "cached home")
	SceneRouter.warmup_hub_scenes()
	assert_true(SceneRouter._warmup_started)


func test_change_scene_rejects_empty() -> void:
	SceneRouter._transition_busy = false
	SceneRouter.change_scene("")
	assert_false(SceneRouter._transition_busy)
