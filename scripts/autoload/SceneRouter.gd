extends Node

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const SETTINGS_SCENE: String = "res://scenes/settings/SettingsScene.tscn"
const TITLE_SCENE: String = "res://scenes/title/TitleScene.tscn"

## 設定画面の戻る先。Title から開いた場合は Title、それ以外は拠点。
var settings_return_scene: String = HOME_SCENE


func change_scene(path: String) -> void:
	get_tree().change_scene_to_file.call_deferred(path)


func open_settings(return_scene: String = HOME_SCENE) -> void:
	settings_return_scene = return_scene if not return_scene.is_empty() else HOME_SCENE
	change_scene(SETTINGS_SCENE)
