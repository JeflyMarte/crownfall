extends Node

const ROOM_SEQUENCE: Array[int] = [
	Enums.RoomType.START,
	Enums.RoomType.COMBAT,
	Enums.RoomType.EVENT,
	Enums.RoomType.TREASURE,
	Enums.RoomType.ELITE,
	Enums.RoomType.EVENT,
	Enums.RoomType.COMBAT,
	Enums.RoomType.MID_BOSS,
	Enums.RoomType.BOSS,
	Enums.RoomType.EXIT,
]

var current_dungeon_data: Resource = null
var current_room_index: int = 0
var current_room_type: int = Enums.RoomType.START
var is_completed: bool = false

func start_dungeon(path: String) -> void:
	current_dungeon_data = load(path)
	current_room_index = 0
	current_room_type = ROOM_SEQUENCE[0]
	is_completed = false

func advance_room() -> void:
	current_room_index += 1
	if current_room_index >= current_dungeon_data.room_count:
		is_completed = true
		return
	current_room_type = ROOM_SEQUENCE[current_room_index]
