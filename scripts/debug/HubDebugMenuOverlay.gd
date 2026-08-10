class_name HubDebugMenuOverlay
extends CanvasLayer

## 拠点左メニュー「デバッグ」— 演出イベント呼び出し（debug_full_unlock 限定）。

const _HubDebugEvents := preload("res://scripts/debug/HubDebugEvents.gd")
const _DebugAccess := preload("res://scripts/debug/DebugAccess.gd")

signal closed
signal event_requested(entry_id: String)

var _dim: ColorRect
var _panel: PanelContainer
var _list: VBoxContainer
var _status: Label


func _ready() -> void:
	layer = 92
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func present() -> void:
	_status.text = "項目を選ぶと演出をキューします"
	visible = true
	AudioManager.play_sfx("ui_confirm")


func _build() -> void:
	_dim = ColorRect.new()
	_dim.color = Color(0.02, 0.03, 0.06, 0.72)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(_on_dim_gui_input)
	add_child(_dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(600, 720)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD_ACTIVE)
	)
	center.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	_panel.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var title := Label.new()
	title.text = "デバッグ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_display(title, UiTypography.SIZE_DISPLAY, UiTypography.COLOR_GOLD)
	root.add_child(title)

	var sub := Label.new()
	sub.text = "章クリア演出などを手動で呼び出します"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_caption(sub, UiTypography.COLOR_SUB)
	root.add_child(sub)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)
	ScrollTouchHelper.enable(scroll)

	for entry in _HubDebugEvents.list_entries():
		if bool(entry.get("section", false)):
			_list.add_child(_make_section_label(entry))
		else:
			_list.add_child(_make_entry_button(entry))

	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_caption(_status, UiTypography.COLOR_MUTED)
	root.add_child(_status)

	var close_btn := Button.new()
	close_btn.text = "閉じる"
	close_btn.custom_minimum_size = Vector2(0, 48)
	UiTypography.apply_button(close_btn)
	close_btn.pressed.connect(_close)
	root.add_child(close_btn)

	visible = false


func _make_section_label(entry: Dictionary) -> Label:
	var label := Label.new()
	label.text = str(entry.get("title", ""))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	UiTypography.apply_caption(label, UiTypography.COLOR_GOLD)
	return label


func _make_entry_button(entry: Dictionary) -> Button:
	var btn := Button.new()
	btn.text = "%s\n%s" % [str(entry.get("title", "")), str(entry.get("hint", ""))]
	btn.custom_minimum_size = Vector2(0, 58)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	UiTypography.apply_button(btn)
	btn.add_theme_font_size_override("font_size", UiTypography.SIZE_CAPTION)
	var entry_id: String = str(entry.get("id", ""))
	btn.pressed.connect(_on_entry_pressed.bind(entry_id))
	return btn


func _on_entry_pressed(entry_id: String) -> void:
	var err: String = _HubDebugEvents.run(entry_id)
	if not err.is_empty():
		_status.text = err
		AudioManager.play_sfx("ui_cancel")
		return
	_status.text = "キューしました"
	AudioManager.play_sfx("ui_confirm")
	event_requested.emit(entry_id)
	_close()


func _on_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_close()
	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		if st.pressed:
			_close()


func _close() -> void:
	closed.emit()
	queue_free()


static func show_on(parent: Node) -> CanvasLayer:
	if not _DebugAccess.is_allowed():
		return null
	var overlay := new()
	overlay.name = "HubDebugMenuOverlay"
	parent.add_child(overlay)
	overlay.present()
	return overlay
