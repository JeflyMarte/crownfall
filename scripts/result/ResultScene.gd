extends Control

func _ready() -> void:
	$VBoxContainer/ButtonBack.pressed.connect(_on_back_button_pressed)

func _on_back_button_pressed() -> void:
	SceneRouter.change_scene("res://scenes/base/BaseScene.tscn")
