class_name StarterJoinOverlay
extends CanvasLayer

## 拠点でのスターター加入（モックショーケース → ガチャ同型リビール）。

const _GachaRevealPresenter := preload("res://scripts/gacha/GachaRevealPresenter.gd")
const _ChrIdlePortraitView := preload("res://scripts/ui/ChrIdlePortraitView.gd")
const _StarterJoinQuotes := preload("res://scripts/roster/StarterJoinQuotes.gd")
const _StarterJoinUiTokens := preload("res://scripts/roster/StarterJoinUiTokens.gd")

signal dismissed(adventurer_id: String)

const REVEAL_IDLE_PX: float = 220.0
const REVEAL_PANEL_HALF_W: float = 300.0
const REVEAL_PANEL_HALF_H: float = 420.0

enum Phase { SHOWCASE, REVEAL, DONE }

var _adventurer_id: String = ""
var _display_name: String = ""
var _job_id: String = ""
var _phase: int = Phase.SHOWCASE
var _reveal_can_dismiss: bool = false

var _dim: ColorRect
var _showcase_root: Control
var _title_banner: TextureRect
var _portrait_glow: TextureRect
var _portrait_icon: TextureRect
var _nameplate_host: Control
var _nameplate_bg: TextureRect
var _job_icon: TextureRect
var _name_label: Label
var _stars_label: Label
var _quote_host: Control
var _quote_bg: TextureRect
var _quote_label: Label
var _quote_tap_label: Label
var _showcase_tween: Tween

var _reveal_root: Control
var _invite_glow: TextureRect
var _reveal_panel: PanelContainer
var _invite_art: TextureRect
var _flash_icon: TextureRect
var _portrait_frame: PanelContainer
var _reveal_portrait_icon: TextureRect
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
	const _PetSystem := preload("res://scripts/pets/PetSystem.gd")
	if _PetSystem.is_pet_id(_adventurer_id):
		var pet_data: Resource = _PetSystem.get_pet_data(_adventurer_id)
		_display_name = str(pet_data.display_name) if pet_data != null else _adventurer_id
		_job_id = ""
	else:
		var def: Variant = GameState.find_base_roster_def(_adventurer_id)
		if def is Dictionary:
			_display_name = str(def.get("name", _adventurer_id))
			_job_id = str(def.get("job", ""))
		else:
			_display_name = _adventurer_id
			_job_id = ""
	_phase = Phase.SHOWCASE
	_reveal_can_dismiss = false
	_refresh_showcase()
	_showcase_root.visible = true
	_reveal_root.visible = false
	visible = true
	_play_showcase_intro()
	AudioManager.play_sfx("ui_confirm", 1.0, 0.0)


func _build() -> void:
	_dim = ColorRect.new()
	_dim.name = "Dim"
	_dim.color = Color(0.02, 0.03, 0.06, 0.82)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(_on_overlay_input)
	add_child(_dim)

	_build_showcase()
	_build_reveal()
	visible = false


func _build_showcase() -> void:
	_showcase_root = Control.new()
	_showcase_root.name = "ShowcaseRoot"
	_showcase_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_showcase_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_showcase_root)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_showcase_root.add_child(center)

	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 14)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(col)

	_title_banner = TextureRect.new()
	_title_banner.name = "TitleBanner"
	_title_banner.texture = _StarterJoinUiTokens.title_banner()
	_title_banner.custom_minimum_size = Vector2(_StarterJoinUiTokens.TITLE_WIDTH, 120.0)
	_title_banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_title_banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_title_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_title_banner)

	var portrait_host := Control.new()
	portrait_host.custom_minimum_size = Vector2(
		_StarterJoinUiTokens.PORTRAIT_PX + 40.0,
		_StarterJoinUiTokens.PORTRAIT_PX + 40.0
	)
	portrait_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(portrait_host)

	_portrait_glow = TextureRect.new()
	_portrait_glow.texture = _StarterJoinUiTokens.portrait_glow()
	## 顔より外側のオーラ用。中心の強い光が顔に重ならないよう少し拡大＋弱める。
	_portrait_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait_glow.offset_left = -28.0
	_portrait_glow.offset_top = -28.0
	_portrait_glow.offset_right = 28.0
	_portrait_glow.offset_bottom = 28.0
	_portrait_glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait_glow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait_glow.modulate = Color(1.0, 1.0, 1.0, 0.42)
	_portrait_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_host.add_child(_portrait_glow)

	## CHR アイコンの半透明ディザを通して Glow が顔に滲むのを防ぐ不透明板。
	var portrait_plate := ColorRect.new()
	portrait_plate.name = "PortraitPlate"
	portrait_plate.color = Color(0.04, 0.05, 0.08, 1.0)
	portrait_plate.set_anchors_preset(Control.PRESET_CENTER)
	portrait_plate.offset_left = -_StarterJoinUiTokens.PORTRAIT_PX * 0.5
	portrait_plate.offset_right = _StarterJoinUiTokens.PORTRAIT_PX * 0.5
	portrait_plate.offset_top = -_StarterJoinUiTokens.PORTRAIT_PX * 0.5
	portrait_plate.offset_bottom = _StarterJoinUiTokens.PORTRAIT_PX * 0.5
	portrait_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_host.add_child(portrait_plate)

	_portrait_icon = TextureRect.new()
	_portrait_icon.set_anchors_preset(Control.PRESET_CENTER)
	_portrait_icon.offset_left = -_StarterJoinUiTokens.PORTRAIT_PX * 0.5
	_portrait_icon.offset_right = _StarterJoinUiTokens.PORTRAIT_PX * 0.5
	_portrait_icon.offset_top = -_StarterJoinUiTokens.PORTRAIT_PX * 0.5
	_portrait_icon.offset_bottom = _StarterJoinUiTokens.PORTRAIT_PX * 0.5
	_portrait_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_host.add_child(_portrait_icon)

	_nameplate_host = Control.new()
	_nameplate_host.custom_minimum_size = Vector2(
		_StarterJoinUiTokens.NAMEPLATE_WIDTH,
		_StarterJoinUiTokens.NAMEPLATE_HEIGHT
	)
	_nameplate_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_nameplate_host)

	_nameplate_bg = TextureRect.new()
	_nameplate_bg.texture = _StarterJoinUiTokens.nameplate()
	_nameplate_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_nameplate_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_nameplate_bg.stretch_mode = TextureRect.STRETCH_SCALE
	_nameplate_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_nameplate_host.add_child(_nameplate_bg)

	var name_row := HBoxContainer.new()
	name_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	name_row.offset_left = 36.0
	name_row.offset_right = -36.0
	name_row.offset_top = 8.0
	name_row.offset_bottom = -8.0
	name_row.add_theme_constant_override("separation", 12)
	name_row.alignment = BoxContainer.ALIGNMENT_CENTER
	name_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_nameplate_host.add_child(name_row)

	_job_icon = TextureRect.new()
	_job_icon.custom_minimum_size = Vector2(
		_StarterJoinUiTokens.JOB_ICON_PX, _StarterJoinUiTokens.JOB_ICON_PX
	)
	_job_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_job_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_job_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_job_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_row.add_child(_job_icon)

	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.clip_text = false
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_row.add_child(_name_label)

	_stars_label = Label.new()
	_stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_stars_label.clip_text = false
	_stars_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_row.add_child(_stars_label)

	_quote_host = Control.new()
	_quote_host.custom_minimum_size = Vector2(
		_StarterJoinUiTokens.QUOTE_WIDTH,
		_StarterJoinUiTokens.QUOTE_HEIGHT
	)
	_quote_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_quote_host)

	## 枠内の空洞／半透明を黒で塞ぐ（テクスチャより背面）。
	var quote_fill := ColorRect.new()
	quote_fill.name = "QuoteFill"
	quote_fill.color = Color(0, 0, 0, 1)
	quote_fill.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	quote_fill.offset_left = 36.0
	quote_fill.offset_right = -36.0
	quote_fill.offset_top = 18.0
	quote_fill.offset_bottom = -18.0
	quote_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quote_host.add_child(quote_fill)

	_quote_bg = TextureRect.new()
	_quote_bg.texture = _StarterJoinUiTokens.quote_panel()
	_quote_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_quote_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	## 縦短枠に合わせて拡縮（焼込タップは消済み。文言は Label）。
	_quote_bg.stretch_mode = TextureRect.STRETCH_SCALE
	_quote_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quote_host.add_child(_quote_bg)

	_quote_label = Label.new()
	_quote_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_quote_label.offset_left = 40.0
	_quote_label.offset_right = -40.0
	_quote_label.offset_top = 20.0
	_quote_label.offset_bottom = -44.0
	_quote_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_quote_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_quote_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_quote_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quote_host.add_child(_quote_label)

	_quote_tap_label = Label.new()
	_quote_tap_label.text = "タップで続ける"
	_quote_tap_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_quote_tap_label.offset_top = -40.0
	_quote_tap_label.offset_bottom = -10.0
	_quote_tap_label.offset_left = 32.0
	_quote_tap_label.offset_right = -32.0
	_quote_tap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_quote_tap_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_quote_tap_label.clip_text = false
	_quote_tap_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	_quote_tap_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_quote_host.add_child(_quote_tap_label)


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
	## テーマ既定の半透明パネルがドット上に乗るのを防ぐ（GachaScene と同方針）。
	_portrait_frame.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	vbox.add_child(_portrait_frame)

	_reveal_portrait_icon = TextureRect.new()
	_reveal_portrait_icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reveal_portrait_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_reveal_portrait_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_reveal_portrait_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_frame.add_child(_reveal_portrait_icon)

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
	UiTypography.apply_display(_label_quote, UiTypography.SIZE_CAPTION, UiTypography.COLOR_GOLD)
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


func _refresh_showcase() -> void:
	var tex: Texture2D = IconPaths.get_icon_texture(_adventurer_id, "chr")
	if tex == null and not _job_id.is_empty():
		tex = IconPaths.get_icon_texture(_job_id, "chr")
	_portrait_icon.texture = tex
	_job_icon.texture = tex
	_name_label.text = _display_name
	const _PetSystem := preload("res://scripts/pets/PetSystem.gd")
	var star_n: int = Adventurer.STARTER_RARITY
	if _PetSystem.is_pet_id(_adventurer_id):
		var pet_data: Resource = _PetSystem.get_pet_data(_adventurer_id)
		star_n = clampi(int(pet_data.rarity) if pet_data != null else 1, 1, 5)
	_stars_label.text = RosterUiHelper.stars_text(star_n)
	_quote_label.text = "「%s」" % _StarterJoinQuotes.line_for(_adventurer_id)
	UiTypography.apply_display(_name_label, UiTypography.SIZE_DISPLAY, UiTypography.COLOR_GOLD)
	UiTypography.apply_display(_stars_label, UiTypography.SIZE_BODY, UiTypography.COLOR_GOLD)
	## 吹き出し下地が暗いので、本文色ではなく金で不透明表示。
	UiTypography.apply_display(_quote_label, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	if _quote_tap_label != null:
		UiTypography.apply_caption(_quote_tap_label, UiTypography.COLOR_GOLD)


func _play_showcase_intro() -> void:
	_showcase_root.modulate.a = 0.0
	_showcase_root.scale = Vector2(0.94, 0.94)
	_showcase_root.pivot_offset = _showcase_root.size * 0.5
	call_deferred("_sync_showcase_pivot")
	if _showcase_tween != null and _showcase_tween.is_valid():
		_showcase_tween.kill()
	_showcase_tween = create_tween()
	_showcase_tween.tween_property(_showcase_root, "modulate:a", 1.0, 0.2)
	_showcase_tween.parallel().tween_property(_showcase_root, "scale", Vector2.ONE, 0.28).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)


func _sync_showcase_pivot() -> void:
	if _showcase_root == null or not is_instance_valid(_showcase_root):
		return
	_showcase_root.pivot_offset = _showcase_root.size * 0.5


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
		Phase.SHOWCASE:
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
	_showcase_root.visible = false
	_reveal_root.visible = true
	_reveal_can_dismiss = false

	const _PetSystem := preload("res://scripts/pets/PetSystem.gd")
	var member: Resource = null
	var star_n: int = Adventurer.STARTER_RARITY
	var sub_line: String = "ロスターに追加されました"
	if _PetSystem.is_pet_id(_adventurer_id):
		member = _PetSystem.grant_starter_pet() if _adventurer_id == _PetSystem.STARTER_PET_ID else null
		if member == null:
			_PetSystem.unlock_pet(_adventurer_id, false)
			_PetSystem.set_active_pet_id(_adventurer_id)
			member = GameState.active_pet
		if member != null:
			_display_name = str(member.display_name)
		var pet_data: Resource = _PetSystem.get_pet_data(_adventurer_id)
		star_n = clampi(int(pet_data.rarity) if pet_data != null else 1, 1, 5)
		sub_line = "随伴オトモとして合流しました"
		_job_id = ""
	else:
		member = GameState.commit_pending_starter_recruit()
		if member == null and not _adventurer_id.is_empty():
			member = GameState.unlock_starter_adventurer(_adventurer_id)
		if member != null:
			_display_name = str(member.display_name)
			_job_id = str(member.job_id)

	_label_banner.visible = false
	_label_banner.text = ""
	_label_reveal_sub.text = sub_line
	var job_bit: String = _job_label()
	if job_bit.is_empty():
		_label_reveal_name.text = "%s\n%s" % [
			_display_name,
			RosterUiHelper.stars_text(star_n),
		]
	else:
		_label_reveal_name.text = "%s\n%s  %s" % [
			_display_name,
			RosterUiHelper.stars_text(star_n),
			job_bit,
		]
	var quote: String = _StarterJoinQuotes.reveal_line_for(_adventurer_id)
	_label_quote.text = "「%s」" % quote
	_label_quote.visible = true
	if _reveal_idle != null and member != null and _reveal_idle.has_method("set_from_member"):
		_reveal_idle.call("set_from_member", member)
	elif _reveal_portrait_icon != null:
		_reveal_portrait_icon.texture = IconPaths.get_icon_texture(_adventurer_id, "chr")

	SaveManager.save_game()
	if _reveal_presenter != null and _reveal_presenter.has_method("play"):
		_reveal_presenter.call(
			"play",
			star_n,
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
