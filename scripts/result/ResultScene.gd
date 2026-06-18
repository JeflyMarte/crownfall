extends Control

func _ready() -> void:
	$VBoxContainer/ButtonBack.pressed.connect(_on_back_button_pressed)
	$VBoxContainer/LabelReward.text = "獲得報酬: EXP:%d Gold:%d" % [
		GameState.last_run_exp_reward,
		GameState.last_run_gold_reward,
	]

func _on_back_button_pressed() -> void:
	GameState.gold += GameState.last_run_gold_reward
	SceneRouter.change_scene("res://scenes/base/BaseScene.tscn")
