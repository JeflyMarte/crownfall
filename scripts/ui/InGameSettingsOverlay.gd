class_name InGameSettingsOverlay
extends CanvasLayer

## 探索中など、シーンを離れずに設定を変更するオーバーレイ。

signal closed

const _SettingsPrefs := preload("res://scripts/settings/SettingsPrefs.gd")

const COLOR_GOLD: Color = Color(0.86, 0.74, 0.45)
const COLOR_SUB: Color = Color(0.72, 0.69, 0.62)
const PANEL_MIN: Vector2 = Vector2(520, 560)

var _speed_buttons: Dictionary = {}
var _dim: ColorRect
var _panel: PanelContainer


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func present() -> void:
	_SettingsPrefs.ensure_loaded()
	visible = true
	AudioManager.play_sfx("ui_confirm", 0.95, 0.0)


func _build() -> void:
	_dim = ColorRect.new()
	_dim.color = Color(0.02, 0.03, 0.06, 0.78)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(_on_dim_gui_input)
	add_child(_dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = PANEL_MIN
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD_ACTIVE)
	)
	center.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	_panel.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var title := Label.new()
	title.text = "設定"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_display(title, 28, COLOR_GOLD)
	root.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	scroll.add_child(body)

	_add_section_label(body, "音声")
	body.add_child(_make_volume_row("Master", _SettingsPrefs.get_master_volume(), _on_master))
	body.add_child(_make_volume_row("BGM", _SettingsPrefs.get_bgm_volume(), _on_bgm))
	body.add_child(_make_volume_row("SE", _SettingsPrefs.get_sfx_volume(), _on_sfx))
	body.add_child(_make_check("ミュート", _SettingsPrefs.is_muted(), _on_mute))

	_add_section_label(body, "ゲームプレイ")
	var speed_lbl := Label.new()
	speed_lbl.text = "戦闘速度"
	UiTypography.apply_caption(speed_lbl, COLOR_SUB)
	body.add_child(speed_lbl)
	var speed_row := HBoxContainer.new()
	speed_row.add_theme_constant_override("separation", 8)
	body.add_child(speed_row)
	for pair in [
		[_SettingsPrefs.SPEED_ID_X1, "×1"],
		[_SettingsPrefs.SPEED_ID_X15, "×1.5"],
		[_SettingsPrefs.SPEED_ID_X2, "×2"],
	]:
		var btn := Button.new()
		btn.toggle_mode = true
		btn.text = str(pair[1])
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 44)
		btn.pressed.connect(_on_speed.bind(str(pair[0])))
		UiTypography.apply_button(btn, false)
		speed_row.add_child(btn)
		_speed_buttons[str(pair[0])] = btn
	_refresh_speed()

	body.add_child(_make_check("ダメージ数字を表示", _SettingsPrefs.show_damage_numbers(), _on_damage))
	body.add_child(_make_check("振動", _SettingsPrefs.is_vibration_enabled(), _on_vibration))
	var vib_hint := Label.new()
	vib_hint.text = "オフにすると戦闘ヒット時の振動を止めます（対応端末のみ）"
	vib_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_caption(vib_hint, COLOR_SUB)
	body.add_child(vib_hint)

	var close_btn := Button.new()
	close_btn.text = "閉じる"
	close_btn.custom_minimum_size = Vector2(0, 48)
	close_btn.pressed.connect(_close)
	UiTypography.apply_button(close_btn, true)
	root.add_child(close_btn)

	## 本文は Button／CheckButton／HSlider の Scroll。未適用だと実機でタッチスクロールできない。
	ScrollTouchHelper.enable(scroll)

	visible = false


func _add_section_label(parent: Control, text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	UiTypography.apply_display(lbl, UiTypography.SIZE_BODY, COLOR_GOLD)
	parent.add_child(lbl)


func _make_volume_row(label_text: String, value: float, handler: Callable) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(72, 0)
	UiTypography.apply_body(lbl, UiTypography.SIZE_BODY_SMALL)
	row.add_child(lbl)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(0, 28)
	slider.value_changed.connect(handler)
	row.add_child(slider)
	return row


func _make_check(text: String, pressed: bool, handler: Callable) -> CheckButton:
	var btn := CheckButton.new()
	btn.text = text
	btn.button_pressed = pressed
	btn.toggled.connect(handler)
	UiTypography.apply_button(btn, false)
	return btn


func _refresh_speed() -> void:
	var current: String = _SettingsPrefs.get_combat_speed_id()
	for speed_id in _speed_buttons.keys():
		var btn: Button = _speed_buttons[speed_id] as Button
		if btn == null:
			continue
		var active: bool = str(speed_id) == current
		btn.button_pressed = active
		UiTypography.apply_button(btn, active)


func _on_master(v: float) -> void:
	_SettingsPrefs.set_master_volume(v)


func _on_bgm(v: float) -> void:
	_SettingsPrefs.set_bgm_volume(v)


func _on_sfx(v: float) -> void:
	_SettingsPrefs.set_sfx_volume(v)


func _on_mute(v: bool) -> void:
	_SettingsPrefs.set_muted(v)


func _on_speed(speed_id: String) -> void:
	_SettingsPrefs.set_combat_speed_id(speed_id)
	_refresh_speed()


func _on_damage(v: bool) -> void:
	_SettingsPrefs.set_show_damage_numbers(v)


func _on_vibration(v: bool) -> void:
	_SettingsPrefs.set_vibration_enabled(v)


func _on_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_close()
	elif event is InputEventScreenTouch:
		if (event as InputEventScreenTouch).pressed:
			_close()


func _close() -> void:
	AudioManager.play_sfx("ui_confirm", 0.9, 0.0)
	visible = false
	closed.emit()
	queue_free()


static func show_on(parent: Node) -> CanvasLayer:
	if parent == null:
		return null
	if parent.get_node_or_null("InGameSettingsOverlay") != null:
		return parent.get_node("InGameSettingsOverlay") as CanvasLayer
	var overlay := new()
	overlay.name = "InGameSettingsOverlay"
	parent.add_child(overlay)
	overlay.present()
	return overlay
