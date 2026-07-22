class_name StarterJoinOverlay
extends CanvasLayer

## 拠点でのスターター加入（セリフ → ガチャ入手と同型リビール）。

const _GachaRevealPresenter := preload("res://scripts/gacha/GachaRevealPresenter.gd")
const _ChrIdlePortraitView := preload("res://scripts/ui/ChrIdlePortraitView.gd")
const _StarterJoinQuotes := preload("res://scripts/roster/StarterJoinQuotes.gd")

signal dismissed(adventurer_id: String)

const REVEAL_IDLE_PX: float = 220.0
const REVEAL_PANEL_HALF_W: float = 300.0
const REVEAL_PANEL_HALF_H: float = 420.0

enum Phase { DIALOGUE, REVEAL, DONE }

var _adventurer_id: String = ""
var _display_name: String = ""
var _job_id: String = ""
var _phase: int = Phase.DIALOGUE
var _reveal_can_dismiss: bool = false

var _dim: ColorRect
var _dialogue_root: Control
var _dialogue_panel: PanelContainer
var _dialogue_name: Label
var _dialogue_line: Label
var _dialogue_hint: Label
var _dialogue_portrait: TextureRect

var _reveal_root: Control
var _invite_glow: TextureRect
var _reveal_panel: PanelContainer
var _invite_art: TextureRect
var _flash_icon: TextureRect
var _portrait_frame: PanelContainer
var _portrait_icon: TextureRect
var _reveal_idle: Control
var _label_banner: Label
var _label_reveal_name: Label
var _label_quote: Label
var _label_reveal_sub: Label
var _label_tap_hint: Label
var _confetti_host: Control
var _reveal_presenter: RefCounted


func _ready() -> void:
	layer = 85
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()


func present(adventurer_id: String) -> void:
	_adventurer_id = adventurer_id.strip_edges()
	var def: Variant = GameState.find_base_roster_def(_adventurer_id)
	if def is Dictionary:
		_display_name = str(def.get("name", _adventurer_id))
		_job_id = str(def.get("job", ""))
	else:
		_display_name = _adventurer_id
		_job_id = ""
	_phase = Phase.DIALOGUE
	_reveal_can_dismiss = false
	_refresh_dialogue()
	_dialogue_root.visible = true
	_reveal_root.visible = false
	visible = true
	AudioManager.play_sfx("ui_confirm", 1.0, 0.0)


func _build() -> void:
	_dim = ColorRect.new()
	_dim.name = "Dim"
	_dim.color = Color(0.02, 0.03, 0.06, 0.78)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(_on_overlay_input)
	add_child(_dim)

	_build_dialogue()
	_build_reveal()
	visible = false


func _build_dialogue() -> void:
	_dialogue_root = Control.new()
	_dialogue_root.name = "DialogueRoot"
	_dialogue_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialogue_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dialogue_root)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue_root.add_child(center)

	_dialogue_panel = PanelContainer.new()
	_dialogue_panel.custom_minimum_size = Vector2(520, 280)
	_dialogue_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue_panel.add_theme_stylebox_override(
		"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_CARD_ACTIVE)
	)
	center.add_child(_dialogue_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue_panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(row)

	_dialogue_portrait = TextureRect.new()
	_dialogue_portrait.custom_minimum_size = Vector2(96, 96)
	_dialogue_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dialogue_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_dialogue_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_dialogue_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_dialogue_portrait)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 10)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(col)

	_dialogue_name = Label.new()
	_dialogue_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_dialogue_name)

	_dialogue_line = Label.new()
	_dialogue_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_line.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_dialogue_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_dialogue_line)

	_dialogue_hint = Label.new()
	_dialogue_hint.text = "タップで続ける"
	_dialogue_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_dialogue_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_dialogue_hint)


func _build_reveal() -> void:
	_reveal_root = Control.new()
	_reveal_root.name = "RevealRoot"
	_reveal_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reveal_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reveal_root.visible = false
	add_child(_reveal_root)

	_invite_glow = TextureRect.new()
	_invite_glow.name = "InviteGlow"
	_invite_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_invite_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_invite_glow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_invite_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_invite_glow.texture = GachaUiTokens.load_tex(GachaUiTokens.INVITE_GLOW)
	_invite_glow.visible = false
	_reveal_root.add_child(_invite_glow)

	_confetti_host = Control.new()
	_confetti_host.name = "ConfettiHost"
	_confetti_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confetti_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_confetti_host.z_index = 2
	_reveal_root.add_child(_confetti_host)

	_reveal_panel = PanelContainer.new()
	_reveal_panel.name = "RevealPanel"
	_reveal_panel.set_anchors_preset(Control.PRESET_CENTER)
	_reveal_panel.offset_left = -REVEAL_PANEL_HALF_W
	_reveal_panel.offset_right = REVEAL_PANEL_HALF_W
	_reveal_panel.offset_top = -REVEAL_PANEL_HALF_H
	_reveal_panel.offset_bottom = REVEAL_PANEL_HALF_H
	_reveal_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_reveal_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_reveal_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reveal_panel.add_theme_stylebox_override("panel", GachaUiTokens.reveal_frame_style())
	_reveal_root.add_child(_reveal_panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 12)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_reveal_panel.add_child(vbox)

	_invite_art = TextureRect.new()
	_invite_art.custom_minimum_size = Vector2(360, 250)
	_invite_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_invite_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_invite_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_invite_art)

	_flash_icon = TextureRect.new()
	_flash_icon.custom_minimum_size = Vector2(48, 48)
	_flash_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_flash_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_flash_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_icon.visible = false
	var token_tex: Texture2D = GachaUiTokens.token_icon()
	if token_tex != null:
		_flash_icon.texture = token_tex
	vbox.add_child(_flash_icon)

	_portrait_frame = PanelContainer.new()
	_portrait_frame.custom_minimum_size = Vector2(REVEAL_IDLE_PX + 24.0, REVEAL_IDLE_PX + 24.0)
	_portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_frame.visible = false
	vbox.add_child(_portrait_frame)

	_portrait_icon = TextureRect.new()
	_portrait_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_frame.add_child(_portrait_icon)

	_reveal_idle = _ChrIdlePortraitView.new()
	_reveal_idle.name = "RevealIdle"
	_reveal_idle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reveal_idle.offset_left = 8.0
	_reveal_idle.offset_top = 8.0
	_reveal_idle.offset_right = -8.0
	_reveal_idle.offset_bottom = -8.0
	if _reveal_idle.has_method("set_portrait_size"):
		_reveal_idle.call("set_portrait_size", REVEAL_IDLE_PX)
	_reveal_idle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_frame.add_child(_reveal_idle)

	_label_banner = Label.new()
	_label_banner.visible = false
	_label_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_label_banner)

	_label_reveal_name = Label.new()
	_label_reveal_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_reveal_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label_reveal_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_label_reveal_name)

	_label_quote = Label.new()
	_label_quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label_quote.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_label_quote)

	_label_reveal_sub = Label.new()
	_label_reveal_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_reveal_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_label_reveal_sub)

	_label_tap_hint = Label.new()
	_label_tap_hint.text = "タップで閉じる"
	_label_tap_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_tap_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(_label_tap_hint)

	UiTypography.apply_display(_label_reveal_name, UiTypography.SIZE_BODY, UiTypography.COLOR_BODY)
	UiTypography.apply_display(_label_quote, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	UiTypography.apply_body(_label_reveal_sub, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_SUB)
	UiTypography.apply_caption(_label_tap_hint, UiTypography.COLOR_MUTED)

	_reveal_presenter = _GachaRevealPresenter.new()
	_reveal_presenter.bind(
		self,
		_dim,
		_reveal_panel,
		_invite_glow,
		_invite_art,
		_flash_icon,
		_portrait_frame,
		[_label_banner, _label_reveal_name, _label_quote, _label_reveal_sub, _label_tap_hint],
		GachaUiTokens.load_tex(GachaUiTokens.INVITE_SEALED),
		GachaUiTokens.load_tex(GachaUiTokens.INVITE_SEALED_STAR2),
		GachaUiTokens.load_tex(GachaUiTokens.INVITE_OPENING)
	)


func _refresh_dialogue() -> void:
	_dialogue_name.text = _display_name
	UiTypography.apply_display(_dialogue_name, UiTypography.SIZE_BODY, UiTypography.COLOR_GOLD)
	_dialogue_line.text = "「%s」" % _StarterJoinQuotes.line_for(_adventurer_id)
	UiTypography.apply_body(_dialogue_line, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_BODY)
	UiTypography.apply_caption(_dialogue_hint, UiTypography.COLOR_MUTED)
	var tex: Texture2D = IconPaths.get_icon_texture(_adventurer_id, "chr")
	if tex == null and not _job_id.is_empty():
		tex = IconPaths.get_icon_texture(_job_id, "chr")
	_dialogue_portrait.texture = tex


func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_on_tap()
	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		if st.pressed:
			_on_tap()


func _on_tap() -> void:
	match _phase:
		Phase.DIALOGUE:
			_begin_reveal()
		Phase.REVEAL:
			if not _reveal_can_dismiss:
				if _reveal_presenter != null and _reveal_presenter.has_method("request_skip"):
					_reveal_presenter.call("request_skip")
				return
			_close()
		_:
			_close()


func _begin_reveal() -> void:
	_phase = Phase.REVEAL
	_dialogue_root.visible = false
	_reveal_root.visible = true
	_reveal_can_dismiss = false

	var member: Resource = GameState.commit_pending_starter_recruit()
	if member == null and not _adventurer_id.is_empty():
		member = GameState.unlock_starter_adventurer(_adventurer_id)
	if member != null:
		_display_name = str(member.display_name)
		_job_id = str(member.job_id)

	_label_banner.visible = false
	_label_banner.text = ""
	_label_reveal_sub.text = "ロスターに追加されました"
	_label_reveal_name.text = "%s\n%s  %s" % [
		_display_name,
		RosterUiHelper.stars_text(Adventurer.STARTER_RARITY),
		_job_label(),
	]
	var quote: String = _StarterJoinQuotes.line_for(_adventurer_id)
	_label_quote.text = "「%s」" % quote
	_label_quote.visible = true
	if _reveal_idle != null and member != null and _reveal_idle.has_method("set_from_member"):
		_reveal_idle.call("set_from_member", member)
	elif _portrait_icon != null:
		_portrait_icon.texture = IconPaths.get_icon_texture(_adventurer_id, "chr")

	SaveManager.save_game()
	if _reveal_presenter != null and _reveal_presenter.has_method("play"):
		_reveal_presenter.call(
			"play",
			Adventurer.STARTER_RARITY,
			Callable(self, "_on_reveal_done"),
			Callable()
		)
	else:
		_on_reveal_done()


func _job_label() -> String:
	var job: Resource = DataRegistry.get_job_data(_job_id)
	if job != null and "display_name" in job:
		return str(job.display_name)
	return _job_id


func _on_reveal_done() -> void:
	_reveal_can_dismiss = true
	_label_tap_hint.visible = true
	_spawn_confetti(48)
	AudioManager.play_sfx("level_up", 1.0, 0.0)


func _spawn_confetti(piece_count: int) -> void:
	if _confetti_host == null:
		return
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


func _close() -> void:
	AudioManager.play_sfx("ui_confirm")
	var aid: String = _adventurer_id
	dismissed.emit(aid)
	queue_free()


static func show_on(parent: Node, adventurer_id: String) -> CanvasLayer:
	var overlay := new()
	overlay.name = "StarterJoinOverlay"
	parent.add_child(overlay)
	overlay.present(adventurer_id)
	return overlay
