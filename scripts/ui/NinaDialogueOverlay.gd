class_name NinaDialogueOverlay
extends CanvasLayer

## 拠点での記録官ニーナ会話（功績／加入予告など）。

const _IntroUiAssets := preload("res://scripts/intro/IntroUiAssets.gd")

signal dismissed

const PORTRAIT_PATH: String = _IntroUiAssets.NINA_DIALOGUE
const PANEL_MIN: Vector2 = Vector2(600, 320)
## 立ち絵は縦長（約 2:3）。
const PORTRAIT_W: float = 120.0
const PORTRAIT_H: float = 180.0

var _lines: Array[String] = []
var _line_index: int = 0
var _dim: ColorRect
var _panel: PanelContainer
var _name_label: Label
var _body_label: Label
var _hint_label: Label
var _portrait: TextureRect
var _tween: Tween


func _ready() -> void:
	layer = 86
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func present(lines: Array) -> void:
	_lines.clear()
	for raw in lines:
		var text: String = str(raw).strip_edges()
		if not text.is_empty():
			_lines.append(text)
	if _lines.is_empty():
		_lines.append("…")
	_line_index = 0
	_refresh_line()
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
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = PANEL_MIN
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD_ACTIVE)
	)
	center.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(PORTRAIT_W, PORTRAIT_H)
	_portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex: Texture2D = _IntroUiAssets.load_tex(PORTRAIT_PATH)
	if tex == null:
		tex = _IntroUiAssets.load_tex(_IntroUiAssets.NINA_DIALOGUE_BUST)
	if tex == null:
		tex = _IntroUiAssets.load_tex(_IntroUiAssets.NINA_ICON)
	_portrait.texture = tex
	row.add_child(_portrait)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 10)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(col)

	_name_label = Label.new()
	_name_label.text = "記録官 ニーナ"
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_name_label)

	_body_label = Label.new()
	_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_body_label)

	_hint_label = Label.new()
	_hint_label.text = "タップで続ける"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_hint_label)

	visible = false


func _refresh_line() -> void:
	var text: String = _lines[_line_index] if _line_index < _lines.size() else "…"
	_body_label.text = text
	UiTypography.apply_display(_name_label, UiTypography.SIZE_BODY, UiTypography.COLOR_GOLD)
	UiTypography.apply_body(_body_label, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_BODY)
	UiTypography.apply_caption(_hint_label, UiTypography.COLOR_MUTED)
	if _line_index >= _lines.size() - 1:
		_hint_label.text = "タップで続ける"
	else:
		_hint_label.text = "タップで次へ"


func _play_intro() -> void:
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.92, 0.92)
	call_deferred("_sync_panel_pivot")
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_panel, "modulate:a", 1.0, 0.14)
	_tween.parallel().tween_property(_panel, "scale", Vector2.ONE, 0.2).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)


func _sync_panel_pivot() -> void:
	if _panel == null or not is_instance_valid(_panel):
		return
	_panel.pivot_offset = _panel.size * 0.5


func _on_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_advance()
	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		if st.pressed:
			_advance()


func _advance() -> void:
	if _line_index < _lines.size() - 1:
		_line_index += 1
		_refresh_line()
		AudioManager.play_sfx("ui_confirm")
		return
	_close()


func _close() -> void:
	AudioManager.play_sfx("ui_confirm")
	dismissed.emit()
	queue_free()


static func show_on(parent: Node, lines: Array) -> CanvasLayer:
	var overlay := new()
	overlay.name = "NinaDialogueOverlay"
	parent.add_child(overlay)
	overlay.present(lines)
	return overlay
