class_name DungeonData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var difficulty: int = 0
@export var room_count: int = 0
@export var enemy_pool: Array[String] = []
@export var boss_id: String = ""
@export var drop_table_id: String = ""
@export var discovery_unlocks: Dictionary = {}
@export var elite_pool: Array[String] = []
