class_name ShopOverlay
extends CanvasLayer

## 魔晶石ショップ（P3-MONET-IAP-001-B）。召喚不足時と設定から開く。

const _IapCatalog := preload("res://scripts/iap/IapCatalog.gd")
const _IapLegalText := preload("res://scripts/iap/IapLegalText.gd")

signal closed
signal tokens_changed

const DIM_COLOR: Color = Color(0.02, 0.02, 0.06, 0.78)
const PANEL_MARGIN: int = 24
const INNER_PAD: int = 12
const ROW_SEP: int = 8
const COLOR_GOLD: Color = Color(0.86, 0.74, 0.45)
const COLOR_SUB: Color = Color(0.72, 0.69, 0.62)

var _status: Label = null
var _token_label: Label = null
var _list: VBoxContainer = null
var _buy_buttons: Array[Button] = []


static func present(host: Node) -> ShopOverlay:
	if host == null:
		return null
	var existing: Node = host.get_node_or_null("ShopOverlay")
	if existing is ShopOverlay:
		var shop: ShopOverlay = existing as ShopOverlay
		shop.open()
		return shop
	var overlay := ShopOverlay.new()
	overlay.name = "ShopOverlay"
	host.add_child(overlay)
	overlay.open()
	return overlay


func _ready() -> void:
	layer = 80
	_build_ui()
	if not PurchaseManager.purchase_finished.is_connected(_on_purchase_finished):
		PurchaseManager.purchase_finished.connect(_on_purchase_finished)
	visible = false


func open() -> void:
	visible = true
	_refresh()


func close() -> void:
	visible = false
	closed.emit()


func _build_ui() -> void:
	var dim := ColorRect.new()
	dim.name = "Dim"
	dim.color = DIM_COLOR
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(_on_dim_input)
	add_child(dim)
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", PANEL_MARGIN)
	margin.add_theme_constant_override("margin_right", PANEL_MARGIN)
	margin.add_theme_constant_override("margin_top", PANEL_MARGIN)
	margin.add_theme_constant_override("margin_bottom", PANEL_MARGIN)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(margin)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(panel)
	var inner := MarginContainer.new()
	inner.add_theme_constant_override("margin_left", INNER_PAD)
	inner.add_theme_constant_override("margin_right", INNER_PAD)
	inner.add_theme_constant_override("margin_top", INNER_PAD)
	inner.add_theme_constant_override("margin_bottom", INNER_PAD)
	panel.add_child(inner)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", ROW_SEP)
	inner.add_child(col)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	col.add_child(header)
	var title := Label.new()
	title.text = "魔晶石ショップ"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_display(title, UiTypography.SIZE_BODY, COLOR_GOLD)
	header.add_child(title)
	_token_label = Label.new()
	_token_label.clip_text = false
	UiTypography.apply_body(_token_label, UiTypography.SIZE_BODY_SMALL, COLOR_GOLD)
	header.add_child(_token_label)
	var close_btn := Button.new()
	close_btn.text = "閉じる"
	UiTypography.apply_button(close_btn, false)
	close_btn.pressed.connect(_on_close_pressed)
	header.add_child(close_btn)
	var note := Label.new()
	note.text = "決済は App Store が行います。大きいパックほど割安です。"
	note.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note.custom_minimum_size = Vector2(0, 0)
	UiTypography.apply_caption(note, COLOR_SUB)
	col.add_child(note)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.clip_contents = true
	ScrollTouchHelper.enable(scroll)
	col.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", ROW_SEP)
	scroll.add_child(_list)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.custom_minimum_size = Vector2(0, 0)
	UiTypography.apply_caption(_status, COLOR_SUB)
	col.add_child(_status)
	var legal := Label.new()
	legal.text = _IapLegalText.settings_body()
	legal.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	legal.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	legal.custom_minimum_size = Vector2(0, 0)
	UiTypography.apply_caption(legal, COLOR_SUB)
	col.add_child(legal)
	_fill_products()


func _fill_products() -> void:
	_buy_buttons.clear()
	for child in _list.get_children():
		child.queue_free()
	for raw: Dictionary in _IapCatalog.all_products():
		var pid: String = str(raw.get("id", ""))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var name_lbl := Label.new()
		name_lbl.text = str(raw.get("title", ""))
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.clip_text = false
		UiTypography.apply_body(name_lbl, UiTypography.SIZE_BODY_SMALL, COLOR_GOLD)
		row.add_child(name_lbl)
		var price_lbl := Label.new()
		price_lbl.text = PurchaseManager.localized_price_text(pid)
		price_lbl.clip_text = false
		UiTypography.apply_body(price_lbl, UiTypography.SIZE_BODY_SMALL)
		row.add_child(price_lbl)
		var buy := Button.new()
		buy.text = "購入"
		buy.set_meta("product_id", pid)
		UiTypography.apply_button(buy, true)
		buy.pressed.connect(_on_buy_pressed.bind(pid))
		row.add_child(buy)
		_buy_buttons.append(buy)
		_list.add_child(row)


func _refresh() -> void:
	if _token_label != null:
		_token_label.text = "%s %d" % [CurrencyHelper.DISPLAY_NAME, GameState.gacha_token]
	var available: bool = PurchaseManager.is_store_available()
	var busy: bool = PurchaseManager.is_busy()
	for btn: Button in _buy_buttons:
		btn.disabled = busy or not available
	if _status == null:
		return
	if not available:
		_status.text = "App Store（iOS）でのみ購入できます。"
	elif busy:
		_status.text = "購入処理中です…"
	else:
		_status.text = ""


func _on_buy_pressed(product_id: String) -> void:
	AudioManager.play_sfx("ui_confirm", 1.0, 0.08)
	var started: Dictionary = PurchaseManager.purchase(product_id)
	if not bool(started.get("ok", false)):
		if _status != null:
			_status.text = str(started.get("message", "購入できませんでした"))
		_refresh()
		return
	_refresh()


func _on_purchase_finished(result: Dictionary) -> void:
	if bool(result.get("ok", false)) and int(result.get("tokens", 0)) > 0:
		AudioManager.play_sfx("ui_confirm", 1.0, 0.08)
		tokens_changed.emit()
	if _status != null:
		_status.text = str(result.get("message", ""))
	_refresh()


func _on_close_pressed() -> void:
	AudioManager.play_sfx("ui_cancel")
	close()


func _on_dim_input(event: InputEvent) -> void:
	## 背面の召喚ボタンへタップを通さない。閉じるのはボタンのみ。
	if (
		(event is InputEventMouseButton and event.pressed)
		or (event is InputEventScreenTouch and event.pressed)
	):
		var dim: Control = get_node_or_null("Dim") as Control
		if dim != null:
			dim.accept_event()
