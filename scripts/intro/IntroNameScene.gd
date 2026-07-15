extends Control

## 隊長名入力 — P3-INTRO-001 / 002。

const _IntroLoreContent := preload("res://scripts/intro/IntroLoreContent.gd")
const _IntroUiAssets := preload("res://scripts/intro/IntroUiAssets.gd")
const NEXT_SCENE: String = "res://scenes/intro/IntroNinaScene.tscn"

var _line_edit: LineEdit
var _confirm_btn: Button
var _error_lbl: Label


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_IntroUiAssets.add_full_bg(self, _IntroUiAssets.BG_NAME, Color(0.05, 0.06, 0.09, 1.0))

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
	UiTypography.apply_body(sub, 18, Color(0.82, 0.84, 0.90))
	root.add_child(sub)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.size_flags_stretch_ratio = 0.4
	root.add_child(spacer)

	var field_panel := PanelContainer.new()
	var field_sb := StyleBoxFlat.new()
	field_sb.bg_color = Color(0.06, 0.07, 0.11, 0.88)
	field_sb.set_border_width_all(2)
	field_sb.border_color = Color(0.55, 0.48, 0.32, 0.85)
	field_sb.set_corner_radius_all(10)
	field_sb.set_content_margin_all(16)
	field_panel.add_theme_stylebox_override("panel", field_sb)
	root.add_child(field_panel)

	var field_col := VBoxContainer.new()
	field_col.add_theme_constant_override("separation", 12)
	field_panel.add_child(field_col)

	_line_edit = LineEdit.new()
	_line_edit.placeholder_text = "例：アステル"
	_line_edit.max_length = _IntroLoreContent.MAX_NAME_LEN
	_line_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_line_edit.custom_minimum_size = Vector2(0, 52)
	_line_edit.text_changed.connect(_on_text_changed)
	_line_edit.text_submitted.connect(func(_t: String) -> void: _on_confirm())
	field_col.add_child(_line_edit)

	_error_lbl = Label.new()
	_error_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_error_lbl.visible = false
	UiTypography.apply_caption(_error_lbl, Color(0.95, 0.45, 0.4))
	field_col.add_child(_error_lbl)

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
