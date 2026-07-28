extends Control

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const EQUIPMENT_SCENE: String = "res://scenes/equipment/EquipmentScene.tscn"

const GRID_COLUMNS: int = 6
const INV_VISIBLE_ROWS: int = 4

const COLOR_GOLD: Color = Color(0.86, 0.74, 0.45)
const COLOR_SUB: Color = Color(0.72, 0.69, 0.62)
const COLOR_ACCENT: Color = Color(0.75, 0.82, 0.95, 1)
## ScrollTouch の PASS 化後も短押しを拾う（装備画面と同ポリシー）。
const CELL_PRESS_MOVE_CANCEL_PX: float = 20.0

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
var _selected_cell_btn: Button = null
var _cell_pointer_down: bool = false
var _cell_press_origin: Vector2 = Vector2.ZERO
var _cell_press_item: Resource = null
var _cell_press_category: String = ""

func _ready() -> void:
	$Header/HeaderRow/LabelTitle.text = ""
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.NONE)
	EquipmentUiTokens.apply_tooltip_theme(self)
	_setup_chrome()
	var bg := get_node_or_null("BgTexture") as TextureRect
	if bg != null:
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_button_back.pressed.connect(_on_back_pressed)
	_btn_sort.pressed.connect(_on_sort_pressed)
	_btn_filter.pressed.connect(_on_filter_pressed)
	_inventory_grid.columns = GRID_COLUMNS
	_inventory_grid.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_inventory_grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_inventory_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_inventory_scroll.clip_contents = true
	_detail_panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)
	)
	_build_category_chips()
	_update_sort_filter_labels()
	call_deferred("_sync_inventory_scroll_height")
	_refresh_display()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		call_deferred("_sync_inventory_scroll_height")


func _sync_inventory_scroll_height() -> void:
	if not is_node_ready():
		return
	## セルは固定 px。幅連動の再計算／全再生成はしない（重さ・枠肥大の再発防止）。
	_inv_cell_size = Vector2(EquipmentUiTokens.INV_CELL_PX, EquipmentUiTokens.INV_CELL_PX)
	var v_sep: int = _inventory_grid.get_theme_constant("v_separation", "GridContainer")
	var height: float = (
		_inv_cell_size.y * float(INV_VISIBLE_ROWS)
		+ float(v_sep * maxi(0, INV_VISIBLE_ROWS - 1))
	)
	_inventory_scroll.custom_minimum_size.y = height


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
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
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
	_selected_cell_btn = null
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
	## rebuild 後も Scroll 内 Button を PASS 化（スクロール＋短押し両立）。
	ScrollTouchHelper.enable(_inventory_scroll)

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
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.clip_contents = true
	btn.flat = false
	btn.focus_mode = Control.FOCUS_NONE
	var icon: Texture2D = _item_icon(item, category)
	_attach_item_icon(btn, icon, cell_px, EquipmentUiTokens.INV_CELL_DESIGN_PX, item, category)
	var rarity: int = _item_rarity(item, category)
	btn.set_meta("cf_rarity", rarity)
	btn.set_meta("cf_item", item)
	btn.set_meta("cf_category", category)
	var owner_member: Resource = GameState.find_item_equipped_owner(item)
	var is_equipped: bool = owner_member != null
	btn.tooltip_text = EquipmentItemDetailHelper.short_name(item, category)
	## ScrollTouch が mouse_filter=PASS にするため pressed は不発になりやすい。gui_input で短押しを取る。
	btn.gui_input.connect(_on_item_cell_gui_input.bind(item, category, btn))
	var selected: bool = item == _selected_item and category == _selected_category
	if selected:
		btn.modulate = Color(0.85, 0.92, 1.0, 1.0)
		_selected_cell_btn = btn
	_apply_item_cell_styles(btn, rarity, cell_px, false, selected)
	_apply_item_badges(btn, item, category, cell_size, is_equipped)
	if owner_member != null:
		_add_owner_portrait_badge(btn, owner_member, cell_size)
	return btn

func _on_item_cell_gui_input(
	event: InputEvent, item: Resource, category: String, btn: Button
) -> void:
	if _cell_pointer_down and _should_cancel_cell_press_for_move(event):
		_cancel_cell_press()
		return
	if not _is_cell_pointer_event(event):
		return
	if event.pressed:
		_cell_pointer_down = true
		_cell_press_origin = _cell_event_position(event)
		_cell_press_item = item
		_cell_press_category = category
	else:
		if _cell_pointer_down and _cell_press_item == item and _cell_press_category == category:
			_on_cell_pressed(item, category, btn)
		_cancel_cell_press()
	## accept_event しない: セル上ドラッグを親 InventoryScroll へ渡す（タップは gui_input で処理）。

func _is_cell_pointer_event(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return event.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventScreenTouch:
		return true
	return false

func _cell_event_position(event: InputEvent) -> Vector2:
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).position
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).position
	if event is InputEventScreenDrag:
		return (event as InputEventScreenDrag).position
	if event is InputEventMouseMotion:
		return (event as InputEventMouseMotion).position
	return Vector2.ZERO

func _should_cancel_cell_press_for_move(event: InputEvent) -> bool:
	if event is InputEventScreenDrag:
		return (
			_cell_press_origin.distance_to((event as InputEventScreenDrag).position)
			>= CELL_PRESS_MOVE_CANCEL_PX
		)
	if event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		if (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			return false
		return _cell_press_origin.distance_to(motion.position) >= CELL_PRESS_MOVE_CANCEL_PX
	return false

func _cancel_cell_press() -> void:
	_cell_pointer_down = false
	_cell_press_item = null
	_cell_press_category = ""

func _on_cell_pressed(item: Resource, category: String, btn: Button) -> void:
	## 詳細だけ更新。グリッド全再生成はしない（所持数が多いと実機で重い）。
	if item == _selected_item and category == _selected_category:
		_refresh_detail_panel()
		return
	_clear_selected_cell_visual()
	_selected_item = item
	_selected_category = category
	_selected_cell_btn = btn
	if btn != null and is_instance_valid(btn):
		var rarity: int = int(btn.get_meta("cf_rarity", 0))
		var cell_px: int = int(_inv_cell_size.x)
		btn.modulate = Color(0.85, 0.92, 1.0, 1.0)
		_apply_item_cell_styles(btn, rarity, cell_px, false, true)
	_refresh_detail_panel()


func _clear_selected_cell_visual() -> void:
	if _selected_cell_btn == null or not is_instance_valid(_selected_cell_btn):
		_selected_cell_btn = null
		return
	var rarity: int = int(_selected_cell_btn.get_meta("cf_rarity", 0))
	var cell_px: int = int(_inv_cell_size.x)
	_selected_cell_btn.modulate = Color.WHITE
	_apply_item_cell_styles(_selected_cell_btn, rarity, cell_px, false, false)
	_selected_cell_btn = null

func _refresh_detail_panel() -> void:
	EquipmentItemDetailHelper.populate_stats_panel(_detail_host, _selected_item, _selected_category, self)

func _attach_item_icon(
	btn: Button,
	icon: Texture2D,
	cell_px: int,
	design_px: int,
	item: Resource = null,
	category: String = ""
) -> void:
	var item_id: String = ""
	if item != null:
		match category:
			"weapon":
				item_id = str(item.weapon_id)
			"armor":
				item_id = str(item.armor_id)
			"accessory":
				item_id = str(item.accessory_id)
	EquipmentUiTokens.attach_item_cell_layers(btn, icon, cell_px, design_px, item_id, category)

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
	_is_equipped: bool
) -> void:
	var rarity: int = _item_rarity(item, category)
	var star_font: int = maxi(11, int(size.y * 0.17))
	_add_corner_badge(
		btn,
		EquipmentUiHelper.rarity_stars_text(rarity),
		Color(0.96, 0.82, 0.35, 1.0),
		EquipmentUiHelper.RARITY_BADGE_POS,
		star_font
	)
	EquipmentUiHelper.apply_legendary_badge(btn, rarity, size)
	if category == "weapon":
		EquipmentUiHelper.apply_enhance_badge(btn, item, category, size, COLOR_GOLD)
	## 装備中の「装」は出さない。ドロップ直後は中央 New 点滅。
	EquipmentUiHelper.apply_new_badge(btn, item, size)

func _add_corner_badge(
	btn: Button,
	text: String,
	color: Color,
	pos: Vector2,
	font_size: int = 13
) -> void:
	if text.is_empty():
		return
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.position = pos
	btn.add_child(lbl)

func _add_owner_portrait_badge(btn: Button, owner_member: Resource, cell_size: Vector2) -> void:
	if owner_member == null:
		return
	var tex: Texture2D = RosterUiHelper.get_member_portrait_texture(owner_member)
	if tex == null:
		return
	var badge_px: float = 28.0
	var icon := TextureRect.new()
	icon.name = "OwnerBadge"
	icon.texture = tex
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.z_index = 3
	icon.anchor_left = 1.0
	icon.anchor_top = 0.0
	icon.anchor_right = 1.0
	icon.anchor_bottom = 0.0
	icon.offset_left = -badge_px - 2.0
	icon.offset_top = 2.0
	icon.offset_right = -2.0
	icon.offset_bottom = 2.0 + badge_px
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
