extends Control

## 世界観ナレーション（自動縦クロール・スキップ可）— P3-INTRO-001 / 002 / P3-INTRO-SCROLL-001。
## 案A: 入場後に一定速度で上→下へ自動スクロール。タップ／ドラッグで加速。

const _IntroLoreContent := preload("res://scripts/intro/IntroLoreContent.gd")
const _IntroUiAssets := preload("res://scripts/intro/IntroUiAssets.gd")
const NEXT_SCENE: String = "res://scenes/intro/IntroNameScene.tscn"

## 自動クロール速度（px/秒）。目安合計 ~60 秒。
const CRAWL_SPEED_PX_PER_SEC: float = 50.0
## 入場後、自動開始までの待ち。
const CRAWL_START_DELAY_SEC: float = 0.5
## タップ／ドラッグ中の加速倍率。
const CRAWL_BOOST_MULT: float = 2.5

var _scroll: ScrollContainer
var _continue_btn: Button
var _hint_lbl: Label
var _crawl_active: bool = false
var _crawl_boost: bool = false
var _reached_end: bool = false


func _ready() -> void:
	_build_ui()
	_start_crawl_after_delay()


func _process(delta: float) -> void:
	if not _crawl_active or _reached_end or _scroll == null:
		return
	var bar: ScrollBar = _scroll.get_v_scroll_bar()
	if bar == null:
		return
	var max_v: float = maxf(0.0, bar.max_value - bar.page)
	if max_v <= 0.0:
		_on_reached_end()
		return
	var speed: float = CRAWL_SPEED_PX_PER_SEC
	if _crawl_boost:
		speed *= CRAWL_BOOST_MULT
	var next_v: float = float(_scroll.scroll_vertical) + speed * delta
	if next_v >= max_v:
		_scroll.scroll_vertical = int(ceil(max_v))
		_on_reached_end()
	else:
		_scroll.scroll_vertical = int(next_v)


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_IntroUiAssets.add_full_bg(self, _IntroUiAssets.BG_LORE, Color(0.04, 0.05, 0.08, 1.0))

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
	_scroll.gui_input.connect(_on_scroll_gui_input)
	root.add_child(_scroll)

	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 28)
	_scroll.add_child(list)

	for i: int in _IntroLoreContent.PANELS.size():
		var panel_wrap := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.06, 0.07, 0.11, 0.82)
		sb.set_border_width_all(1)
		sb.border_color = Color(0.45, 0.40, 0.28, 0.7)
		sb.set_corner_radius_all(8)
		sb.set_content_margin_all(16)
		panel_wrap.add_theme_stylebox_override("panel", sb)
		list.add_child(panel_wrap)

		var panel_lbl := Label.new()
		panel_lbl.text = _IntroLoreContent.PANELS[i]
		panel_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		panel_lbl.custom_minimum_size = Vector2(0, 72)
		UiTypography.apply_body(panel_lbl, 22, Color(0.92, 0.90, 0.84))
		panel_wrap.add_child(panel_lbl)

	_hint_lbl = Label.new()
	_hint_lbl.text = "物語が流れます（タッチで加速）"
	_hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_caption(_hint_lbl)
	list.add_child(_hint_lbl)

	_continue_btn = Button.new()
	_continue_btn.text = "続ける"
	_continue_btn.custom_minimum_size = Vector2(0, 52)
	_continue_btn.disabled = true
	_continue_btn.modulate = Color(1, 1, 1, 0.45)
	UiTypography.apply_button(_continue_btn)
	_continue_btn.pressed.connect(_go_next)
	root.add_child(_continue_btn)


func _start_crawl_after_delay() -> void:
	await get_tree().create_timer(CRAWL_START_DELAY_SEC).timeout
	if not is_instance_valid(self):
		return
	# レイアウト確定後にクロール開始（max_value が正しい値になる）。
	await get_tree().process_frame
	if not is_instance_valid(self):
		return
	_crawl_active = true


func _on_scroll_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT:
			_crawl_boost = mb.pressed
			if not mb.pressed:
				_check_manual_end()
	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event
		_crawl_boost = st.pressed
		if not st.pressed:
			_check_manual_end()
	elif event is InputEventMouseMotion and _crawl_boost:
		_check_manual_end()
	elif event is InputEventScreenDrag:
		_crawl_boost = true
		_check_manual_end()


func _check_manual_end() -> void:
	if _reached_end or _scroll == null:
		return
	var bar: ScrollBar = _scroll.get_v_scroll_bar()
	if bar == null:
		return
	var max_v: float = maxf(0.0, bar.max_value - bar.page)
	if max_v <= 0.0 or float(_scroll.scroll_vertical) >= max_v - 2.0:
		_on_reached_end()


func _on_reached_end() -> void:
	if _reached_end:
		return
	_reached_end = true
	_crawl_active = false
	_crawl_boost = false
	if _hint_lbl != null:
		_hint_lbl.text = "準備ができたら続けてください"
	if _continue_btn != null:
		_continue_btn.disabled = false
		_continue_btn.modulate = Color(1, 1, 1, 1)


func _go_next() -> void:
	_crawl_active = false
	SceneRouter.change_scene(NEXT_SCENE)
