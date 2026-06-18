extends Node

var is_in_combat: bool = false

func start_combat() -> void:
	is_in_combat = true

func end_combat() -> void:
	is_in_combat = false
