extends Node

## シーン切替・ウィンドウサイズ変更時に SafeAreaHelper を再適用する。

var _pending: bool = false


func _ready() -> void:
	var win: Window = get_window()
	if win != null:
		win.size_changed.connect(_request_reapply)
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_reapply")


func _on_node_added(node: Node) -> void:
	if node == get_tree().current_scene:
		_request_reapply()


func _request_reapply() -> void:
	if _pending:
		return
	_pending = true
	call_deferred("_reapply")


func _reapply() -> void:
	_pending = false
	var scene: Node = get_tree().current_scene
	if scene == null:
		return
	SafeAreaHelper.apply_scene_chrome(scene)
