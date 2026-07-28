extends GutTest

## パーティ画面: 上段は非 Scroll・MainScroll のみ。rebuild 後も ScrollTouch が効く。


func test_roster_active_party_host_is_not_scroll_container() -> void:
	var packed: PackedScene = load("res://scenes/roster/RosterScene.tscn")
	assert_not_null(packed)
	var scene: Node = packed.instantiate()
	add_child_autofree(scene)
	var host: Node = scene.get_node_or_null("MainScroll/MainVBox/ActivePartyHost")
	assert_not_null(host)
	assert_false(host is ScrollContainer, "上段パーティは ScrollContainer にしない")
	assert_true(host is MarginContainer or host is Control)
	var main: Node = scene.get_node_or_null("MainScroll")
	assert_true(main is ScrollContainer, "MainScroll が縦スクロール本体")


func test_roster_rebuild_reapplies_scroll_touch_pass() -> void:
	GameState.reset_for_new_game()
	GameState.seed_all_starters_unlocked()
	var packed: PackedScene = load("res://scenes/roster/RosterScene.tscn")
	assert_not_null(packed)
	var scene: Node = packed.instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	var grid: GridContainer = scene.get_node_or_null("MainScroll/MainVBox/RosterGrid") as GridContainer
	assert_not_null(grid)
	assert_gt(grid.get_child_count(), 0, "一覧カードが生成されている")
	var found_pass_btn := false
	for card in grid.get_children():
		if card == null:
			continue
		for child in card.find_children("*", "Button", true, false):
			var btn: Button = child as Button
			if btn == null:
				continue
			assert_eq(
				btn.mouse_filter,
				Control.MOUSE_FILTER_PASS,
				"一覧タップ Button は ScrollTouch で PASS"
			)
			found_pass_btn = true
			break
		if found_pass_btn:
			break
	assert_true(found_pass_btn, "一覧にタップ Button がある")


func test_scroll_touch_hooks_grid_additions() -> void:
	var scroll := ScrollContainer.new()
	add_child_autofree(scroll)
	var content := VBoxContainer.new()
	scroll.add_child(content)
	var grid := GridContainer.new()
	content.add_child(grid)
	ScrollTouchHelper.enable(scroll, false)
	var btn := Button.new()
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	grid.add_child(btn)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(btn.mouse_filter, Control.MOUSE_FILTER_PASS, "深い Grid 追加の Button も PASS 化")
