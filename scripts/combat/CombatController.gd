extends Node

var is_in_combat: bool = false
var current_enemy_data: Resource = null
var current_enemy_hp: int = 0
var last_exp_reward: int = 0
var last_gold_reward: int = 0

func start_combat(enemy_data: Resource) -> void:
	is_in_combat = true
	current_enemy_data = enemy_data
	current_enemy_hp = enemy_data.max_hp
	last_exp_reward = 0
	last_gold_reward = 0

func end_combat() -> void:
	is_in_combat = false
	current_enemy_data = null
	current_enemy_hp = 0

func apply_damage_to_enemy(amount: int) -> void:
	if not is_in_combat:
		return
	if current_enemy_data == null:
		return
	current_enemy_hp = max(0, current_enemy_hp - amount)

func capture_rewards() -> void:
	if current_enemy_data == null:
		return
	last_exp_reward = current_enemy_data.exp_reward
	last_gold_reward = current_enemy_data.gold_reward

func is_enemy_defeated() -> bool:
	return is_in_combat and current_enemy_hp <= 0
