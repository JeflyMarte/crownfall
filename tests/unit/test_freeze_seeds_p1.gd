extends GutTest

## フリーズ種 P1: pressed 中 rebuild を deferred にする経路の存在確認。


func test_dungeon_select_defers_list_rebuild_from_featured() -> void:
	var packed: PackedScene = load("res://scenes/dungeon/DungeonSelectScene.tscn")
	assert_not_null(packed)
	var scene: Node = packed.instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	## `_set_featured_dungeon` は call_deferred("_build_list") を使う。
	var src: String = FileAccess.get_file_as_string("res://scripts/dungeon/DungeonSelectScene.gd")
	assert_true(src.contains("call_deferred(\"_build_list\")"), "featured should defer list rebuild")


func test_claim_handlers_use_deferred_refresh() -> void:
	var base_src: String = FileAccess.get_file_as_string("res://scripts/base/BaseScene.gd")
	assert_true(
		base_src.contains("call_deferred(\"_refresh_daily_missions\")"),
		"daily claim defers refresh"
	)
	var cmd_src: String = FileAccess.get_file_as_string("res://scripts/commander/CommanderScene.gd")
	assert_true(cmd_src.contains("call_deferred(\"_rebuild_page\")"), "gift claim defers rebuild")
	var guild_src: String = FileAccess.get_file_as_string("res://scripts/guild/GuildScene.gd")
	assert_true(guild_src.contains("call_deferred(\"_refresh_all\")"), "certify defers refresh")


func test_dungeon_defers_combat_visuals_api_exists() -> void:
	var src: String = FileAccess.get_file_as_string("res://scripts/dungeon/DungeonScene.gd")
	assert_true(src.contains("_flush_deferred_combat_room_visuals"), "flush helper present")
	assert_true(src.contains("_defer_combat_room_visuals"), "defer flag present")
	assert_true(src.contains("_flush_deferred_room_art"), "room art flush helper present")
	assert_true(src.contains("_defer_room_art_refresh"), "room art defer flag present")
	assert_true(src.contains("_begin_post_transition_flush"), "split flush pipeline present")
	assert_true(
		src.contains("_run_post_transition_flush_async"),
		"async split flush present"
	)
	## 暗転 defer 時に前部屋の死体を残すと幕明けで一瞬見える。
	var defer_hide_idx: int = src.find("_defer_combat_room_visuals = true")
	assert_gt(defer_hide_idx, 0, "defer assignment present")
	var hide_after: int = src.find("_hide_enemy_sprite()", defer_hide_idx)
	var else_after: int = src.find("else:", defer_hide_idx)
	assert_true(
		hide_after > defer_hide_idx and (else_after < 0 or hide_after < else_after),
		"defer path must hide previous enemy sprites before fade-in"
	)
