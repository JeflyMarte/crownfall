class_name HubNinaNavigator
extends Control

## 拠点ホーム右上のニーナ顔＋吹き出し（P3-UI-NINA-NAV-001）。
## 10秒ローテ／タップで次へ。文言は HubNinaNavHelper。
## 吹き出しパネルの少し下に調査室ショートカット（左メニューからはオミット）。

signal survey_pressed

const _IntroUiAssets := preload("res://scripts/intro/IntroUiAssets.gd")
const _HubNinaNavHelper := preload("res://scripts/ui/HubNinaNavHelper.gd")

const ROTATE_SEC: float = 10.0
const PANEL_W: float = 308.0
const PANEL_H: float = 160.0
const FACE_PX: float = 80.0
const SURVEY_ICON_PX: float = 350.0
const SURVEY_FRAME_INSET: float = 10.0
const GAP_BELOW_PANEL: float = 40.0
## 親右端より外へはみ出して画面右端寄りに寄せる（負＝右方向）。
const SURVEY_MARGIN_RIGHT: float = -80.0
const MARGIN_RIGHT: float = 12.0
## TopBar 直下から下げて、指揮官カード／バナーと被りにくくする。
const GAP_BELOW_TOP: float = 48.0
## 調査室ショートカットの「押せる」アテンション点滅。
const SURVEY_PULSE_SEC: float = 0.75
const SURVEY_PULSE_DIM: Color = Color(0.9, 0.86, 0.78, 1.0)
const SURVEY_PULSE_BRIGHT: Color = Color(1.4, 1.22, 0.72, 1.0)

var _panel: PanelContainer
var _bubble: Label
var _survey_frame: PanelContainer
var _survey_btn: TextureButton
var _survey_pulse_tween: Tween
var _messages: Array[Dictionary] = []
var _index: int = 0
var _elapsed: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_chrome()
	refresh_messages()
	_start_survey_attention_pulse()
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
	var frame_px: float = SURVEY_ICON_PX
	var total_h: float = PANEL_H + GAP_BELOW_PANEL + frame_px
	set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	offset_left = - PANEL_W - MARGIN_RIGHT
	offset_right = - MARGIN_RIGHT
	offset_top = top
	offset_bottom = top + total_h
	custom_minimum_size = Vector2(PANEL_W, total_h)
	if _panel != null:
		_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		_panel.offset_left = 0.0
		_panel.offset_right = 0.0
		_panel.offset_top = 0.0
		_panel.offset_bottom = PANEL_H
		_panel.custom_minimum_size = Vector2(PANEL_W, PANEL_H)
	if _survey_frame != null:
		## 吹き出しの右下寄りに枠付きアイコンを配置。
		_survey_frame.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		_survey_frame.offset_left = - SURVEY_MARGIN_RIGHT - frame_px
		_survey_frame.offset_right = - SURVEY_MARGIN_RIGHT
		_survey_frame.offset_top = PANEL_H + GAP_BELOW_PANEL
		_survey_frame.offset_bottom = PANEL_H + GAP_BELOW_PANEL + frame_px
		_survey_frame.custom_minimum_size = Vector2(frame_px, frame_px)


func _start_survey_attention_pulse() -> void:
	if _survey_frame == null:
		return
	if _survey_pulse_tween != null and is_instance_valid(_survey_pulse_tween):
		_survey_pulse_tween.kill()
	_survey_frame.modulate = SURVEY_PULSE_DIM
	_survey_frame.scale = Vector2.ONE
	_survey_pulse_tween = create_tween().set_loops()
	_survey_pulse_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_survey_pulse_tween.tween_property(_survey_frame, "modulate", SURVEY_PULSE_BRIGHT, SURVEY_PULSE_SEC)
	_survey_pulse_tween.tween_property(_survey_frame, "modulate", SURVEY_PULSE_DIM, SURVEY_PULSE_SEC)


func _exit_tree() -> void:
	if _survey_pulse_tween != null and is_instance_valid(_survey_pulse_tween):
		_survey_pulse_tween.kill()
	_survey_pulse_tween = null


func _build_chrome() -> void:
	name = "NinaNavPanel"
	z_index = 12

	_panel = PanelContainer.new()
	_panel.name = "SpeechPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.gui_input.connect(_on_gui_input)
	_panel.tooltip_text = "タップで次の案内"
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.07, 0.12, 0.88)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.55, 0.45, 0.18, 0.7)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 8.0
	sb.content_margin_top = 8.0
	sb.content_margin_right = 8.0
	sb.content_margin_bottom = 8.0
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel.add_child(row)

	var bubble_col := VBoxContainer.new()
	bubble_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bubble_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bubble_col.add_theme_constant_override("separation", 4)
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
	face_frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
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

	_survey_frame = PanelContainer.new()
	_survey_frame.name = "SurveyFrame"
	_survey_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	_survey_frame.clip_contents = true
	_survey_frame.tooltip_text = "調査室"
	## アイコン自体が丸切り抜きなので、枠 StyleBox は置かない。
	var survey_sb := StyleBoxEmpty.new()
	survey_sb.content_margin_left = 0.0
	survey_sb.content_margin_top = 0.0
	survey_sb.content_margin_right = 0.0
	survey_sb.content_margin_bottom = 0.0
	_survey_frame.add_theme_stylebox_override("panel", survey_sb)
	add_child(_survey_frame)

	_survey_btn = TextureButton.new()
	_survey_btn.name = "BtnSurvey"
	_survey_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	_survey_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_survey_btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_survey_btn.ignore_texture_size = true
	_survey_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_survey_btn.tooltip_text = "調査室"
	var survey_tex: Texture2D = IconPaths.get_icon_texture("survey", "hub")
	if survey_tex == null:
		survey_tex = IconPaths.get_icon_texture("survey", "ui")
	_survey_btn.texture_normal = survey_tex
	_survey_btn.pressed.connect(_on_survey_pressed)
	_survey_frame.add_child(_survey_btn)


func _on_survey_pressed() -> void:
	survey_pressed.emit()


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
