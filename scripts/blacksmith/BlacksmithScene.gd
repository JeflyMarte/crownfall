extends Control

const _AffixRoller = preload("res://scripts/equipment/AffixRoller.gd")
const _EquipmentEnhancer = preload("res://scripts/equipment/EquipmentEnhancer.gd")

const COLOR_OK: Color = Color(0.7, 0.92, 0.6, 1)
const COLOR_SHORT: Color = Color(0.82, 0.45, 0.42, 1)
const COLOR_SUB: Color = Color(0.6, 0.62, 0.7, 1)
const COLOR_TEXT: Color = Color(0.82, 0.84, 0.9, 1)
const COLOR_GOLD: Color = Color(0.85, 0.74, 0.45, 1)
const COLOR_ACCENT: Color = Color(0.75, 0.82, 0.95, 1)

@onready var _material_inventory_row: HBoxContainer = $VBoxContainer/MaterialScroll/MaterialInventoryRow
@onready var _craft_section: VBoxContainer = $VBoxContainer/CraftSection
@onready var _enhance_section: VBoxContainer = $VBoxContainer/EnhanceSection
@onready var _enhance_weapon_list: VBoxContainer = $VBoxContainer/EnhanceSection/EnhanceWeaponList
@onready var _enhance_detail: VBoxContainer = $VBoxContainer/EnhanceSection/EnhanceDetail
@onready var _btn_mode_craft: Button = $VBoxContainer/ModeRow/BtnModeCraft
@onready var _btn_mode_enhance: Button = $VBoxContainer/ModeRow/BtnModeEnhance

var _mode: String = "craft"
var _selected_weapon: Resource = null

func _ready() -> void:
	$VBoxContainer/ButtonBack.pressed.connect(_on_back_pressed)
	_btn_mode_craft.pressed.connect(func(): _set_mode("craft"))
	_btn_mode_enhance.pressed.connect(func(): _set_mode("enhance"))
	_set_mode("craft")

func _set_mode(mode: String) -> void:
	_mode = mode
	var craft_on: bool = mode == "craft"
	_craft_section.visible = craft_on
	_enhance_section.visible = not craft_on
	_btn_mode_craft.disabled = craft_on
	_btn_mode_enhance.disabled = not craft_on
	if craft_on:
		_build_craft_ui()
	else:
		_build_enhance_ui()

func _build_craft_ui() -> void:
	$VBoxContainer/LabelGold.text = "Gold: %d" % GameState.gold
	_rebuild_material_inventory()
	_rebuild_craft_list()

func _build_enhance_ui() -> void:
	$VBoxContainer/LabelGold.text = "Gold: %d" % GameState.gold
	_rebuild_material_inventory()
	_rebuild_enhance_weapon_list()
	_rebuild_enhance_detail()

func _rebuild_material_inventory() -> void:
	for child in _material_inventory_row.get_children():
		child.queue_free()
	var entries: Array[Dictionary] = []
	for raw_id in GameState.material_inventory.keys():
		var mat_id: String = str(raw_id)
		var qty: int = GameState.get_material_quantity(mat_id)
		if qty > 0:
			entries.append({"id": mat_id, "qty": qty})
	if entries.is_empty():
		var empty := Label.new()
		empty.text = "素材: なし"
		empty.add_theme_color_override("font_color", COLOR_SUB)
		_material_inventory_row.add_child(empty)
		return
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["qty"]) > int(b["qty"])
	)
	for entry in entries:
		_material_inventory_row.add_child(_make_material_chip(str(entry["id"]), int(entry["qty"]), true))

func _rebuild_craft_list() -> void:
	var container: VBoxContainer = $VBoxContainer/CraftSection/CraftListContainer
	for child in container.get_children():
		child.queue_free()
	var recipes: Array = _sort_craft_recipes(DataRegistry.get_all_craft_data())
	if recipes.is_empty():
		var label := Label.new()
		label.text = "（レシピなし）"
		container.add_child(label)
		return
	for craft in recipes:
		_add_craft_row(container, craft)

func _rebuild_enhance_weapon_list() -> void:
	for child in _enhance_weapon_list.get_children():
		child.queue_free()
	var weapons: Array = _sorted_enhance_candidates()
	if weapons.is_empty():
		var empty := Label.new()
		empty.text = "（鑑定済みの武器がありません）"
		empty.add_theme_color_override("font_color", COLOR_SUB)
		_enhance_weapon_list.add_child(empty)
		_selected_weapon = null
		return
	if _selected_weapon == null or _selected_weapon not in weapons:
		_selected_weapon = weapons[0]
	for weapon in weapons:
		_enhance_weapon_list.add_child(_make_enhance_weapon_row(weapon))

func _sorted_enhance_candidates() -> Array:
	var weapons: Array = []
	for item in GameState.inventory:
		if item == null or not bool(item.is_appraised):
			continue
		if str(item.weapon_id).is_empty():
			continue
		weapons.append(item)
	weapons.sort_custom(func(a: Resource, b: Resource) -> bool:
		var a_eq: bool = _is_weapon_equipped(a)
		var b_eq: bool = _is_weapon_equipped(b)
		if a_eq != b_eq:
			return a_eq
		return _EquipmentEnhancer.get_display_name(a) < _EquipmentEnhancer.get_display_name(b)
	)
	return weapons

func _is_weapon_equipped(weapon: Resource) -> bool:
	return GameState.find_item_equipped_member_index(weapon) >= 0

func _make_enhance_weapon_row(weapon: Resource) -> Control:
	var row := Button.new()
	row.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var level: int = _EquipmentEnhancer.get_enhance_level(weapon)
	var atk: int = _EquipmentEnhancer.get_effective_attack(weapon)
	var suffix: String = "  ATK %d" % atk
	if _is_weapon_equipped(weapon):
		suffix += "  （装備中）"
	row.text = _EquipmentEnhancer.get_display_name(weapon) + suffix
	if level >= _EquipmentEnhancer.MAX_LEVEL:
		row.add_theme_color_override("font_color", COLOR_GOLD)
	elif weapon == _selected_weapon:
		row.add_theme_color_override("font_color", COLOR_ACCENT)
	row.pressed.connect(func():
		_selected_weapon = weapon
		_rebuild_enhance_weapon_list()
		_rebuild_enhance_detail()
	)
	return row

func _rebuild_enhance_detail() -> void:
	for child in _enhance_detail.get_children():
		child.queue_free()
	if _selected_weapon == null:
		return
	var level: int = _EquipmentEnhancer.get_enhance_level(_selected_weapon)
	var current_atk: int = _EquipmentEnhancer.get_effective_attack(_selected_weapon)
	var title := Label.new()
	title.text = _EquipmentEnhancer.get_display_name(_selected_weapon)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	_enhance_detail.add_child(title)
	var stat := Label.new()
	if level >= _EquipmentEnhancer.MAX_LEVEL:
		stat.text = "ATK %d（炉研ぎ上限 +%d）" % [current_atk, _EquipmentEnhancer.MAX_LEVEL]
	else:
		stat.text = "ATK %d → %d（+%d）" % [current_atk, current_atk + 1, level + 1]
	stat.add_theme_color_override("font_color", COLOR_SUB)
	_enhance_detail.add_child(stat)
	if level >= _EquipmentEnhancer.MAX_LEVEL:
		return
	var check: Dictionary = _EquipmentEnhancer.can_enhance(_selected_weapon)
	var next_level: int = int(check.get("next_level", level + 1))
	var gold_cost: int = int(check.get("gold_cost", _EquipmentEnhancer.get_gold_cost(next_level)))
	var materials: Dictionary = check.get("materials", _EquipmentEnhancer.get_material_cost(next_level))
	var cost_row := HBoxContainer.new()
	cost_row.add_theme_constant_override("separation", 8)
	var gold_lbl := Label.new()
	gold_lbl.text = "%d G" % gold_cost
	gold_lbl.add_theme_color_override("font_color", COLOR_GOLD if GameState.gold >= gold_cost else COLOR_SHORT)
	cost_row.add_child(gold_lbl)
	for mat_id in materials:
		cost_row.add_child(_make_material_req_cell(str(mat_id), int(materials[mat_id])))
	_enhance_detail.add_child(cost_row)
	var btn := Button.new()
	btn.text = "炉で研ぐ（+%d）" % next_level
	btn.disabled = not bool(check.get("ok", false))
	btn.pressed.connect(_on_enhance_pressed)
	_enhance_detail.add_child(btn)
	if not bool(check.get("ok", false)):
		var reason := Label.new()
		reason.text = str(check.get("reason", ""))
		reason.add_theme_color_override("font_color", COLOR_SHORT)
		_enhance_detail.add_child(reason)

func _on_enhance_pressed() -> void:
	if _selected_weapon == null:
		return
	var result: Dictionary = _EquipmentEnhancer.enhance_weapon(_selected_weapon)
	if not bool(result.get("ok", false)):
		_log_craft(str(result.get("reason", "炉研ぎに失敗しました")))
		_build_enhance_ui()
		return
	SaveManager.save_game()
	_log_craft(
		"炉研ぎ成功: %s（ATK %d）" % [
			str(result.get("display_name", "")),
			int(result.get("effective_attack", 0)),
		]
	)
	_build_enhance_ui()

func _sort_craft_recipes(recipes: Array) -> Array:
	var sorted: Array = recipes.duplicate()
	sorted.sort_custom(func(a: Resource, b: Resource) -> bool:
		var a_ok: bool = _can_craft(a)
		var b_ok: bool = _can_craft(b)
		if a_ok != b_ok:
			return a_ok
		return str(a.display_name) < str(b.display_name)
	)
	return sorted

func _add_craft_row(container: VBoxContainer, craft: Resource) -> void:
	var can_craft: bool = _can_craft(craft)
	var row := VBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	var out_tex: Texture2D = IconPaths.get_icon_texture(craft.output_id, craft.output_type)
	if out_tex != null:
		var out_icon := TextureRect.new()
		out_icon.texture = out_tex
		out_icon.custom_minimum_size = Vector2(32, 32)
		out_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		out_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		header.add_child(out_icon)
	var title_col := VBoxContainer.new()
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = craft.display_name
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", COLOR_OK if can_craft else COLOR_TEXT)
	title_col.add_child(title)
	var sub := Label.new()
	sub.text = "%s — %s" % [
		_output_type_label(craft.output_type),
		DataRegistry.get_item_name(craft.output_id, craft.output_type),
	]
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", COLOR_SUB)
	title_col.add_child(sub)
	header.add_child(title_col)
	var cost := Label.new()
	cost.text = "%d G" % craft.gold_cost
	cost.add_theme_color_override("font_color", COLOR_GOLD)
	cost.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(cost)
	row.add_child(header)
	var mats_row := HBoxContainer.new()
	mats_row.add_theme_constant_override("separation", 6)
	for mat_id in craft.required_materials:
		mats_row.add_child(_make_material_req_cell(str(mat_id), int(craft.required_materials[mat_id])))
	row.add_child(mats_row)
	if craft.output_type == "armor" or craft.output_type == "accessory" or craft.output_type == "weapon":
		var btn := Button.new()
		btn.text = _craft_button_label(craft, can_craft)
		btn.disabled = not can_craft
		btn.pressed.connect(func(): _on_craft_pressed(craft))
		row.add_child(btn)
	var sep := HSeparator.new()
	container.add_child(row)
	container.add_child(sep)

func _output_type_label(output_type: String) -> String:
	match output_type:
		"weapon":
			return "武器"
		"armor":
			return "防具"
		"accessory":
			return "装飾"
		_:
			return output_type

func _make_material_chip(mat_id: String, qty: int, show_name: bool) -> Control:
	var chip := HBoxContainer.new()
	chip.add_theme_constant_override("separation", 4)
	chip.tooltip_text = "%s x%d" % [DataRegistry.get_material_name(mat_id), qty]
	var icon_tex: Texture2D = IconPaths.get_icon_texture(mat_id, "material")
	if icon_tex != null:
		var icon := TextureRect.new()
		icon.texture = icon_tex
		icon.custom_minimum_size = Vector2(20, 20)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		chip.add_child(icon)
	else:
		var glyph := Label.new()
		glyph.text = "材"
		glyph.add_theme_font_size_override("font_size", 12)
		glyph.add_theme_color_override("font_color", COLOR_SUB)
		chip.add_child(glyph)
	var text := Label.new()
	if show_name:
		text.text = "%s x%d" % [DataRegistry.get_material_name(mat_id), qty]
	else:
		text.text = str(qty)
	text.add_theme_font_size_override("font_size", 13)
	text.add_theme_color_override("font_color", COLOR_TEXT)
	chip.add_child(text)
	return chip

func _make_material_req_cell(mat_id: String, needed: int) -> Control:
	var owned: int = GameState.get_material_quantity(mat_id)
	var ok: bool = owned >= needed
	var chip := HBoxContainer.new()
	chip.add_theme_constant_override("separation", 3)
	chip.tooltip_text = "%s %d/%d" % [DataRegistry.get_material_name(mat_id), owned, needed]
	var icon_tex: Texture2D = IconPaths.get_icon_texture(mat_id, "material")
	if icon_tex != null:
		var icon := TextureRect.new()
		icon.texture = icon_tex
		icon.custom_minimum_size = Vector2(18, 18)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		chip.add_child(icon)
	var qty := Label.new()
	qty.text = "%d/%d" % [owned, needed]
	qty.add_theme_font_size_override("font_size", 13)
	qty.add_theme_color_override("font_color", COLOR_OK if ok else COLOR_SHORT)
	chip.add_child(qty)
	return chip

func _craft_button_label(craft: Resource, can_craft: bool) -> String:
	if can_craft:
		return "作成"
	if GameState.gold < craft.gold_cost:
		return "Gold不足"
	return "素材不足"

func _can_craft(craft: Resource) -> bool:
	return CraftHelper.can_craft(craft)

func _craft_output_exists(craft: Resource) -> bool:
	return CraftHelper.craft_output_exists(craft)

func _has_enough_materials(required: Dictionary) -> bool:
	return CraftHelper.has_enough_materials(required)

func _on_craft_pressed(craft: Resource) -> void:
	if craft.output_type != "armor" and craft.output_type != "accessory" and craft.output_type != "weapon":
		_log_craft("作成できません（出力不正）")
		return
	if craft.output_id.is_empty() or not _craft_output_exists(craft):
		_log_craft("作成できません（出力不正）")
		return
	if GameState.gold < craft.gold_cost:
		_log_craft("ゴールドが足りません")
		return
	if not _has_enough_materials(craft.required_materials):
		_log_craft("素材が足りません")
		return
	GameState.gold -= craft.gold_cost
	GameState.consume_materials(craft.required_materials)
	_generate_craft_output(craft)
	SaveManager.save_game()
	_log_craft("作成完了: %s" % DataRegistry.get_item_name(craft.output_id, craft.output_type))
	_build_craft_ui()

func _auto_appraise(instance: Resource, category: String, rarity: int) -> void:
	instance.is_appraised = true
	var roll: Dictionary = _AffixRoller.roll_for_equipment(category, rarity)
	if roll.is_empty() or roll.has("error"):
		instance.prefix_ids = []
		instance.suffix_ids = []
		return
	var prefix: Array[String] = []
	for v in roll.get("prefix_ids", []):
		prefix.append(str(v))
	var suffix: Array[String] = []
	for v in roll.get("suffix_ids", []):
		suffix.append(str(v))
	instance.prefix_ids = prefix
	instance.suffix_ids = suffix

func _generate_craft_output(craft: Resource) -> void:
	if craft.output_type == "armor":
		_spawn_armor(craft.output_id)
	elif craft.output_type == "accessory":
		_spawn_accessory(craft.output_id)
	elif craft.output_type == "weapon":
		_spawn_weapon(craft.output_id)

func _spawn_weapon(weapon_id: String) -> void:
	var weapon_data: Resource = DataRegistry.get_weapon_data(weapon_id)
	if weapon_data == null:
		return
	var instance := WeaponInstance.new()
	instance.instance_id = str(Time.get_ticks_msec()) + "_craft_" + str(randi() % 100000)
	instance.weapon_id = weapon_id
	instance.rolled_attack = weapon_data.base_attack + randi() % 6
	instance.attack_speed = weapon_data.base_attack_speed
	instance.critical_rate = weapon_data.base_critical_rate
	instance.knockback = weapon_data.base_knockback
	instance.stagger_power = weapon_data.base_stagger_power
	instance.attack_range = weapon_data.base_attack_range
	instance.weight = weapon_data.weight
	_auto_appraise(instance, _AffixRoller.CATEGORY_WEAPON, weapon_data.rarity)
	GameState.inventory.append(instance)

func _spawn_armor(armor_id: String) -> void:
	var armor_data: Resource = DataRegistry.get_armor_data(armor_id)
	if armor_data == null:
		return
	var instance := ArmorInstance.new()
	instance.instance_id = str(Time.get_ticks_msec()) + "_craft_" + str(randi() % 100000)
	instance.armor_id = armor_id
	instance.rolled_defense = armor_data.base_defense + randi() % 4
	instance.hp_bonus = armor_data.base_hp_bonus
	instance.resistance = armor_data.base_resistance
	instance.weight = armor_data.weight
	instance.rarity = armor_data.rarity
	_auto_appraise(instance, _AffixRoller.CATEGORY_ARMOR, armor_data.rarity)
	GameState.armor_inventory.append(instance)

func _spawn_accessory(accessory_id: String) -> void:
	var accessory_data: Resource = DataRegistry.get_accessory_data(accessory_id)
	if accessory_data == null:
		return
	var instance := AccessoryInstance.new()
	instance.instance_id = str(Time.get_ticks_msec()) + "_craft_" + str(randi() % 100000)
	instance.accessory_id = accessory_id
	_auto_appraise(instance, _AffixRoller.CATEGORY_ACCESSORY, accessory_data.rarity)
	GameState.accessory_inventory.append(instance)

func _set_status(msg: String) -> void:
	$VBoxContainer/LabelStatus.text = msg

func _log_craft(msg: String) -> void:
	print("[Craft] ", msg)
	_set_status(msg)

func _on_back_pressed() -> void:
	SceneRouter.change_scene("res://scenes/base/BaseScene.tscn")
