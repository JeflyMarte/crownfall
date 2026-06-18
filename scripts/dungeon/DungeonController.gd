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
var current_exploration_policy: int = Enums.ExplorationPolicy.EXPLORE
var run_exp_reward: int = 0
var run_gold_reward: int = 0

func start_dungeon(path: String) -> void:
	current_dungeon_data = load(path)
	current_room_index = 0
	current_room_type = ROOM_SEQUENCE[0]
	is_completed = false
	current_exploration_policy = Enums.ExplorationPolicy.EXPLORE
	run_exp_reward = 0
	run_gold_reward = 0

func set_policy(policy: int) -> void:
	current_exploration_policy = policy

func advance_room() -> void:
	current_room_index += 1
	if current_room_index >= current_dungeon_data.room_count:
		is_completed = true
		return
	current_room_type = ROOM_SEQUENCE[current_room_index]

func is_combat_room() -> bool:
	return current_room_type in [
		Enums.RoomType.COMBAT,
		Enums.RoomType.ELITE,
		Enums.RoomType.MID_BOSS,
		Enums.RoomType.BOSS,
	]

func accumulate_rewards(exp: int, gold: int) -> void:
	run_exp_reward += exp
	run_gold_reward += gold

func pick_enemy_data() -> Resource:
	if current_dungeon_data == null:
		return null
	var pool: Array = current_dungeon_data.enemy_pool
	if pool.is_empty():
		return null
	var enemy_id: String = pool[randi() % pool.size()]
	return load("res://resources/enemies/" + enemy_id + ".tres")
