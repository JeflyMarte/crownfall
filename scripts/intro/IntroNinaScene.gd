extends Control

## 記録官ニーナの最短紹介 — P3-INTRO-001。

const _IntroLoreContent := preload("res://scripts/intro/IntroLoreContent.gd")
const NEXT_SCENE: String = "res://scenes/roster/StarterPickScene.tscn"

var _line_idx: int = 0
var _bubble: Label
var _next_btn: Button


func _ready() -> void:
	_build_ui()
	_refresh_line()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.05, 0.06, 0.09, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 32)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	margin.add_child(root)

	var name_lbl := Label.new()
	name_lbl.text = "記録官 ニーナ"
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_display(name_lbl, UiTypography.SIZE_DISPLAY_TITLE, UiTypography.COLOR_GOLD)
	root.add_child(name_lbl)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)

	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.13, 0.18, 0.96)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.55, 0.48, 0.72)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", sb)
	root.add_child(panel)

	_bubble = Label.new()
	_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble.custom_minimum_size = Vector2(0, 120)
	UiTypography.apply_body(_bubble, 22)
	panel.add_child(_bubble)

	var spacer2 := Control.new()
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer2)

	_next_btn = Button.new()
	_next_btn.custom_minimum_size = Vector2(0, 52)
	UiTypography.apply_button(_next_btn)
	_next_btn.pressed.connect(_on_next)
	root.add_child(_next_btn)


func _refresh_line() -> void:
	var lines: Array[String] = _IntroLoreContent.NINA_LINES
	if _line_idx < 0 or _line_idx >= lines.size():
		SceneRouter.change_scene(NEXT_SCENE)
		return
	_bubble.text = lines[_line_idx]
	var last: bool = _line_idx >= lines.size() - 1
	_next_btn.text = "隊員を選ぶ" if last else "次へ"


func _on_next() -> void:
	_line_idx += 1
	if _line_idx >= _IntroLoreContent.NINA_LINES.size():
		SceneRouter.change_scene(NEXT_SCENE)
		return
	_refresh_line()
