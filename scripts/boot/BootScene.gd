extends Node
## 起動入口: ロードせずタイトルへ。Continue / New Game は TitleScene が担う（P3-INTRO-001）。
## シーンルートは BootScene.tscn の Node と一致させる（Control だと起動不能）。

const TITLE_SCENE := "res://scenes/title/TitleScene.tscn"


func _ready() -> void:
	get_tree().change_scene_to_file.call_deferred(TITLE_SCENE)
