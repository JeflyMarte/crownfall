extends SceneTree

## UI 監査ツール（P3-UI3-001）。主要画面を順にロードしてスクリーンショットを保存する。
## 実行: godot --path . -s tools/ui_audit.gd  （ヘッドレス不可・レンダリング必須）
## 出力: user://ui_audit/*.png（起動ログに絶対パスを表示）

const SCENES: Array = [
	["home", "res://scenes/base/BaseScene.tscn"],
	["dungeon_select", "res://scenes/dungeon/DungeonSelectScene.tscn"],
	["equipment", "res://scenes/equipment/EquipmentScene.tscn"],
	["roster", "res://scenes/roster/RosterScene.tscn"],
	["blacksmith", "res://scenes/blacksmith/BlacksmithScene.tscn"],
	["gacha", "res://scenes/gacha/GachaScene.tscn"],
	["codex", "res://scenes/codex/CodexScene.tscn"],
]

const WAIT_FRAMES: int = 12

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var out_dir: String = OS.get_user_data_dir() + "/ui_audit"
	DirAccess.make_dir_recursive_absolute(out_dir)
	print("[ui_audit] output: ", out_dir)
	for pair in SCENES:
		var tag: String = pair[0]
		var path: String = pair[1]
		if not ResourceLoader.exists(path):
			print("[ui_audit] skip (missing): ", path)
			continue
		var err: int = change_scene_to_file(path)
		if err != OK:
			print("[ui_audit] load error %d: %s" % [err, path])
			continue
		for i in WAIT_FRAMES:
			await process_frame
		var img: Image = root.get_viewport().get_texture().get_image()
		var file: String = out_dir + "/%s.png" % tag
		img.save_png(file)
		print("[ui_audit] saved: ", file)
	print("[ui_audit] done")
	quit(0)
