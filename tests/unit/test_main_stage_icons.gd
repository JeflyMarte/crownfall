extends GutTest

## ③〜⑤の章アイコンが Whisperwood 複製ではなく、パス配線＋実ファイルを持つこと。


func test_main_stage_icons_exist_and_mapped() -> void:
	var stages: Array[String] = [
		"mistfen_3_1", "mistfen_3_2", "mistfen_3_3", "mistfen_3_4", "mistfen_3_5",
		"blackshore_4_1", "blackshore_4_2", "blackshore_4_3", "blackshore_4_4", "blackshore_4_5",
		"frostridge_5_1", "frostridge_5_2", "frostridge_5_3", "frostridge_5_4", "frostridge_5_5",
	]
	for stage_id in stages:
		var path: String = IconPaths.stage_icon_path(stage_id)
		assert_ne(path, "", "stage icon path missing: %s" % stage_id)
		assert_true(path.begins_with("res://"), path)
		assert_true(FileAccess.file_exists(path), "missing icon file: %s" % path)


func test_post_whisperwood_stage_icons_not_copied_from_whisperwood() -> void:
	## ③〜⑤が Whisperwood 2-1..2-5 のバイト複製でないこと（過去の仮置き事故の再発防止）。
	var whisper_md5: Dictionary = {}
	for i in range(1, 6):
		var wp: String = "res://assets/dungeon/whisperwood/stages/ICO_DG_Whisperwood_2_%d.png" % i
		whisper_md5[FileAccess.get_md5(wp)] = wp

	var pairs: Array = [
		["res://assets/dungeon/mistfen/stages/ICO_DG_Mistfen_3_%d.png", "mistfen"],
		["res://assets/dungeon/blackshore/stages/ICO_DG_Blackshore_4_%d.png", "blackshore"],
		["res://assets/dungeon/frostridge/stages/ICO_DG_Frostridge_5_%d.png", "frostridge"],
	]
	var seen: Dictionary = {}
	for pair in pairs:
		var tmpl: String = pair[0]
		var biome: String = pair[1]
		for i in range(1, 6):
			var path: String = tmpl % i
			assert_true(FileAccess.file_exists(path), path)
			var md5: String = FileAccess.get_md5(path)
			assert_false(
				whisper_md5.has(md5),
				"%s stage %d still matches whisperwood %s" % [biome, i, whisper_md5.get(md5, "")]
			)
			assert_false(seen.has(md5), "duplicate icon bytes: %s vs %s" % [path, seen.get(md5, "")])
			seen[md5] = path
