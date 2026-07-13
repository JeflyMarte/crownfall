extends Control

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const EQUIPMENT_SCENE: String = "res://scenes/equipment/EquipmentScene.tscn"

const GRID_COLUMNS: int = 6
const INV_VISIBLE_ROWS: int = 4

const COLOR_GOLD: Color = Color(0.86, 0.74, 0.45)
const COLOR_SUB: Color = Color(0.72, 0.69, 0.62)
const COLOR_ACCENT: Color = Color(0.75, 0.82, 0.95, 1)

@onready var _button_back: Button = $Header/HeaderRow/ButtonBack
@onready var _label_gold: Label = $Header/HeaderRow/GoldChip/GoldRow/LabelGold
@onready var _label_token: Label = $Header/HeaderRow/TokenChip/TokenRow/LabelToken
@onready var _category_row: HBoxContainer = $MainVBox/CategoryRow
@onready var _btn_sort: Button = $MainVBox/InventoryHeaderRow/ButtonSort
@onready var _btn_filter: Button = $MainVBox/InventoryHeaderRow/ButtonFilter
@onready var _label_count: Label = $MainVBox/InventoryHeaderRow/LabelCount
@onready var _inventory_scroll: ScrollContainer = $MainVBox/InventoryScroll
@onready var _inventory_grid: GridContainer = $MainVBox/InventoryScroll/InventoryGrid
@onready var _detail_panel: PanelContainer = $MainVBox/DetailPanel
@onready var _detail_host: VBoxContainer = $MainVBox/DetailPanel/DetailScroll/DetailVBox

var _inventory_filter: String = "all"
var _inventory_sort: String = "rarity"
var _inventory_equipped_filter: String = "all"
var _inv_cell_size: Vector2 = Vector2(EquipmentUiTokens.INV_CELL_PX, EquipmentUiTokens.INV_CELL_PX)
var _category_panels: Dictionary = {}
var _selected_item: Resource = null
var _selected_category: String = ""
var _last_layout_width: float = -1.0

func _ready() -> void:
	$Header/HeaderRow/LabelTitle.text = ""
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.NONE)
	EquipmentUiTokens.apply_tooltip_theme(self)
	_setup_chrome()
	_button_back.pressed.connect(_on_back_pressed)
	_btn_sort.pressed.connect(_on_sort_pressed)
	_btn_filter.pressed.connect(_on_filter_pressed)
	_inventory_grid.columns = GRID_COLUMNS
	_inventory_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_detail_panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)
	)
	_build_category_chips()
	_update_sort_filter_labels()
	call_deferred("_handle_layout_resized")
	_refresh_display()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		call_deferred("_handle_layout_resized")

func _handle_layout_resized() -> void:
	if not is_node_ready():
		return
	# ルート幅が実際に変化したときだけ再計算する（詳細パネル更新による
	# レイアウト通知でセルが再拡大していく無限ループを防ぐ）。
	var width: float = size.x
	if width < 100.0 or absf(width - _last_layout_width) < 1.0:
		return
	_last_layout_width = width
	_sync_inventory_cell_size()
	_rebuild_inventory_grid()

func _setup_chrome() -> void:
	var back_tex: Texture2D = EquipmentUiTokens.back_icon()
	if back_tex != null:
		_button_back.text = ""
		_button_back.icon = back_tex
		_button_back.expand_icon = true
		_button_back.custom_minimum_size = Vector2(40, 40)
	var filter_tex: Texture2D = EquipmentUiTokens.filter_icon()
	if filter_tex != null:
		_btn_filter.icon = filter_tex
		_btn_filter.expand_icon = true

func _build_category_chips() -> void:
	for child in _category_row.get_children():
		child.queue_free()
	_category_panels.clear()
	for cat_id in ["all", "weapon", "armor", "accessory"]:
		var wrap := PanelContainer.new()
		wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		wrap.custom_minimum_size = EquipmentUiTokens.CATEGORY_MIN_SIZE
		wrap.add_theme_stylebox_override(
			"panel", EquipmentUiTokens.category_tab_style(_inventory_filter == cat_id)
		)
		_category_row.add_child(wrap)
		_category_panels[cat_id] = wrap
		var col := VBoxContainer.new()
		col.set_anchors_preset(Control.PRESET_FULL_RECT)
		col.offset_left = 2
		col.offset_top = 2
		col.offset_right = -2
		col.offset_bottom = -2
		col.add_theme_constant_override("separation", 0)
		col.mouse_filter = Control.MOUSE_FILTER_IGNORE
		wrap.add_child(col)
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(40, 40)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture = EquipmentUiTokens.category_icon(cat_id)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(icon)
		var lbl := Label.new()
		lbl.text = EquipmentUiHelper.category_label(cat_id)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UiTypography.apply_caption(lbl)
		col.add_child(lbl)
		var btn := Button.new()
		btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.flat = true
		btn.pressed.connect(_on_category_pressed.bind(cat_id))
		wrap.add_child(btn)

func _on_category_pressed(category: String) -> void:
	_inventory_filter = category
	_refresh_category_buttons()
	_rebuild_inventory_grid()

func _refresh_category_buttons() -> void:
	for cat_id in _category_panels.keys():
		var panel: PanelContainer = _category_panels[cat_id]
		panel.add_theme_stylebox_override(
			"panel", EquipmentUiTokens.category_tab_style(_inventory_filter == cat_id)
		)

func _on_sort_pressed() -> void:
	var keys: Array = EquipmentUiHelper.SORT_LABELS.keys()
	var idx: int = keys.find(_inventory_sort)
	_inventory_sort = str(keys[(idx + 1) % keys.size()])
	_update_sort_filter_labels()
	_rebuild_inventory_grid()

func _on_filter_pressed() -> void:
	var keys: Array = EquipmentUiHelper.EQUIPPED_FILTER_LABELS.keys()
	var idx: int = keys.find(_inventory_equipped_filter)
	_inventory_equipped_filter = str(keys[(idx + 1) % keys.size()])
	_update_sort_filter_labels()
	_rebuild_inventory_grid()

func _update_sort_filter_labels() -> void:
	_btn_sort.text = str(EquipmentUiHelper.SORT_LABELS.get(_inventory_sort, _inventory_sort))
	_btn_filter.text = str(
		EquipmentUiHelper.EQUIPPED_FILTER_LABELS.get(_inventory_equipped_filter, _inventory_equipped_filter)
	)

func _refresh_display() -> void:
	_label_gold.text = "%d" % GameState.gold
	_label_token.text = CurrencyHelper.format_amount()
	_rebuild_inventory_grid()
	_refresh_detail_panel()

func _rebuild_inventory_grid() -> void:
	for child in _inventory_grid.get_children():
		child.queue_free()
	var entries: Array = []
	if _inventory_filter == "all" or _inventory_filter == "weapon":
		for it in $EquipmentController.get_appraised_weapons():
			entries.append({"item": it, "category": "weapon"})
	if _inventory_filter == "all" or _inventory_filter == "armor":
		for it in $EquipmentController.get_appraised_armors():
			entries.append({"item": it, "category": "armor"})
	if _inventory_filter == "all" or _inventory_filter == "accessory":
		for it in $EquipmentController.get_appraised_accessories():
			entries.append({"item": it, "category": "accessory"})
	entries = EquipmentUiHelper.filter_by_equipped_state(entries, _inventory_equipped_filter, -1)
	_label_count.text = "%d件" % entries.size()
	if entries.is_empty():
		_inventory_grid.add_child(_make_hint_label("該当する装備がありません"))
		_selected_item = null
		_selected_category = ""
		_refresh_detail_panel()
		return
	for e in EquipmentUiHelper.sort_inventory_entries(entries, _inventory_sort):
		_inventory_grid.add_child(_make_item_cell(e["item"], str(e["category"])))

func _make_hint_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_caption(lbl, COLOR_SUB)
	return lbl

func _make_item_cell(item: Resource, category: String) -> Button:
	var cell_size: Vector2 = _inv_cell_size
	var cell_px: int = int(cell_size.x)
	var btn := Button.new()
	btn.custom_minimum_size = cell_size
	btn.flat = false
	btn.focus_mode = Control.FOCUS_NONE
	var icon: Texture2D = _item_icon(item, category)
	_attach_item_icon(btn, icon, cell_px, EquipmentUiTokens.INV_CELL_DESIGN_PX)
	var rarity: int = _item_rarity(item, category)
	var owner_idx: int = EquipmentUiHelper.equipped_member_index(item)
	var is_equipped: bool = owner_idx >= 0
	btn.tooltip_text = EquipmentItemDetailHelper.short_name(item, category)
	btn.pressed.connect(_on_cell_pressed.bind(item, category))
	var selected: bool = item == _selected_item and category == _selected_category
	if selected:
		btn.modulate = Color(0.85, 0.92, 1.0, 1.0)
	_apply_item_cell_styles(btn, rarity, cell_px, false, selected)
	_apply_item_badges(btn, item, category, cell_size, is_equipped)
	if owner_idx >= 0:
		_add_owner_portrait_badge(btn, owner_idx, cell_size)
	return btn

func _on_cell_pressed(item: Resource, category: String) -> void:
	_selected_item = item
	_selected_category = category
	_rebuild_inventory_grid()
	_refresh_detail_panel()

func _refresh_detail_panel() -> void:
	EquipmentItemDetailHelper.populate_stats_panel(_detail_host, _selected_item, _selected_category)

func _sync_inventory_cell_size() -> void:
	var sep: int = _inventory_grid.get_theme_constant("h_separation", "GridContainer")
	# ルート幅を基準に算出する。スクロール実サイズは詳細パネルの高さ変化に
	# 引きずられて揺れるため使わない。
	var width: float = size.x - 16.0
	var cell_px: int = EquipmentUiTokens.cell_px_for_grid_width(width, GRID_COLUMNS, sep)
	_inv_cell_size = Vector2(cell_px, cell_px)
	var v_sep: int = _inventory_grid.get_theme_constant("v_separation", "GridContainer")
	var height: float = _inv_cell_size.y * float(INV_VISIBLE_ROWS) + float(v_sep * maxi(0, INV_VISIBLE_ROWS - 1))
	_inventory_scroll.custom_minimum_size.y = height

func _attach_item_icon(btn: Button, icon: Texture2D, cell_px: int, design_px: int) -> void:
	EquipmentUiTokens.attach_item_cell_layers(btn, icon, cell_px, design_px)

func _apply_item_cell_styles(
	btn: Button,
	rarity: int,
	cell_px: int,
	disabled_highlight: bool = false,
	selected: bool = false
) -> void:
	var normal: StyleBox = EquipmentUiTokens.rarity_slot_style(rarity, selected, cell_px)
	var hover: StyleBox = EquipmentUiTokens.rarity_slot_style(rarity, true, cell_px)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus", normal)
	btn.add_theme_stylebox_override(
		"disabled", EquipmentUiTokens.rarity_slot_style(rarity, disabled_highlight, cell_px)
	)

func _apply_item_badges(
	btn: Button,
	item: Resource,
	category: String,
	size: Vector2,
	is_equipped: bool
) -> void:
	var rarity: int = _item_rarity(item, category)
	var star_font: int = maxi(11, int(size.y * 0.17))
	_add_corner_badge(
		btn,
		EquipmentUiHelper.rarity_stars_text(rarity),
		Color(0.96, 0.82, 0.35, 1.0),
		Vector2(3.0, 2.0),
		star_font
	)
	EquipmentUiHelper.apply_legendary_badge(btn, rarity, size)
	if category == "weapon":
		EquipmentUiHelper.apply_enhance_badge(btn, item, category, size, COLOR_GOLD)
	if is_equipped:
		var eq_font: int = maxi(10, int(size.y * 0.14))
		var eq_y: float = size.y - float(eq_font) - 4.0
		if rarity >= Enums.Rarity.LEGENDARY:
			var badge_h: float = EquipmentUiTokens.legendary_badge_size(size).y
			eq_y = size.y - badge_h - float(eq_font) - 6.0
		_add_corner_badge(btn, "装", COLOR_ACCENT, Vector2(3.0, eq_y), eq_font)

func _add_corner_badge(
	btn: Button,
	text: String,
	color: Color,
	pos: Vector2,
	font_size: int = 13
) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.position = pos
	btn.add_child(lbl)

func _add_owner_portrait_badge(btn: Button, owner_idx: int, cell_size: Vector2) -> void:
	var member: Resource = GameState.get_member(owner_idx)
	if member == null:
		return
	var tex: Texture2D = IconPaths.get_icon_texture(str(member.job_id), "chr")
	if tex == null:
		return
	var icon := TextureRect.new()
	icon.texture = tex
	icon.custom_minimum_size = Vector2(18, 18)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.position = Vector2(cell_size.x - 18.0, 2.0)
	btn.add_child(icon)

func _item_icon(item: Resource, category: String) -> Texture2D:
	if item == null:
		return null
	match category:
		"weapon":
			return IconPaths.get_icon_texture(str(item.weapon_id), "weapon")
		"armor":
			return IconPaths.get_icon_texture(str(item.armor_id), "armor")
		"accessory":
			return IconPaths.get_icon_texture(str(item.accessory_id), "accessory")
	return null

func _item_rarity(item: Resource, category: String) -> int:
	var data: Resource = null
	match category:
		"weapon":
			data = DataRegistry.get_weapon_data(str(item.weapon_id))
		"armor":
			data = DataRegistry.get_armor_data(str(item.armor_id))
		"accessory":
			data = DataRegistry.get_accessory_data(str(item.accessory_id))
	if data != null and "rarity" in data:
		return int(data.rarity)
	return 0

func _on_back_pressed() -> void:
	SceneRouter.change_scene(HOME_SCENE)
