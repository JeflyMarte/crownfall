extends Control

func _ready() -> void:
	$VBoxContainer/ButtonDungeon.pressed.connect(_on_dungeon_button_pressed)
	_update_party_display()

func _update_party_display() -> void:
	$VBoxContainer/LabelMember0.text = GameState.party_members[0].display_name
	$VBoxContainer/LabelMember1.text = GameState.party_members[1].display_name
	$VBoxContainer/LabelMember2.text = GameState.party_members[2].display_name

func _on_dungeon_button_pressed() -> void:
	SceneRouter.change_scene("res://scenes/dungeon/DungeonScene.tscn")
