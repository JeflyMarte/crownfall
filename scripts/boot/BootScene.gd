extends Node

func _ready() -> void:
	SaveManager.load_game()
	DailyMissionSystem.ensure_refreshed()
	SceneRouter.change_scene("res://scenes/base/BaseScene.tscn")
