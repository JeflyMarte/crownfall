extends Control

## 世界観ナレーション（縦スクロール・スキップ可）— P3-INTRO-001。

const _IntroLoreContent := preload("res://scripts/intro/IntroLoreContent.gd")
const NEXT_SCENE: String = "res://scenes/intro/IntroNameScene.tscn"

var _scroll: ScrollContainer
var _continue_btn: Button


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.04, 0.05, 0.08, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	root.add_child(header)

	var title := Label.new()
	title.text = "はじまり"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UiTypography.apply_display(title, UiTypography.SIZE_DISPLAY_TITLE, UiTypography.COLOR_GOLD)
	header.add_child(title)

	var skip_btn := Button.new()
	skip_btn.text = "スキップ"
	skip_btn.custom_minimum_size = Vector2(120, 44)
	UiTypography.apply_button(skip_btn)
	skip_btn.pressed.connect(_go_next)
	header.add_child(skip_btn)

	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(_scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 28)
	_scroll.add_child(list)

	for i: int in _IntroLoreContent.PANELS.size():
		var panel_lbl := Label.new()
		panel_lbl.text = _IntroLoreContent.PANELS[i]
		panel_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panel_lbl.custom_minimum_size = Vector2(0, 96)
		UiTypography.apply_body(panel_lbl, 22, Color(0.88, 0.86, 0.80))
		list.add_child(panel_lbl)

	var hint := Label.new()
	hint.text = "下へスクロールして読み進めてください"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_caption(hint)
	list.add_child(hint)

	_continue_btn = Button.new()
	_continue_btn.text = "続ける"
	_continue_btn.custom_minimum_size = Vector2(0, 52)
	UiTypography.apply_button(_continue_btn)
	_continue_btn.pressed.connect(_go_next)
	root.add_child(_continue_btn)


func _go_next() -> void:
	SceneRouter.change_scene(NEXT_SCENE)
