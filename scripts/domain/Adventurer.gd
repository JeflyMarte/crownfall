class_name Adventurer
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var level: int = 1
@export var exp: int = 0
@export var job_id: String = ""
@export var base_stats: Stats
@export var equipped_weapon: Resource = null
@export var equipped_armor: Resource = null
@export var equipped_accessory: Resource = null
@export var traits: Array[String] = []
