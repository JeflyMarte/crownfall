extends GutTest

## ダンジョン選択: フル幅リストタップは PASS（畳みバナー上スクロール用）


func test_scroll_list_tap_uses_pass_not_keep_stop() -> void:
	var packed: PackedScene = load("res://scenes/dungeon/DungeonSelectScene.tscn")
	assert_not_null(packed)
	var scene: Control = packed.instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	var list: VBoxContainer = scene.get_node("MainColumn/ScrollList/ListVBox") as VBoxContainer
	assert_not_null(list)
	var found_pass_header: bool = false
	for child in list.get_children():
		var btn: BaseButton = _find_fullrect_button(child)
		if btn == null:
			continue
		## 畳みバナー／章のフル幅は keep_stop なし・PASS。
		assert_false(
			bool(btn.get_meta(&"_cf_keep_mouse_stop", false)),
			"list full-bleed button must not keep mouse stop"
		)
		assert_eq(btn.mouse_filter, Control.MOUSE_FILTER_PASS)
		found_pass_header = true
		break
	assert_true(found_pass_header, "expected at least one list full-bleed button")
	var tier_btn: Button = scene.get_node("MainColumn/TabsRow/ButtonNormal") as Button
	assert_not_null(tier_btn)
	assert_true(bool(tier_btn.get_meta(&"_cf_keep_mouse_stop", false)))
	assert_eq(tier_btn.mouse_filter, Control.MOUSE_FILTER_STOP)


func _find_fullrect_button(node: Node) -> BaseButton:
	if node is BaseButton:
		var b: BaseButton = node as BaseButton
		## フル幅オーバーレイ相当: anchors full rect または親いっぱい。
		if b.anchor_right >= 0.99 and b.anchor_bottom >= 0.99:
			return b
	for child in node.get_children():
		var found: BaseButton = _find_fullrect_button(child)
		if found != null:
			return found
	return null
