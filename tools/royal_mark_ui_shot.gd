extends Node

## 王痕育成 UI スクショ用（プロジェクト autoload 付きで実行）。

const _DebugFullUnlock := preload("res://scripts/debug/DebugFullUnlock.gd")
const SCENE: String = "res://scenes/royal_mark/RoyalMarkScene.tscn"


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_DebugFullUnlock.apply()
	GameState.royal_mark_shards = 0
	GameState.royal_mark_ranks = {}
	SaveManager.save_game()
	var packed: PackedScene = load(SCENE) as PackedScene
	var scene: Control = packed.instantiate() as Control
	get_tree().root.add_child(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	var img: Image = get_viewport().get_texture().get_image()
	var out: String = "res://review/royal_mark_ui_rebuild/shot_rank0.png"
	if img != null:
		img.save_png(out)
		print("SHOT_OK ", out)
	else:
		print("SHOT_FAIL")
	get_tree().quit()
