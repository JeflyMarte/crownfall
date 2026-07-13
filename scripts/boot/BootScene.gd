extends Node

const _SettingsPrefs := preload("res://scripts/settings/SettingsPrefs.gd")

func _ready() -> void:
	_SettingsPrefs.ensure_loaded()
	SaveManager.load_game()
	DailyMissionSystem.ensure_refreshed()
	EventSystem.ensure_active()
	SceneRouter.change_scene("res://scenes/base/BaseScene.tscn")
