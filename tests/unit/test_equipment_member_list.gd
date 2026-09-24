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


func test_long_member_name_caps_label_min_width() -> void:
	## 長い名前でも名前 Label の min 幅が Info 取り分を超えて CardRow を押し広げない。
	GameState.reset_for_new_game()
	GameState.seed_all_starters_unlocked()
	var packed: PackedScene = load("res://scenes/equipment/EquipmentScene.tscn")
	assert_not_null(packed)
	var scene: Node = packed.instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	var members: Array = scene.call("_get_view_members")
	assert_gt(members.size(), 0)
	var target: Resource = members[0]
	target.display_name = "ヴァルデン超長い名前テスト"
	scene.set("_selected_member_index", 0)
	scene.call("_update_character_card")
	await get_tree().process_frame
	await get_tree().process_frame
	var name_lbl: Label = scene.get_node(
		"VBoxContainer/CharacterCard/CardRow/InfoBox/NameRow/LabelName"
	) as Label
	assert_not_null(name_lbl)
	var avail: float = float(scene.call("_name_label_available_width"))
	assert_gt(avail, 64.0)
	## fit 後の min 幅は avail 以下（EXPAND+ellipsis 時は 0）。
	assert_lte(name_lbl.custom_minimum_size.x, avail + 1.0)
	var card_row: Control = scene.get_node(
		"VBoxContainer/CharacterCard/CardRow"
	) as Control
	assert_not_null(card_row)
	## 名前全文幅で CardRow min が viewport を大幅超過しないこと。
	assert_lte(card_row.get_combined_minimum_size().x, 760.0)
	var src: String = FileAccess.get_file_as_string(
		"res://scripts/equipment/EquipmentScene.gd"
	)
	assert_true(
		src.find("画面幅（EquipmentScene / viewport）") >= 0
		or src.find("NameRow／InfoBox／CardRow の size は名前") >= 0
	)
