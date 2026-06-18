extends Node

var is_in_combat: bool = false
var current_enemy_data: Resource = null

func start_combat(enemy_data: Resource) -> void:
	is_in_combat = true
	current_enemy_data = enemy_data

func end_combat() -> void:
	is_in_combat = false
	current_enemy_data = null
