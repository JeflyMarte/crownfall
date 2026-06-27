extends Control

func _ready() -> void:
	$VBoxContainer/ButtonNext.pressed.connect(_on_next_button_pressed)
	var reward_text: String = "獲得報酬: EXP:%d Gold:%d" % [
		GameState.last_run_exp_reward,
		GameState.last_run_gold_reward,
	]
	if GameState.last_run_token_reward > 0:
		reward_text += " Token:%d" % GameState.last_run_token_reward
	$VBoxContainer/LabelReward.text = reward_text
	_update_loot_label()
	_update_levelup_label()

func _update_levelup_label() -> void:
	var label: Label = $VBoxContainer.get_node_or_null("LabelLevelUp")
	if label == null:
		return
	var ups: Dictionary = GameState.last_run_level_ups
	if ups.is_empty():
		label.visible = false
		return
	var parts: PackedStringArray = []
	for member in GameState.party_members:
		if member != null and ups.has(member.id):
			parts.append("%s +%dLv (Lv%d)" % [member.display_name, int(ups[member.id]), int(member.level)])
	label.visible = not parts.is_empty()
	label.text = "レベルアップ!  " + "  /  ".join(parts)

func _update_loot_label() -> void:
	var weapon: String = GameState.last_run_weapon_dropped
	var armor: String = GameState.last_run_armor_dropped
	var accessory: String = GameState.last_run_accessory_dropped
	var parts: PackedStringArray = []
	if not weapon.is_empty():
		parts.append("武器: " + weapon)
	if not armor.is_empty():
		parts.append("防具: " + armor)
	if not accessory.is_empty():
		parts.append("装飾品: " + accessory)
	if parts.is_empty():
		$VBoxContainer/LabelLoot.text = "入手: なし"
	else:
		$VBoxContainer/LabelLoot.text = "入手  " + "  /  ".join(parts)

func _on_next_button_pressed() -> void:
	$VBoxContainer/ButtonNext.disabled = true
	GameState.gold += GameState.last_run_gold_reward
	if GameState.last_run_token_reward > 0:
		GameState.gacha_token += GameState.last_run_token_reward
		GameState.last_run_token_reward = 0
	SceneRouter.change_scene("res://scenes/appraisal/AppraisalScene.tscn")
