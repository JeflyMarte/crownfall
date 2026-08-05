extends Control

## 特権強化画面 — 略奪／成長／戦力を設定音量と同型スライダーで割り振り。

const _CommanderPermitBoost := preload("res://scripts/commander/CommanderPermitBoost.gd")
const _CommanderUiTokens := preload("res://scripts/commander/CommanderUiTokens.gd")
const _RoomGuide := preload("res://scripts/ui/DungeonRouteGuideOverlay.gd")
const COMMANDER_SCENE: String = "res://scenes/commander/CommanderScene.tscn"

const COLOR_GOLD: Color = Color(0.86, 0.74, 0.45)
const COLOR_SUB: Color = Color(0.72, 0.69, 0.62)
const SECTION_GAP: int = 16
const BODY_SEP: int = 8
const INNER_PAD: int = 10
const HEADER_CONTENT_GAP: float = 24.0
const _META_BODY_BASE_TOP: StringName = &"_cf_body_base_top"

@onready var _label_title: Label = $Header/HeaderRow/LabelTitle
@onready var _btn_back: Button = $Header/HeaderRow/ButtonBack
@onready var _bg_texture: TextureRect = $BgTexture
@onready var _main_scroll: ScrollContainer = $MainScroll
@onready var _content_host: VBoxContainer = $MainScroll/MainVBox/ContentHost

var _points_label: Label = null
var _summary_label: Label = null
var _sliders: Dictionary = {}
var _value_labels: Dictionary = {}
var _bonus_labels: Dictionary = {}
var _updating_sliders: bool = false


func _ready() -> void:
	_CommanderPermitBoost.ensure_and_sync()
	if not _CommanderPermitBoost.is_ui_unlocked():
		call_deferred("_bounce_locked")
		return
	var bg_tex: Texture2D = _CommanderUiTokens.load_tex(_CommanderUiTokens.BG)
	if bg_tex != null and _bg_texture != null:
		_bg_texture.texture = bg_tex
	_label_title.text = _CommanderPermitBoost.DISPLAY_NAME
	UiTypography.apply_screen_title(_label_title)
	UiTypography.apply_button(_btn_back, false)
	_btn_back.pressed.connect(_on_back_pressed)
	_setup_room_guide_help()
	_content_host.add_theme_constant_override("separation", SECTION_GAP)
	_sync_main_scroll_below_header()
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.MYPAGE)
	ScrollTouchHelper.enable(_main_scroll)
	_rebuild_page()
	_configure_layout()
	call_deferred("_configure_layout")


func _setup_room_guide_help() -> void:
	var row: Control = $Header/HeaderRow as Control
	if row == null or row.get_node_or_null("HubRoomGuideHelpBtn") != null:
		return
	var btn: Button = _RoomGuide.attach_help_button(row, self, _RoomGuide.GUIDE_PERMIT, "？")
	if btn == null:
		return
	var back: Node = row.get_node_or_null("ButtonBack")
	if back != null:
		row.move_child(btn, back.get_index() + 1)
	btn.custom_minimum_size = Vector2(40, 40)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_configure_layout()


func _configure_layout() -> void:
	if _main_scroll == null:
		return
	_sync_main_scroll_below_header()
	var bottom: Control = $BottomNav as Control
	var nav_h: float = 12.0
	if bottom != null and bottom.visible:
		nav_h = maxf(NavUiTokens.BOTTOM_NAV_HEIGHT, bottom.size.y) + 8.0
	_main_scroll.offset_bottom = -nav_h


func _sync_main_scroll_below_header() -> void:
	var header: Control = $Header as Control
	if header == null or _main_scroll == null:
		return
	var top_inset: float = 0.0
	if SafeAreaHelper.should_apply_chrome():
		top_inset = SafeAreaHelper.top_inset()
	var header_bottom: float = header.offset_bottom
	if header.size.y > 1.0:
		header_bottom = maxf(header_bottom, header.offset_top + header.size.y)
	var desired_top: float = header_bottom + HEADER_CONTENT_GAP
	_main_scroll.offset_top = desired_top
	_main_scroll.set_meta(
		_META_BODY_BASE_TOP,
		maxf(HEADER_CONTENT_GAP + 46.0, desired_top - top_inset)
	)


func _rebuild_page() -> void:
	for child in _content_host.get_children():
		child.queue_free()
	_sliders.clear()
	_value_labels.clear()
	_bonus_labels.clear()
	_content_host.add_child(_build_overview_section())
	_content_host.add_child(_build_tracks_section())
	_refresh_labels()


func _build_overview_section() -> Control:
	var panel := PanelContainer.new()
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", INNER_PAD)
	pad.add_theme_constant_override("margin_right", INNER_PAD)
	pad.add_theme_constant_override("margin_top", INNER_PAD)
	pad.add_theme_constant_override("margin_bottom", INNER_PAD)
	panel.add_child(pad)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", BODY_SEP)
	pad.add_child(body)
	var heading := Label.new()
	heading.text = "調査許可の強化"
	UiTypography.apply_display(heading, UiTypography.SIZE_BODY, COLOR_GOLD)
	body.add_child(heading)
	_points_label = Label.new()
	UiTypography.apply_body(_points_label, UiTypography.SIZE_BODY_SMALL, COLOR_SUB)
	body.add_child(_points_label)
	_summary_label = Label.new()
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_caption(_summary_label, COLOR_SUB)
	body.add_child(_summary_label)
	var hint := Label.new()
	hint.text = "S+到達で許可点が貯まります。いつでも振り直せます。"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UiTypography.apply_caption(hint, COLOR_SUB)
	body.add_child(hint)
	return panel


func _build_tracks_section() -> Control:
	var panel := PanelContainer.new()
	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", INNER_PAD)
	pad.add_theme_constant_override("margin_right", INNER_PAD)
	pad.add_theme_constant_override("margin_top", INNER_PAD)
	pad.add_theme_constant_override("margin_bottom", INNER_PAD)
	panel.add_child(pad)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	pad.add_child(body)
	for track: String in _CommanderPermitBoost.TRACK_ORDER:
		body.add_child(_make_track_row(track))
	return panel


func _make_track_row(track: String) -> Control:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 8)
	col.add_child(title_row)
	var lbl := Label.new()
	lbl.text = str(_CommanderPermitBoost.TRACK_LABELS.get(track, track))
	lbl.custom_minimum_size = Vector2(72, 0)
	UiTypography.apply_body(lbl, UiTypography.SIZE_BODY_SMALL)
	title_row.add_child(lbl)
	var bonus := Label.new()
	bonus.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bonus.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UiTypography.apply_caption(bonus, COLOR_SUB)
	title_row.add_child(bonus)
	_bonus_labels[track] = bonus

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	col.add_child(row)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.step = 1.0
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.custom_minimum_size = Vector2(0, 28)
	slider.value = float(_CommanderPermitBoost.get_alloc(track))
	slider.max_value = float(maxi(1, _CommanderPermitBoost.max_for_track(track)))
	slider.value_changed.connect(_on_track_changed.bind(track))
	row.add_child(slider)
	_sliders[track] = slider
	var pct := Label.new()
	pct.custom_minimum_size = Vector2(40, 0)
	pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UiTypography.apply_caption(pct, COLOR_SUB)
	row.add_child(pct)
	_value_labels[track] = pct
	return col


func _on_track_changed(value: float, track: String) -> void:
	if _updating_sliders:
		return
	_CommanderPermitBoost.set_alloc(track, int(round(value)))
	SaveManager.save_game()
	_refresh_labels()
	_refresh_slider_bounds()


func _refresh_labels() -> void:
	if _points_label != null:
		_points_label.text = "残り許可点 %d ／ 累計 %d" % [
			_CommanderPermitBoost.points_unspent(),
			_CommanderPermitBoost.points_earned(),
		]
	if _summary_label != null:
		_summary_label.text = _CommanderPermitBoost.summary_caption()
	for track: String in _CommanderPermitBoost.TRACK_ORDER:
		var n: int = _CommanderPermitBoost.get_alloc(track)
		var value_lbl: Label = _value_labels.get(track) as Label
		if value_lbl != null:
			value_lbl.text = str(n)
		var bonus_lbl: Label = _bonus_labels.get(track) as Label
		if bonus_lbl != null:
			bonus_lbl.text = _CommanderPermitBoost.track_bonus_caption(track)


func _refresh_slider_bounds() -> void:
	_updating_sliders = true
	for track: String in _CommanderPermitBoost.TRACK_ORDER:
		var slider: HSlider = _sliders.get(track) as HSlider
		if slider == null:
			continue
		var max_v: int = maxi(1, _CommanderPermitBoost.max_for_track(track))
		var cur: int = _CommanderPermitBoost.get_alloc(track)
		slider.max_value = float(max_v)
		slider.set_value_no_signal(float(cur))
	_updating_sliders = false


func _bounce_locked() -> void:
	## S級未満で直リンクされた場合はマイページへ戻す。
	get_tree().change_scene_to_file(COMMANDER_SCENE)


func _on_back_pressed() -> void:
	AudioManager.play_sfx("ui_cancel")
	SaveManager.save_game()
	get_tree().change_scene_to_file(COMMANDER_SCENE)
