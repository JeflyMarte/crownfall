extends Control

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const ROSTER_SCENE: String = "res://scenes/roster/RosterScene.tscn"
const CODEX_SCENE: String = "res://scenes/codex/CodexScene.tscn"
const GACHA_SCENE: String = "res://scenes/gacha/GachaScene.tscn"

const FORGE_TITLE_FONT_SIZE: int = 34
const COLOR_TEXT_STRONG: Color = Color(0.98, 0.96, 0.92, 1.0)
const COLOR_SUB_STRONG: Color = Color(0.92, 0.88, 0.82, 1.0)
const COLOR_SHORT: Color = Color(0.82, 0.45, 0.42, 1)
const COLOR_OK: Color = Color(0.55, 0.88, 0.5)
const COLOR_SUB: Color = UiTypography.COLOR_SUB
const COLOR_TEXT: Color = UiTypography.COLOR_BODY
const COLOR_GOLD: Color = UiTypography.COLOR_GOLD
const COLOR_ACCENT: Color = Color(0.82, 0.9, 1.0, 1)

const _AffixRoller = preload("res://scripts/equipment/AffixRoller.gd")
const _EquipmentEnhancer = preload("res://scripts/equipment/EquipmentEnhancer.gd")
const _WeaponStatResolver = preload("res://scripts/equipment/WeaponStatResolver.gd")
const _ArmorStatResolver = preload("res://scripts/equipment/ArmorStatResolver.gd")
const _AccessoryStatResolver = preload("res://scripts/equipment/AccessoryStatResolver.gd")

const _COST_MAT_ICON_PX: int = 48

const FORGE_FLASH_CRAFT: Color = Color(1.0, 0.78, 0.35)
const FORGE_FLASH_ENHANCE: Color = Color(0.72, 0.86, 1.0)
const FORGE_FLASH_PEAK_ALPHA: float = 0.32

@onready var _btn_back: Button = $Header/HeaderRow/ButtonBack
@onready var _label_title: Label = $Header/HeaderRow/LabelTitle
@onready var _label_gold: Label = $Header/HeaderRow/GoldChip/GoldRow/LabelGold
@onready var _label_token: Label = $Header/HeaderRow/TokenChip/TokenRow/LabelToken
@onready var _btn_produce: Button = $ModeTabs/BtnProduce
@onready var _btn_enhance: Button = $ModeTabs/BtnEnhance
@onready var _btn_dismantle: Button = $ModeTabs/BtnDismantle
@onready var _produce_notify_dot: PanelContainer = $ModeTabs/BtnProduce/NotifyDot
@onready var _flash_overlay: ColorRect = $FxLayer/FlashOverlay
@onready var _category_row: HBoxContainer = $CategoryRow
@onready var _left_list: VBoxContainer = $MainSplit/LeftScroll/LeftList
@onready var _detail_panel: PanelContainer = $MainSplit/DetailPanel
@onready var _hero_pedestal: TextureRect = $MainSplit/DetailPanel/DetailVBox/HeroPanel/HeroStack/HeroPedestal
@onready var _hero_weapon_pivot: Control = $MainSplit/DetailPanel/DetailVBox/HeroPanel/HeroStack/HeroWeaponPivot
@onready var _hero_icon_slot: Control = $MainSplit/DetailPanel/DetailVBox/HeroPanel/HeroStack/HeroWeaponPivot/HeroIconSlot
@onready var _rarity_title_label: Label = $MainSplit/DetailPanel/DetailVBox/RarityTitleLabel
@onready var _title_label: Label = $MainSplit/DetailPanel/DetailVBox/TitleLabel
@onready var _subtitle_label: Label = $MainSplit/DetailPanel/DetailVBox/SubtitleLabel
@onready var _stats_grid: GridContainer = $MainSplit/DetailPanel/DetailVBox/StatsGrid
@onready var _unique_panel: PanelContainer = $MainSplit/DetailPanel/DetailVBox/UniquePanel
@onready var _unique_label: Label = $MainSplit/DetailPanel/DetailVBox/UniquePanel/UniqueLabel
@onready var _cost_panel: PanelContainer = $MainSplit/DetailPanel/DetailVBox/CostPanel
@onready var _anvil_bg: TextureRect = $MainSplit/DetailPanel/DetailVBox/CostPanel/CostRoot/AnvilBg
@onready var _materials_row: HBoxContainer = $MainSplit/DetailPanel/DetailVBox/CostPanel/CostRoot/CostVBox/MaterialsRow
@onready var _gold_cost_label: Label = $MainSplit/DetailPanel/DetailVBox/CostPanel/CostRoot/CostVBox/GoldRow/GoldCostLabel
@onready var _cost_header_label: Label = $MainSplit/DetailPanel/DetailVBox/CostPanel/CostRoot/CostVBox/CostHeaderLabel
@onready var _craft_button: Button = $MainSplit/DetailPanel/DetailVBox/CraftButton
@onready var _reason_label: Label = $MainSplit/DetailPanel/DetailVBox/ReasonLabel
@onready var _craftable_panel: VBoxContainer = $CraftablePanel
@onready var _craftable_header: Label = $CraftablePanel/LabelCraftableHeader
@onready var _craftable_row: HBoxContainer = $CraftablePanel/CraftableScroll/CraftableRow
@onready var _label_status: Label = $LabelStatus

var _mode: String = "produce"
var _category: String = "weapon"
var _selected_craft: Resource = null
var _selected_weapon: Resource = null
var _mode_button_group: ButtonGroup
var _category_panels: Dictionary = {}
var _hero_pulse_base_scale: Vector2 = Vector2.ONE

func _ready() -> void:
	_label_title.text = ""
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.FORGE)
	_mode_button_group = ButtonGroup.new()
	_btn_produce.button_group = _mode_button_group
	_btn_enhance.button_group = _mode_button_group
	_btn_back.pressed.connect(_on_back_pressed)
	_btn_produce.pressed.connect(func(): _set_mode("produce"))
	_btn_enhance.pressed.connect(func(): _set_mode("enhance"))
	if EventSystem.PERIODIC_EVENTS_ENABLED and EventSystem.has_signal("event_updated"):
		pass
	_detail_panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_NORMAL)
	)
	_cost_panel.add_theme_stylebox_override("panel", BlacksmithUiHelper.cost_panel_style())
	_unique_panel.add_theme_stylebox_override("panel", BlacksmithUiHelper.unique_panel_style())
	BlacksmithUiHelper.apply_primary_button(_craft_button)
	_craft_button.pressed.connect(_on_craft_button_pressed)
	_produce_notify_dot.add_theme_stylebox_override("panel", BlacksmithUiHelper.notify_dot_style())
	_flash_overlay.color = Color(1.0, 1.0, 1.0, 0.0)
	_hero_pulse_base_scale = _hero_weapon_pivot.scale
	_setup_hero_display_layout()
	_setup_forge_chrome()
	_apply_detail_typography()
	_detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cost_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_craft_button.size_flags_vertical = Control.SIZE_SHRINK_END
	_setup_craftable_header()
	_setup_tab_styles()
	_set_mode("produce")


func _setup_craftable_header() -> void:
	UiTypography.apply_body(_craftable_header, UiTypography.SIZE_CAPTION, UiTypography.COLOR_GOLD)

func _setup_hero_display_layout() -> void:
	var pedestal_px: int = ForgeUiTokens.HERO_PEDESTAL_PX
	var display_px: int = ForgeUiTokens.HERO_DISPLAY_PX
	var half_ped: float = pedestal_px * 0.5
	_hero_pedestal.offset_left = -half_ped
	_hero_pedestal.offset_top = -half_ped
	_hero_pedestal.offset_right = half_ped
	_hero_pedestal.offset_bottom = half_ped
	var half_weapon: float = display_px * 0.5
	_hero_weapon_pivot.offset_left = -half_weapon
	_hero_weapon_pivot.offset_top = -half_weapon
	_hero_weapon_pivot.offset_right = half_weapon
	_hero_weapon_pivot.offset_bottom = half_weapon
	_hero_weapon_pivot.pivot_offset = Vector2(half_weapon, half_weapon)
	_hero_weapon_pivot.rotation_degrees = 0.0
	_hero_icon_slot.custom_minimum_size = Vector2(display_px, display_px)
	_hero_pedestal.visible = false
	_hero_weapon_pivot.visible = false

func _setup_forge_chrome() -> void:
	var back_tex: Texture2D = ForgeUiTokens.back_icon()
	if back_tex != null:
		_btn_back.text = ""
		_btn_back.icon = back_tex
		_btn_back.expand_icon = true
		_btn_back.custom_minimum_size = Vector2(40, 40)
	var pedestal_tex: Texture2D = ForgeUiTokens.load_tex(ForgeUiTokens.HERO_GLOW)
	if pedestal_tex != null:
		_hero_pedestal.texture = pedestal_tex
		_hero_pedestal.modulate = Color(1.0, 1.0, 1.0, 1.0)
	var anvil_tex: Texture2D = ForgeUiTokens.load_tex(ForgeUiTokens.ANVIL_PANEL)
	if anvil_tex != null:
		_anvil_bg.texture = anvil_tex
	_build_category_icons()

func _set_mode(mode: String) -> void:
	_mode = mode
	_btn_produce.button_pressed = mode == "produce"
	_btn_enhance.button_pressed = mode == "enhance"
	_category_row.visible = mode == "produce"
	_craftable_panel.visible = mode == "produce"
	if mode == "enhance" and _category != "weapon":
		_category = "weapon"
	_update_category_styles()
	_update_tab_styles()
	_refresh_all()

func _set_category(category: String) -> void:
	if _mode != "produce":
		return
	_category = category
	_selected_craft = null
	_update_category_styles()
	_refresh_all()

func _build_category_icons() -> void:
	for child in _category_row.get_children():
		child.queue_free()
	_category_panels.clear()
	for cat in ["weapon", "armor", "accessory"]:
		var wrap := PanelContainer.new()
		wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		wrap.custom_minimum_size = ForgeUiTokens.CATEGORY_MIN_SIZE
		wrap.add_theme_stylebox_override(
			"panel", BlacksmithUiHelper.category_tab_style(_category == cat)
		)
		_category_row.add_child(wrap)
		_category_panels[cat] = wrap
		var col := VBoxContainer.new()
		col.set_anchors_preset(Control.PRESET_FULL_RECT)
		col.offset_left = 4
		col.offset_top = 4
		col.offset_right = -4
		col.offset_bottom = -4
		col.add_theme_constant_override("separation", 2)
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrap.add_child(col)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(52, 52)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = ForgeUiTokens.category_icon(cat)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(icon)
		var lbl := Label.new()
		lbl.text = BlacksmithUiHelper.category_label(cat)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UiTypography.apply_caption(lbl)
		col.add_child(lbl)
		var btn := Button.new()
		btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.flat = true
		btn.pressed.connect(func(): _set_category(cat))
		wrap.add_child(btn)

func _update_category_styles() -> void:
	for cat in _category_panels.keys():
		var panel: PanelContainer = _category_panels[cat]
		if panel != null:
			panel.add_theme_stylebox_override(
				"panel", BlacksmithUiHelper.category_tab_style(_category == str(cat))
			)

func _apply_detail_typography() -> void:
	_rarity_title_label.visible = false
	UiTypography.apply_display(_title_label, UiTypography.SIZE_BODY, COLOR_TEXT_STRONG)
	UiTypography.apply_body(_subtitle_label, UiTypography.SIZE_BODY_SMALL, COLOR_SUB_STRONG)
	UiTypography.apply_body(_unique_label, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	UiTypography.apply_body(_cost_header_label, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	UiTypography.apply_body(_gold_cost_label, UiTypography.SIZE_BODY, COLOR_TEXT_STRONG)

func _setup_tab_styles() -> void:
	BlacksmithUiHelper.apply_mode_tab(_btn_dismantle, false)
	_update_tab_styles()

func _update_tab_styles() -> void:
	BlacksmithUiHelper.apply_mode_tab(_btn_produce, _mode == "produce")
	BlacksmithUiHelper.apply_mode_tab(_btn_enhance, _mode == "enhance")
	BlacksmithUiHelper.apply_mode_tab(_btn_dismantle, false)

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
	label.add_theme_color_override("font_color", COLOR_SUB_STRONG)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _make_recipe_list_card(craft: Resource) -> PanelContainer:
	var can_craft: bool = CraftHelper.can_craft(craft)
	var selected: bool = craft == _selected_craft
	var rarity: int = BlacksmithUiHelper.output_rarity(craft)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, BlacksmithUiHelper.LIST_CARD_MIN_HEIGHT)
	panel.add_theme_stylebox_override(
		"panel", BlacksmithUiHelper.simple_list_card_style(selected, can_craft, rarity)
	)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	var icon_host := _make_selectable_list_icon(
		str(craft.output_id),
		str(craft.output_type),
		craft,
		"_on_recipe_card_input",
		rarity
	)
	row.add_child(icon_host)
	var name_lbl := Label.new()
	name_lbl.text = BlacksmithUiHelper.output_display_name(craft)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.max_lines_visible = 2
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiTypography.apply_body(
		name_lbl,
		UiTypography.SIZE_BODY_SMALL,
		COLOR_TEXT_STRONG if selected else UiTypography.COLOR_BODY
	)
	row.add_child(name_lbl)
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
		"panel", BlacksmithUiHelper.simple_list_card_style(selected, false, rarity)
	)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	var icon_host := _make_selectable_list_icon(
		str(weapon.weapon_id), "weapon", weapon, "_on_enhance_card_input", rarity
	)
	row.add_child(icon_host)
	var name_lbl := Label.new()
	name_lbl.text = _EquipmentEnhancer.get_display_name(weapon)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.max_lines_visible = 2
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var name_color: Color = UiTypography.COLOR_BODY
	if level >= _EquipmentEnhancer.MAX_FORGE_LEVEL:
		name_color = UiTypography.COLOR_GOLD
	elif selected:
		name_color = COLOR_ACCENT
	UiTypography.apply_body(name_lbl, UiTypography.SIZE_BODY_SMALL, name_color)
	row.add_child(name_lbl)
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
	_rarity_title_label.visible = false
	_rarity_title_label.text = ""
	_title_label.text = message
	_subtitle_label.text = ""
	_hero_weapon_pivot.visible = false
	_hero_pedestal.visible = false
	_cost_panel.visible = false
	_craft_button.visible = false

func _add_stat_row(key: String, value: String, stat_key: String = "") -> void:
	var left := HBoxContainer.new()
	left.add_theme_constant_override("separation", 6)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not stat_key.is_empty():
		var stat_tex: Texture2D = ForgeUiTokens.stat_icon(stat_key)
		if stat_tex != null:
			var icon := TextureRect.new()
			icon.texture = stat_tex
			icon.custom_minimum_size = Vector2(
				ForgeUiTokens.STAT_ICON_PX, ForgeUiTokens.STAT_ICON_PX
			)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			left.add_child(icon)
	var key_lbl := Label.new()
	key_lbl.text = key
	key_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_body(key_lbl, UiTypography.SIZE_BODY_SMALL, COLOR_SUB_STRONG)
	left.add_child(key_lbl)
	_stats_grid.add_child(left)
	var val_lbl := Label.new()
	val_lbl.text = value
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_body(val_lbl, UiTypography.SIZE_BODY, COLOR_TEXT_STRONG)
	_stats_grid.add_child(val_lbl)

func _populate_stats_from_entries(entries: Array) -> void:
	for entry in entries:
		if entry is Dictionary:
			_add_stat_row(
				str(entry.get("label", "")),
				str(entry.get("value", "")),
				str(entry.get("key", ""))
			)

func _populate_unique_from_craft(craft: Resource) -> void:
	if craft == null or str(craft.output_type) != "weapon":
		return
	var wd: Resource = DataRegistry.get_weapon_data(str(craft.output_id))
	if wd == null:
		return
	var effect_text: String = EquipmentItemDetailHelper.weapon_legendary_effect_text_from_data(wd)
	if effect_text.is_empty():
		return
	_unique_label.text = "固有効果\n%s" % effect_text
	_unique_panel.visible = true

func _add_stats_section_spacer(height: float = 14.0) -> void:
	for _i in 2:
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(0, height)
		gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_stats_grid.add_child(gap)

func _update_hero_icon(item_id: String, category: String, _rarity: int) -> void:
	_clear_hero_icon()
	_hero_pedestal.visible = true
	_hero_weapon_pivot.visible = true
	_hero_weapon_pivot.rotation_degrees = 0.0
	BlacksmithUiHelper.attach_hero_icon(
		_hero_icon_slot, item_id, category, ForgeUiTokens.HERO_DISPLAY_PX
	)

func _update_cost_panel(gold_cost: int, materials: Dictionary) -> void:
	_gold_cost_label.text = "必要ゴールド: %d" % gold_cost
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
	_rarity_title_label.visible = false
	_rarity_title_label.text = ""
	var rarity_col: Color = BlacksmithUiHelper.rarity_color(rarity)
	_title_label.text = BlacksmithUiHelper.output_display_name(craft)
	_title_label.add_theme_color_override(
		"font_color", rarity_col.lerp(UiTypography.COLOR_BODY, 0.45)
	)
	_subtitle_label.text = BlacksmithUiHelper.output_subtitle(craft)
	_populate_stats_from_entries(BlacksmithUiHelper.craft_stat_entries(craft))
	_add_stats_section_spacer()
	var owned: int = BlacksmithUiHelper.owned_count(str(craft.output_type), str(craft.output_id))
	_add_stat_row("所持数", "%d" % owned)
	_populate_unique_from_craft(craft)
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
	_rarity_title_label.visible = false
	_rarity_title_label.text = ""
	var rarity_col: Color = BlacksmithUiHelper.rarity_color(rarity)
	_title_label.text = _EquipmentEnhancer.get_display_name(weapon)
	_title_label.add_theme_color_override(
		"font_color", rarity_col.lerp(UiTypography.COLOR_BODY, 0.45)
	)
	_subtitle_label.text = "炉研ぎ +%d / +%d" % [level, _EquipmentEnhancer.MAX_FORGE_LEVEL]
	if level >= _EquipmentEnhancer.MAX_FORGE_LEVEL:
		_add_stat_row("攻撃力", "%d（上限）" % current_atk, "atk")
	else:
		_add_stat_row("攻撃力", "%d → %d" % [current_atk, current_atk + 1], "atk")
	if _is_weapon_equipped(weapon):
		_add_stat_row("状態", "装備中")
	if level >= _EquipmentEnhancer.MAX_FORGE_LEVEL:
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
		empty.add_theme_color_override("font_color", COLOR_SUB_STRONG)
		_craftable_row.add_child(empty)
		return
	for craft in recipes:
		_craftable_row.add_child(_make_craftable_chip(craft))

func _make_selectable_list_icon(
	item_id: String,
	category: String,
	payload: Resource,
	handler_name: String,
	rarity: int = 0
) -> Control:
	var cell_px: int = BlacksmithUiHelper.list_cell_px()
	var host := Control.new()
	host.custom_minimum_size = Vector2(cell_px, cell_px)
	host.mouse_filter = Control.MOUSE_FILTER_STOP
	host.gui_input.connect(Callable(self, handler_name).bind(payload))
	host.add_child(
		BlacksmithUiHelper.make_item_icon_cell(item_id, category, rarity, cell_px, false)
	)
	return host

func _make_craftable_chip(craft: Resource) -> PanelContainer:
	var selected: bool = craft == _selected_craft
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
	var cell_px: int = BlacksmithUiHelper.list_cell_px()
	icon_wrap.custom_minimum_size = Vector2(cell_px, cell_px)
	col.add_child(icon_wrap)
	var chip_rarity: int = BlacksmithUiHelper.output_rarity(craft)
	icon_wrap.add_child(
		BlacksmithUiHelper.make_item_icon_cell(
			str(craft.output_id), str(craft.output_type), chip_rarity, cell_px, false
		)
	)
	var can_make: bool = CraftHelper.can_craft(craft)
	var name_lbl := Label.new()
	name_lbl.text = BlacksmithUiHelper.output_display_name(craft)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.max_lines_visible = 2
	UiTypography.apply_body(
		name_lbl,
		UiTypography.SIZE_BODY_SMALL,
		Color(0.96, 0.98, 0.92, 1.0) if can_make else UiTypography.COLOR_BODY
	)
	col.add_child(name_lbl)
	return panel

func _on_craftable_chip_input(event: InputEvent, craft: Resource) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cat: String = str(craft.output_type)
		if _category != cat:
			_category = cat
			_update_category_styles()
		_selected_craft = craft
		_refresh_all()

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
	_WeaponStatResolver.apply_drop_stats(instance, weapon_data)
	_auto_appraise(instance, _AffixRoller.CATEGORY_WEAPON, weapon_data.rarity)
	GameState.inventory.append(instance)

func _spawn_armor(armor_id: String) -> void:
	var armor_data: Resource = DataRegistry.get_armor_data(armor_id)
	if armor_data == null:
		return
	var instance := ArmorInstance.new()
	instance.instance_id = str(Time.get_ticks_msec()) + "_craft_" + str(randi() % 100000)
	instance.armor_id = armor_id
	_ArmorStatResolver.apply_drop_stats(instance, armor_data)
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
	_AccessoryStatResolver.apply_drop_stats(instance, accessory_data)
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
	if not _hero_weapon_pivot.visible:
		return
	_hero_weapon_pivot.scale = _hero_pulse_base_scale
	var tw := create_tween()
	tw.tween_property(_hero_weapon_pivot, "scale", _hero_pulse_base_scale * 1.08, 0.12)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_hero_weapon_pivot, "scale", _hero_pulse_base_scale, 0.22)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_back_pressed() -> void:
	_go_to(HOME_SCENE)

func _go_to(scene_path: String) -> void:
	SceneRouter.change_scene(scene_path)
