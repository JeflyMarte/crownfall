@tool
extends EditorScript

## Godot の外部スクリプトエディタを Cursor に設定する（1 回実行）。
## 実行: Godot で本ファイルを開き、メニュー File → Run。

const CURSOR_CANDIDATES: Array[String] = [
	"/Applications/Cursor.app/Contents/MacOS/Cursor",
	"/usr/local/bin/cursor",
]

const EXEC_FLAGS: String = "{project} --goto {file}:{line}:{col}"


func _run() -> void:
	var settings := get_editor_interface().get_editor_settings()
	var exec_path := _find_cursor_executable()
	if exec_path.is_empty():
		push_error("Cursor が見つかりません。/Applications/Cursor.app をインストールしてください。")
		return

	settings.set_setting("text_editor/external/use_external_editor", true)
	settings.set_setting("text_editor/external/exec_path", exec_path)
	settings.set_setting("text_editor/external/exec_flags", EXEC_FLAGS)
	print("外部エディタを Cursor に設定しました: ", exec_path)
	print("Exec Flags: ", EXEC_FLAGS)


func _find_cursor_executable() -> String:
	for path in CURSOR_CANDIDATES:
		if FileAccess.file_exists(path):
			return path
	var output: Array = []
	var exit_code := OS.execute("which", ["cursor"], output, true)
	if exit_code == 0 and not output.is_empty():
		return String(output[0]).strip_edges()
	return ""
