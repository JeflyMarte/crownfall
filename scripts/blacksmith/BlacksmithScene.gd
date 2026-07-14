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
const _MaterialUiTokens = preload("res://scripts/equipment/MaterialUiTokens.gd")
const COLOR_ACCENT: Color = Color(0.82, 0.9, 1.0, 1)

const _AffixRoller = preload("res://scripts/equipment/AffixRoller.gd")
const _EquipmentEnhancer = preload("res://scripts/equipment/EquipmentEnhancer.gd")
const _WeaponStatResolver = preload("res://scripts/equipment/WeaponStatResolver.gd")
const _ArmorStatResolver = preload("res://scripts/equipment/ArmorStatResolver.gd")
const _AccessoryStatResolver = preload("res://scripts/equipment/AccessoryStatResolver.gd")

const _COST_MAT_ICON_PX: int = 48

const FORGE_FLASH_CRAFT: Color = Color(1.0, 0.78, 0.35)
const FORGE_FLASH_ENHANCE: Color = Color(0.72, 0.86, 1.0)
const FORGE_FLASH_ALCHEMY: Color = Color(0.55, 0.92, 0.78)
const FORGE_FLASH_DISMANTLE: Color = Color(0.86, 0.72, 1.0)
const FORGE_FLASH_PEAK_ALPHA: float = 0.32

@onready var _btn_back: Button = $Header/HeaderRow/ButtonBack
@onready var _label_title: Label = $Header/HeaderRow/LabelTitle
@onready var _label_gold: Label = $Header/HeaderRow/GoldChip/GoldRow/LabelGold
@onready var _label_token: Label = $Header/HeaderRow/TokenChip/TokenRow/LabelToken
@onready var _btn_produce: Button = $ModeTabs/BtnProduce
@onready var _btn_enhance: Button = $ModeTabs/BtnEnhance
@onready var _btn_alchemy: Button = $ModeTabs/BtnAlchemy
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
var _selected_enhance_item: Resource = null
var _selected_alchemy_base: Resource = null
var _selected_alchemy_fodder: Resource = null
var _selected_dismantle_item: Resource = null
var _mode_button_group: ButtonGroup
var _category_panels: Dictionary = {}
var _hero_pulse_base_scale: Vector2 = Vector2.ONE
var _bulk_dismantle_btn: Button
var _dismantle_confirm: ConfirmationDialog
var _legendary_dismantle_confirm: ConfirmationDialog
var _legendary_dismantle_final_confirm: ConfirmationDialog
var _alchemy_confirm: ConfirmationDialog
var _pending_dismantle_item: Resource = null

func _ready() -> void:
	_label_title.text = ""
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.FORGE)
	_mode_button_group = ButtonGroup.new()
	_btn_produce.button_group = _mode_button_group
	_btn_enhance.button_group = _mode_button_group
	_btn_alchemy.button_group = _mode_button_group
	_btn_dismantle.button_group = _mode_button_group
	_btn_back.pressed.connect(_on_back_pressed)
	_btn_produce.pressed.connect(func(): _set_mode("produce"))
	_btn_enhance.pressed.connect(func(): _set_mode("enhance"))
	_btn_alchemy.pressed.connect(func(): _set_mode("alchemy"))
	_btn_dismantle.pressed.connect(func(): _set_mode("dismantle"))
	_btn_dismantle.disabled = false
	_btn_dismantle.text = "分解"
	_btn_alchemy.text = "錬成"
	_setup_dismantle_dialogs()
	_setup_alchemy_confirm()
	_setup_bulk_dismantle_button()
	_detail_panel.add_theme_stylebox_override(
		"panel", BlacksmithUiHelper.detail_panel_style()
	)
	_cost_panel.add_theme_stylebox_override("panel", BlacksmithUiHelper.cost_panel_style())
	_unique_panel.add_theme_stylebox_override("panel", BlacksmithUiHelper.unique_panel_style())
	BlacksmithUiHelper.apply_bulk_dismantle_button(_bulk_dismantle_btn)
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

func _setup_alchemy_confirm() -> void:
	_alchemy_confirm = ConfirmationDialog.new()
	_alchemy_confirm.title = "装備錬成"
	_alchemy_confirm.ok_button_text = "錬成する"
	_alchemy_confirm.cancel_button_text = "やめる"
	_alchemy_confirm.confirmed.connect(_execute_alchemy)
	_alchemy_confirm.canceled.connect(_on_forge_confirm_canceled)
	add_child(_alchemy_confirm)


func _on_forge_confirm_canceled() -> void:
	AudioManager.play_sfx("ui_cancel")


func _setup_dismantle_dialogs() -> void:
	_dismantle_confirm = ConfirmationDialog.new()
	_dismantle_confirm.title = "装備分解"
	_dismantle_confirm.ok_button_text = "分解する"
	_dismantle_confirm.cancel_button_text = "やめる"
	_dismantle_confirm.confirmed.connect(_on_bulk_dismantle_confirmed)
	_dismantle_confirm.canceled.connect(_on_forge_confirm_canceled)
	add_child(_dismantle_confirm)
	_legendary_dismantle_confirm = ConfirmationDialog.new()
	_legendary_dismantle_confirm.title = "レジェンド装備の分解（1/2）"
	_legendary_dismantle_confirm.ok_button_text = "続ける"
	_legendary_dismantle_confirm.cancel_button_text = "やめる"
	_legendary_dismantle_confirm.confirmed.connect(_on_legendary_dismantle_step1)
	_legendary_dismantle_confirm.canceled.connect(_on_forge_confirm_canceled)
	add_child(_legendary_dismantle_confirm)
	_legendary_dismantle_final_confirm = ConfirmationDialog.new()
	_legendary_dismantle_final_confirm.title = "レジェンド装備の分解（2/2）"
	_legendary_dismantle_final_confirm.ok_button_text = "分解する"
	_legendary_dismantle_final_confirm.cancel_button_text = "やめる"
	_legendary_dismantle_final_confirm.confirmed.connect(_on_legendary_dismantle_final)
	_legendary_dismantle_final_confirm.canceled.connect(_on_forge_confirm_canceled)
	add_child(_legendary_dismantle_final_confirm)

func _setup_bulk_dismantle_button() -> void:
	_bulk_dismantle_btn = Button.new()
	_bulk_dismantle_btn.text = "◇◆を一括分解"
	_bulk_dismantle_btn.visible = false
	_bulk_dismantle_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bulk_dismantle_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	BlacksmithUiHelper.apply_bulk_dismantle_button(_bulk_dismantle_btn)
	_bulk_dismantle_btn.pressed.connect(_on_bulk_dismantle_pressed)
	# MainSplit(HBox) の第3列にすると縦に肥大化し左一覧を圧迫するため、
	# 詳細パネル内・分解ボタン直下に置く。
	var detail_vbox: VBoxContainer = $MainSplit/DetailPanel/DetailVBox
	detail_vbox.add_child(_bulk_dismantle_btn)
	detail_vbox.move_child(_bulk_dismantle_btn, _craft_button.get_index() + 1)

func _setup_forge_chrome() -> void:
	var back_tex: Texture2D = ForgeUiTokens.back_icon()
	if back_tex != null:
		_btn_back.text = ""
		_btn_back.icon = back_tex
		_btn_back.expand_icon = true
		_btn_back.custom_minimum_size = Vector2(40, 40)
	# 武器詳細ヒーロー: 武器背景ペデスタル + 素のアイコン（Glow は載せない）。
	_hero_pedestal.texture = ForgeUiTokens.load_tex(ForgeUiTokens.HERO_ITEM_BG)
	_hero_pedestal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_hero_pedestal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_hero_pedestal.visible = false
	_build_category_icons()

func _set_mode(mode: String) -> void:
	_mode = mode
	_btn_produce.button_pressed = mode == "produce"
	_btn_enhance.button_pressed = mode == "enhance"
	_btn_alchemy.button_pressed = mode == "alchemy"
	_btn_dismantle.button_pressed = mode == "dismantle"
	_category_row.visible = (
		mode == "produce" or mode == "enhance" or mode == "alchemy" or mode == "dismantle"
	)
	_craftable_panel.visible = mode == "produce" or mode == "alchemy"
	_bulk_dismantle_btn.visible = mode == "dismantle"
	if mode == "enhance":
		_selected_enhance_item = null
	elif mode == "alchemy":
		_selected_alchemy_base = null
		_selected_alchemy_fodder = null
	elif mode == "dismantle":
		_selected_dismantle_item = null
	_update_category_styles()
	_update_tab_styles()
	_apply_craft_button_style()
	_refresh_all()


func _apply_craft_button_style() -> void:
	match _mode:
		"enhance", "alchemy":
			BlacksmithUiHelper.apply_primary_button(
				_craft_button, BlacksmithUiHelper.PRIMARY_KIND_ENHANCE
			)
		"dismantle":
			BlacksmithUiHelper.apply_primary_button(
				_craft_button, BlacksmithUiHelper.PRIMARY_KIND_DISMANTLE
			)
		_:
			BlacksmithUiHelper.apply_primary_button(
				_craft_button, BlacksmithUiHelper.PRIMARY_KIND_PRODUCE
			)

func _set_category(category: String) -> void:
	if _mode == "produce":
		_category = category
		_selected_craft = null
	elif _mode == "enhance" or _mode == "alchemy" or _mode == "dismantle":
		_category = category
		if _mode == "enhance":
			_selected_enhance_item = null
		elif _mode == "alchemy":
			_selected_alchemy_base = null
			_selected_alchemy_fodder = null
		else:
			_selected_dismantle_item = null
	else:
		return
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
			"panel", BlacksmithUiHelper.category_tab_style(_category_tab_active(cat))
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

func _category_tab_active(cat: String) -> bool:
	return _category == cat and (
		_mode == "produce" or _mode == "enhance" or _mode == "alchemy" or _mode == "dismantle"
	)

func _update_category_styles() -> void:
	for cat in _category_panels.keys():
		var panel: PanelContainer = _category_panels[cat]
		if panel != null:
			panel.add_theme_stylebox_override(
				"panel", BlacksmithUiHelper.category_tab_style(_category_tab_active(str(cat)))
			)

func _apply_detail_typography() -> void:
	_rarity_title_label.visible = false
	UiTypography.apply_display(_title_label, UiTypography.SIZE_BODY, COLOR_TEXT_STRONG)
	UiTypography.apply_body(_subtitle_label, UiTypography.SIZE_BODY_SMALL, COLOR_SUB_STRONG)
	UiTypography.apply_body(_unique_label, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	UiTypography.apply_body(_cost_header_label, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	UiTypography.apply_body(_gold_cost_label, UiTypography.SIZE_BODY, COLOR_TEXT_STRONG)
	# 統計・理由ラベルも暗背景で読めるよう強めの色を既定に
	_reason_label.add_theme_color_override("font_color", COLOR_SUB_STRONG)

func _setup_tab_styles() -> void:
	_update_tab_styles()

func _update_tab_styles() -> void:
	BlacksmithUiHelper.apply_mode_tab(_btn_produce, _mode == "produce")
	BlacksmithUiHelper.apply_mode_tab(_btn_enhance, _mode == "enhance")
	BlacksmithUiHelper.apply_mode_tab(_btn_alchemy, _mode == "alchemy")
	BlacksmithUiHelper.apply_mode_tab(_btn_dismantle, _mode == "dismantle")

func _refresh_all() -> void:
	_update_currency()
	_update_mode_tab_dots()
	_rebuild_left_list()
	_rebuild_detail()
	if _mode == "produce":
		_rebuild_craftable_strip()
	elif _mode == "alchemy":
		_rebuild_alchemy_fodder_strip()

func _update_currency() -> void:
	_label_gold.text = "%d" % GameState.gold
	_label_token.text = CurrencyHelper.format_amount()

func _update_mode_tab_dots() -> void:
	_btn_produce.text = "生産"
	_btn_alchemy.text = "錬成"
	_produce_notify_dot.visible = BlacksmithUiHelper.has_craftable_recipes()

func _rebuild_left_list() -> void:
	for child in _left_list.get_children():
		child.queue_free()
	if _mode == "produce":
		_rebuild_produce_left_list()
	elif _mode == "enhance":
		_rebuild_enhance_left_list()
	elif _mode == "alchemy":
		_rebuild_alchemy_left_list()
	else:
		_rebuild_dismantle_left_list()
	_update_bulk_dismantle_button()

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
	var items: Array = _sorted_enhance_candidates()
	if items.is_empty():
		_left_list.add_child(_make_empty_label(_empty_label_for_category(_category, "enhance")))
		_selected_enhance_item = null
		return
	if _selected_enhance_item == null or _selected_enhance_item not in items:
		_selected_enhance_item = items[0]
	for item in items:
		_left_list.add_child(_make_enhance_list_card(item))

func _rebuild_dismantle_left_list() -> void:
	var items: Array = _sorted_dismantle_candidates()
	if items.is_empty():
		_left_list.add_child(_make_empty_label(_empty_label_for_category(_category, "dismantle")))
		_selected_dismantle_item = null
		return
	if _selected_dismantle_item == null or _selected_dismantle_item not in items:
		_selected_dismantle_item = items[0]
	for item in items:
		_left_list.add_child(_make_dismantle_list_card(item))


func _rebuild_alchemy_left_list() -> void:
	var items: Array = _sorted_alchemy_base_candidates()
	if items.is_empty():
		_left_list.add_child(_make_empty_label(_empty_label_for_category(_category, "alchemy")))
		_selected_alchemy_base = null
		_selected_alchemy_fodder = null
		return
	if _selected_alchemy_base == null or _selected_alchemy_base not in items:
		_selected_alchemy_base = items[0]
		_selected_alchemy_fodder = null
	for item in items:
		_left_list.add_child(_make_alchemy_base_card(item))

func _empty_label_for_category(category: String, mode: String) -> String:
	var kind: String = BlacksmithUiHelper.category_label(category)
	if mode == "dismantle":
		return "（分解可能な%sがありません）" % kind
	if mode == "alchemy":
		return "（錬成できる%sがありません）" % kind
	return "（鑑定済みの%sがありません）" % kind

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
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override(
		"panel", BlacksmithUiHelper.simple_list_card_style(selected, can_craft, rarity)
	)
	panel.gui_input.connect(_on_recipe_card_input.bind(craft))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)
	var icon_host := _make_selectable_list_icon(
		str(craft.output_id),
		str(craft.output_type),
		rarity,
		selected
	)
	row.add_child(icon_host)
	var name_lbl := Label.new()
	name_lbl.text = BlacksmithUiHelper.output_display_name(craft)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_list_name_label(name_lbl, BlacksmithUiHelper.rarity_name_color(rarity))
	row.add_child(name_lbl)
	return panel

func _on_recipe_card_input(event: InputEvent, craft: Resource) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_selected_craft = craft
		_refresh_all()

func _make_enhance_list_card(item: Resource) -> PanelContainer:
	var selected: bool = item == _selected_enhance_item
	var level: int = _EquipmentEnhancer.get_enhance_level(item)
	var category: String = _category
	var item_id: String = _item_id_for_category(item, category)
	var rarity: int = _EquipmentEnhancer.item_rarity(item)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, BlacksmithUiHelper.LIST_CARD_MIN_HEIGHT)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override(
		"panel", BlacksmithUiHelper.simple_list_card_style(selected, false, rarity)
	)
	panel.gui_input.connect(_on_enhance_card_input.bind(item))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)
	row.add_child(_make_selectable_list_icon(item_id, category, rarity, selected))
	var name_lbl := Label.new()
	name_lbl.text = _EquipmentEnhancer.get_display_name(item)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var name_color: Color = BlacksmithUiHelper.rarity_name_color(rarity)
	if level >= _EquipmentEnhancer.MAX_FORGE_LEVEL:
		name_color = UiTypography.COLOR_GOLD
	_apply_list_name_label(name_lbl, name_color)
	row.add_child(name_lbl)
	return panel

func _make_dismantle_list_card(item: Resource) -> PanelContainer:
	var selected: bool = item == _selected_dismantle_item
	var category: String = _category
	var item_id: String = _item_id_for_category(item, category)
	var rarity: int = _EquipmentEnhancer.item_rarity(item)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, BlacksmithUiHelper.LIST_CARD_MIN_HEIGHT)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override(
		"panel", BlacksmithUiHelper.simple_list_card_style(selected, false, rarity)
	)
	panel.gui_input.connect(_on_dismantle_card_input.bind(item))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)
	row.add_child(_make_selectable_list_icon(item_id, category, rarity, selected))
	var name_lbl := Label.new()
	name_lbl.text = _EquipmentEnhancer.get_display_name(item)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_list_name_label(name_lbl, BlacksmithUiHelper.rarity_name_color(rarity))
	row.add_child(name_lbl)
	return panel

func _item_id_for_category(item: Resource, category: String) -> String:
	match category:
		"armor":
			return str(item.armor_id)
		"accessory":
			return str(item.accessory_id)
		_:
			return str(item.weapon_id)

func _apply_list_name_label(lbl: Label, color: Color) -> void:
	## 1行・省略なし。長い名前はフォントを段階的に小さくして収める。
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	lbl.max_lines_visible = 1
	lbl.clip_text = false
	lbl.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var font_size: int = UiTypography.SIZE_CAPTION
	var char_count: int = lbl.text.length()
	if char_count >= 10:
		font_size = 14
	elif char_count >= 7:
		font_size = 16
	UiTypography.apply_body(lbl, font_size, color)

func _on_enhance_card_input(event: InputEvent, item: Resource) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_selected_enhance_item = item
		_refresh_all()

func _on_dismantle_card_input(event: InputEvent, item: Resource) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_selected_dismantle_item = item
		_refresh_all()


func _make_alchemy_base_card(item: Resource) -> PanelContainer:
	var selected: bool = item == _selected_alchemy_base
	var category: String = _category
	var item_id: String = _item_id_for_category(item, category)
	var rarity: int = _EquipmentEnhancer.item_rarity(item)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, BlacksmithUiHelper.LIST_CARD_MIN_HEIGHT)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override(
		"panel", BlacksmithUiHelper.simple_list_card_style(selected, false, rarity)
	)
	panel.gui_input.connect(_on_alchemy_base_card_input.bind(item))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(row)
	row.add_child(_make_selectable_list_icon(item_id, category, rarity, selected))
	var name_lbl := Label.new()
	name_lbl.text = _EquipmentEnhancer.get_display_name(item)
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_list_name_label(name_lbl, BlacksmithUiHelper.rarity_name_color(rarity))
	row.add_child(name_lbl)
	return panel


func _on_alchemy_base_card_input(event: InputEvent, item: Resource) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _selected_alchemy_base != item:
			_selected_alchemy_fodder = null
		_selected_alchemy_base = item
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
	elif _mode == "enhance":
		_rebuild_enhance_detail()
	elif _mode == "alchemy":
		_rebuild_alchemy_detail()
	else:
		_rebuild_dismantle_detail()

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
	# 武器・防具・装飾いずれも詳細ヒーローに同一背景を表示。
	_hero_pedestal.visible = _hero_pedestal.texture != null
	_hero_weapon_pivot.visible = true
	_hero_weapon_pivot.rotation_degrees = 0.0
	BlacksmithUiHelper.attach_hero_icon(
		_hero_icon_slot, item_id, category, ForgeUiTokens.HERO_DISPLAY_PX
	)

func _update_cost_panel(gold_cost: int, materials: Dictionary) -> void:
	_cost_header_label.text = "必要コスト"
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
	var rarity_col: Color = BlacksmithUiHelper.rarity_name_color(rarity)
	_title_label.text = BlacksmithUiHelper.output_display_name(craft)
	_title_label.add_theme_color_override("font_color", rarity_col)
	_subtitle_label.text = BlacksmithUiHelper.output_subtitle(craft)
	_populate_stats_from_entries(BlacksmithUiHelper.craft_stat_entries(craft))
	_add_stats_section_spacer()
	var owned: int = BlacksmithUiHelper.owned_count(str(craft.output_type), str(craft.output_id))
	_add_stat_row("所持数", "%d" % owned)
	_populate_unique_from_craft(craft)
	_update_cost_panel(int(craft.gold_cost), craft.required_materials)
	_craft_button.text = "生産する"
	_craft_button.disabled = not can_craft
	if can_craft:
		_reason_label.visible = false
	else:
		_reason_label.text = _craft_button_label(craft, false)
		_reason_label.visible = not _reason_label.text.is_empty()

func _rebuild_enhance_detail() -> void:
	if _selected_enhance_item == null:
		_set_detail_empty("%sを選択してください" % BlacksmithUiHelper.category_label(_category))
		return
	var item: Resource = _selected_enhance_item
	var level: int = _EquipmentEnhancer.get_enhance_level(item)
	var rarity: int = _EquipmentEnhancer.item_rarity(item)
	var item_id: String = _item_id_for_category(item, _category)
	_update_hero_icon(item_id, _category, rarity)
	_rarity_title_label.visible = false
	_title_label.text = _EquipmentEnhancer.get_display_name(item)
	_title_label.add_theme_color_override("font_color", BlacksmithUiHelper.rarity_name_color(rarity))
	_subtitle_label.text = "炉研ぎ +%d / +%d" % [level, _EquipmentEnhancer.MAX_FORGE_LEVEL]
	_populate_enhance_stats(item)
	if _is_item_equipped(item):
		_add_stat_row("状態", "装備中")
	if level >= _EquipmentEnhancer.MAX_FORGE_LEVEL:
		_cost_panel.visible = false
		_craft_button.visible = false
		return
	var check: Dictionary = _EquipmentEnhancer.can_enhance_item(item)
	var next_level: int = int(check.get("next_level", level + 1))
	var gold_cost: int = int(check.get("gold_cost", _EquipmentEnhancer.get_gold_cost(next_level)))
	var materials: Dictionary = check.get(
		"materials", _EquipmentEnhancer.get_material_cost(next_level, rarity)
	)
	_update_cost_panel(gold_cost, materials)
	_craft_button.text = "炉で研ぐ（+%d）" % next_level
	_craft_button.disabled = not bool(check.get("ok", false))
	if not bool(check.get("ok", false)):
		_reason_label.text = str(check.get("reason", ""))
		_reason_label.visible = not _reason_label.text.is_empty()

func _populate_enhance_stats(item: Resource) -> void:
	match _category:
		"weapon":
			var current_atk: int = _EquipmentEnhancer.get_effective_attack(item)
			var level: int = _EquipmentEnhancer.get_enhance_level(item)
			if level >= _EquipmentEnhancer.MAX_FORGE_LEVEL:
				_add_stat_row("攻撃力", "%d（上限）" % current_atk, "atk")
			else:
				_add_stat_row("攻撃力", "%d → %d" % [current_atk, current_atk + 1], "atk")
		"armor":
			var def_now: int = _EquipmentEnhancer.effective_armor_defense(item)
			var hp_now: int = _EquipmentEnhancer.effective_armor_hp(item)
			var enh: int = _EquipmentEnhancer.get_enhance_level(item)
			if enh >= _EquipmentEnhancer.MAX_FORGE_LEVEL:
				_add_stat_row("防御力", "%d（上限）" % def_now, "def")
				_add_stat_row("HP", "%d（上限）" % hp_now, "hp")
			else:
				_add_stat_row("防御力", "%d → %d" % [def_now, def_now + 1], "def")
				_add_stat_row("HP", "%d → %d" % [hp_now, hp_now + 2], "hp")
		"accessory":
			var acc_data: Resource = DataRegistry.get_accessory_data(str(item.accessory_id))
			for field_pair in [["hp_bonus", "HP", "hp"], ["attack_bonus", "攻撃力", "atk"], ["defense_bonus", "防御力", "def"]]:
				var raw: int = _AccessoryStatResolver.resolve_int_stat(item, field_pair[0], acc_data)
				if raw <= 0:
					continue
				var now: int = _EquipmentEnhancer.effective_accessory_int_bonus(item, field_pair[0], acc_data)
				var enh_lv: int = _EquipmentEnhancer.get_enhance_level(item)
				if enh_lv >= _EquipmentEnhancer.MAX_FORGE_LEVEL:
					_add_stat_row(field_pair[1], "%d（上限）" % now, field_pair[2])
				else:
					_add_stat_row(field_pair[1], "%d → %d" % [now, now + 1], field_pair[2])

func _rebuild_dismantle_detail() -> void:
	if _selected_dismantle_item == null:
		_set_detail_empty("%sを選択してください" % BlacksmithUiHelper.category_label(_category))
		return
	var item: Resource = _selected_dismantle_item
	var preview: Dictionary = _EquipmentEnhancer.dismantle_preview(item)
	var rarity: int = _EquipmentEnhancer.item_rarity(item)
	_update_hero_icon(_item_id_for_category(item, _category), _category, rarity)
	_title_label.text = _EquipmentEnhancer.get_display_name(item)
	_title_label.add_theme_color_override("font_color", BlacksmithUiHelper.rarity_name_color(rarity))
	_subtitle_label.text = "分解すると以下の素材を獲得"
	_populate_dismantle_yield(preview.get("materials", {}))
	var can_do: bool = bool(preview.get("ok", false))
	_cost_panel.visible = false
	_craft_button.visible = true
	_craft_button.text = "分解する"
	_craft_button.disabled = not can_do
	if can_do:
		_reason_label.visible = false
	else:
		_reason_label.text = str(preview.get("reason", ""))
		_reason_label.visible = not _reason_label.text.is_empty()

func _populate_dismantle_yield(materials: Dictionary) -> void:
	if materials.is_empty():
		_add_stat_row("獲得素材", "なし")
		return
	for mat_id in materials:
		var qty: int = int(materials[mat_id])
		if qty <= 0:
			continue
		_add_stat_row(DataRegistry.get_material_name(str(mat_id)), "× %d" % qty)


func _rebuild_alchemy_detail() -> void:
	if _selected_alchemy_base == null:
		_set_detail_empty("主材にする%sを選んでください" % BlacksmithUiHelper.category_label(_category))
		return
	var base: Resource = _selected_alchemy_base
	var rarity: int = _EquipmentEnhancer.item_rarity(base)
	_update_hero_icon(_item_id_for_category(base, _category), _category, rarity)
	_title_label.text = _EquipmentEnhancer.get_display_name(base)
	_title_label.add_theme_color_override("font_color", BlacksmithUiHelper.rarity_name_color(rarity))
	_subtitle_label.text = "素材を下段から選び、装備レベルを上げる"
	_add_stat_row("現在レベル", "Lv.%d" % _EquipmentEnhancer.get_equip_level(base))
	if _selected_alchemy_fodder == null:
		_cost_panel.visible = false
		_craft_button.visible = true
		_craft_button.text = "錬成する"
		_craft_button.disabled = true
		_reason_label.text = "下段から素材装備を選択してください"
		_reason_label.visible = true
		return
	var from_lv: int = _EquipmentEnhancer.get_equip_level(base)
	var gain_raw: int = _EquipmentEnhancer.alchemy_level_gain(_selected_alchemy_fodder)
	var to_lv: int = mini(_EquipmentEnhancer.EQUIP_MAX_LEVEL, from_lv + gain_raw)
	var applied: int = maxi(0, to_lv - from_lv)
	var gold_cost: int = _EquipmentEnhancer.alchemy_gold_cost(applied)
	_add_stat_row("結果レベル", "Lv.%d → Lv.%d（+%d）" % [from_lv, to_lv, applied])
	_add_stat_row("消費素材", _EquipmentEnhancer.get_display_name(_selected_alchemy_fodder))
	_add_stat_row("注意", "素材は消滅（分解報酬なし）")
	_update_cost_panel(gold_cost, {})
	_cost_header_label.text = "錬成コスト"
	_craft_button.text = "錬成する"
	var preview: Dictionary = _EquipmentEnhancer.alchemy_preview(base, _selected_alchemy_fodder)
	var can_do: bool = bool(preview.get("ok", false))
	_craft_button.disabled = not can_do
	if can_do:
		_reason_label.visible = false
	else:
		_reason_label.text = str(preview.get("reason", ""))
		_reason_label.visible = not _reason_label.text.is_empty()


func _format_material_summary(materials: Dictionary) -> String:
	var parts: PackedStringArray = []
	for mat_id in materials:
		var qty: int = int(materials[mat_id])
		if qty <= 0:
			continue
		parts.append("%s×%d" % [DataRegistry.get_material_name(str(mat_id)), qty])
	return " / ".join(parts) if not parts.is_empty() else "なし"

func _on_craft_button_pressed() -> void:
	if _mode == "produce" and _selected_craft != null:
		_on_craft_pressed(_selected_craft)
	elif _mode == "enhance" and _selected_enhance_item != null:
		_on_enhance_pressed()
	elif _mode == "alchemy" and _selected_alchemy_base != null and _selected_alchemy_fodder != null:
		_on_alchemy_pressed()
	elif _mode == "dismantle" and _selected_dismantle_item != null:
		_on_dismantle_pressed()

func _rebuild_craftable_strip() -> void:
	_craftable_header.text = "作成可能"
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


func _rebuild_alchemy_fodder_strip() -> void:
	_craftable_header.text = "素材にする装備"
	for child in _craftable_row.get_children():
		child.queue_free()
	if _selected_alchemy_base == null:
		var empty := Label.new()
		empty.text = "（まず左側で主材を選んでください）"
		empty.add_theme_color_override("font_color", COLOR_SUB_STRONG)
		_craftable_row.add_child(empty)
		return
	var fodders: Array = _sorted_alchemy_fodder_candidates()
	if fodders.is_empty():
		var empty2 := Label.new()
		empty2.text = "（消費できる同種装備がありません）"
		empty2.add_theme_color_override("font_color", COLOR_SUB_STRONG)
		_craftable_row.add_child(empty2)
		_selected_alchemy_fodder = null
		return
	if _selected_alchemy_fodder != null and _selected_alchemy_fodder not in fodders:
		_selected_alchemy_fodder = null
	for item in fodders:
		_craftable_row.add_child(_make_alchemy_fodder_chip(item))


func _make_alchemy_fodder_chip(item: Resource) -> PanelContainer:
	var selected: bool = item == _selected_alchemy_fodder
	var rarity: int = _EquipmentEnhancer.item_rarity(item)
	var item_id: String = _item_id_for_category(item, _category)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(96, 88)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override(
		"panel", BlacksmithUiHelper.simple_list_card_style(selected, false, rarity)
	)
	panel.gui_input.connect(_on_alchemy_fodder_chip_input.bind(item))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(col)
	col.add_child(_make_selectable_list_icon(item_id, _category, rarity, selected))
	var name_lbl := Label.new()
	name_lbl.text = _EquipmentEnhancer.get_display_name(item)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	UiTypography.apply_body(
		name_lbl, UiTypography.SIZE_CAPTION, BlacksmithUiHelper.rarity_name_color(rarity)
	)
	col.add_child(name_lbl)
	return panel


func _on_alchemy_fodder_chip_input(event: InputEvent, item: Resource) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_selected_alchemy_fodder = item
		_refresh_all()

func _make_selectable_list_icon(
	item_id: String,
	category: String,
	rarity: int = 0,
	highlight: bool = false
) -> Control:
	var cell_px: int = BlacksmithUiHelper.list_cell_px()
	var host := Control.new()
	host.custom_minimum_size = Vector2(cell_px, cell_px)
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cell: PanelContainer = BlacksmithUiHelper.make_item_icon_cell(
		item_id, category, rarity, cell_px, highlight
	)
	_set_mouse_filter_tree(cell, Control.MOUSE_FILTER_IGNORE)
	host.add_child(cell)
	return host

func _set_mouse_filter_tree(node: Node, filter: Control.MouseFilter) -> void:
	if node is Control:
		(node as Control).mouse_filter = filter
	for child in node.get_children():
		_set_mouse_filter_tree(child, filter)

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
			str(craft.output_id), str(craft.output_type), chip_rarity, cell_px, selected
		)
	)
	var can_make: bool = CraftHelper.can_craft(craft)
	var name_lbl := Label.new()
	name_lbl.text = BlacksmithUiHelper.output_display_name(craft)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_lbl.max_lines_visible = 1
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var name_col: Color = BlacksmithUiHelper.rarity_name_color(chip_rarity)
	if not can_make:
		name_col = name_col.darkened(0.25)
	UiTypography.apply_body(name_lbl, UiTypography.SIZE_BODY_SMALL, name_col)
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
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	col.tooltip_text = "%s %d/%d" % [DataRegistry.get_material_name(mat_id), owned, needed]
	col.add_child(_MaterialUiTokens.make_icon_cell(mat_id, _COST_MAT_ICON_PX, ok))
	var qty := Label.new()
	qty.text = "%d / %d" % [owned, needed]
	UiTypography.apply_body(qty, UiTypography.SIZE_CAPTION, COLOR_OK if ok else COLOR_SHORT)
	qty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(qty)
	return col

func _sorted_enhance_candidates() -> Array:
	var items: Array = []
	for item in _inventory_for_category(_category):
		if item == null or not bool(item.is_appraised):
			continue
		items.append(item)
	items.sort_custom(func(a: Resource, b: Resource) -> bool:
		var a_eq: bool = _is_item_equipped(a)
		var b_eq: bool = _is_item_equipped(b)
		if a_eq != b_eq:
			return a_eq
		return _EquipmentEnhancer.get_display_name(a) < _EquipmentEnhancer.get_display_name(b)
	)
	return items

func _sorted_dismantle_candidates() -> Array:
	var items: Array = []
	for item in _inventory_for_category(_category):
		if bool(_EquipmentEnhancer.can_dismantle_item(item).get("ok", false)):
			items.append(item)
	items.sort_custom(func(a: Resource, b: Resource) -> bool:
		return _EquipmentEnhancer.get_display_name(a) < _EquipmentEnhancer.get_display_name(b)
	)
	return items


func _sorted_alchemy_base_candidates() -> Array:
	var items: Array = []
	for item in _inventory_for_category(_category):
		if item == null:
			continue
		if _is_item_equipped(item):
			continue
		if _EquipmentEnhancer.get_equip_level(item) >= _EquipmentEnhancer.EQUIP_MAX_LEVEL:
			continue
		items.append(item)
	items.sort_custom(func(a: Resource, b: Resource) -> bool:
		var la: int = _EquipmentEnhancer.get_equip_level(a)
		var lb: int = _EquipmentEnhancer.get_equip_level(b)
		if la != lb:
			return la > lb
		return _EquipmentEnhancer.get_display_name(a) < _EquipmentEnhancer.get_display_name(b)
	)
	return items


func _sorted_alchemy_fodder_candidates() -> Array:
	var items: Array = []
	if _selected_alchemy_base == null:
		return items
	for item in _inventory_for_category(_category):
		if item == null or item == _selected_alchemy_base:
			continue
		if _is_item_equipped(item):
			continue
		items.append(item)
	items.sort_custom(func(a: Resource, b: Resource) -> bool:
		var la: int = _EquipmentEnhancer.get_equip_level(a)
		var lb: int = _EquipmentEnhancer.get_equip_level(b)
		if la != lb:
			return la > lb
		return _EquipmentEnhancer.get_display_name(a) < _EquipmentEnhancer.get_display_name(b)
	)
	return items

func _inventory_for_category(category: String) -> Array:
	match category:
		"armor":
			return GameState.armor_inventory
		"accessory":
			return GameState.accessory_inventory
		_:
			return GameState.inventory

func _is_item_equipped(item: Resource) -> bool:
	return GameState.find_item_equipped_member_index(item) >= 0

func _update_bulk_dismantle_button() -> void:
	if _bulk_dismantle_btn == null:
		return
	var preview: Dictionary = _EquipmentEnhancer.dismantle_bulk_preview()
	var count: int = int(preview.get("count", 0))
	_bulk_dismantle_btn.disabled = count <= 0
	_bulk_dismantle_btn.text = (
		"◇◆を一括分解（%d件）" % count if count > 0 else "◇◆を一括分解"
	)
	_bulk_dismantle_btn.tooltip_text = _bulk_dismantle_btn.text
	BlacksmithUiHelper.apply_bulk_dismantle_button(_bulk_dismantle_btn)

func _craft_button_label(craft: Resource, can_craft: bool) -> String:
	if can_craft:
		return "生産する"
	if GameState.gold < craft.gold_cost:
		return "ゴールド不足"
	return "素材不足"

func _on_craft_pressed(craft: Resource) -> void:
	if craft.output_type != "armor" and craft.output_type != "accessory" and craft.output_type != "weapon":
		_log_craft_error("作成できません（出力不正）")
		return
	if craft.output_id.is_empty() or not CraftHelper.craft_output_exists(craft):
		_log_craft_error("作成できません（出力不正）")
		return
	if GameState.gold < craft.gold_cost:
		_log_craft_error("ゴールドが足りません")
		return
	if not CraftHelper.has_enough_materials(craft.required_materials):
		_log_craft_error("素材が足りません")
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

func _on_alchemy_pressed() -> void:
	if _selected_alchemy_base == null or _selected_alchemy_fodder == null:
		return
	var preview: Dictionary = _EquipmentEnhancer.alchemy_preview(
		_selected_alchemy_base, _selected_alchemy_fodder
	)
	if not bool(preview.get("ok", false)):
		_log_craft_error(str(preview.get("reason", "錬成できません")))
		return
	if bool(preview.get("needs_confirm", false)):
		_alchemy_confirm.dialog_text = (
			"%s を素材にして錬成します。\n素材は消滅します。よろしいですか？\n（Lv.%d → Lv.%d / Gold %d）"
			% [
				_EquipmentEnhancer.get_display_name(_selected_alchemy_fodder),
				int(preview.get("from_level", 1)),
				int(preview.get("to_level", 1)),
				int(preview.get("gold_cost", 0)),
			]
		)
		_alchemy_confirm.popup_centered()
		return
	_execute_alchemy()


func _execute_alchemy() -> void:
	if _selected_alchemy_base == null or _selected_alchemy_fodder == null:
		return
	var result: Dictionary = _EquipmentEnhancer.perform_alchemy(
		_selected_alchemy_base, _selected_alchemy_fodder
	)
	if not bool(result.get("ok", false)):
		_log_craft_error(str(result.get("reason", "錬成に失敗しました")))
		return
	_log_craft(
		"錬成成功: Lv.%d → Lv.%d（Gold %d）"
		% [int(result.get("from_level", 1)), int(result.get("to_level", 1)), int(result.get("gold_cost", 0))]
	)
	_selected_alchemy_fodder = null
	SaveManager.save_game()
	_refresh_all()
	_play_forge_success_feedback(FORGE_FLASH_ALCHEMY)


func _on_enhance_pressed() -> void:
	if _selected_enhance_item == null:
		return
	var result: Dictionary = _EquipmentEnhancer.enhance_item(_selected_enhance_item)
	if not bool(result.get("ok", false)):
		_log_craft_error(str(result.get("reason", "炉研ぎに失敗しました")))
		_refresh_all()
		return
	SaveManager.save_game()
	var msg: String = "炉研ぎ成功: %s" % str(result.get("display_name", ""))
	if _category == "weapon":
		msg += "（攻撃力 %d）" % int(result.get("effective_attack", 0))
	elif _category == "armor":
		msg += "（防御力 %d / HP %d）" % [
			int(result.get("effective_defense", 0)),
			int(result.get("effective_hp", 0)),
		]
	_log_craft(msg)
	_refresh_all()
	_play_forge_success_feedback(FORGE_FLASH_ENHANCE)

func _on_dismantle_pressed() -> void:
	if _selected_dismantle_item == null:
		return
	var item: Resource = _selected_dismantle_item
	if _EquipmentEnhancer.item_rarity(item) >= Enums.Rarity.LEGENDARY:
		_pending_dismantle_item = item
		_legendary_dismantle_confirm.dialog_text = (
			"レジェンド装備「%s」を分解します。\n本当によろしいですか？（1/2）"
			% _EquipmentEnhancer.get_display_name(item)
		)
		_legendary_dismantle_confirm.popup_centered()
		return
	_execute_dismantle(item)

func _on_legendary_dismantle_step1() -> void:
	if _pending_dismantle_item == null:
		return
	_legendary_dismantle_final_confirm.dialog_text = (
		"「%s」を分解すると元に戻せません。\n最終確認です。（2/2）"
		% _EquipmentEnhancer.get_display_name(_pending_dismantle_item)
	)
	_legendary_dismantle_final_confirm.popup_centered()

func _on_legendary_dismantle_final() -> void:
	if _pending_dismantle_item == null:
		return
	_execute_dismantle(_pending_dismantle_item)
	_pending_dismantle_item = null

func _execute_dismantle(item: Resource) -> void:
	var result: Dictionary = _EquipmentEnhancer.dismantle_item(item)
	if not bool(result.get("ok", false)):
		_log_craft_error(str(result.get("reason", "分解に失敗しました")))
		_refresh_all()
		return
	SaveManager.save_game()
	_selected_dismantle_item = null
	_selected_enhance_item = null
	_log_craft("分解完了: %s" % _format_material_summary(result.get("materials", {})))
	_refresh_all()
	_play_forge_success_feedback(FORGE_FLASH_DISMANTLE)

func _on_bulk_dismantle_pressed() -> void:
	var preview: Dictionary = _EquipmentEnhancer.dismantle_bulk_preview()
	var count: int = int(preview.get("count", 0))
	if count <= 0:
		_log_craft_error("分解対象がありません")
		return
	_dismantle_confirm.dialog_text = (
		"◇◆装備 %d件を分解します。\n獲得: %s\nよろしいですか？"
		% [count, _format_material_summary(preview.get("materials", {}))]
	)
	_dismantle_confirm.popup_centered()

func _on_bulk_dismantle_confirmed() -> void:
	var result: Dictionary = _EquipmentEnhancer.dismantle_bulk_common_rare()
	if not bool(result.get("ok", false)):
		_log_craft_error(str(result.get("reason", "一括分解に失敗しました")))
		_refresh_all()
		return
	SaveManager.save_game()
	_selected_dismantle_item = null
	_log_craft(
		"一括分解完了: %d件 / %s"
		% [int(result.get("count", 0)), _format_material_summary(result.get("materials", {}))]
	)
	_refresh_all()
	_play_forge_success_feedback(FORGE_FLASH_DISMANTLE)

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


func _log_craft_error(msg: String) -> void:
	AudioManager.play_sfx("ui_error")
	_log_craft(msg)

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
