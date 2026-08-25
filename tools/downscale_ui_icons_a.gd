extends SceneTree

## 軽量化 A: UI アイコン／肖像を表示近傍へ縮小（ニアレスト）。
## 用法: godot4 --headless --path . -s tools/downscale_ui_icons_a.gd
##
## 対象と目標辺:
## - assets/ui/combat/enemy_icons → 256（表示〜64）
## - assets/ui/chr_icons → 512（表示〜200–280）
## - assets/gacha/portraits → 512（バナー／リビール）
## 既に目標以下の画像は触らない。戦闘スプライト／BG は対象外。

const JOBS: Array[Dictionary] = [
	{"dir": "res://assets/ui/combat/enemy_icons", "max_side": 256},
	{"dir": "res://assets/ui/chr_icons", "max_side": 512},
	{"dir": "res://assets/gacha/portraits", "max_side": 512},
]


func _init() -> void:
	var resized: int = 0
	var skipped: int = 0
	var failed: int = 0
	var bytes_before: int = 0
	var bytes_after: int = 0
	for job: Dictionary in JOBS:
		var dir_path: String = str(job["dir"])
		var max_side: int = int(job["max_side"])
		var abs_dir: String = ProjectSettings.globalize_path(dir_path)
		var da := DirAccess.open(abs_dir)
		if da == null:
			push_error("missing dir: %s" % abs_dir)
			failed += 1
			continue
		da.list_dir_begin()
		var fname: String = da.get_next()
		while not fname.is_empty():
			if not da.current_is_dir() and fname.ends_with(".png") and not fname.ends_with(".import"):
				var full: String = abs_dir.path_join(fname)
				var before_sz: int = _file_size(full)
				var result: String = _resize_png(full, max_side)
				match result:
					"resized":
						resized += 1
						bytes_before += before_sz
						bytes_after += _file_size(full)
						print("RESIZED %s" % full)
					"skip":
						skipped += 1
					_:
						failed += 1
						push_error("FAIL %s: %s" % [full, result])
			fname = da.get_next()
		da.list_dir_end()
	print(
		"DONE resized=%d skipped=%d failed=%d before_mb=%.2f after_mb=%.2f"
		% [
			resized,
			skipped,
			failed,
			float(bytes_before) / 1048576.0,
			float(bytes_after) / 1048576.0,
		]
	)
	quit(1 if failed > 0 else 0)


func _file_size(path: String) -> int:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return 0
	var n: int = f.get_length()
	f.close()
	return n


func _resize_png(abs_path: String, max_side: int) -> String:
	var img := Image.new()
	var err: Error = img.load(abs_path)
	if err != OK:
		return "load_error_%d" % err
	var w: int = img.get_width()
	var h: int = img.get_height()
	if w <= 0 or h <= 0:
		return "bad_size"
	if maxi(w, h) <= max_side:
		return "skip"
	var scale: float = float(max_side) / float(maxi(w, h))
	var nw: int = maxi(1, int(round(float(w) * scale)))
	var nh: int = maxi(1, int(round(float(h) * scale)))
	## ドット絵／UI アイコンはニアレスト（ぼかし防止）。
	img.resize(nw, nh, Image.INTERPOLATE_NEAREST)
	err = img.save_png(abs_path)
	if err != OK:
		return "save_error_%d" % err
	return "resized"
