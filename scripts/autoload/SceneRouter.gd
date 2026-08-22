extends Node

## 拠点タブ等の画面遷移。よく使う .tscn をキャッシュし、短いローディングで体感ラグを抑える。

const _BgmCatalog := preload("res://scripts/audio/BgmCatalog.gd")

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const SETTINGS_SCENE: String = "res://scenes/settings/SettingsScene.tscn"
const TITLE_SCENE: String = "res://scenes/title/TitleScene.tscn"

## 設定画面の戻る先。Title から開いた場合は Title、それ以外は拠点。
var settings_return_scene: String = HOME_SCENE

## path → PackedScene（一度読んだ拠点系を再利用）。
var _packed_cache: Dictionary = {}
var _warmup_started: bool = false
var _transition_busy: bool = false
var _loading_layer: CanvasLayer = null
var _loading_label: Label = null


func change_scene(path: String) -> void:
	if path.is_empty():
		return
	if _transition_busy:
		return
	_change_scene_async(path)


func open_settings(return_scene: String = HOME_SCENE) -> void:
	settings_return_scene = return_scene if not return_scene.is_empty() else HOME_SCENE
	change_scene(SETTINGS_SCENE)
	## タイトルから開いた設定は hub ではなく title BGM を維持。
	if _is_title_return(settings_return_scene):
		AudioManager.play_bgm(_BgmCatalog.ID_TITLE)


## 拠点入場後に下ナビ先を裏で温める（初回タップのディスク待ちを減らす）。
func warmup_hub_scenes() -> void:
	if _warmup_started:
		return
	_warmup_started = true
	for path: String in hub_warmup_paths():
		_request_threaded(path)


## 任意シーンの裏読み（ダンジョン選択入場時の補完など）。
func request_warmup(path: String) -> void:
	_request_threaded(path)


func hub_warmup_paths() -> PackedStringArray:
	## BottomNavHelper と揃える（循環 preload 回避のため直書き）。
	## ダンジョン／結果は初潜り・初クリアの同期 load 待ちを減らす。
	return PackedStringArray([
		HOME_SCENE,
		"res://scenes/dungeon/DungeonSelectScene.tscn",
		"res://scenes/dungeon/DungeonScene.tscn",
		"res://scenes/result/ResultScene.tscn",
		"res://scenes/equipment/EquipmentScene.tscn",
		"res://scenes/roster/RosterScene.tscn",
		"res://scenes/blacksmith/BlacksmithScene.tscn",
		"res://scenes/equipment/EquipmentCatalogScene.tscn",
		"res://scenes/gacha/GachaScene.tscn",
		"res://scenes/codex/CodexScene.tscn",
		"res://scenes/showcase/ShowcaseScene.tscn",
		"res://scenes/commander/CommanderScene.tscn",
		SETTINGS_SCENE,
	])


func cached_packed(path: String) -> PackedScene:
	return _packed_cache.get(path, null) as PackedScene


func _change_scene_async(path: String) -> void:
	_transition_busy = true
	_apply_scene_bgm(path)
	_show_loading()
	## ローディングを1フレ描画してから同期ロード／切替（真っ暗タップ感を避ける）。
	await get_tree().process_frame
	var packed: PackedScene = _resolve_packed(path)
	if packed == null:
		_hide_loading()
		_transition_busy = false
		push_error("SceneRouter: failed to load %s" % path)
		return
	var err: Error = get_tree().change_scene_to_packed(packed)
	if err != OK:
		push_error("SceneRouter: change_scene_to_packed failed (%s) %s" % [error_string(err), path])
	## 入場側 call_deferred（一覧構築）をローディング中に消化する。
	await get_tree().process_frame
	await get_tree().process_frame
	_hide_loading()
	_transition_busy = false


func _resolve_packed(path: String) -> PackedScene:
	var cached: PackedScene = cached_packed(path)
	if cached != null:
		return cached
	## 裏読み完了分を取り込む。
	if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_LOADED:
		var threaded: Resource = ResourceLoader.load_threaded_get(path)
		if threaded is PackedScene:
			_packed_cache[path] = threaded
			return threaded as PackedScene
	var loaded: Resource = load(path)
	if loaded is PackedScene:
		_packed_cache[path] = loaded
		return loaded as PackedScene
	return null


func _request_threaded(path: String) -> void:
	if path.is_empty() or _packed_cache.has(path):
		return
	if not ResourceLoader.exists(path):
		return
	var status: int = ResourceLoader.load_threaded_get_status(path)
	if (
		status == ResourceLoader.THREAD_LOAD_IN_PROGRESS
		or status == ResourceLoader.THREAD_LOAD_LOADED
	):
		return
	ResourceLoader.load_threaded_request(path, "PackedScene", false)


func _ensure_loading_ui() -> void:
	if _loading_layer != null and is_instance_valid(_loading_layer):
		return
	_loading_layer = CanvasLayer.new()
	_loading_layer.name = "SceneRouterLoading"
	_loading_layer.layer = 128
	_loading_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_loading_layer)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.02, 0.04, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_loading_layer.add_child(dim)
	_loading_label = Label.new()
	_loading_label.text = "読み込み中…"
	_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_loading_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_loading_label.add_theme_font_size_override("font_size", 22)
	_loading_label.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85, 1.0))
	_loading_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loading_layer.add_child(_loading_label)
	_loading_layer.visible = false


func _show_loading() -> void:
	_ensure_loading_ui()
	_loading_layer.visible = true


func _hide_loading() -> void:
	if _loading_layer != null and is_instance_valid(_loading_layer):
		_loading_layer.visible = false


func _apply_scene_bgm(path: String) -> void:
	var bgm_id: String = _BgmCatalog.bgm_for_scene(path)
	if bgm_id.is_empty():
		return
	AudioManager.play_bgm(bgm_id)


func _is_title_return(path: String) -> bool:
	return path == TITLE_SCENE or path.ends_with("TitleScene.tscn")
