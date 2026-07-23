class_name HubNinaNavigator
extends PanelContainer

## 拠点ホーム右上のニーナ顔＋吹き出し（P3-UI-NINA-NAV-001）。
## 10秒ローテ／タップで次へ。文言は HubNinaNavHelper。

const _IntroUiAssets := preload("res://scripts/intro/IntroUiAssets.gd")
const _HubNinaNavHelper := preload("res://scripts/ui/HubNinaNavHelper.gd")

const ROTATE_SEC: float = 10.0
const PANEL_W: float = 308.0
const PANEL_H: float = 160.0
const FACE_PX: float = 80.0
const MARGIN_RIGHT: float = 12.0
## TopBar 直下から下げて、指揮官カード／バナーと被りにくくする。
const GAP_BELOW_TOP: float = 48.0

var _bubble: Label
var _messages: Array[Dictionary] = []
var _index: int = 0
var _elapsed: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	_build_chrome()
	refresh_messages()
	set_process(true)


func _process(delta: float) -> void:
	if _messages.size() <= 1:
		return
	_elapsed += delta
	if _elapsed >= ROTATE_SEC:
		_elapsed = 0.0
		_advance()


func refresh_messages() -> void:
	_messages = _HubNinaNavHelper.build_rotation()
	_index = 0
	_elapsed = 0.0
	_apply_current()


func place_below_top_bar(top_bar: Control) -> void:
	if top_bar == null:
		return
	var top: float = top_bar.offset_bottom + GAP_BELOW_TOP
	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	offset_left = -PANEL_W - MARGIN_RIGHT
	offset_right = -MARGIN_RIGHT
	offset_top = top
	offset_bottom = top + PANEL_H
	custom_minimum_size = Vector2(PANEL_W, PANEL_H)


func _build_chrome() -> void:
	name = "NinaNavPanel"
	z_index = 12
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.07, 0.12, 0.88)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.55, 0.45, 0.18, 0.7)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 8.0
	sb.content_margin_top = 8.0
	sb.content_margin_right = 8.0
	sb.content_margin_bottom = 8.0
	add_theme_stylebox_override("panel", sb)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(row)

	var bubble_col := VBoxContainer.new()
	bubble_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bubble_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bubble_col.add_theme_constant_override("separation", 2)
	row.add_child(bubble_col)

	var name_lbl := Label.new()
	name_lbl.text = "記録官 ニーナ"
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_caption(name_lbl, UiTypography.COLOR_GOLD)
	bubble_col.add_child(name_lbl)

	_bubble = Label.new()
	_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bubble.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_bubble.clip_text = false
	_bubble.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_body(_bubble, 15, UiTypography.COLOR_BODY)
	bubble_col.add_child(_bubble)

	var face_frame := PanelContainer.new()
	face_frame.custom_minimum_size = Vector2(FACE_PX, FACE_PX)
	face_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	face_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	face_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face_frame.clip_contents = true
	var face_sb := StyleBoxFlat.new()
	face_sb.bg_color = Color(0.08, 0.09, 0.14, 1.0)
	face_sb.set_border_width_all(1)
	face_sb.border_color = Color(0.62, 0.52, 0.35, 0.85)
	face_sb.set_corner_radius_all(8)
	face_frame.add_theme_stylebox_override("panel", face_sb)
	row.add_child(face_frame)

	var face := TextureRect.new()
	face.custom_minimum_size = Vector2(FACE_PX, FACE_PX)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon_tex: Texture2D = _IntroUiAssets.load_tex(_IntroUiAssets.NINA_ICON)
	if icon_tex == null:
		icon_tex = _IntroUiAssets.load_tex(_IntroUiAssets.NINA_PORTRAIT)
		face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	face.texture = icon_tex
	face_frame.add_child(face)

	tooltip_text = "タップで次の案内"


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_elapsed = 0.0
			_advance()
			accept_event()


func _advance() -> void:
	if _messages.is_empty():
		return
	_index = (_index + 1) % _messages.size()
	_apply_current()


func _apply_current() -> void:
	if _bubble == null:
		return
	if _messages.is_empty():
		_bubble.text = ""
		return
	var item: Dictionary = _messages[_index]
	_bubble.text = str(item.get("text", ""))
