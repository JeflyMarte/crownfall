extends Control

## 隊長名入力 — P3-INTRO-001。

const _IntroLoreContent := preload("res://scripts/intro/IntroLoreContent.gd")
const _CommanderProfile := preload("res://scripts/commander/CommanderProfile.gd")
const NEXT_SCENE: String = "res://scenes/intro/IntroNinaScene.tscn"

var _line_edit: LineEdit
var _confirm_btn: Button
var _error_lbl: Label


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.06, 0.09, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 48)
	margin.add_theme_constant_override("margin_bottom", 36)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	margin.add_child(root)

	var title := Label.new()
	title.text = "隊長の名前"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_display(title, UiTypography.SIZE_DISPLAY_TITLE, UiTypography.COLOR_GOLD)
	root.add_child(title)

	var sub := Label.new()
	sub.text = "調査隊を率いるあなたの名前を決めてください。"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_body(sub, 18, Color(0.75, 0.78, 0.85))
	root.add_child(sub)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.size_flags_stretch_ratio = 0.4
	root.add_child(spacer)

	_line_edit = LineEdit.new()
	_line_edit.placeholder_text = "例：アステル"
	_line_edit.max_length = _IntroLoreContent.MAX_NAME_LEN
	_line_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_line_edit.custom_minimum_size = Vector2(0, 52)
	_line_edit.text_changed.connect(_on_text_changed)
	_line_edit.text_submitted.connect(func(_t: String) -> void: _on_confirm())
	root.add_child(_line_edit)

	_error_lbl = Label.new()
	_error_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_error_lbl.visible = false
	UiTypography.apply_caption(_error_lbl, Color(0.95, 0.45, 0.4))
	root.add_child(_error_lbl)

	var spacer2 := Control.new()
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer2.size_flags_stretch_ratio = 0.6
	root.add_child(spacer2)

	_confirm_btn = Button.new()
	_confirm_btn.text = "この名前で登録"
	_confirm_btn.disabled = true
	_confirm_btn.custom_minimum_size = Vector2(0, 52)
	UiTypography.apply_button(_confirm_btn)
	_confirm_btn.pressed.connect(_on_confirm)
	root.add_child(_confirm_btn)


func _on_text_changed(new_text: String) -> void:
	var ok: bool = not new_text.strip_edges().is_empty()
	_confirm_btn.disabled = not ok
	_error_lbl.visible = false


func _on_confirm() -> void:
	var name_text: String = _line_edit.text.strip_edges()
	if not GameState.apply_intro_commander_name(name_text):
		_error_lbl.text = "名前を入力してください"
		_error_lbl.visible = true
		return
	SceneRouter.change_scene(NEXT_SCENE)
