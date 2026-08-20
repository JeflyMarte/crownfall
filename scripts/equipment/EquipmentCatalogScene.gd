extends Control

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const EQUIPMENT_SCENE: String = "res://scenes/equipment/EquipmentScene.tscn"

const GRID_COLUMNS: int = 6
const INV_VISIBLE_ROWS: int = 4

const COLOR_GOLD: Color = Color(0.86, 0.74, 0.45)
const COLOR_SUB: Color = Color(0.72, 0.69, 0.62)
const COLOR_ACCENT: Color = Color(0.75, 0.82, 0.95, 1)
## ScrollTouch の PASS 化後も短押しを拾う（装備画面と同ポリシー）。
## iPhone は静止長押しでも微細 ScreenDrag が来る。累積キャンセル禁止（フリック／実スクロールのみ）。
const CELL_PRESS_FLICK_CANCEL_PX: float = 40.0
const CELL_LONG_PRESS_SEC: float = 0.50
## ロックは軽操作なのにフルセーブすると所持が多い実機で固まる。まとめて書く。
const LOCK_SAVE_DEBOUNCE_SEC: float = 0.45
const _CELL_PRESS_NONE: int = 0
const _CELL_PRESS_TOUCH: int = 1
const _CELL_PRESS_MOUSE: int = 2

@onready var _button_back: Button = $Header/HeaderRow/ButtonBack
@onready var _label_gold: Label = $Header/HeaderRow/GoldChip/GoldRow/LabelGold
@onready var _label_token: Label = $Header/HeaderRow/TokenChip/TokenRow/LabelToken
@onready var _category_row: HBoxContainer = $MainVBox/CategoryRow
@onready var _btn_sort: Button = $MainVBox/InventoryHeaderRow/ButtonSort
@onready var _btn_filter: Button = $MainVBox/InventoryHeaderRow/ButtonFilter
@onready var _btn_effect: Button = $MainVBox/InventoryHeaderRow/ButtonEffect
@onready var _label_count: Label = $MainVBox/InventoryHeaderRow/LabelCount
@onready var _inventory_scroll: ScrollContainer = $MainVBox/InventoryScroll
@onready var _inventory_grid: GridContainer = $MainVBox/InventoryScroll/InventoryGrid
@onready var _detail_panel: PanelContainer = $MainVBox/DetailPanel
@onready var _detail_host: VBoxContainer = $MainVBox/DetailPanel/DetailScroll/DetailVBox

var _inventory_filter: String = "all"
var _inventory_sort: String = "rarity"
var _inventory_equipped_filter: String = "all"
## 効果ファミリー id の複数選択（空＝指定なし）。
var _effect_families: Array[String] = []
var _effect_sheet: CanvasLayer = null
var _inv_cell_size: Vector2 = Vector2(EquipmentUiTokens.INV_CELL_PX, EquipmentUiTokens.INV_CELL_PX)
var _category_panels: Dictionary = {}
var _selected_item: Resource = null
var _selected_category: String = ""
var _selected_relic_id: String = ""
var _selected_cell_btn: Button = null
var _cell_pointer_down: bool = false
var _cell_long_press_fired: bool = false
var _cell_press_origin: Vector2 = Vector2.ZERO
var _cell_press_source: int = _CELL_PRESS_NONE
var _cell_press_scroll_v: int = 0
var _cell_long_press_timer: Timer = null
var _cell_press_item: Resource = null
var _cell_press_category: String = ""
var _cell_press_relic_id: String = ""
var _cell_press_btn: Button = null
var _lock_toast: Label = null
var _lock_toast_tween: Tween = null
var _lock_save_pending: bool = false
var _lock_save_timer: Timer = null

func _ready() -> void:
	$Header/HeaderRow/LabelTitle.text = ""
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.NONE)
	HeaderCurrencyHelper.apply_to_row($Header/HeaderRow)
	EquipmentUiTokens.apply_tooltip_theme(self)
	_setup_chrome()
	var bg := get_node_or_null("BgTexture") as TextureRect
	if bg != null:
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_button_back.pressed.connect(_on_back_pressed)
	_btn_sort.pressed.connect(_on_sort_pressed)
	_btn_filter.pressed.connect(_on_filter_pressed)
	_btn_effect.pressed.connect(_on_effect_pressed)
	_inventory_grid.columns = GRID_COLUMNS
	_inventory_grid.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_inventory_grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_inventory_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_inventory_scroll.clip_contents = true
	var detail_scroll: ScrollContainer = _detail_host.get_parent() as ScrollContainer
	if detail_scroll != null:
		detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
		detail_scroll.clip_contents = true
	_detail_panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)
	)
	_build_category_chips()
	_update_sort_filter_labels()
	_ensure_long_press_timer()
	call_deferred("_sync_inventory_scroll_height")
	_refresh_display()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		call_deferred("_sync_inventory_scroll_height")


func _exit_tree() -> void:
	## 画面離脱前に未書き込みロックを確定（debounce 待ちを落とさない）。
	_flush_lock_save()


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
	for cat_id in ["all", "weapon", "armor", "accessory", "relic"]:
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
		var icon_px: float = float(EquipmentUiTokens.CATEGORY_ICON_PX)
		icon.custom_minimum_size = Vector2(icon_px, icon_px)
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
	_update_sort_filter_labels()
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

func _on_effect_pressed() -> void:
	if _inventory_filter == "relic":
		return
	_open_effect_family_sheet()

func _update_sort_filter_labels() -> void:
	_btn_sort.text = str(EquipmentUiHelper.SORT_LABELS.get(_inventory_sort, _inventory_sort))
	_btn_filter.text = str(
		EquipmentUiHelper.EQUIPPED_FILTER_LABELS.get(_inventory_equipped_filter, _inventory_equipped_filter)
	)
	_btn_effect.text = EquipmentEffectFamilyFilter.button_summary(_effect_families)
	## レリックは効果ファミリー対象外（キャラ装備画面と同ポリシー）。
	_btn_effect.disabled = _inventory_filter == "relic"

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
	## レリックは「すべて」に混ぜず専用タブのみ（キャラ装備画面と同型）。
	if _inventory_filter == "relic":
		for rid in GameState.owned_relics:
			var relic_id: String = str(rid)
			if relic_id.is_empty():
				continue
			entries.append({"relic_id": relic_id, "category": "relic"})
	entries = EquipmentUiHelper.filter_by_equipped_state(entries, _inventory_equipped_filter, -1)
	if _inventory_filter != "relic":
		entries = EquipmentEffectFamilyFilter.filter_entries(entries, _effect_families)
	## 袋上限は武+防+飾の合算（フィルタ／レリックタブでも母数は所持合計）。
	_label_count.text = GameState.equipment_inventory_count_label()
	if entries.is_empty():
		var empty_msg: String = "該当する装備がありません"
		if _inventory_filter == "relic":
			empty_msg = "所持しているレリックがありません"
		_inventory_grid.add_child(_make_hint_label(empty_msg))
		_selected_item = null
		_selected_category = ""
		_selected_relic_id = ""
		_refresh_detail_panel()
		ScrollTouchHelper.enable(_inventory_scroll)
		return
	for e in EquipmentUiHelper.sort_inventory_entries(entries, _inventory_sort):
		if str(e.get("category", "")) == "relic":
			_inventory_grid.add_child(_make_relic_cell(str(e.get("relic_id", ""))))
		else:
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
	btn.tooltip_text = "%s\n（短押しで詳細／長押しでロック）" % EquipmentItemDetailHelper.short_name(
		item, category
	)
	## 短押し=詳細、長押し=ロック（P3-UX-EQUIP-LOCK-001。キャラ画面ではロックしない）。
	btn.gui_input.connect(_on_item_cell_gui_input.bind(item, category, btn))
	var selected: bool = (
		_selected_relic_id.is_empty()
		and item == _selected_item
		and category == _selected_category
	)
	if selected:
		btn.modulate = Color(0.85, 0.92, 1.0, 1.0)
		_selected_cell_btn = btn
	_apply_item_cell_styles(btn, rarity, cell_px, false, selected)
	_apply_item_badges(btn, item, category, cell_size, is_equipped)
	if owner_member != null:
		_add_owner_portrait_badge(btn, owner_member, cell_size)
	return btn


func _make_relic_cell(relic_id: String) -> Button:
	var cell_size: Vector2 = _inv_cell_size
	var cell_px: int = int(cell_size.x)
	var btn := Button.new()
	btn.custom_minimum_size = cell_size
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.clip_contents = true
	btn.flat = false
	btn.focus_mode = Control.FOCUS_NONE
	var icon_key: String = CombatPassives.relic_icon_key(relic_id)
	var tex: Texture2D = IconPaths.get_icon_texture(icon_key, "relic")
	EquipmentUiTokens.attach_item_cell_layers(
		btn, tex, cell_px, EquipmentUiTokens.INV_CELL_DESIGN_PX, icon_key, "relic"
	)
	btn.set_meta("cf_category", "relic")
	btn.set_meta("cf_relic_id", relic_id)
	var owner_member: Resource = GameState.find_relic_equipped_owner(relic_id)
	btn.tooltip_text = "%s\n（短押しで詳細）" % EquipmentItemDetailHelper.relic_hover_summary(relic_id)
	btn.gui_input.connect(_on_relic_cell_gui_input.bind(relic_id, btn))
	var selected: bool = relic_id == _selected_relic_id and not relic_id.is_empty()
	if selected:
		btn.modulate = Color(0.85, 0.92, 1.0, 1.0)
		_selected_cell_btn = btn
	_apply_relic_cell_styles(btn, cell_px, selected)
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
	var is_touch: bool = event is InputEventScreenTouch
	var is_mouse: bool = event is InputEventMouseButton
	if event.pressed:
		if _cell_pointer_down:
			return
		_cell_press_source = _CELL_PRESS_TOUCH if is_touch else _CELL_PRESS_MOUSE
		_cell_press_origin = _cell_event_position(event)
		_begin_cell_press(item, category, "", btn)
	else:
		if not _cell_pointer_down:
			return
		if _cell_press_source == _CELL_PRESS_TOUCH and is_mouse:
			return
		if _cell_press_source == _CELL_PRESS_MOUSE and is_touch:
			return
		_end_cell_press()


func _on_relic_cell_gui_input(event: InputEvent, relic_id: String, btn: Button) -> void:
	if _cell_pointer_down and _should_cancel_cell_press_for_move(event):
		_cancel_cell_press()
		return
	if not _is_cell_pointer_event(event):
		return
	var is_touch: bool = event is InputEventScreenTouch
	var is_mouse: bool = event is InputEventMouseButton
	if event.pressed:
		if _cell_pointer_down:
			return
		_cell_press_source = _CELL_PRESS_TOUCH if is_touch else _CELL_PRESS_MOUSE
		_cell_press_origin = _cell_event_position(event)
		_begin_cell_press(null, "relic", relic_id, btn)
	else:
		if not _cell_pointer_down:
			return
		if _cell_press_source == _CELL_PRESS_TOUCH and is_mouse:
			return
		if _cell_press_source == _CELL_PRESS_MOUSE and is_touch:
			return
		_end_cell_press()

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
	## スクロールが動いたらキャンセル（長押し中の指ぶれは無視）。
	if _inventory_scroll != null and _inventory_scroll.scroll_vertical != _cell_press_scroll_v:
		return true
	## 累積ではなく「1イベントのフリック」だけキャンセル（iPhone 微動対策）。
	if event is InputEventScreenDrag:
		return (event as InputEventScreenDrag).relative.length() >= CELL_PRESS_FLICK_CANCEL_PX
	if event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		if (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) == 0:
			return false
		return _cell_press_origin.distance_to(motion.position) >= CELL_PRESS_FLICK_CANCEL_PX
	return false

func _ensure_long_press_timer() -> void:
	if _cell_long_press_timer != null and is_instance_valid(_cell_long_press_timer):
		return
	_cell_long_press_timer = Timer.new()
	_cell_long_press_timer.name = "CatalogCellLongPressTimer"
	_cell_long_press_timer.one_shot = true
	_cell_long_press_timer.wait_time = CELL_LONG_PRESS_SEC
	_cell_long_press_timer.timeout.connect(_on_cell_long_press_timeout)
	add_child(_cell_long_press_timer)

func _begin_cell_press(
	item: Resource, category: String, relic_id: String, btn: Button
) -> void:
	_ensure_long_press_timer()
	_cell_long_press_timer.stop()
	_cell_pointer_down = true
	_cell_long_press_fired = false
	_cell_press_item = item
	_cell_press_category = category
	_cell_press_relic_id = relic_id
	_cell_press_btn = btn
	_cell_press_scroll_v = _inventory_scroll.scroll_vertical if _inventory_scroll != null else 0
	_cell_long_press_timer.start(CELL_LONG_PRESS_SEC)

func _on_cell_long_press_timeout() -> void:
	if not _cell_pointer_down:
		return
	## レリックはロック対象外。武／防／飾のみ。
	if _cell_press_item != null and _cell_press_relic_id.is_empty():
		var item: Resource = _cell_press_item
		var category: String = _cell_press_category
		var btn: Button = _cell_press_btn
		## release 欠落でも次の操作が死なないよう、ロック後は即 press 状態をクリア。
		_cancel_cell_press()
		_toggle_catalog_item_lock(item, category, btn)
		return
	_cell_long_press_fired = true

func _end_cell_press() -> void:
	if not _cell_pointer_down:
		return
	_cell_pointer_down = false
	_cell_press_source = _CELL_PRESS_NONE
	if _cell_long_press_timer != null:
		_cell_long_press_timer.stop()
	if not _cell_long_press_fired:
		if not _cell_press_relic_id.is_empty():
			_on_relic_cell_pressed(_cell_press_relic_id, _cell_press_btn)
		elif _cell_press_item != null:
			_on_cell_pressed(_cell_press_item, _cell_press_category, _cell_press_btn)
	_cell_press_item = null
	_cell_press_category = ""
	_cell_press_relic_id = ""
	_cell_press_btn = null

func _cancel_cell_press() -> void:
	_cell_pointer_down = false
	_cell_long_press_fired = false
	_cell_press_source = _CELL_PRESS_NONE
	if _cell_long_press_timer != null:
		_cell_long_press_timer.stop()
	_cell_press_item = null
	_cell_press_category = ""
	_cell_press_relic_id = ""
	_cell_press_btn = null

func _toggle_catalog_item_lock(item: Resource, category: String, btn: Button) -> void:
	if item == null:
		return
	if category != "weapon" and category != "armor" and category != "accessory":
		return
	var now_locked: bool = EquipmentEnhancer.toggle_item_locked(item)
	## 同期フルセーブは所持が多いと主スレッドが数秒止まり「フリーズ」に見える。
	_request_lock_save()
	## バッジだけ更新（全グリッド再生成は重い）。
	if btn != null and is_instance_valid(btn):
		_clear_item_cell_overlay_badges(btn)
		_apply_item_badges(
			btn,
			item,
			category,
			_inv_cell_size,
			GameState.find_item_equipped_owner(item) != null
		)
	if item == _selected_item and category == _selected_category:
		## pressed 中に詳細を壊すと発信 Button ごと free → Abort（鍛冶焼直しと同型）。
		call_deferred("_sync_catalog_lock_row_after_toggle")
	_show_lock_toast("ロックしました" if now_locked else "ロックを解除しました")


func _request_lock_save() -> void:
	_lock_save_pending = true
	_ensure_lock_save_timer()
	_lock_save_timer.start(LOCK_SAVE_DEBOUNCE_SEC)


func _ensure_lock_save_timer() -> void:
	if _lock_save_timer != null and is_instance_valid(_lock_save_timer):
		return
	_lock_save_timer = Timer.new()
	_lock_save_timer.name = "CatalogLockSaveTimer"
	_lock_save_timer.one_shot = true
	_lock_save_timer.wait_time = LOCK_SAVE_DEBOUNCE_SEC
	_lock_save_timer.timeout.connect(_flush_lock_save)
	add_child(_lock_save_timer)


func _flush_lock_save() -> void:
	if not _lock_save_pending:
		return
	_lock_save_pending = false
	if _lock_save_timer != null and is_instance_valid(_lock_save_timer):
		_lock_save_timer.stop()
	SaveManager.save_game()


func _sync_catalog_lock_row_after_toggle() -> void:
	## 詳細全文 rebuild せず、ロック行の文言だけ合わせる（Abort／ちらつき回避）。
	if _selected_item == null:
		return
	if (
		_selected_category != "weapon"
		and _selected_category != "armor"
		and _selected_category != "accessory"
	):
		return
	var row: Node = _detail_host.get_node_or_null("CatalogLockRow")
	if row == null:
		_refresh_detail_panel()
		return
	var lock_btn: Button = null
	for child in row.get_children():
		if child is Button:
			lock_btn = child as Button
			break
	if lock_btn == null:
		_refresh_detail_panel()
		return
	var locked: bool = EquipmentEnhancer.is_item_locked(_selected_item)
	lock_btn.text = (
		"%s ロック解除" % EquipmentUiHelper.LOCK_BADGE_TEXT
		if locked
		else "%s ロックする" % EquipmentUiHelper.LOCK_BADGE_TEXT
	)

func _show_lock_toast(text: String) -> void:
	if text.is_empty():
		return
	if _lock_toast == null or not is_instance_valid(_lock_toast):
		_lock_toast = Label.new()
		_lock_toast.name = "LockToast"
		_lock_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_lock_toast.z_index = 80
		_lock_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_lock_toast.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_lock_toast.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		_lock_toast.offset_left = 24.0
		_lock_toast.offset_right = -24.0
		_lock_toast.offset_top = -160.0
		_lock_toast.offset_bottom = -112.0
		UiTypography.apply_body(_lock_toast, UiTypography.SIZE_BODY, COLOR_GOLD)
		add_child(_lock_toast)
	_lock_toast.text = text
	_lock_toast.visible = true
	_lock_toast.modulate.a = 1.0
	if _lock_toast_tween != null and is_instance_valid(_lock_toast_tween):
		_lock_toast_tween.kill()
	_lock_toast_tween = create_tween()
	_lock_toast_tween.tween_interval(0.9)
	_lock_toast_tween.tween_property(_lock_toast, "modulate:a", 0.0, 0.25)
	_lock_toast_tween.tween_callback(func() -> void:
		if _lock_toast != null:
			_lock_toast.visible = false
	)

func _clear_item_cell_overlay_badges(btn: Button) -> void:
	if btn == null:
		return
	var to_free: Array[Node] = []
	for child in btn.get_children():
		var n: String = str(child.name)
		if n == "ItemIcon" or n == "OwnerBadge":
			continue
		if (
			n == "RarityCornerBadge"
			or n == "LegendaryBadge"
			or n == "LockBadge"
			or n == "NewEquipBadgeHost"
			or child is Label
		):
			to_free.append(child)
	for node in to_free:
		btn.remove_child(node)
		node.queue_free()

func _on_cell_pressed(item: Resource, category: String, btn: Button) -> void:
	## 詳細だけ更新。グリッド全再生成はしない（所持数が多いと実機で重い）。
	if (
		_selected_relic_id.is_empty()
		and item == _selected_item
		and category == _selected_category
	):
		_refresh_detail_panel()
		return
	_clear_selected_cell_visual()
	_selected_item = item
	_selected_category = category
	_selected_relic_id = ""
	_selected_cell_btn = btn
	if btn != null and is_instance_valid(btn):
		var rarity: int = int(btn.get_meta("cf_rarity", 0))
		var cell_px: int = int(_inv_cell_size.x)
		btn.modulate = Color(0.85, 0.92, 1.0, 1.0)
		_apply_item_cell_styles(btn, rarity, cell_px, false, true)
	_refresh_detail_panel()


func _on_relic_cell_pressed(relic_id: String, btn: Button) -> void:
	if relic_id == _selected_relic_id and not relic_id.is_empty():
		_refresh_detail_panel()
		return
	_clear_selected_cell_visual()
	_selected_item = null
	_selected_category = "relic"
	_selected_relic_id = relic_id
	_selected_cell_btn = btn
	if btn != null and is_instance_valid(btn):
		var cell_px: int = int(_inv_cell_size.x)
		btn.modulate = Color(0.85, 0.92, 1.0, 1.0)
		_apply_relic_cell_styles(btn, cell_px, true)
	_refresh_detail_panel()


func _clear_selected_cell_visual() -> void:
	if _selected_cell_btn == null or not is_instance_valid(_selected_cell_btn):
		_selected_cell_btn = null
		return
	var cell_px: int = int(_inv_cell_size.x)
	_selected_cell_btn.modulate = Color.WHITE
	if str(_selected_cell_btn.get_meta("cf_category", "")) == "relic":
		_apply_relic_cell_styles(_selected_cell_btn, cell_px, false)
	else:
		var rarity: int = int(_selected_cell_btn.get_meta("cf_rarity", 0))
		_apply_item_cell_styles(_selected_cell_btn, rarity, cell_px, false, false)
	_selected_cell_btn = null

func _refresh_detail_panel() -> void:
	if not _selected_relic_id.is_empty():
		EquipmentItemDetailHelper.populate_relic_stats_panel(_detail_host, _selected_relic_id, self)
		return
	## populate は host をクリアする。ロック行は後から先頭へ移す（下に隠れない）。
	EquipmentItemDetailHelper.populate_stats_panel(_detail_host, _selected_item, _selected_category, self)
	_append_catalog_lock_row()
	var lock_row: Node = _detail_host.get_node_or_null("CatalogLockRow")
	if lock_row != null:
		_detail_host.move_child(lock_row, 0)

func _append_catalog_lock_row() -> void:
	## 短押しで詳細を開いたあと、ここから確実にロックできる（長押しの代替）。
	if _selected_item == null:
		return
	if (
		_selected_category != "weapon"
		and _selected_category != "armor"
		and _selected_category != "accessory"
	):
		return
	var row := HBoxContainer.new()
	row.name = "CatalogLockRow"
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_host.add_child(row)
	var hint := Label.new()
	hint.text = "長押しでも切替可"
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_caption(hint, COLOR_SUB)
	row.add_child(hint)
	var btn := Button.new()
	var locked: bool = EquipmentEnhancer.is_item_locked(_selected_item)
	btn.text = "%s ロック解除" % EquipmentUiHelper.LOCK_BADGE_TEXT if locked else "%s ロックする" % EquipmentUiHelper.LOCK_BADGE_TEXT
	btn.custom_minimum_size = Vector2(160, 44)
	btn.set_meta(&"_cf_keep_mouse_stop", true)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	UiTypography.apply_menu_button(btn)
	btn.pressed.connect(_on_catalog_detail_lock_pressed)
	row.add_child(btn)

func _on_catalog_detail_lock_pressed() -> void:
	if _selected_item == null:
		return
	_toggle_catalog_item_lock(_selected_item, _selected_category, _selected_cell_btn)

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


func _apply_relic_cell_styles(btn: Button, cell_px: int, selected: bool = false) -> void:
	var normal: StyleBox = EquipmentUiTokens.relic_cell_style(selected, cell_px)
	var hover: StyleBox = EquipmentUiTokens.relic_cell_style(true, cell_px)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus", normal)
	btn.add_theme_stylebox_override("disabled", EquipmentUiTokens.relic_cell_style(false, cell_px))

func _apply_item_badges(
	btn: Button,
	item: Resource,
	category: String,
	size: Vector2,
	_is_equipped: bool
) -> void:
	var rarity: int = _item_rarity(item, category)
	EquipmentUiHelper.apply_rarity_badges(btn, rarity, size)
	EquipmentUiHelper.apply_equip_level_badge(btn, item, size)
	if category == "weapon":
		EquipmentUiHelper.apply_enhance_badge(btn, item, category, size, COLOR_GOLD)
	## 装備中の「装」は出さない。ドロップ直後は中央 New 点滅。ロックは右下。
	EquipmentUiHelper.apply_lock_badge(btn, item, size)
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


func _open_effect_family_sheet() -> void:
	_close_effect_family_sheet()
	var layer := CanvasLayer.new()
	layer.name = "EffectFamilySheet"
	layer.layer = 60
	add_child(layer)
	_effect_sheet = layer
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(root)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.55)
	dim.gui_input.connect(_on_effect_sheet_dim_input)
	root.add_child(dim)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(520, 0)
	panel.offset_left = -260
	panel.offset_right = 260
	panel.offset_top = -220
	panel.offset_bottom = 220
	panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD)
	)
	root.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	var title := Label.new()
	title.text = "効果で絞り込み"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_body(title, UiTypography.SIZE_BODY, COLOR_GOLD)
	vbox.add_child(title)
	var hint := Label.new()
	hint.text = "複数選択可（いずれかに該当）"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_caption(hint, COLOR_SUB)
	vbox.add_child(hint)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(grid)
	var draft: Array[String] = EquipmentEffectFamilyFilter.normalize_selection(_effect_families)
	for fid in EquipmentEffectFamilyFilter.FAMILY_ORDER:
		var chip := Button.new()
		chip.toggle_mode = true
		chip.button_pressed = draft.has(fid)
		chip.text = EquipmentEffectFamilyFilter.family_label(fid)
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.custom_minimum_size = Vector2(0, 44)
		UiTypography.apply_menu_button(chip, false)
		chip.toggled.connect(_on_effect_chip_toggled.bind(fid, draft))
		grid.add_child(chip)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	vbox.add_child(row)
	var btn_clear := Button.new()
	btn_clear.text = "クリア"
	btn_clear.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_menu_button(btn_clear, false)
	btn_clear.pressed.connect(_on_effect_sheet_clear.bind(draft, grid))
	row.add_child(btn_clear)
	var btn_ok := Button.new()
	btn_ok.text = "決定"
	btn_ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_menu_button(btn_ok, true)
	btn_ok.pressed.connect(_on_effect_sheet_confirm.bind(draft))
	row.add_child(btn_ok)


func _on_effect_chip_toggled(pressed: bool, family_id: String, draft: Array) -> void:
	var fid: String = str(family_id)
	if pressed:
		if not draft.has(fid):
			draft.append(fid)
	else:
		draft.erase(fid)


func _on_effect_sheet_clear(draft: Array, grid: GridContainer) -> void:
	draft.clear()
	if grid == null:
		return
	for child in grid.get_children():
		if child is Button:
			(child as Button).set_pressed_no_signal(false)


func _on_effect_sheet_confirm(draft: Array) -> void:
	_effect_families = EquipmentEffectFamilyFilter.normalize_selection(draft)
	_close_effect_family_sheet()
	_update_sort_filter_labels()
	_rebuild_inventory_grid()


func _on_effect_sheet_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close_effect_family_sheet()


func _close_effect_family_sheet() -> void:
	if _effect_sheet != null and is_instance_valid(_effect_sheet):
		_effect_sheet.queue_free()
	_effect_sheet = null


func _on_back_pressed() -> void:
	_flush_lock_save()
	_close_effect_family_sheet()
	SceneRouter.change_scene(HOME_SCENE)
