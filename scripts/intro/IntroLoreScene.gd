extends Control

## 世界観ナレーション（自動縦クロール・スキップ可）— P3-INTRO-001 / 002 / P3-INTRO-SCROLL-001。
## 案A polish: clip＋リスト移動で上→下クロール。上下フェード／緩急付き。
## 全文が1画面に収まる場合も、前後余白で必ずスクロール距離を確保する。
## 画面どこでもタッチで即加速。本文末尾が中央より上で「TAP」→タップで次へ。

const _IntroLoreContent := preload("res://scripts/intro/IntroLoreContent.gd")
const _IntroUiAssets := preload("res://scripts/intro/IntroUiAssets.gd")
const _SafeAreaHelper := preload("res://scripts/ui/SafeAreaHelper.gd")
const NEXT_SCENE: String = "res://scenes/intro/IntroNameScene.tscn"

## 自動クロール基準速度（px/秒）。
const CRAWL_SPEED_PX_PER_SEC: float = 50.0
const CRAWL_START_DELAY_SEC: float = 0.5
## 画面タッチ中の速度倍率（どこを押しても即加速）。
const CRAWL_BOOST_MULT: float = 4.0
const PANEL_DWELL_RADIUS_PX: float = 56.0
const PANEL_DWELL_SPEED_MULT: float = 0.42
const EASE_EDGE_PX: float = 80.0
const FADE_BAND_PX: float = 56.0
## 先頭／末尾に足す余白（viewport 高さ比）。これで必ずクロール距離が生まれる。
const LEAD_IN_VIEW_RATIO: float = 0.72
const LEAD_OUT_VIEW_RATIO: float = 0.85
## aspect=keep でも Home Indicator 近傍に沈まないよう Intro 専用の下余白下限。
const INTRO_MIN_BOTTOM_MARGIN: float = 48.0
const INTRO_BASE_TOP_MARGIN: float = 28.0
const INTRO_BASE_BOTTOM_MARGIN: float = 24.0
const TAP_PROMPT_TEXT: String = "TAP"

var _clip: Control
var _list: VBoxContainer
var _lead_in: Control
var _lead_out: Control
## 読みやすさ用の dwell 対象（全文を収めた単一パネル）。
var _panel_nodes: Array[Control] = []
var _lore_body_lbl: RichTextLabel
var _hint_lbl: Label
var _tap_prompt_lbl: Label
var _tap_catcher: ColorRect
var _crawl_active: bool = false
var _press_held: bool = false
var _crawl_boost: bool = false
var _reached_end: bool = false
var _advance_ready: bool = false
## TAP 表示時に押したままの指を離しても進まない（新しいタップが必要）。
var _suppress_release_advance: bool = false
var _scroll_pos: float = 0.0
var _layout_ready: bool = false
var _root_margin: MarginContainer
var _tap_pulse_tween: Tween


func _ready() -> void:
	AudioManager.play_bgm("introduction")
	_build_ui()
	_apply_safe_area_margins()
	# 初回フレーム前に仮幅を入れておく（遅延待ち中のレイアウト暴れ防止）。
	call_deferred("_prepare_crawl_layout")
	call_deferred("_apply_safe_area_margins")
	_start_crawl_after_delay()


func _input(event: InputEvent) -> void:
	## スキップ等の GUI より先に、画面全体のタッチで加速する（イベントは消費しない）。
	if _advance_ready or _reached_end:
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				_begin_press()
			else:
				_end_press()
	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		if st.pressed:
			_begin_press()
		else:
			_end_press()
	elif event is InputEventScreenDrag:
		_begin_press()


func _process(delta: float) -> void:
	if not _crawl_active or _reached_end or not _layout_ready:
		return
	if _clip == null or _list == null:
		return
	var max_v: float = _max_scroll()
	if max_v <= 1.0:
		# 余白調整後も距離が無いなら読み終わり扱い（固まるのを防ぐ）。
		_enable_tap_to_advance()
		return
	var speed: float = CRAWL_SPEED_PX_PER_SEC * _crawl_speed_mult(_scroll_pos, max_v)
	var next_v: float = _scroll_pos + speed * delta
	if next_v >= max_v:
		_set_scroll_pos(max_v)
		_enable_tap_to_advance()
		return
	_set_scroll_pos(next_v)
	## 本文末尾が画面中央より上に出たら TAP（スクロール終端より早く出ることがある）。
	if _is_last_line_above_center():
		_enable_tap_to_advance()


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
	var panel_wrap := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	## 半透明の単一パネルに全文をまとめる（段落ごとの枠は使わない）。
	sb.bg_color = Color(0.06, 0.07, 0.11, 0.48)
	sb.set_border_width_all(1)
	sb.border_color = Color(0.45, 0.40, 0.28, 0.45)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(18)
	panel_wrap.add_theme_stylebox_override("panel", sb)
	_list.add_child(panel_wrap)
	_panel_nodes.append(panel_wrap)

	_lore_body_lbl = RichTextLabel.new()
	_lore_body_lbl.bbcode_enabled = true
	_lore_body_lbl.fit_content = true
	_lore_body_lbl.scroll_active = false
	_lore_body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lore_body_lbl.custom_minimum_size = Vector2(0, 72)
	_lore_body_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_log_rich(_lore_body_lbl, 22, Color(0.92, 0.90, 0.84))
	_lore_body_lbl.text = "\n\n".join(_IntroLoreContent.PANELS)
	panel_wrap.add_child(_lore_body_lbl)

	_hint_lbl = Label.new()
	_hint_lbl.text = "画面をタッチで加速"
	_hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiTypography.apply_caption(_hint_lbl)
	_list.add_child(_hint_lbl)

	_lead_out = _make_spacer(120.0)
	_list.add_child(_lead_out)

	_add_fade_band(_clip, true)
	_add_fade_band(_clip, false)
	_build_tap_prompt()
	_advance_ready = false


func _build_tap_prompt() -> void:
	_tap_prompt_lbl = Label.new()
	_tap_prompt_lbl.text = TAP_PROMPT_TEXT
	_tap_prompt_lbl.visible = false
	_tap_prompt_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tap_prompt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tap_prompt_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	## 全文クロール完了後、画面中央に点滅表示。
	_tap_prompt_lbl.set_anchors_preset(Control.PRESET_CENTER)
	_tap_prompt_lbl.offset_left = -180.0
	_tap_prompt_lbl.offset_right = 180.0
	_tap_prompt_lbl.offset_top = -40.0
	_tap_prompt_lbl.offset_bottom = 40.0
	_tap_prompt_lbl.z_index = 8
	UiTypography.apply_display(_tap_prompt_lbl, 48, UiTypography.COLOR_GOLD)
	add_child(_tap_prompt_lbl)


func _apply_safe_area_margins() -> void:
	if _root_margin == null:
		return
	## Home Indicator 近傍で本文・ヒントが沈まないよう Intro 専用の下余白を確保する。
	## aspect=keep 時は SafeAreaHelper が inset=0 を返すため、モバイルでは下限を常時確保する。
	var top: float = INTRO_BASE_TOP_MARGIN + _SafeAreaHelper.top_inset()
	var bottom: float = INTRO_BASE_BOTTOM_MARGIN + _SafeAreaHelper.bottom_inset()
	if _needs_intro_bottom_guard():
		bottom = maxf(bottom, INTRO_MIN_BOTTOM_MARGIN)
	_root_margin.add_theme_constant_override("margin_top", int(ceil(top)))
	_root_margin.add_theme_constant_override("margin_bottom", int(ceil(bottom)))


func _needs_intro_bottom_guard() -> bool:
	var os_name: String = OS.get_name()
	if os_name == "iOS" or os_name == "Android":
		return true
	if ProjectSettings.has_setting(_SafeAreaHelper.SETTINGS_SIMULATE):
		return bool(ProjectSettings.get_setting(_SafeAreaHelper.SETTINGS_SIMULATE))
	return false


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
	if _lore_body_lbl != null:
		_lore_body_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var body_w: float = maxf(0.0, view_w - 36.0)
		_lore_body_lbl.custom_minimum_size = Vector2(body_w, 0.0)
		## fit_content 再計算のため幅確定後にテキストを載せ直す。
		var body_text: String = _lore_body_lbl.text
		_lore_body_lbl.text = body_text
	_list.custom_minimum_size = Vector2(view_w, 0.0)
	_list.size.x = view_w
	_list.reset_size()
	var content_h: float = maxf(_list.get_combined_minimum_size().y, _list.size.y)
	_list.size = Vector2(view_w, content_h)
	_list.position.x = 0.0


func _on_clip_gui_input(event: InputEvent) -> void:
	## クリップ内ドラッグは手動スクロール＋加速。押下自体は `_input` でも拾う。
	if event is InputEventScreenDrag:
		_begin_press()
		_set_scroll_pos(_scroll_pos - float(event.relative.y))
		if _is_last_line_above_center():
			_enable_tap_to_advance()
	elif event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		if (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_begin_press()
			_set_scroll_pos(_scroll_pos - float(motion.relative.y))
			if _is_last_line_above_center():
				_enable_tap_to_advance()


func _begin_press() -> void:
	if _reached_end or _advance_ready:
		return
	_press_held = true
	## どこを触っても即加速。
	_crawl_boost = true


func _end_press() -> void:
	_press_held = false
	_crawl_boost = false


## 本文ブロック下端（＝最終行付近）が画面中央より上か。
func _is_last_line_above_center() -> bool:
	if _lore_body_lbl == null or not is_instance_valid(_lore_body_lbl):
		return false
	if not _layout_ready:
		return false
	var body_rect: Rect2 = _lore_body_lbl.get_global_rect()
	if body_rect.size.y <= 1.0:
		return false
	var last_line_bottom: float = body_rect.position.y + body_rect.size.y
	var mid_y: float = get_viewport_rect().get_center().y
	return last_line_bottom < mid_y


func _enable_tap_to_advance() -> void:
	if _reached_end:
		return
	_reached_end = true
	_crawl_active = false
	## 加速タッチのまま TAP 条件に達した場合、その release では進まない。
	_suppress_release_advance = _press_held
	_end_press()
	_advance_ready = true
	if _hint_lbl != null:
		_hint_lbl.visible = false
	_show_tap_prompt()


func _show_tap_prompt() -> void:
	if _tap_prompt_lbl == null:
		return
	_tap_prompt_lbl.visible = true
	_tap_prompt_lbl.modulate = Color(1, 1, 1, 1)
	_ensure_tap_catcher()
	if _tap_pulse_tween != null and _tap_pulse_tween.is_valid():
		_tap_pulse_tween.kill()
	_tap_pulse_tween = create_tween()
	_tap_pulse_tween.set_loops()
	_tap_pulse_tween.tween_property(_tap_prompt_lbl, "modulate:a", 0.35, 0.55)
	_tap_pulse_tween.tween_property(_tap_prompt_lbl, "modulate:a", 1.0, 0.55)


func _ensure_tap_catcher() -> void:
	if _tap_catcher != null and is_instance_valid(_tap_catcher):
		_tap_catcher.visible = true
		return
	_tap_catcher = ColorRect.new()
	_tap_catcher.name = "TapCatcher"
	_tap_catcher.color = Color(0, 0, 0, 0)
	_tap_catcher.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tap_catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	_tap_catcher.z_index = 7
	_tap_catcher.gui_input.connect(_on_tap_catcher_gui_input)
	add_child(_tap_catcher)
	## TAP 文言はキャッチより前面。
	if _tap_prompt_lbl != null:
		move_child(_tap_prompt_lbl, get_child_count() - 1)


func _on_tap_catcher_gui_input(event: InputEvent) -> void:
	if not _advance_ready or not _reached_end:
		return
	var pressed_now: bool = false
	var released_now: bool = false
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event
		if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT:
			pressed_now = mb.pressed
			released_now = not mb.pressed
	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		pressed_now = st.pressed
		released_now = not st.pressed
	## TAP 表示時に押したままの指は、離すだけで消費（進まない）。
	if released_now and _suppress_release_advance:
		_suppress_release_advance = false
		return
	if pressed_now and not _suppress_release_advance:
		_go_next()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_apply_safe_area_margins()
		if _layout_ready:
			_prepare_crawl_layout()
			var max_v: float = _max_scroll()
			if max_v > 0.0:
				_set_scroll_pos(minf(_scroll_pos, max_v))
			if not _reached_end and _is_last_line_above_center():
				_enable_tap_to_advance()


func _go_next() -> void:
	_crawl_active = false
	_end_press()
	if _tap_pulse_tween != null and _tap_pulse_tween.is_valid():
		_tap_pulse_tween.kill()
	SceneRouter.change_scene(NEXT_SCENE)
