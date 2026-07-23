class_name DungeonUnlockOverlay
extends CanvasLayer

## 「○○が解放された！」ポップアップ。

signal dismissed(display_name: String)

var _display_name: String = ""
var _dim: ColorRect
var _panel: PanelContainer
var _title_label: Label
var _hint_label: Label
var _tween: Tween


func _ready() -> void:
	layer = 85
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func present(display_name: String) -> void:
	_display_name = display_name.strip_edges()
	_title_label.text = "%sが解放された！" % _display_name
	UiTypography.apply_display(
		_title_label, 28, Color(1.0, 0.92, 0.38), UiTypography.OUTLINE_STRONG
	)
	UiTypography.apply_caption(_hint_label, UiTypography.COLOR_SUB)
	visible = true
	_play_intro()
	call_deferred("_play_sfx")


func _play_sfx() -> void:
	AudioManager.play_sfx("ui_confirm")


func _build() -> void:
	_dim = ColorRect.new()
	_dim.name = "Dim"
	_dim.color = Color(0.02, 0.03, 0.06, 0.72)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(_on_dim_gui_input)
	add_child(_dim)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.custom_minimum_size = Vector2(340, 160)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD_ACTIVE)
	)
	center.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(margin)

	var inner := VBoxContainer.new()
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_theme_constant_override("separation", 14)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(inner)

	var eyebrow := Label.new()
	eyebrow.text = "ダンジョン解放"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_caption(eyebrow, UiTypography.COLOR_GOLD)
	inner.add_child(eyebrow)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(_title_label)

	_hint_label = Label.new()
	_hint_label.text = "タップして閉じる"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(_hint_label)

	visible = false


func _play_intro() -> void:
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.7, 0.7)
	_panel.pivot_offset = _panel.custom_minimum_size * 0.5
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_panel, "modulate:a", 1.0, 0.16)
	_tween.parallel().tween_property(_panel, "scale", Vector2(1.08, 1.08), 0.26).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	_tween.chain().tween_property(_panel, "scale", Vector2.ONE, 0.1)


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
	AudioManager.play_sfx("ui_confirm")
	var name_str: String = _display_name
	dismissed.emit(name_str)
	queue_free()


static func show_on(parent: Node, display_name: String) -> CanvasLayer:
	var overlay := new()
	overlay.name = "DungeonUnlockOverlay"
	parent.add_child(overlay)
	overlay.present(display_name)
	return overlay
