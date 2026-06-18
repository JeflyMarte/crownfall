extends Node

const SAVE_PATH: String = "user://save_data.json"

func save_game() -> void:
	var data: Dictionary = {
		"gold": GameState.gold,
	}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data))
	file.close()
