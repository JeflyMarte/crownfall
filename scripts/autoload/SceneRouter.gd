extends Node

const _BgmCatalog := preload("res://scripts/audio/BgmCatalog.gd")

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const SETTINGS_SCENE: String = "res://scenes/settings/SettingsScene.tscn"
const TITLE_SCENE: String = "res://scenes/title/TitleScene.tscn"

## 設定画面の戻る先。Title から開いた場合は Title、それ以外は拠点。
var settings_return_scene: String = HOME_SCENE


func change_scene(path: String) -> void:
	_apply_scene_bgm(path)
	get_tree().change_scene_to_file.call_deferred(path)


func open_settings(return_scene: String = HOME_SCENE) -> void:
	settings_return_scene = return_scene if not return_scene.is_empty() else HOME_SCENE
	change_scene(SETTINGS_SCENE)
	## タイトルから開いた設定は hub ではなく title BGM を維持。
	if _is_title_return(settings_return_scene):
		AudioManager.play_bgm(_BgmCatalog.ID_TITLE)


func _apply_scene_bgm(path: String) -> void:
	var bgm_id: String = _BgmCatalog.bgm_for_scene(path)
	if bgm_id.is_empty():
		return
	AudioManager.play_bgm(bgm_id)


func _is_title_return(path: String) -> bool:
	return path == TITLE_SCENE or path.ends_with("TitleScene.tscn")
