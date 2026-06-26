extends Control

func _ready() -> void:
	$VBoxContainer/ButtonBack.pressed.connect(_on_back_pressed)
	_build_craft_ui()

func _build_craft_ui() -> void:
	$VBoxContainer/LabelGold.text = "Gold: %d" % GameState.gold
	$VBoxContainer/LabelMaterials.text = _format_materials()
	_rebuild_craft_list()

func _rebuild_craft_list() -> void:
	var container: VBoxContainer = $VBoxContainer/CraftListContainer
	for child in container.get_children():
		child.queue_free()
	var recipes: Array = DataRegistry.get_all_craft_data()
	if recipes.is_empty():
		var label := Label.new()
		label.text = "（レシピなし）"
		container.add_child(label)
		return
	for craft in recipes:
		_add_craft_row(container, craft)

func _add_craft_row(container: VBoxContainer, craft: Resource) -> void:
	var row := VBoxContainer.new()
	var info := Label.new()
	info.text = "[%s]  素材: %s  Gold: %dG  出力: %s — %s" % [
		craft.display_name,
		_format_required_materials(craft.required_materials),
		craft.gold_cost,
		craft.output_type,
		craft.output_id,
	]
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(info)
	if craft.output_type == "armor" or craft.output_type == "accessory" or craft.output_type == "weapon":
		var btn := Button.new()
		btn.text = "作成"
		btn.pressed.connect(func(): _on_craft_pressed(craft))
		row.add_child(btn)
	container.add_child(row)

func _on_craft_pressed(craft: Resource) -> void:
	if craft.output_type == "weapon":
		_log_craft("Craft Failed: weapon crafting unavailable")
		return
	if craft.output_type != "armor" and craft.output_type != "accessory":
		_log_craft("Craft Failed: invalid output")
		return
	if craft.output_id.is_empty() or not _craft_output_exists(craft):
		_log_craft("Craft Failed: invalid output")
		return
	if GameState.gold < craft.gold_cost:
		_log_craft("Craft Failed: not enough gold")
		return
	if not _has_enough_materials(craft.required_materials):
		_log_craft("Craft Failed: not enough materials")
		return
	GameState.gold -= craft.gold_cost
	GameState.consume_materials(craft.required_materials)
	_generate_craft_output(craft)
	SaveManager.save_game()
	_log_craft("Craft Success: %s" % craft.output_id)
	_build_craft_ui()

func _craft_output_exists(craft: Resource) -> bool:
	if craft.output_type == "armor":
		return DataRegistry.get_armor_data(craft.output_id) != null
	if craft.output_type == "accessory":
		return DataRegistry.get_accessory_data(craft.output_id) != null
	return false

func _has_enough_materials(required: Dictionary) -> bool:
	for mat_id in required:
		if GameState.get_material_quantity(mat_id) < int(required[mat_id]):
			return false
	return true

func _generate_craft_output(craft: Resource) -> void:
	if craft.output_type == "armor":
		_spawn_armor(craft.output_id)
	elif craft.output_type == "accessory":
		_spawn_accessory(craft.output_id)

func _spawn_armor(armor_id: String) -> void:
	var armor_data: Resource = DataRegistry.get_armor_data(armor_id)
	if armor_data == null:
		return
	var instance := ArmorInstance.new()
	instance.instance_id = str(Time.get_ticks_msec()) + "_craft_" + str(randi() % 100000)
	instance.armor_id = armor_id
	instance.is_appraised = false
	instance.rolled_defense = armor_data.base_defense + randi() % 4
	instance.hp_bonus = armor_data.base_hp_bonus
	instance.resistance = armor_data.base_resistance
	instance.weight = armor_data.weight
	instance.rarity = armor_data.rarity
	GameState.armor_inventory.append(instance)

func _spawn_accessory(accessory_id: String) -> void:
	var accessory_data: Resource = DataRegistry.get_accessory_data(accessory_id)
	if accessory_data == null:
		return
	var instance := AccessoryInstance.new()
	instance.instance_id = str(Time.get_ticks_msec()) + "_craft_" + str(randi() % 100000)
	instance.accessory_id = accessory_id
	instance.is_appraised = false
	GameState.accessory_inventory.append(instance)

func _format_materials() -> String:
	if GameState.material_inventory.is_empty():
		return "素材: なし"
	var parts: PackedStringArray = []
	for mat_id in GameState.material_inventory:
		var qty: int = GameState.get_material_quantity(mat_id)
		if qty > 0:
			parts.append("%s x%d" % [mat_id, qty])
	if parts.is_empty():
		return "素材: なし"
	return "素材: " + " / ".join(parts)

func _format_required_materials(required: Dictionary) -> String:
	if required.is_empty():
		return "なし"
	var parts: PackedStringArray = []
	for mat_id in required:
		var needed: int = int(required[mat_id])
		var owned: int = GameState.get_material_quantity(mat_id)
		parts.append("%s %d/%d" % [mat_id, owned, needed])
	return " / ".join(parts)

func _set_status(msg: String) -> void:
	$VBoxContainer/LabelStatus.text = msg

func _log_craft(msg: String) -> void:
	print("[Craft] ", msg)
	_set_status(msg)

func _on_back_pressed() -> void:
	SceneRouter.change_scene("res://scenes/base/BaseScene.tscn")
