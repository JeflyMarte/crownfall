extends Node

var is_in_combat: bool = false
var current_enemy_data: Resource = null
var current_enemy_hp: int = 0

func start_combat(enemy_data: Resource) -> void:
	is_in_combat = true
	current_enemy_data = enemy_data
	current_enemy_hp = enemy_data.max_hp

func end_combat() -> void:
	is_in_combat = false
	current_enemy_data = null
	current_enemy_hp = 0
