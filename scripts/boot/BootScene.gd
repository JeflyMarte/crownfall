extends Node

func _ready() -> void:
	SaveManager.load_game()
	SceneRouter.change_scene("res://scenes/base/BaseScene.tscn")
