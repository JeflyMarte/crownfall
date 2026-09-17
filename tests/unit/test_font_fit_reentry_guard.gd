extends GutTest
## font fit 再入ガード（Dungeon header と同型の即死予防）。


func test_fit_label_font_to_width_blocks_resized_reentry() -> void:
	var label := Label.new()
	add_child_autofree(label)
	label.text = "0-0 訓練用模擬水路【潮脈王ネレイオン・デプス】降臨"
	label.size = Vector2(64, 24)
	var depth: Array = [0]
	var max_depth: Array = [0]
	var handler := func() -> void:
		depth[0] = int(depth[0]) + 1
		max_depth[0] = maxi(int(max_depth[0]), int(depth[0]))
		UiTypography.fit_label_font_to_width(label, UiTypography.SIZE_CAPTION, 11, 64.0)
		depth[0] = int(depth[0]) - 1
	label.resized.connect(handler)
	handler.call()
	assert_lt(int(max_depth[0]), 8, "fit_label_font_to_width must guard resized reentry")
	assert_false(bool(label.get_meta("_cf_fitting_font", false)))


func test_starter_pick_has_no_confirmation_dialog() -> void:
	var src: String = FileAccess.get_file_as_string("res://scripts/roster/StarterPickScene.gd")
	assert_false(src.contains("ConfirmationDialog.new("), "StarterPick must use Control overlay")
	assert_true(src.contains("ConfirmOverlay"))
	assert_true(src.contains("_show_confirm_overlay"))
