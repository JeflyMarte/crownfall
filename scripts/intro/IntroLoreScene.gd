extends Control

## 世界観ナレーション（自動縦クロール・スキップ可）— P3-INTRO-001 / 002 / P3-INTRO-SCROLL-001。
## 案A polish: clip＋リスト移動で上→下クロール。上下フェード／緩急付き。
## 全文が1画面に収まる場合も、前後余白で必ずスクロール距離を確保する。

const _IntroLoreContent := preload("res://scripts/intro/IntroLoreContent.gd")
const _IntroUiAssets := preload("res://scripts/intro/IntroUiAssets.gd")
const _SafeAreaHelper := preload("res://scripts/ui/SafeAreaHelper.gd")
const NEXT_SCENE: String = "res://scenes/intro/IntroNameScene.tscn"

## 自動クロール基準速度（px/秒）。
const CRAWL_SPEED_PX_PER_SEC: float = 50.0
const CRAWL_START_DELAY_SEC: float = 0.5
const CRAWL_BOOST_MULT: float = 2.5
const PANEL_DWELL_RADIUS_PX: float = 56.0
const PANEL_DWELL_SPEED_MULT: float = 0.42
const EASE_EDGE_PX: float = 80.0
const FADE_BAND_PX: float = 56.0
## 先頭／末尾に足す余白（viewport 高さ比）。これで必ずクロール距離が生まれる。
const LEAD_IN_VIEW_RATIO: float = 0.72
const LEAD_OUT_VIEW_RATIO: float = 0.85

var _clip: Control
var _list: VBoxContainer
var _lead_in: Control
var _lead_out: Control
var _panel_nodes: Array[Control] = []
var _continue_btn: Button
var _hint_lbl: Label
var _crawl_active: bool = false
var _crawl_boost: bool = false
var _reached_end: bool = false
var _scroll_pos: float = 0.0
var _layout_ready: bool = false
var _root_margin: MarginContainer


func _ready() -> void:
	_build_ui()
	_apply_safe_area_margins()
	# 初回フレーム前に仮幅を入れておく（遅延待ち中のレイアウト暴れ防止）。
	call_deferred("_prepare_crawl_layout")
	call_deferred("_apply_safe_area_margins")
	_start_crawl_after_delay()


func _process(delta: float) -> void:
	if not _crawl_active or _reached_end or not _layout_ready:
		return
	if _clip == null or _list == null:
		return
	var max_v: float = _max_scroll()
	if max_v <= 1.0:
		# 余白調整後も距離が無いなら読み終わり扱い（固まるのを防ぐ）。
		_on_reached_end()
		return
	var speed: float = CRAWL_SPEED_PX_PER_SEC * _crawl_speed_mult(_scroll_pos, max_v)
	var next_v: float = _scroll_pos + speed * delta
	if next_v >= max_v:
		_set_scroll_pos(max_v)
		_on_reached_end()
	else:
		_set_scroll_pos(next_v)


func _max_scroll() -> float:
	if _clip == null or _list == null:
		return 0.0
	var content_h: float = maxf(_list.size.y, _list.get_combined_minimum_size().y)
	var view_h: float = _clip.size.y
	if view_h <= 1.0:
		return 0.0
	return maxf(0.0, content_h - view_h)


func _set_scroll_pos(value: float) -> void:
	_scroll_pos = maxf(0.0, value)
	if _list != null:
		_list.position = Vector2(0.0, -_scroll_pos)


func _crawl_speed_mult(scroll_y: float, max_v: float) -> float:
	if _crawl_boost:
		return CRAWL_BOOST_MULT
	var mult: float = 1.0
	if scroll_y < EASE_EDGE_PX:
		mult *= lerpf(0.35, 1.0, clampf(scroll_y / EASE_EDGE_PX, 0.0, 1.0))
	var dist_end: float = max_v - scroll_y
	if dist_end < EASE_EDGE_PX:
		mult *= lerpf(0.35, 1.0, clampf(dist_end / EASE_EDGE_PX, 0.0, 1.0))
	var view_center: float = scroll_y + float(_clip.size.y) * 0.42
	for panel: Control in _panel_nodes:
		if panel == null or not is_instance_valid(panel):
			continue
		var panel_center: float = panel.position.y + panel.size.y * 0.5
		var dist: float = absf(view_center - panel_center)
		if dist <= PANEL_DWELL_RADIUS_PX:
			var t: float = 1.0 - (dist / PANEL_DWELL_RADIUS_PX)
			mult *= lerpf(1.0, PANEL_DWELL_SPEED_MULT, t)
			break
	return maxf(0.2, mult)


func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_IntroUiAssets.add_full_bg(self, _IntroUiAssets.BG_LORE, Color(0.04, 0.05, 0.08, 1.0))

	_root_margin = MarginContainer.new()
	_root_margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root_margin.add_theme_constant_override("margin_left", 28)
	_root_margin.add_theme_constant_override("margin_right", 28)
	_root_margin.add_theme_constant_override("margin_top", 28)
	_root_margin.add_theme_constant_override("margin_bottom", 24)
	add_child(_root_margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	_root_margin.add_child(root)

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

	_clip = Control.new()
	_clip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_clip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_clip.clip_contents = true
	_clip.custom_minimum_size = Vector2(0, 240)
	_clip.gui_input.connect(_on_clip_gui_input)
	root.add_child(_clip)

	_list = VBoxContainer.new()
	_list.position = Vector2.ZERO
	_list.add_theme_constant_override("separation", 28)
	# 幅確定前の一瞬表示（左半分レイアウト）を防ぐ。
	_list.visible = false
	_list.modulate = Color(1, 1, 1, 0)
	_clip.add_child(_list)

	_lead_in = _make_spacer(120.0)
	_list.add_child(_lead_in)

	_panel_nodes.clear()
	for i: int in _IntroLoreContent.PANELS.size():
		var panel_wrap := PanelContainer.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.06, 0.07, 0.11, 0.82)
		sb.set_border_width_all(1)
		sb.border_color = Color(0.45, 0.40, 0.28, 0.7)
		sb.set_corner_radius_all(8)
		sb.set_content_margin_all(16)
		panel_wrap.add_theme_stylebox_override("panel", sb)
		_list.add_child(panel_wrap)
		_panel_nodes.append(panel_wrap)

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
	_list.add_child(_hint_lbl)

	_lead_out = _make_spacer(120.0)
	_list.add_child(_lead_out)

	_add_fade_band(_clip, true)
	_add_fade_band(_clip, false)

	_continue_btn = Button.new()
	_continue_btn.text = "続ける"
	_continue_btn.custom_minimum_size = Vector2(0, 56)
	_continue_btn.disabled = true
	_continue_btn.modulate = Color(1, 1, 1, 0.45)
	_continue_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	_continue_btn.focus_mode = Control.FOCUS_ALL
	UiTypography.apply_button(_continue_btn)
	_continue_btn.pressed.connect(_go_next)
	root.add_child(_continue_btn)


func _apply_safe_area_margins() -> void:
	if _root_margin == null:
		return
	## iPhone Home Indicator 下に「続ける」が沈みタップ不能になるのを防ぐ。
	var top: float = 28.0 + _SafeAreaHelper.top_inset()
	var bottom: float = 24.0 + _SafeAreaHelper.bottom_inset()
	_root_margin.add_theme_constant_override("margin_top", int(ceil(top)))
	_root_margin.add_theme_constant_override("margin_bottom", int(ceil(bottom)))


func _make_spacer(height_px: float) -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, height_px)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer


func _add_fade_band(host: Control, top: bool) -> void:
	var band := TextureRect.new()
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	band.stretch_mode = TextureRect.STRETCH_SCALE
	band.texture = _make_fade_texture(top)
	band.z_index = 2
	if top:
		band.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		band.offset_bottom = FADE_BAND_PX
	else:
		band.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		band.offset_top = -FADE_BAND_PX
	host.add_child(band)


func _make_fade_texture(top: bool) -> GradientTexture2D:
	var grad := Gradient.new()
	if top:
		grad.colors = PackedColorArray([
			Color(0.04, 0.05, 0.08, 0.92),
			Color(0.04, 0.05, 0.08, 0.0),
		])
	else:
		grad.colors = PackedColorArray([
			Color(0.04, 0.05, 0.08, 0.0),
			Color(0.04, 0.05, 0.08, 0.92),
		])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.width = 8
	tex.height = int(FADE_BAND_PX)
	return tex


func _start_crawl_after_delay() -> void:
	await get_tree().create_timer(CRAWL_START_DELAY_SEC).timeout
	if not is_instance_valid(self):
		return
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(self):
		return
	_prepare_crawl_layout()
	await get_tree().process_frame
	if not is_instance_valid(self):
		return
	_prepare_crawl_layout()
	_set_scroll_pos(0.0)
	_reveal_list()
	_layout_ready = true
	_crawl_active = true


func _reveal_list() -> void:
	if _list == null:
		return
	_list.visible = true
	_list.modulate = Color(1, 1, 1, 1)


func _content_width() -> float:
	if _clip != null and _clip.size.x > 1.0:
		return _clip.size.x
	var vp_w: float = get_viewport_rect().size.x
	# Intro 左右マージン 28+28 を差し引いた仮幅。
	return maxf(100.0, vp_w - 56.0)


func _prepare_crawl_layout() -> void:
	if _clip == null or _list == null:
		return
	var view_h: float = maxf(240.0, _clip.size.y)
	var view_w: float = _content_width()
	if _lead_in != null:
		_lead_in.custom_minimum_size = Vector2(0, view_h * LEAD_IN_VIEW_RATIO)
	if _lead_out != null:
		_lead_out.custom_minimum_size = Vector2(0, view_h * LEAD_OUT_VIEW_RATIO)
	# 高さは潰さず、幅だけ確定して折返しを安定させる。
	for panel: Control in _panel_nodes:
		if panel == null:
			continue
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for child in panel.get_children():
			if child is Label:
				var lbl: Label = child as Label
				lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				lbl.custom_minimum_size = Vector2(maxf(0.0, view_w - 32.0), 72.0)
	_list.custom_minimum_size = Vector2(view_w, 0.0)
	_list.size.x = view_w
	_list.reset_size()
	var content_h: float = maxf(_list.get_combined_minimum_size().y, _list.size.y)
	_list.size = Vector2(view_w, content_h)
	_list.position.x = 0.0


func _on_clip_gui_input(event: InputEvent) -> void:
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
	elif event is InputEventScreenDrag:
		_crawl_boost = true
		_set_scroll_pos(_scroll_pos - float(event.relative.y))
		_check_manual_end()


func _check_manual_end() -> void:
	if _reached_end or not _layout_ready:
		return
	var max_v: float = _max_scroll()
	if max_v <= 1.0:
		return
	if _scroll_pos >= max_v - 2.0:
		_set_scroll_pos(max_v)
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
		_continue_btn.mouse_filter = Control.MOUSE_FILTER_STOP
		## 実機でヒット領域が潰れている場合に備え、明示的に前面へ。
		_continue_btn.z_index = 8
		_continue_btn.move_to_front()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_safe_area_margins()
		if _layout_ready:
			_prepare_crawl_layout()
			var max_v: float = _max_scroll()
			if max_v > 0.0:
				_set_scroll_pos(minf(_scroll_pos, max_v))


func _go_next() -> void:
	_crawl_active = false
	SceneRouter.change_scene(NEXT_SCENE)
