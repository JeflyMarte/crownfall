class_name NinaDialogueOverlay
extends CanvasLayer

## 拠点での記録官ニーナ会話（功績／加入予告など）。
## 行は String（ニーナ）または { "speaker": "nina"|"nonoka", "text": "..." }。

const _IntroUiAssets := preload("res://scripts/intro/IntroUiAssets.gd")
const _SurveyStaff := preload("res://scripts/survey/SurveyStaff.gd")

signal dismissed

const PORTRAIT_PATH: String = _IntroUiAssets.NINA_DIALOGUE
const PANEL_MIN: Vector2 = Vector2(600, 320)
## 立ち絵は縦長（約 2:3）。
const PORTRAIT_W: float = 120.0
const PORTRAIT_H: float = 180.0

const SPEAKER_NINA: String = "nina"
const SPEAKER_NONOKA: String = "nonoka"

var _entries: Array[Dictionary] = []
var _line_index: int = 0
var _dim: ColorRect
var _panel: PanelContainer
var _name_label: Label
var _body_label: Label
var _hint_label: Label
var _portrait: TextureRect
var _tween: Tween
var _nina_portrait_tex: Texture2D = null
var _nonoka_portrait_tex: Texture2D = null


func _ready() -> void:
	layer = 86
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func present(lines: Array) -> void:
	_entries.clear()
	for raw in lines:
		var entry: Dictionary = _normalize_entry(raw)
		if entry.is_empty():
			continue
		_entries.append(entry)
	if _entries.is_empty():
		_entries.append({"speaker": SPEAKER_NINA, "text": "…"})
	_line_index = 0
	_refresh_line()
	visible = true
	_play_intro()
	call_deferred("_play_sfx")


func _normalize_entry(raw: Variant) -> Dictionary:
	if raw is Dictionary:
		var d: Dictionary = raw as Dictionary
		var text: String = str(d.get("text", "")).strip_edges()
		if text.is_empty():
			return {}
		var speaker: String = str(d.get("speaker", SPEAKER_NINA)).strip_edges().to_lower()
		if speaker != SPEAKER_NONOKA:
			speaker = SPEAKER_NINA
		return {"speaker": speaker, "text": text}
	var text_s: String = str(raw).strip_edges()
	if text_s.is_empty():
		return {}
	return {"speaker": SPEAKER_NINA, "text": text_s}


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
	_nina_portrait_tex = _IntroUiAssets.load_tex(PORTRAIT_PATH)
	if _nina_portrait_tex == null:
		_nina_portrait_tex = _IntroUiAssets.load_tex(_IntroUiAssets.NINA_DIALOGUE_BUST)
	if _nina_portrait_tex == null:
		_nina_portrait_tex = _IntroUiAssets.load_tex(_IntroUiAssets.NINA_ICON)
	_nonoka_portrait_tex = _SurveyStaff.load_icon_texture(_SurveyStaff.ID_NONOKA)
	if _nonoka_portrait_tex == null:
		var npath: String = _SurveyStaff.portrait_path(_SurveyStaff.ID_NONOKA)
		if not npath.is_empty() and ResourceLoader.exists(npath):
			_nonoka_portrait_tex = load(npath) as Texture2D
	_portrait.texture = _nina_portrait_tex
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
	var entry: Dictionary = _entries[_line_index] if _line_index < _entries.size() else {}
	var speaker: String = str(entry.get("speaker", SPEAKER_NINA))
	var text: String = str(entry.get("text", "…"))
	_body_label.text = text
	if speaker == SPEAKER_NONOKA:
		_name_label.text = "研究員 ノノカ"
		if _nonoka_portrait_tex != null:
			_portrait.texture = _nonoka_portrait_tex
	else:
		_name_label.text = "記録官 ニーナ"
		if _nina_portrait_tex != null:
			_portrait.texture = _nina_portrait_tex
	UiTypography.apply_display(_name_label, UiTypography.SIZE_BODY, UiTypography.COLOR_GOLD)
	UiTypography.apply_body(_body_label, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_BODY)
	UiTypography.apply_caption(_hint_label, UiTypography.COLOR_MUTED)
	if _line_index >= _entries.size() - 1:
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
	if _line_index < _entries.size() - 1:
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
