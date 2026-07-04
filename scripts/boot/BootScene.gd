extends Node

func _ready() -> void:
	SaveManager.load_game()
	DailyMissionSystem.ensure_refreshed()
	EventSystem.ensure_active()
	SceneRouter.change_scene("res://scenes/base/BaseScene.tscn")
