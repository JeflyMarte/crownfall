extends Control

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const ROSTER_SCENE: String = "res://scenes/roster/RosterScene.tscn"
const CODEX_SCENE: String = "res://scenes/codex/CodexScene.tscn"
const GACHA_SCENE: String = "res://scenes/gacha/GachaScene.tscn"

const COLOR_OK: Color = Color(0.7, 0.92, 0.6, 1)
const COLOR_SHORT: Color = Color(0.82, 0.45, 0.42, 1)
const COLOR_SUB: Color = Color(0.6, 0.62, 0.7, 1)
const COLOR_TEXT: Color = Color(0.82, 0.84, 0.9, 1)
const COLOR_GOLD: Color = Color(0.85, 0.74, 0.45, 1)
const COLOR_ACCENT: Color = Color(0.75, 0.82, 0.95, 1)

const _AffixRoller = preload("res://scripts/equipment/AffixRoller.gd")
const _EquipmentEnhancer = preload("res://scripts/equipment/EquipmentEnhancer.gd")

const _DETAIL_ICON_PX: int = 72
const _LIST_ICON_PX: int = 36
const _CRAFTABLE_ICON_PX: int = 40

@onready var _label_gold: Label = $Header/HeaderRow/GoldChip/GoldRow/LabelGold
@onready var _label_token: Label = $Header/HeaderRow/TokenChip/TokenRow/LabelToken
@onready var _btn_produce: Button = $ModeTabs/BtnProduce
@onready var _btn_enhance: Button = $ModeTabs/BtnEnhance
@onready var _category_row: HBoxContainer = $CategoryRow
@onready var _btn_cat_weapon: Button = $CategoryRow/BtnCatWeapon
@onready var _btn_cat_armor: Button = $CategoryRow/BtnCatArmor
@onready var _btn_cat_accessory: Button = $CategoryRow/BtnCatAccessory
@onready var _left_list: VBoxContainer = $MainSplit/LeftScroll/LeftList
@onready var _detail_panel: PanelContainer = $MainSplit/DetailPanel
@onready var _detail_vbox: VBoxContainer = $MainSplit/DetailPanel/DetailVBox
@onready var _craftable_panel: VBoxContainer = $CraftablePanel
@onready var _craftable_row: HBoxContainer = $CraftablePanel/CraftableScroll/CraftableRow
@onready var _label_status: Label = $LabelStatus

var _mode: String = "produce"
var _category: String = "weapon"
var _selected_craft: Resource = null
var _selected_weapon: Resource = null

func _ready() -> void:
	$Header/HeaderRow/ButtonBack.pressed.connect(_on_back_pressed)
	_btn_produce.pressed.connect(func(): _set_mode("produce"))
	_btn_enhance.pressed.connect(func(): _set_mode("enhance"))
	_btn_cat_weapon.pressed.connect(func(): _set_category("weapon"))
	_btn_cat_armor.pressed.connect(func(): _set_category("armor"))
	_btn_cat_accessory.pressed.connect(func(): _set_category("accessory"))
	$BottomNav/NavRow/NavHome.pressed.connect(_go_to.bind(HOME_SCENE))
	$BottomNav/NavRow/NavParty.pressed.connect(_go_to.bind(ROSTER_SCENE))
	$BottomNav/NavRow/NavCodex.pressed.connect(_go_to.bind(CODEX_SCENE))
	$BottomNav/NavRow/NavShop.pressed.connect(_go_to.bind(GACHA_SCENE))
	_detail_panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_NORMAL)
	)
	_set_mode("produce")

func _set_mode(mode: String) -> void:
	_mode = mode
	_btn_produce.button_pressed = mode == "produce"
	_btn_enhance.button_pressed = mode == "enhance"
	_category_row.visible = mode == "produce"
	_craftable_panel.visible = mode == "produce"
	if mode == "enhance" and _category != "weapon":
		_category = "weapon"
		_sync_category_buttons()
	_refresh_all()

func _set_category(category: String) -> void:
	if _mode != "produce":
		return
	_category = category
	_sync_category_buttons()
	_selected_craft = null
	_refresh_all()

func _sync_category_buttons() -> void:
	_btn_cat_weapon.button_pressed = _category == "weapon"
	_btn_cat_armor.button_pressed = _category == "armor"
	_btn_cat_accessory.button_pressed = _category == "accessory"

func _refresh_all() -> void:
	_update_currency()
	_update_mode_tab_dots()
	_rebuild_left_list()
	_rebuild_detail()
	if _mode == "produce":
		_rebuild_craftable_strip()

func _update_currency() -> void:
	_label_gold.text = "%d" % GameState.gold
	_label_token.text = CurrencyHelper.format_amount()

func _update_mode_tab_dots() -> void:
	var craftable: bool = BlacksmithUiHelper.has_craftable_recipes()
	_btn_produce.text = "生産 ●" if craftable else "生産"

func _rebuild_left_list() -> void:
	for child in _left_list.get_children():
		child.queue_free()
	if _mode == "produce":
		_rebuild_produce_left_list()
	else:
		_rebuild_enhance_left_list()

func _rebuild_produce_left_list() -> void:
	var recipes: Array = BlacksmithUiHelper.recipes_for_category(_category)
	if recipes.is_empty():
		_left_list.add_child(_make_empty_label("（レシピなし）"))
		_selected_craft = null
		return
	if _selected_craft == null or _selected_craft not in recipes:
		_selected_craft = recipes[0]
	for craft in recipes:
		_left_list.add_child(_make_recipe_list_card(craft))

func _rebuild_enhance_left_list() -> void:
	var weapons: Array = _sorted_enhance_candidates()
	if weapons.is_empty():
		_left_list.add_child(_make_empty_label("（鑑定済みの武器がありません）"))
		_selected_weapon = null
		return
	if _selected_weapon == null or _selected_weapon not in weapons:
		_selected_weapon = weapons[0]
	for weapon in weapons:
		_left_list.add_child(_make_enhance_list_card(weapon))

func _make_empty_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", COLOR_SUB)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _make_recipe_list_card(craft: Resource) -> PanelContainer:
	var can_craft: bool = CraftHelper.can_craft(craft)
	var selected: bool = craft == _selected_craft
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", BlacksmithUiHelper.card_style(selected, can_craft))
	panel.gui_input.connect(_on_recipe_card_input.bind(craft))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	panel.add_child(row)
	row.add_child(_make_item_icon(str(craft.output_id), str(craft.output_type), _LIST_ICON_PX))
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)
	var name_lbl := Label.new()
	name_lbl.text = str(craft.display_name)
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.add_theme_color_override(
		"font_color", COLOR_OK if can_craft else COLOR_TEXT
	)
	col.add_child(name_lbl)
	var sub := Label.new()
	sub.text = "%s  所持 %d" % [
		BlacksmithUiHelper.rarity_gem(BlacksmithUiHelper.output_rarity(craft)),
		BlacksmithUiHelper.owned_count(str(craft.output_type), str(craft.output_id)),
	]
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", COLOR_SUB)
	col.add_child(sub)
	return panel

func _on_recipe_card_input(event: InputEvent, craft: Resource) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_selected_craft = craft
		_refresh_all()

func _make_enhance_list_card(weapon: Resource) -> PanelContainer:
	var selected: bool = weapon == _selected_weapon
	var level: int = _EquipmentEnhancer.get_enhance_level(weapon)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", BlacksmithUiHelper.card_style(selected))
	panel.gui_input.connect(_on_enhance_card_input.bind(weapon))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	panel.add_child(row)
	row.add_child(_make_item_icon(str(weapon.weapon_id), "weapon", _LIST_ICON_PX))
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 2)
	row.add_child(col)
	var name_lbl := Label.new()
	name_lbl.text = _EquipmentEnhancer.get_display_name(weapon)
	name_lbl.add_theme_font_size_override("font_size", 13)
	if level >= _EquipmentEnhancer.MAX_LEVEL:
		name_lbl.add_theme_color_override("font_color", COLOR_GOLD)
	elif selected:
		name_lbl.add_theme_color_override("font_color", COLOR_ACCENT)
	col.add_child(name_lbl)
	var sub := Label.new()
	sub.text = "ATK %d" % _EquipmentEnhancer.get_effective_attack(weapon)
	if _is_weapon_equipped(weapon):
		sub.text += "  装備中"
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", COLOR_SUB)
	col.add_child(sub)
	return panel

func _on_enhance_card_input(event: InputEvent, weapon: Resource) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_selected_weapon = weapon
		_refresh_all()

func _rebuild_detail() -> void:
	for child in _detail_vbox.get_children():
		child.queue_free()
	if _mode == "produce":
		_rebuild_produce_detail()
	else:
		_rebuild_enhance_detail()

func _rebuild_produce_detail() -> void:
	if _selected_craft == null:
		_detail_vbox.add_child(_make_empty_label("レシピを選択してください"))
		return
	var craft: Resource = _selected_craft
	var can_craft: bool = CraftHelper.can_craft(craft)
	_detail_vbox.add_child(
		_make_item_icon(str(craft.output_id), str(craft.output_type), _DETAIL_ICON_PX)
	)
	var title := Label.new()
	title.text = "%s %s" % [
		BlacksmithUiHelper.rarity_gem(BlacksmithUiHelper.output_rarity(craft)),
		BlacksmithUiHelper.output_display_name(craft),
	]
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	_detail_vbox.add_child(title)
	var recipe_name := Label.new()
	recipe_name.text = str(craft.display_name)
	recipe_name.add_theme_font_size_override("font_size", 13)
	recipe_name.add_theme_color_override("font_color", COLOR_SUB)
	_detail_vbox.add_child(recipe_name)
	for line in BlacksmithUiHelper.preview_lines(craft):
		var stat := Label.new()
		stat.text = line
		stat.add_theme_color_override("font_color", COLOR_SUB)
		_detail_vbox.add_child(stat)
	var owned := Label.new()
	owned.text = "所持数 %d" % BlacksmithUiHelper.owned_count(
		str(craft.output_type), str(craft.output_id)
	)
	owned.add_theme_color_override("font_color", COLOR_SUB)
	_detail_vbox.add_child(owned)
	_detail_vbox.add_child(_make_cost_row(int(craft.gold_cost), craft.required_materials))
	var btn := Button.new()
	btn.text = _craft_button_label(craft, can_craft)
	btn.disabled = not can_craft
	btn.pressed.connect(func(): _on_craft_pressed(craft))
	_detail_vbox.add_child(btn)

func _rebuild_enhance_detail() -> void:
	if _selected_weapon == null:
		_detail_vbox.add_child(_make_empty_label("武器を選択してください"))
		return
	var weapon: Resource = _selected_weapon
	var level: int = _EquipmentEnhancer.get_enhance_level(weapon)
	var current_atk: int = _EquipmentEnhancer.get_effective_attack(weapon)
	_detail_vbox.add_child(_make_item_icon(str(weapon.weapon_id), "weapon", _DETAIL_ICON_PX))
	var title := Label.new()
	title.text = _EquipmentEnhancer.get_display_name(weapon)
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	_detail_vbox.add_child(title)
	var stat := Label.new()
	if level >= _EquipmentEnhancer.MAX_LEVEL:
		stat.text = "ATK %d（炉研ぎ上限 +%d）" % [current_atk, _EquipmentEnhancer.MAX_LEVEL]
	else:
		stat.text = "ATK %d → %d（+%d）" % [current_atk, current_atk + 1, level + 1]
	stat.add_theme_color_override("font_color", COLOR_SUB)
	_detail_vbox.add_child(stat)
	if _is_weapon_equipped(weapon):
		var eq_lbl := Label.new()
		eq_lbl.text = "装備中の武器"
		eq_lbl.add_theme_color_override("font_color", COLOR_ACCENT)
		_detail_vbox.add_child(eq_lbl)
	if level >= _EquipmentEnhancer.MAX_LEVEL:
		return
	var check: Dictionary = _EquipmentEnhancer.can_enhance(weapon)
	var next_level: int = int(check.get("next_level", level + 1))
	var gold_cost: int = int(check.get("gold_cost", _EquipmentEnhancer.get_gold_cost(next_level)))
	var materials: Dictionary = check.get("materials", _EquipmentEnhancer.get_material_cost(next_level))
	_detail_vbox.add_child(_make_cost_row(gold_cost, materials))
	var btn := Button.new()
	btn.text = "炉で研ぐ（+%d）" % next_level
	btn.disabled = not bool(check.get("ok", false))
	btn.pressed.connect(_on_enhance_pressed)
	_detail_vbox.add_child(btn)
	if not bool(check.get("ok", false)):
		var reason := Label.new()
		reason.text = str(check.get("reason", ""))
		reason.add_theme_color_override("font_color", COLOR_SHORT)
		_detail_vbox.add_child(reason)

func _make_cost_row(gold_cost: int, materials: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var gold_lbl := Label.new()
	gold_lbl.text = "%d G" % gold_cost
	gold_lbl.add_theme_color_override(
		"font_color", COLOR_GOLD if GameState.gold >= gold_cost else COLOR_SHORT
	)
	row.add_child(gold_lbl)
	for mat_id in materials:
		row.add_child(_make_material_req_cell(str(mat_id), int(materials[mat_id])))
	return row

func _rebuild_craftable_strip() -> void:
	for child in _craftable_row.get_children():
		child.queue_free()
	var recipes: Array = CraftHelper.get_craftable_recipes()
	if recipes.is_empty():
		var empty := Label.new()
		empty.text = "（作成可能なレシピはありません）"
		empty.add_theme_color_override("font_color", COLOR_SUB)
		_craftable_row.add_child(empty)
		return
	for craft in recipes:
		_craftable_row.add_child(_make_craftable_chip(craft))

func _make_craftable_chip(craft: Resource) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(
		"panel", BlacksmithUiHelper.card_style(craft == _selected_craft, true)
	)
	panel.gui_input.connect(_on_craftable_chip_input.bind(craft))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	panel.add_child(col)
	col.add_child(_make_item_icon(str(craft.output_id), str(craft.output_type), _CRAFTABLE_ICON_PX))
	var name_lbl := Label.new()
	name_lbl.text = str(craft.display_name)
	name_lbl.add_theme_font_size_override("font_size", 11)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(name_lbl)
	return panel

func _on_craftable_chip_input(event: InputEvent, craft: Resource) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_category = str(craft.output_type)
		_sync_category_buttons()
		_selected_craft = craft
		_refresh_all()

func _make_item_icon(item_id: String, category: String, size_px: int) -> Control:
	var wrap := CenterContainer.new()
	wrap.custom_minimum_size = Vector2(size_px, size_px)
	var tex: Texture2D = IconPaths.get_icon_texture(item_id, category)
	if tex != null:
		var icon := TextureRect.new()
		icon.texture = tex
		icon.custom_minimum_size = Vector2(size_px, size_px)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		wrap.add_child(icon)
	else:
		var glyph := Label.new()
		glyph.text = "?"
		glyph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		glyph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		wrap.add_child(glyph)
	return wrap

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

func _craft_button_label(craft: Resource, can_craft: bool) -> String:
	if can_craft:
		return "作成"
	if GameState.gold < craft.gold_cost:
		return "Gold不足"
	return "素材不足"

func _on_craft_pressed(craft: Resource) -> void:
	if craft.output_type != "armor" and craft.output_type != "accessory" and craft.output_type != "weapon":
		_log_craft("作成できません（出力不正）")
		return
	if craft.output_id.is_empty() or not CraftHelper.craft_output_exists(craft):
		_log_craft("作成できません（出力不正）")
		return
	if GameState.gold < craft.gold_cost:
		_log_craft("ゴールドが足りません")
		return
	if not CraftHelper.has_enough_materials(craft.required_materials):
		_log_craft("素材が足りません")
		return
	GameState.gold -= craft.gold_cost
	GameState.consume_materials(craft.required_materials)
	_generate_craft_output(craft)
	DailyMissionSystem.report_progress("craft_item")
	SaveManager.save_game()
	_log_craft("作成完了: %s" % DataRegistry.get_item_name(craft.output_id, craft.output_type))
	_refresh_all()

func _on_enhance_pressed() -> void:
	if _selected_weapon == null:
		return
	var result: Dictionary = _EquipmentEnhancer.enhance_weapon(_selected_weapon)
	if not bool(result.get("ok", false)):
		_log_craft(str(result.get("reason", "炉研ぎに失敗しました")))
		_refresh_all()
		return
	SaveManager.save_game()
	_log_craft(
		"炉研ぎ成功: %s（ATK %d）" % [
			str(result.get("display_name", "")),
			int(result.get("effective_attack", 0)),
		]
	)
	_refresh_all()

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

func _log_craft(msg: String) -> void:
	print("[Craft] ", msg)
	_label_status.text = msg
	_label_status.visible = not msg.is_empty()

func _on_back_pressed() -> void:
	_go_to(HOME_SCENE)

func _go_to(scene_path: String) -> void:
	SceneRouter.change_scene(scene_path)
