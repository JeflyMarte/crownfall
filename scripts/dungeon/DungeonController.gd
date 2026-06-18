extends Node

var current_dungeon_data: Resource = null
var current_room_index: int = 0

func start_dungeon(path: String) -> void:
	current_dungeon_data = load(path)
	current_room_index = 0
