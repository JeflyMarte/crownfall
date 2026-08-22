extends GutTest

## フリーズ種 P2: AcceptDialog をダンジョン選択の編成空通知から撤去。


func test_dungeon_select_party_empty_uses_control_overlay() -> void:
	var src: String = FileAccess.get_file_as_string("res://scripts/dungeon/DungeonSelectScene.gd")
	assert_false(src.contains("AcceptDialog.new()"), "no AcceptDialog in dungeon select")
	assert_true(src.contains("PartyEmptyOverlay"), "control overlay present")


func test_settings_redeem_uses_control_overlay() -> void:
	var src: String = FileAccess.get_file_as_string("res://scripts/settings/SettingsScene.gd")
	assert_false(src.contains("AcceptDialog.new()"), "no AcceptDialog in settings redeem")
	assert_true(src.contains("RedeemResultOverlay"), "control overlay present")


func test_dungeon_select_party_empty_overlay_shows() -> void:
	var packed: PackedScene = load("res://scenes/dungeon/DungeonSelectScene.tscn")
	assert_not_null(packed)
	var scene: Node = packed.instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	scene._show_party_empty_notice()
	assert_not_null(scene._party_empty_overlay)
	assert_true(scene._party_empty_overlay.visible)
	scene._hide_party_empty_notice()
	assert_false(scene._party_empty_overlay.visible)
