extends Node
## 起動入口: ロードせずタイトルへ。Continue / New Game は TitleScene が担う（P3-INTRO-001）。
## シーンルートは BootScene.tscn の Node と一致させる（Control だと起動不能）。

const TITLE_SCENE := "res://scenes/title/TitleScene.tscn"
const _SettingsPrefs := preload("res://scripts/settings/SettingsPrefs.gd")


func _ready() -> void:
	_SettingsPrefs.ensure_loaded()
	get_tree().change_scene_to_file.call_deferred(TITLE_SCENE)
