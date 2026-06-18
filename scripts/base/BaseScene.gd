extends Control

func _ready() -> void:
	$VBoxContainer/ButtonDungeon.pressed.connect(_on_dungeon_button_pressed)

func _on_dungeon_button_pressed() -> void:
	print("[BaseScene] ダンジョンへボタン押下")
