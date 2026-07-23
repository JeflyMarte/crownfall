extends SceneTree

## 高さ揺れが重度の Idle PNG を足元固定で焼き直す（モバイルでも拡縮しないため）。
## Usage: godot --headless --path . -s tools/bake_chr_idle_stabilize.gd

const _ChrIdlePortrait = preload("res://scripts/ui/ChrIdlePortrait.gd")

## 焼き対象（重度ズーム揺れ）。軽微（vanguard 等）は間引き側に任せ、PNG は触らない。
const FOLDERS: PackedStringArray = ["beast_tamer"]


func _init() -> void:
	var failed: int = 0
	for folder_id in FOLDERS:
		if not _bake_folder(folder_id):
			failed += 1
	if failed > 0:
		push_error("bake_chr_idle_stabilize: %d folder(s) failed" % failed)
		quit(1)
		return
	print("bake_chr_idle_stabilize: OK")
	quit(0)


func _bake_folder(folder_id: String) -> bool:
	var paths: PackedStringArray = _ChrIdlePortrait.idle_frame_paths(folder_id)
	if paths.is_empty():
		push_error("no idle frames: %s" % folder_id)
		return false
	var raw: Array[Texture2D] = []
	for path in paths:
		var tex: Texture2D = load(path) as Texture2D
		if tex == null:
			push_error("load failed: %s" % path)
			return false
		raw.append(tex)
	## デスクトップ headless で正規化を走らせ、結果を PNG に書き戻す。
	var prepared: Array[Texture2D] = _ChrIdlePortrait._prepare_idle_textures(raw)
	if prepared.size() != raw.size():
		push_error(
			"%s: prepare changed frame count %d → %d (expected stabilize, not filter)"
			% [folder_id, raw.size(), prepared.size()]
		)
		return false
	for i in prepared.size():
		var img: Image = prepared[i].get_image()
		if img == null or img.get_width() <= 0:
			push_error("prepared image empty: %s idle_%d" % [folder_id, i])
			return false
		if img.is_compressed():
			img.decompress()
		var abs_path: String = ProjectSettings.globalize_path(paths[i])
		var err: Error = img.save_png(abs_path)
		if err != OK:
			push_error("save_png failed (%s): %s" % [error_string(err), abs_path])
			return false
		print("baked %s" % paths[i])
	return true
