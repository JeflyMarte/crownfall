extends Control

func _ready() -> void:
	$VBoxContainer/ButtonFinish.pressed.connect(_on_finish_button_pressed)

func _on_finish_button_pressed() -> void:
	SceneRouter.change_scene("res://scenes/result/ResultScene.tscn")
