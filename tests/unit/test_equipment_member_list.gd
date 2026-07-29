extends GutTest


func test_equipment_scene_has_member_list_button() -> void:
	var packed: PackedScene = load("res://scenes/equipment/EquipmentScene.tscn")
	assert_not_null(packed)
	var scene: Node = packed.instantiate()
	add_child_autofree(scene)
	var btn: Node = scene.get_node_or_null(
		"VBoxContainer/CharacterCard/CardRow/InfoBox/NameRow/BtnMemberList"
	)
	assert_not_null(btn)
	assert_true(btn is Button)
	assert_eq((btn as Button).text, "一覧")
	var name_lbl: Node = scene.get_node_or_null(
		"VBoxContainer/CharacterCard/CardRow/InfoBox/NameRow/LabelName"
	)
	assert_not_null(name_lbl)


func test_member_list_sheet_opens_and_picks() -> void:
	GameState.reset_for_new_game()
	GameState.seed_all_starters_unlocked()
	var packed: PackedScene = load("res://scenes/equipment/EquipmentScene.tscn")
	assert_not_null(packed)
	var scene: Node = packed.instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	assert_true(scene.has_method("_open_member_list_sheet"))
	scene.call("_open_member_list_sheet")
	await get_tree().process_frame
	var sheet: Node = scene.get_node_or_null("MemberListSheet")
	assert_not_null(sheet, "一覧シートが表示される")
	var members: Array = scene.call("_get_view_members")
	assert_gt(members.size(), 1)
	var pick_idx: int = mini(1, members.size() - 1)
	scene.call("_on_member_list_pick", pick_idx)
	await get_tree().process_frame
	assert_eq(int(scene.get("_selected_member_index")), pick_idx)
	assert_null(scene.get_node_or_null("MemberListSheet"), "選択後にシートが閉じる")
