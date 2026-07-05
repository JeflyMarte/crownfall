extends Control

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const ROSTER_SCENE: String = "res://scenes/roster/RosterScene.tscn"
const CODEX_SCENE: String = "res://scenes/codex/CodexScene.tscn"
const GACHA_SCENE: String = "res://scenes/gacha/GachaScene.tscn"

const COLOR_OK: Color = Color(0.7, 0.92, 0.6, 1)
const COLOR_SHORT: Color = Color(0.82, 0.45, 0.42, 1)
const COLOR_SUB: Color = UiTypography.COLOR_SUB
const COLOR_TEXT: Color = UiTypography.COLOR_BODY
const COLOR_GOLD: Color = UiTypography.COLOR_GOLD
const COLOR_ACCENT: Color = Color(0.82, 0.9, 1.0, 1)

const _AffixRoller = preload("res://scripts/equipment/AffixRoller.gd")
const _EquipmentEnhancer = preload("res://scripts/equipment/EquipmentEnhancer.gd")

const _DETAIL_ICON_PX: int = 120
const _LIST_ICON_PX: int = 48
const _CRAFTABLE_ICON_PX: int = 56
const _COST_MAT_ICON_PX: int = 48

const FORGE_FLASH_CRAFT: Color = Color(1.0, 0.78, 0.35)
const FORGE_FLASH_ENHANCE: Color = Color(0.72, 0.86, 1.0)
const FORGE_FLASH_PEAK_ALPHA: float = 0.32

@onready var _label_title: Label = $Header/HeaderRow/LabelTitle
@onready var _label_gold: Label = $Header/HeaderRow/GoldChip/GoldRow/LabelGold
@onready var _label_token: Label = $Header/HeaderRow/TokenChip/TokenRow/LabelToken
@onready var _btn_produce: Button = $ModeTabs/BtnProduce
@onready var _btn_enhance: Button = $ModeTabs/BtnEnhance
@onready var _btn_dismantle: Button = $ModeTabs/BtnDismantle
@onready var _produce_notify_dot: PanelContainer = $ModeTabs/BtnProduce/NotifyDot
@onready var _flash_overlay: ColorRect = $FxLayer/FlashOverlay
@onready var _category_row: HBoxContainer = $CategoryRow
@onready var _btn_cat_weapon: Button = $CategoryRow/BtnCatWeapon
@onready var _btn_cat_armor: Button = $CategoryRow/BtnCatArmor
@onready var _btn_cat_accessory: Button = $CategoryRow/BtnCatAccessory
@onready var _left_list: VBoxContainer = $MainSplit/LeftScroll/LeftList
@onready var _detail_panel: PanelContainer = $MainSplit/DetailPanel
@onready var _hero_frame: PanelContainer = $MainSplit/DetailPanel/DetailVBox/HeroPanel/HeroFrame
@onready var _hero_icon_slot: CenterContainer = $MainSplit/DetailPanel/DetailVBox/HeroPanel/HeroFrame/HeroIconSlot
@onready var _title_label: Label = $MainSplit/DetailPanel/DetailVBox/TitleLabel
@onready var _subtitle_label: Label = $MainSplit/DetailPanel/DetailVBox/SubtitleLabel
@onready var _stats_grid: GridContainer = $MainSplit/DetailPanel/DetailVBox/StatsGrid
@onready var _unique_panel: PanelContainer = $MainSplit/DetailPanel/DetailVBox/UniquePanel
@onready var _unique_label: Label = $MainSplit/DetailPanel/DetailVBox/UniquePanel/UniqueLabel
@onready var _cost_panel: PanelContainer = $MainSplit/DetailPanel/DetailVBox/CostPanel
@onready var _materials_row: HBoxContainer = $MainSplit/DetailPanel/DetailVBox/CostPanel/CostVBox/MaterialsRow
@onready var _gold_cost_label: Label = $MainSplit/DetailPanel/DetailVBox/CostPanel/CostVBox/GoldRow/GoldCostLabel
@onready var _cost_header_label: Label = $MainSplit/DetailPanel/DetailVBox/CostPanel/CostVBox/CostHeaderLabel
@onready var _craft_button: Button = $MainSplit/DetailPanel/DetailVBox/CraftButton
@onready var _reason_label: Label = $MainSplit/DetailPanel/DetailVBox/ReasonLabel
@onready var _craftable_panel: VBoxContainer = $CraftablePanel
@onready var _craftable_row: HBoxContainer = $CraftablePanel/CraftableScroll/CraftableRow
@onready var _label_status: Label = $LabelStatus

var _mode: String = "produce"
var _category: String = "weapon"
var _selected_craft: Resource = null
var _selected_weapon: Resource = null
var _mode_button_group: ButtonGroup
var _category_button_group: ButtonGroup
var _hero_pulse_base_scale: Vector2 = Vector2.ONE

func _ready() -> void:
	UiTypography.apply_screen_title(_label_title, UiTypography.SIZE_DISPLAY_TITLE)
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.FORGE)
	_mode_button_group = ButtonGroup.new()
	_btn_produce.button_group = _mode_button_group
	_btn_enhance.button_group = _mode_button_group
	_category_button_group = ButtonGroup.new()
	_btn_cat_weapon.button_group = _category_button_group
	_btn_cat_armor.button_group = _category_button_group
	_btn_cat_accessory.button_group = _category_button_group
	$Header/HeaderRow/ButtonBack.pressed.connect(_on_back_pressed)
	_btn_produce.pressed.connect(func(): _set_mode("produce"))
	_btn_enhance.pressed.connect(func(): _set_mode("enhance"))
	_btn_cat_weapon.pressed.connect(func(): _set_category("weapon"))
	_btn_cat_armor.pressed.connect(func(): _set_category("armor"))
	_btn_cat_accessory.pressed.connect(func(): _set_category("accessory"))
	_detail_panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_NORMAL)
	)
	_cost_panel.add_theme_stylebox_override("panel", BlacksmithUiHelper.cost_panel_style())
	_unique_panel.add_theme_stylebox_override("panel", BlacksmithUiHelper.unique_panel_style())
	BlacksmithUiHelper.apply_primary_button(_craft_button)
	_craft_button.pressed.connect(_on_craft_button_pressed)
	_produce_notify_dot.add_theme_stylebox_override("panel", BlacksmithUiHelper.notify_dot_style())
	_flash_overlay.color = Color(1.0, 1.0, 1.0, 0.0)
	_hero_pulse_base_scale = _hero_frame.scale
	_apply_detail_typography()
	_setup_tab_styles()
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
	_update_tab_styles()
	_refresh_all()

func _set_category(category: String) -> void:
	if _mode != "produce":
		return
	_category = category
	_sync_category_buttons()
	_selected_craft = null
	_update_tab_styles()
	_refresh_all()

func _sync_category_buttons() -> void:
	_btn_cat_weapon.button_pressed = _category == "weapon"
	_btn_cat_armor.button_pressed = _category == "armor"
	_btn_cat_accessory.button_pressed = _category == "accessory"

func _apply_detail_typography() -> void:
	UiTypography.apply_display(_title_label, UiTypography.SIZE_BODY, UiTypography.COLOR_BODY)
	UiTypography.apply_body(_subtitle_label, UiTypography.SIZE_CAPTION, UiTypography.COLOR_SUB)
	UiTypography.apply_body(_unique_label, UiTypography.SIZE_CAPTION, UiTypography.COLOR_GOLD)
	UiTypography.apply_body(_cost_header_label, UiTypography.SIZE_CAPTION, UiTypography.COLOR_GOLD)
	UiTypography.apply_body(_gold_cost_label, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_BODY)

func _setup_tab_styles() -> void:
	BlacksmithUiHelper.apply_mode_tab(_btn_dismantle, false)
	_update_tab_styles()

func _update_tab_styles() -> void:
	BlacksmithUiHelper.apply_mode_tab(_btn_produce, _mode == "produce")
	BlacksmithUiHelper.apply_mode_tab(_btn_enhance, _mode == "enhance")
	BlacksmithUiHelper.apply_category_tab(_btn_cat_weapon, _category == "weapon")
	BlacksmithUiHelper.apply_category_tab(_btn_cat_armor, _category == "armor")
	BlacksmithUiHelper.apply_category_tab(_btn_cat_accessory, _category == "accessory")

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
	_btn_produce.text = "生産"
	_produce_notify_dot.visible = BlacksmithUiHelper.has_craftable_recipes()

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
	var rarity: int = BlacksmithUiHelper.output_rarity(craft)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, BlacksmithUiHelper.LIST_CARD_MIN_HEIGHT)
	panel.add_theme_stylebox_override(
		"panel", BlacksmithUiHelper.list_card_style(selected, can_craft, rarity)
	)
	panel.gui_input.connect(_on_recipe_card_input.bind(craft))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	row.add_child(_make_list_icon_frame(str(craft.output_id), str(craft.output_type), rarity))
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 4)
	row.add_child(col)
	var name_lbl := Label.new()
	name_lbl.text = str(craft.display_name)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.max_lines_visible = 2
	UiTypography.apply_body(
		name_lbl,
		UiTypography.SIZE_BODY_SMALL,
		Color(0.96, 0.98, 0.92, 1.0) if can_craft else UiTypography.COLOR_BODY
	)
	col.add_child(name_lbl)
	var sub_row := HBoxContainer.new()
	sub_row.add_theme_constant_override("separation", 6)
	col.add_child(sub_row)
	var rarity_badge := Label.new()
	rarity_badge.text = BlacksmithUiHelper.rarity_short_label(rarity)
	UiTypography.apply_body(rarity_badge, 15, BlacksmithUiHelper.rarity_color(rarity), 2)
	sub_row.add_child(rarity_badge)
	var sub := Label.new()
	sub.text = "所持 %d" % BlacksmithUiHelper.owned_count(
		str(craft.output_type), str(craft.output_id)
	)
	UiTypography.apply_body(sub, UiTypography.SIZE_CAPTION, UiTypography.COLOR_SUB)
	sub_row.add_child(sub)
	return panel

func _on_recipe_card_input(event: InputEvent, craft: Resource) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_selected_craft = craft
		_refresh_all()

func _make_enhance_list_card(weapon: Resource) -> PanelContainer:
	var selected: bool = weapon == _selected_weapon
	var level: int = _EquipmentEnhancer.get_enhance_level(weapon)
	var weapon_data: Resource = DataRegistry.get_weapon_data(str(weapon.weapon_id))
	var rarity: int = int(weapon_data.rarity) if weapon_data != null else 0
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, BlacksmithUiHelper.LIST_CARD_MIN_HEIGHT)
	panel.add_theme_stylebox_override(
		"panel", BlacksmithUiHelper.list_card_style(selected, false, rarity)
	)
	panel.gui_input.connect(_on_enhance_card_input.bind(weapon))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	row.add_child(_make_list_icon_frame(str(weapon.weapon_id), "weapon", rarity))
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 4)
	row.add_child(col)
	var name_lbl := Label.new()
	name_lbl.text = _EquipmentEnhancer.get_display_name(weapon)
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.max_lines_visible = 2
	var name_color: Color = UiTypography.COLOR_BODY
	if level >= _EquipmentEnhancer.MAX_LEVEL:
		name_color = UiTypography.COLOR_GOLD
	elif selected:
		name_color = COLOR_ACCENT
	UiTypography.apply_body(name_lbl, UiTypography.SIZE_BODY_SMALL, name_color)
	col.add_child(name_lbl)
	var sub_row := HBoxContainer.new()
	sub_row.add_theme_constant_override("separation", 6)
	col.add_child(sub_row)
	var rarity_badge := Label.new()
	rarity_badge.text = BlacksmithUiHelper.rarity_short_label(rarity)
	UiTypography.apply_body(rarity_badge, 15, BlacksmithUiHelper.rarity_color(rarity), 2)
	sub_row.add_child(rarity_badge)
	var sub := Label.new()
	sub.text = "ATK %d" % _EquipmentEnhancer.get_effective_attack(weapon)
	if level > 0:
		sub.text += "  +%d" % level
	if _is_weapon_equipped(weapon):
		sub.text += "  装備中"
	UiTypography.apply_body(sub, UiTypography.SIZE_CAPTION, UiTypography.COLOR_SUB)
	sub_row.add_child(sub)
	return panel

func _on_enhance_card_input(event: InputEvent, weapon: Resource) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_selected_weapon = weapon
		_refresh_all()

func _rebuild_detail() -> void:
	_clear_stats_grid()
	_clear_materials_row()
	_clear_hero_icon()
	_unique_panel.visible = false
	_reason_label.visible = false
	_cost_panel.visible = true
	_craft_button.visible = true
	if _mode == "produce":
		_rebuild_produce_detail()
	else:
		_rebuild_enhance_detail()

func _clear_stats_grid() -> void:
	for child in _stats_grid.get_children():
		child.queue_free()

func _clear_materials_row() -> void:
	for child in _materials_row.get_children():
		child.queue_free()

func _clear_hero_icon() -> void:
	for child in _hero_icon_slot.get_children():
		child.queue_free()

func _set_detail_empty(message: String) -> void:
	_title_label.text = message
	_subtitle_label.text = ""
	_hero_frame.visible = false
	_cost_panel.visible = false
	_craft_button.visible = false

func _add_stat_row(key: String, value: String) -> void:
	var key_lbl := Label.new()
	key_lbl.text = key
	UiTypography.apply_body(key_lbl, UiTypography.SIZE_CAPTION, COLOR_SUB)
	_stats_grid.add_child(key_lbl)
	var val_lbl := Label.new()
	val_lbl.text = value
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UiTypography.apply_body(val_lbl, UiTypography.SIZE_BODY_SMALL, COLOR_TEXT)
	_stats_grid.add_child(val_lbl)

func _populate_stats_from_lines(lines: PackedStringArray) -> void:
	for line in lines:
		var text: String = str(line)
		if text.begins_with("固有スキル "):
			_unique_label.text = "固有効果\n%s" % text.substr(5)
			_unique_panel.visible = true
			continue
		var space_idx: int = text.find(" ")
		if space_idx < 0:
			_add_stat_row(text, "")
			continue
		_add_stat_row(text.substr(0, space_idx), text.substr(space_idx + 1))

func _update_hero_icon(item_id: String, category: String, rarity: int) -> void:
	_clear_hero_icon()
	_hero_frame.visible = true
	_hero_frame.add_theme_stylebox_override("panel", BlacksmithUiHelper.rarity_box(rarity, true))
	_hero_icon_slot.add_child(_make_item_icon(item_id, category, _DETAIL_ICON_PX))

func _update_cost_panel(gold_cost: int, materials: Dictionary) -> void:
	_gold_cost_label.text = "必要 Gold: %d" % gold_cost
	_gold_cost_label.add_theme_color_override(
		"font_color", COLOR_GOLD if GameState.gold >= gold_cost else COLOR_SHORT
	)
	for mat_id in materials:
		_materials_row.add_child(_make_material_req_cell(str(mat_id), int(materials[mat_id])))

func _rebuild_produce_detail() -> void:
	if _selected_craft == null:
		_set_detail_empty("レシピを選択してください")
		return
	var craft: Resource = _selected_craft
	var can_craft: bool = CraftHelper.can_craft(craft)
	var rarity: int = BlacksmithUiHelper.output_rarity(craft)
	_update_hero_icon(str(craft.output_id), str(craft.output_type), rarity)
	_title_label.text = "%s %s" % [
		BlacksmithUiHelper.rarity_gem(rarity),
		BlacksmithUiHelper.output_display_name(craft),
	]
	_title_label.add_theme_color_override(
		"font_color", BlacksmithUiHelper.rarity_color(rarity).lerp(UiTypography.COLOR_BODY, 0.45)
	)
	_subtitle_label.text = str(craft.display_name)
	_populate_stats_from_lines(BlacksmithUiHelper.preview_lines(craft))
	_add_stat_row(
		"所持数",
		"%d" % BlacksmithUiHelper.owned_count(str(craft.output_type), str(craft.output_id))
	)
	_update_cost_panel(int(craft.gold_cost), craft.required_materials)
	_craft_button.text = _craft_button_label(craft, can_craft)
	_craft_button.disabled = not can_craft

func _rebuild_enhance_detail() -> void:
	if _selected_weapon == null:
		_set_detail_empty("武器を選択してください")
		return
	var weapon: Resource = _selected_weapon
	var level: int = _EquipmentEnhancer.get_enhance_level(weapon)
	var current_atk: int = _EquipmentEnhancer.get_effective_attack(weapon)
	var weapon_data: Resource = DataRegistry.get_weapon_data(str(weapon.weapon_id))
	var rarity: int = int(weapon_data.rarity) if weapon_data != null else 0
	_update_hero_icon(str(weapon.weapon_id), "weapon", rarity)
	_title_label.text = _EquipmentEnhancer.get_display_name(weapon)
	_title_label.add_theme_color_override(
		"font_color", BlacksmithUiHelper.rarity_color(rarity).lerp(UiTypography.COLOR_BODY, 0.45)
	)
	_subtitle_label.text = "炉研ぎ +%d / +%d" % [level, _EquipmentEnhancer.MAX_LEVEL]
	if level >= _EquipmentEnhancer.MAX_LEVEL:
		_add_stat_row("攻撃力", "%d（上限）" % current_atk)
	else:
		_add_stat_row("攻撃力", "%d → %d" % [current_atk, current_atk + 1])
	if _is_weapon_equipped(weapon):
		_add_stat_row("状態", "装備中")
	if level >= _EquipmentEnhancer.MAX_LEVEL:
		_cost_panel.visible = false
		_craft_button.visible = false
		return
	var check: Dictionary = _EquipmentEnhancer.can_enhance(weapon)
	var next_level: int = int(check.get("next_level", level + 1))
	var gold_cost: int = int(check.get("gold_cost", _EquipmentEnhancer.get_gold_cost(next_level)))
	var materials: Dictionary = check.get(
		"materials", _EquipmentEnhancer.get_material_cost(next_level)
	)
	_update_cost_panel(gold_cost, materials)
	_craft_button.text = "炉で研ぐ（+%d）" % next_level
	_craft_button.disabled = not bool(check.get("ok", false))
	if not bool(check.get("ok", false)):
		_reason_label.text = str(check.get("reason", ""))
		_reason_label.visible = not _reason_label.text.is_empty()

func _on_craft_button_pressed() -> void:
	if _mode == "produce" and _selected_craft != null:
		_on_craft_pressed(_selected_craft)
	elif _mode == "enhance" and _selected_weapon != null:
		_on_enhance_pressed()

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
	var selected: bool = craft == _selected_craft
	var rarity: int = BlacksmithUiHelper.output_rarity(craft)
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.custom_minimum_size = Vector2(
		BlacksmithUiHelper.CRAFTABLE_CHIP_WIDTH,
		BlacksmithUiHelper.CRAFTABLE_CHIP_HEIGHT
	)
	panel.add_theme_stylebox_override("panel", BlacksmithUiHelper.craftable_strip_style(selected))
	panel.gui_input.connect(_on_craftable_chip_input.bind(craft))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(col)
	var icon_wrap := CenterContainer.new()
	icon_wrap.custom_minimum_size = Vector2(_CRAFTABLE_ICON_PX, _CRAFTABLE_ICON_PX)
	col.add_child(icon_wrap)
	var icon_frame := PanelContainer.new()
	icon_frame.custom_minimum_size = Vector2(_CRAFTABLE_ICON_PX, _CRAFTABLE_ICON_PX)
	icon_frame.add_theme_stylebox_override("panel", BlacksmithUiHelper.rarity_box(rarity, selected))
	icon_wrap.add_child(icon_frame)
	var icon_slot := CenterContainer.new()
	icon_slot.custom_minimum_size = Vector2(_CRAFTABLE_ICON_PX - 8, _CRAFTABLE_ICON_PX - 8)
	icon_frame.add_child(icon_slot)
	icon_slot.add_child(
		_make_item_icon(str(craft.output_id), str(craft.output_type), _CRAFTABLE_ICON_PX - 8)
	)
	BlacksmithUiHelper.add_corner_badge(
		icon_frame,
		BlacksmithUiHelper.rarity_short_label(rarity),
		BlacksmithUiHelper.rarity_color(rarity),
		Vector2(2.0, 0.0),
		10
	)
	var name_lbl := Label.new()
	name_lbl.text = str(craft.display_name)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.max_lines_visible = 2
	UiTypography.apply_body(name_lbl, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_BODY)
	col.add_child(name_lbl)
	return panel

func _on_craftable_chip_input(event: InputEvent, craft: Resource) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_category = str(craft.output_type)
		_sync_category_buttons()
		_selected_craft = craft
		_refresh_all()

func _make_list_icon_frame(item_id: String, category: String, rarity: int) -> PanelContainer:
	var frame := PanelContainer.new()
	var frame_px: int = _LIST_ICON_PX + 4
	frame.custom_minimum_size = Vector2(frame_px, frame_px)
	frame.add_theme_stylebox_override("panel", BlacksmithUiHelper.rarity_box(rarity, false))
	var slot := CenterContainer.new()
	slot.custom_minimum_size = Vector2(_LIST_ICON_PX, _LIST_ICON_PX)
	frame.add_child(slot)
	slot.add_child(_make_item_icon(item_id, category, _LIST_ICON_PX))
	BlacksmithUiHelper.add_corner_badge(
		frame,
		BlacksmithUiHelper.rarity_gem(rarity),
		BlacksmithUiHelper.rarity_color(rarity),
		Vector2(1.0, -1.0),
		12
	)
	return frame

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
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", BlacksmithUiHelper.material_chip_style(ok))
	panel.tooltip_text = "%s %d/%d" % [DataRegistry.get_material_name(mat_id), owned, needed]
	var chip := VBoxContainer.new()
	chip.add_theme_constant_override("separation", 4)
	panel.add_child(chip)
	var icon_row := CenterContainer.new()
	chip.add_child(icon_row)
	var icon_tex: Texture2D = IconPaths.get_icon_texture(mat_id, "material")
	if icon_tex != null:
		var icon := TextureRect.new()
		icon.texture = icon_tex
		icon.custom_minimum_size = Vector2(_COST_MAT_ICON_PX, _COST_MAT_ICON_PX)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_row.add_child(icon)
	var qty := Label.new()
	qty.text = "%d / %d" % [owned, needed]
	UiTypography.apply_body(qty, UiTypography.SIZE_CAPTION, COLOR_OK if ok else COLOR_SHORT)
	qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chip.add_child(qty)
	return panel

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
		return "生産する"
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
	var msg: String = "作成完了: %s" % DataRegistry.get_item_name(craft.output_id, craft.output_type)
	_log_craft(msg)
	_refresh_all()
	_play_forge_success_feedback(FORGE_FLASH_CRAFT)

func _on_enhance_pressed() -> void:
	if _selected_weapon == null:
		return
	var result: Dictionary = _EquipmentEnhancer.enhance_weapon(_selected_weapon)
	if not bool(result.get("ok", false)):
		_log_craft(str(result.get("reason", "炉研ぎに失敗しました")))
		_refresh_all()
		return
	SaveManager.save_game()
	var msg: String = "炉研ぎ成功: %s（ATK %d）" % [
		str(result.get("display_name", "")),
		int(result.get("effective_attack", 0)),
	]
	_log_craft(msg)
	_refresh_all()
	_play_forge_success_feedback(FORGE_FLASH_ENHANCE)

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

func _play_forge_success_feedback(flash_color: Color) -> void:
	_flash_forge_screen(flash_color)
	_pulse_hero_icon()

func _flash_forge_screen(flash_color: Color) -> void:
	_flash_overlay.color = Color(flash_color.r, flash_color.g, flash_color.b, 0.0)
	var tw := create_tween()
	tw.tween_property(_flash_overlay, "color:a", FORGE_FLASH_PEAK_ALPHA, 0.08)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_flash_overlay, "color:a", 0.0, 0.34)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _pulse_hero_icon() -> void:
	if not _hero_frame.visible:
		return
	_hero_frame.scale = _hero_pulse_base_scale
	var tw := create_tween()
	tw.tween_property(_hero_frame, "scale", _hero_pulse_base_scale * 1.14, 0.12)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_hero_frame, "scale", _hero_pulse_base_scale, 0.22)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_back_pressed() -> void:
	_go_to(HOME_SCENE)

func _go_to(scene_path: String) -> void:
	SceneRouter.change_scene(scene_path)
