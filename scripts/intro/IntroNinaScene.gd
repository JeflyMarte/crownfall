extends Control

## 記録官ニーナの最短紹介 — P3-INTRO-001 / 002 / P3-INTRO-NINA-TYPE-001。
## レイアウト: 左立ち絵 / 右吹き出し / 下に次へ。
## 表示: ドラクエ風 — 1吹き出しずつ・文字送り。送り中の入力は全文表示、完了後に次へ。

const _IntroLoreContent := preload("res://scripts/intro/IntroLoreContent.gd")
const _IntroUiAssets := preload("res://scripts/intro/IntroUiAssets.gd")
const NEXT_SCENE: String = "res://scenes/roster/StarterPickScene.tscn"

## 1文字あたりの表示間隔（秒）。
const CHAR_INTERVAL_SEC: float = 0.045

var _line_idx: int = 0
var _bubble: Label
var _next_btn: Button
var _full_line: String = ""
var _revealed_chars: int = 0
var _typing: bool = false
var _char_timer: float = 0.0


func _ready() -> void:
	AudioManager.play_bgm("introduction")
	_build_ui()
	_start_line()


func _process(delta: float) -> void:
	if not _typing:
		return
	_char_timer += delta
	while _typing and _char_timer >= CHAR_INTERVAL_SEC:
		_char_timer -= CHAR_INTERVAL_SEC
		_revealed_chars += 1
		if _revealed_chars >= _full_line.length():
			_finish_typing()
		else:
			_bubble.visible_characters = _revealed_chars


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_IntroUiAssets.add_full_bg(self, _IntroUiAssets.BG_NAME, Color(0.05, 0.06, 0.09, 1.0))

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 16)
	margin.add_child(root)

	var name_lbl := Label.new()
	name_lbl.text = "記録官 ニーナ"
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_display(name_lbl, UiTypography.SIZE_DISPLAY_TITLE, UiTypography.COLOR_GOLD)
	root.add_child(name_lbl)

	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 16)
	root.add_child(row)

	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(280, 400)
	portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.texture = _IntroUiAssets.load_tex(_IntroUiAssets.NINA_PORTRAIT)
	row.add_child(portrait)

	var bubble_col := VBoxContainer.new()
	bubble_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bubble_col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bubble_col.add_theme_constant_override("separation", 12)
	row.add_child(bubble_col)

	var bubble_spacer := Control.new()
	bubble_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bubble_spacer.size_flags_stretch_ratio = 0.35
	bubble_col.add_child(bubble_spacer)

	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.11, 0.16, 0.94)
	sb.set_border_width_all(2)
	sb.border_color = Color(0.62, 0.52, 0.35)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", sb)
	bubble_col.add_child(panel)

	_bubble = Label.new()
	_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble.custom_minimum_size = Vector2(0, 140)
	_bubble.visible_characters = 0
	UiTypography.apply_body(_bubble, 22)
	panel.add_child(_bubble)

	var bubble_spacer2 := Control.new()
	bubble_spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bubble_spacer2.size_flags_stretch_ratio = 0.65
	bubble_col.add_child(bubble_spacer2)

	_next_btn = Button.new()
	_next_btn.custom_minimum_size = Vector2(0, 52)
	UiTypography.apply_button(_next_btn)
	_next_btn.pressed.connect(_on_next)
	root.add_child(_next_btn)


func _start_line() -> void:
	var lines: Array[String] = _IntroLoreContent.NINA_LINES
	if _line_idx < 0 or _line_idx >= lines.size():
		SceneRouter.change_scene(NEXT_SCENE)
		return
	_full_line = lines[_line_idx]
	_revealed_chars = 0
	_char_timer = 0.0
	_typing = true
	_bubble.text = _full_line
	_bubble.visible_characters = 0
	# 送り中は「▼」、完了後に次へ／隊員選択へ切替。
	_next_btn.text = "▼"


func _finish_typing() -> void:
	_typing = false
	_revealed_chars = _full_line.length()
	_bubble.visible_characters = -1
	var last: bool = _line_idx >= _IntroLoreContent.NINA_LINES.size() - 1
	_next_btn.text = "隊員を選ぶ" if last else "次へ"


func _on_next() -> void:
	if _typing:
		_finish_typing()
		return
	_line_idx += 1
	if _line_idx >= _IntroLoreContent.NINA_LINES.size():
		SceneRouter.change_scene(NEXT_SCENE)
		return
	_start_line()
