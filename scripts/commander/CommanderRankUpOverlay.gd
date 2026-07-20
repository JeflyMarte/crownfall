class_name CommanderRankUpOverlay
extends CanvasLayer

## 拠点ホームでの調査許可等級アップ演出（P3-CMD-RANKUP-001）。

const _CommanderProfile := preload("res://scripts/commander/CommanderProfile.gd")
const _CommanderUiTokens := preload("res://scripts/commander/CommanderUiTokens.gd")

signal dismissed(rank_code: String)

var _rank_code: String = ""
var _dim: ColorRect
var _confetti_host: Control
var _panel: PanelContainer
var _title_label: Label
var _subtitle_label: Label
var _icon: TextureRect
var _hint_label: Label
var _tween: Tween


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func present(rank_code: String) -> void:
	_rank_code = rank_code.strip_edges().to_upper()
	if _CommanderProfile.RANK_ORDER.find(_rank_code) < 0:
		_rank_code = _CommanderProfile.current_rank()
	_refresh_copy()
	visible = true
	_play_intro()
	_spawn_confetti(72)
	## hub BGM 開始直後でも確実に聞こえるよう1フレーム遅延。音源は level_up と同一。
	call_deferred("_play_rank_up_sfx")


func _play_rank_up_sfx() -> void:
	AudioManager.play_sfx("rank_up", 1.0, 0.0)


func _build() -> void:
	_dim = ColorRect.new()
	_dim.name = "Dim"
	_dim.color = Color(0.02, 0.03, 0.06, 0.72)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(_on_dim_gui_input)
	add_child(_dim)

	_confetti_host = Control.new()
	_confetti_host.name = "ConfettiHost"
	_confetti_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confetti_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_confetti_host)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	_panel.name = "Panel"
	_panel.custom_minimum_size = Vector2(320, 220)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD_ACTIVE)
	)
	center.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(vbox)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 24)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(margin)

	var inner := VBoxContainer.new()
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	inner.add_theme_constant_override("separation", 10)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(inner)

	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(72, 72)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(_icon)

	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(_title_label)

	_subtitle_label = Label.new()
	_subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(_subtitle_label)

	_hint_label = Label.new()
	_hint_label.text = "タップして閉じる"
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(_hint_label)

	visible = false


func _refresh_copy() -> void:
	_title_label.text = "%s級 ランクアップ！！" % _rank_code
	UiTypography.apply_display(
		_title_label, 40, Color(1.0, 0.92, 0.38), UiTypography.OUTLINE_STRONG
	)
	_subtitle_label.text = str(_CommanderProfile.RANK_SUBTITLES.get(_rank_code, ""))
	UiTypography.apply_body(_subtitle_label, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	UiTypography.apply_caption(_hint_label, UiTypography.COLOR_SUB)
	_icon.texture = _CommanderUiTokens.rank_icon(_rank_code)


func _play_intro() -> void:
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.55, 0.55)
	_panel.pivot_offset = _panel.custom_minimum_size * 0.5
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_panel, "modulate:a", 1.0, 0.18)
	_tween.parallel().tween_property(_panel, "scale", Vector2(1.1, 1.1), 0.28).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	_tween.chain().tween_property(_panel, "scale", Vector2.ONE, 0.1)


func _spawn_confetti(piece_count: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var area: Rect2 = _confetti_host.get_viewport_rect()
	var width: float = maxf(area.size.x, 1.0)
	var height: float = maxf(area.size.y, 1.0)
	for _i: int in piece_count:
		var piece := ColorRect.new()
		piece.size = Vector2(rng.randf_range(5.0, 12.0), rng.randf_range(8.0, 18.0))
		piece.color = Color.from_hsv(rng.randf(), rng.randf_range(0.7, 1.0), 1.0, 0.95)
		piece.rotation = rng.randf_range(-0.9, 0.9)
		piece.position = Vector2(
			rng.randf_range(0.0, width),
			rng.randf_range(-40.0, height * 0.28)
		)
		piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
		piece.z_index = 2
		_confetti_host.add_child(piece)
		var drift_x: float = rng.randf_range(-140.0, 140.0)
		var fall_y: float = height + rng.randf_range(30.0, 90.0)
		var duration: float = rng.randf_range(1.1, 2.4)
		var tw: Tween = create_tween()
		tw.set_parallel(true)
		tw.tween_property(piece, "position:y", fall_y, duration).set_trans(Tween.TRANS_QUAD).set_ease(
			Tween.EASE_IN
		)
		tw.tween_property(piece, "position:x", piece.position.x + drift_x, duration)
		tw.tween_property(piece, "rotation", piece.rotation + rng.randf_range(-2.8, 2.8), duration)
		tw.tween_property(piece, "modulate:a", 0.0, 0.45).set_delay(maxf(0.0, duration - 0.45))
		tw.chain().tween_callback(piece.queue_free)


func _on_dim_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_close()
	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		if st.pressed:
			_close()


func _close() -> void:
	AudioManager.play_sfx("ui_confirm")
	var code: String = _rank_code
	_CommanderProfile.acknowledge_rank(code)
	SaveManager.save_game()
	dismissed.emit(code)
	queue_free()


static func show_on(parent: Node, rank_code: String) -> CanvasLayer:
	var overlay := new()
	overlay.name = "CommanderRankUpOverlay"
	parent.add_child(overlay)
	overlay.present(rank_code)
	return overlay
