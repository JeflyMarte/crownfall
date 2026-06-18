extends Control

func _ready() -> void:
	$VBoxContainer/ButtonFinish.pressed.connect(_on_finish_button_pressed)
	$DungeonController.start_dungeon("res://resources/dungeons/royal_ruins.tres")
	_update_room_label()

func _update_room_label() -> void:
	var idx: int = $DungeonController.current_room_index + 1
	var total: int = $DungeonController.current_dungeon_data.room_count
	$VBoxContainer/LabelRoom.text = "部屋: %d / %d" % [idx, total]

func _on_finish_button_pressed() -> void:
	SceneRouter.change_scene("res://scenes/result/ResultScene.tscn")
