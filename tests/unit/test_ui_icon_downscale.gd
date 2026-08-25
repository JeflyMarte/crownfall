extends GutTest

## 軽量化 A: UI アイコン／肖像の最大辺が目標以下であること。


func test_enemy_turn_icons_max_side_256() -> void:
	_assert_dir_max_side("res://assets/ui/combat/enemy_icons", 256)


func test_chr_icons_max_side_512() -> void:
	_assert_dir_max_side("res://assets/ui/chr_icons", 512)


func test_gacha_portraits_max_side_512() -> void:
	_assert_dir_max_side("res://assets/gacha/portraits", 512)


func _assert_dir_max_side(dir_res: String, max_side: int) -> void:
	var abs_dir: String = ProjectSettings.globalize_path(dir_res)
	var da := DirAccess.open(abs_dir)
	assert_not_null(da, "dir exists: %s" % dir_res)
	if da == null:
		return
	var checked: int = 0
	da.list_dir_begin()
	var fname: String = da.get_next()
	while not fname.is_empty():
		if not da.current_is_dir() and fname.ends_with(".png"):
			var img := Image.new()
			var err: Error = img.load(abs_dir.path_join(fname))
			assert_eq(err, OK, "load %s" % fname)
			if err == OK:
				assert_lte(img.get_width(), max_side, "%s width" % fname)
				assert_lte(img.get_height(), max_side, "%s height" % fname)
				checked += 1
		fname = da.get_next()
	da.list_dir_end()
	assert_gt(checked, 0, "at least one png in %s" % dir_res)
