extends GutTest

## パッシブ等の深い VBox 追加でも ScrollTouch が再 PASS 化する。


func test_scroll_touch_hooks_nested_list_additions() -> void:
	var scroll := ScrollContainer.new()
	add_child_autofree(scroll)
	var content := VBoxContainer.new()
	content.name = "Content"
	scroll.add_child(content)
	var list := VBoxContainer.new()
	list.name = "List"
	content.add_child(list)
	ScrollTouchHelper.enable(scroll)
	var btn := Button.new()
	btn.text = "equip"
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	list.add_child(btn)
	## deferred refresh
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(btn.mouse_filter, Control.MOUSE_FILTER_PASS, "深い List 追加の Button も PASS 化")


func test_passive_tab_is_scroll_container() -> void:
	var packed: PackedScene = load("res://scenes/equipment/EquipmentScene.tscn")
	assert_not_null(packed)
	var scene: Node = packed.instantiate()
	add_child_autofree(scene)
	var tab: Node = scene.get_node_or_null("VBoxContainer/TabContainer/TabPassive")
	assert_true(tab is ScrollContainer)
	var list: Node = scene.get_node_or_null(
		"VBoxContainer/TabContainer/TabPassive/PassiveContent/PassiveList"
	)
	assert_not_null(list)
