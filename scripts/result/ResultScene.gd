extends Control

func _ready() -> void:
	$VBoxContainer/ButtonBack.pressed.connect(_on_back_button_pressed)

func _on_back_button_pressed() -> void:
	print("[ResultScene] 拠点へ戻るボタン押下")
