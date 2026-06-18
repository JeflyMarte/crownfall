extends Control

const DEBUG_ATTACK_DAMAGE: int = 10

func _ready() -> void:
	$VBoxContainer/ButtonFinish.pressed.connect(_on_finish_button_pressed)
	$VBoxContainer/ButtonNextRoom.pressed.connect(_on_next_room_pressed)
	$VBoxContainer/ButtonAttack.pressed.connect(_on_attack_pressed)
	$DungeonController.start_dungeon("res://resources/dungeons/royal_ruins.tres")
	_update_room_label()
	_update_enemy_label()
	_update_enemy_hp_label()

func _update_room_label() -> void:
	var idx: int = $DungeonController.current_room_index + 1
	var total: int = $DungeonController.current_dungeon_data.room_count
	$VBoxContainer/LabelRoom.text = "部屋: %d / %d" % [idx, total]

func _on_next_room_pressed() -> void:
	$DungeonController.advance_room()
	_update_room_label()
	if $DungeonController.is_completed:
		$VBoxContainer/ButtonNextRoom.disabled = true
	if $DungeonController.is_combat_room():
		var enemy_data: Resource = $DungeonController.pick_enemy_data()
		if enemy_data != null:
			$CombatController.start_combat(enemy_data)
	else:
		$CombatController.end_combat()
	_update_enemy_label()
	_update_enemy_hp_label()

func _update_enemy_label() -> void:
	var data: Resource = $CombatController.current_enemy_data
	if data != null:
		$VBoxContainer/LabelEnemy.text = data.display_name
	else:
		$VBoxContainer/LabelEnemy.text = ""

func _update_enemy_hp_label() -> void:
	if $CombatController.is_in_combat:
		$VBoxContainer/LabelEnemyHp.text = "HP: %d" % $CombatController.current_enemy_hp
		$VBoxContainer/ButtonAttack.disabled = false
	else:
		$VBoxContainer/LabelEnemyHp.text = ""
		$VBoxContainer/ButtonAttack.disabled = true

func _on_attack_pressed() -> void:
	$CombatController.apply_damage_to_enemy(DEBUG_ATTACK_DAMAGE)
	_update_enemy_hp_label()
	if $CombatController.is_enemy_defeated():
		$VBoxContainer/LabelLog.text = "敵を倒した（仮）"
		$VBoxContainer/ButtonAttack.disabled = true

func _on_finish_button_pressed() -> void:
	SceneRouter.change_scene("res://scenes/result/ResultScene.tscn")
