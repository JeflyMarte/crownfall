extends CanvasLayer

## 0-0 訓練坑のニーナ説明（P3-INTRO-TUTORIAL-001）。スキップなし・1ページ。

signal dismissed

const _IntroUiAssets := preload("res://scripts/intro/IntroUiAssets.gd")

const BG_PATH: String = "res://assets/ui/UI_BG_HubSimpleGuide.png"
const PANEL_MIN: Vector2 = Vector2(700, 680)
const FACE_ICON_PX: float = 88.0
const BG_CONTENT_MARGIN: int = 88
const INK_TITLE: Color = Color(0.22, 0.12, 0.05, 1.0)
const INK_BODY: Color = Color(0.18, 0.11, 0.06, 1.0)
const HEADER_TOP_GAP: float = 28.0

var _dim: ColorRect
var _panel_shell: Control
var _title_label: Label
var _body_label: RichTextLabel
var _next_btn: Button
var _tween: Tween
var _emit_lock: bool = false


func _ready() -> void:
	layer = 92
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false


func present(title: String, body: String) -> void:
	_emit_lock = false
	_title_label.text = title
	_body_label.text = body
	visible = true
	_play_intro()
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

	_panel_shell = Control.new()
	_panel_shell.custom_minimum_size = PANEL_MIN
	_panel_shell.clip_contents = true
	_panel_shell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(_panel_shell)

	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.clip_contents = true
	panel.gui_input.connect(_on_dim_gui_input)
	var empty := StyleBoxEmpty.new()
	panel.add_theme_stylebox_override("panel", empty)
	_panel_shell.add_child(panel)

	var bg := TextureRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_SCALE
	bg.texture = _IntroUiAssets.load_tex(BG_PATH)
	panel.add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", BG_CONTENT_MARGIN)
	margin.add_theme_constant_override("margin_right", BG_CONTENT_MARGIN)
	margin.add_theme_constant_override("margin_top", BG_CONTENT_MARGIN - 4)
	margin.add_theme_constant_override("margin_bottom", BG_CONTENT_MARGIN - 16)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(margin)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 14)
	inner.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(inner)

	var header_gap := Control.new()
	header_gap.custom_minimum_size = Vector2(0, HEADER_TOP_GAP)
	header_gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(header_gap)

	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 10)
	inner.add_child(header)
	var face := TextureRect.new()
	face.custom_minimum_size = Vector2(FACE_ICON_PX, FACE_ICON_PX)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var face_tex: Texture2D = _IntroUiAssets.load_tex(_IntroUiAssets.NINA_ICON_GUIDE)
	if face_tex != null:
		face.texture = face_tex
	header.add_child(face)
	var who := Label.new()
	who.text = "記録官 ニーナ"
	who.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UiTypography.apply_display(who, UiTypography.SIZE_BODY, INK_TITLE)
	header.add_child(who)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_display(_title_label, UiTypography.SIZE_DISPLAY, INK_TITLE)
	inner.add_child(_title_label)

	var body_scroll := ScrollContainer.new()
	body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	body_scroll.clip_contents = true
	body_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	inner.add_child(body_scroll)
	_body_label = RichTextLabel.new()
	_body_label.bbcode_enabled = true
	_body_label.fit_content = true
	_body_label.scroll_active = false
	_body_label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_body_label.add_theme_color_override("default_color", INK_BODY)
	_body_label.add_theme_font_size_override("normal_font_size", 18)
	_body_label.add_theme_font_size_override("bold_font_size", 18)
	var body_font: Font = UiTypography.display_font()
	if body_font != null:
		_body_label.add_theme_font_override("normal_font", body_font)
		_body_label.add_theme_font_override("bold_font", body_font)
	body_scroll.add_child(_body_label)
	ScrollTouchHelper.enable(body_scroll)

	_next_btn = Button.new()
	_next_btn.text = "次へ"
	_next_btn.custom_minimum_size = Vector2(0, 48)
	UiTypography.apply_button(_next_btn)
	_next_btn.pressed.connect(_close)
	inner.add_child(_next_btn)


func _play_intro() -> void:
	_panel_shell.modulate.a = 0.0
	_panel_shell.scale = Vector2(0.86, 0.86)
	_panel_shell.pivot_offset = PANEL_MIN * 0.5
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_panel_shell, "modulate:a", 1.0, 0.16)
	_tween.parallel().tween_property(_panel_shell, "scale", Vector2(1.04, 1.04), 0.24).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	_tween.chain().tween_property(_panel_shell, "scale", Vector2.ONE, 0.1)


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
	if _emit_lock or not visible:
		return
	_emit_lock = true
	visible = false
	AudioManager.play_sfx("ui_confirm")
	dismissed.emit()
