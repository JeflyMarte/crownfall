extends GutTest

## dungeon_progress が cleared のみでも update_discovery が落ちないこと。

const DungeonControllerScript = preload("res://scripts/dungeon/DungeonController.gd")

var _saved_progress: Dictionary = {}

func before_each() -> void:
	_saved_progress = GameState.dungeon_progress.duplicate(true)
	GameState.dungeon_progress = {}

func after_each() -> void:
	GameState.dungeon_progress = _saved_progress

func test_update_discovery_with_cleared_only_progress() -> void:
	var dungeon: Resource = DataRegistry.get_dungeon_data("mourngate")
	assert_not_null(dungeon, "mourngate dungeon data")
	GameState.dungeon_progress["mourngate"] = {"cleared": true}
	var ctrl: Node = DungeonControllerScript.new()
	add_child_autofree(ctrl)
	ctrl.current_dungeon_data = dungeon
	ctrl.update_discovery(0.0)
	var prog: Dictionary = GameState.dungeon_progress.get("mourngate", {})
	assert_true(prog.has("discovery"), "discovery key filled")
	assert_gt(float(prog.get("discovery", -1.0)), 0.0)
	assert_true(bool(prog.get("cleared", false)), "cleared preserved")
