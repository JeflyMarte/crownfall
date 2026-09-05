extends Control

## 特権強化画面 — Permit_Frame 背景に数値／操作だけ重ねる。
## −／＋はドラフト編集。決定でセーブしてマイページへ戻る。戻るは破棄。

const _CommanderPermitBoost := preload("res://scripts/commander/CommanderPermitBoost.gd")
const _CommanderUiTokens := preload("res://scripts/commander/CommanderUiTokens.gd")
const _RoomGuide := preload("res://scripts/ui/DungeonRouteGuideOverlay.gd")
const COMMANDER_SCENE: String = "res://scenes/commander/CommanderScene.tscn"

const DESIGN_W: float = 853.0
const DESIGN_H: float = 1280.0

const SLOT_BACK := Rect2(23, 23, 60, 60)
const SLOT_HELP := Rect2(92, 23, 60, 60)
const SLOT_POINTS := Rect2(47, 207, 450, 43)
const SLOT_UNSPENT := Rect2(300, 833, 117, 47)
const SLOT_RESET := Rect2(424, 848, 167, 52)
const SLOT_DECIDE := Rect2(603, 848, 208, 52)

## カード0=略奪 / 1=成長 / 2=戦力（TRACK_ORDER と同順）。
const SLOT_BONUS: Array[Rect2] = [
	Rect2(62, 578, 208, 37),
	Rect2(322, 578, 208, 37),
	Rect2(582, 578, 208, 37),
]
const SLOT_MINUS: Array[Rect2] = [
	Rect2(65, 723, 57, 50),
	Rect2(325, 723, 57, 50),
	Rect2(585, 723, 57, 50),
]
const SLOT_VAL: Array[Rect2] = [
	Rect2(112, 723, 92, 50),
	Rect2(385, 723, 92, 50),
	Rect2(658, 723, 92, 50),
]
const SLOT_PLUS: Array[Rect2] = [
	Rect2(220, 723, 57, 50),
	Rect2(480, 723, 57, 50),
	Rect2(740, 723, 57, 50),
]

const COLOR_GOLD: Color = Color(0.92, 0.78, 0.42)
const COLOR_NUM: Color = Color(1.0, 0.88, 0.45)

@onready var _header: PanelContainer = $Header
@onready var _main_scroll: ScrollContainer = $MainScroll
@onready var _bg_texture: TextureRect = $BgTexture
@onready var _bottom_nav: PanelContainer = $BottomNav

var _letterbox: ColorRect
var _frame_host: Control
var _bg: TextureRect
var _btn_back: Button
var _btn_help: Button
var _label_points: Label
var _label_unspent: Label
var _btn_reset: Button
var _btn_decide: Button
var _bonus_labels: Array[Label] = []
var _val_labels: Array[Label] = []
var _minus_btns: Array[Button] = []
var _plus_btns: Array[Button] = []
var _draft: Dictionary = {}


func _ready() -> void:
	_CommanderPermitBoost.ensure_and_sync()
	if not _CommanderPermitBoost.is_ui_unlocked():
		call_deferred("_bounce_locked")
		return
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.MYPAGE)
	_header.visible = false
	_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_main_scroll.visible = false
	_main_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _bg_texture != null:
		_bg_texture.visible = false
		_bg_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_init_draft_from_saved()
	_build_letterbox()
	_build_frame_overlay()
	_refresh_draft_labels()
	resized.connect(_layout_frame_host)
	call_deferred("_layout_frame_host")


func _exit_tree() -> void:
	## 決定前のドラフトは破棄。保留セーブは触らない。
	pass


func _init_draft_from_saved() -> void:
	_draft = {}
	for track: String in _CommanderPermitBoost.TRACK_ORDER:
		_draft[track] = _CommanderPermitBoost.get_alloc(track)


func _build_letterbox() -> void:
	_letterbox = ColorRect.new()
	_letterbox.name = "LetterboxBlack"
	_letterbox.color = Color(0, 0, 0, 1)
	_letterbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_letterbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_letterbox.z_index = -20
	add_child(_letterbox)
	move_child(_letterbox, 0)


func _build_frame_overlay() -> void:
	_frame_host = Control.new()
	_frame_host.name = "PermitFrameHost"
	_frame_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame_host)
	move_child(_frame_host, 1)

	_bg = TextureRect.new()
	_bg.name = "PermitFrameBg"
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg.stretch_mode = TextureRect.STRETCH_SCALE
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg.texture = _CommanderUiTokens.load_tex(_CommanderUiTokens.PERMIT_FRAME)
	_frame_host.add_child(_bg)

	_btn_back = _make_hit_button()
	_btn_back.pressed.connect(_on_back_pressed)
	_frame_host.add_child(_btn_back)

	_btn_help = _make_hit_button()
	_btn_help.pressed.connect(_on_help_pressed)
	_frame_host.add_child(_btn_help)

	_label_points = Label.new()
	_label_points.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_label_points.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label_points.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame_host.add_child(_label_points)

	_bonus_labels.clear()
	_val_labels.clear()
	_minus_btns.clear()
	_plus_btns.clear()
	for i: int in _CommanderPermitBoost.TRACK_ORDER.size():
		var track: String = _CommanderPermitBoost.TRACK_ORDER[i]
		var bonus := Label.new()
		bonus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bonus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		bonus.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_frame_host.add_child(bonus)
		_bonus_labels.append(bonus)

		var minus := _make_hit_button()
		minus.pressed.connect(_on_minus_pressed.bind(track))
		_frame_host.add_child(minus)
		_minus_btns.append(minus)

		var val := Label.new()
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		val.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		val.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_frame_host.add_child(val)
		_val_labels.append(val)

		var plus := _make_hit_button()
		plus.pressed.connect(_on_plus_pressed.bind(track))
		_frame_host.add_child(plus)
		_plus_btns.append(plus)

	_label_unspent = Label.new()
	_label_unspent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_unspent.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label_unspent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame_host.add_child(_label_unspent)

	_btn_reset = _make_label_hit_button("リセット", 18)
	_btn_reset.pressed.connect(_on_reset_pressed)
	_frame_host.add_child(_btn_reset)

	_btn_decide = _make_label_hit_button("決定", 22)
	_btn_decide.pressed.connect(_on_decide_pressed)
	_frame_host.add_child(_btn_decide)

	_bottom_nav.z_index = 20


func _make_hit_button() -> Button:
	var btn := Button.new()
	btn.text = ""
	btn.focus_mode = Control.FOCUS_NONE
	var empty := StyleBoxEmpty.new()
	btn.add_theme_stylebox_override("normal", empty)
	btn.add_theme_stylebox_override("hover", empty)
	btn.add_theme_stylebox_override("pressed", empty)
	btn.add_theme_stylebox_override("disabled", empty)
	btn.add_theme_stylebox_override("focus", empty)
	return btn


func _make_label_hit_button(label: String, font_px: int = 22) -> Button:
	## 枠はフレーム焼込。文字だけ重ねる。
	var btn := _make_hit_button()
	btn.text = label
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	UiTypography.apply_button(btn, false)
	btn.add_theme_font_size_override("font_size", font_px)
	btn.add_theme_color_override("font_color", COLOR_GOLD)
	btn.add_theme_color_override("font_hover_color", COLOR_NUM)
	btn.add_theme_color_override("font_pressed_color", COLOR_GOLD)
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.92))
	btn.add_theme_constant_override("outline_size", 5)
	return btn


func _layout_frame_host() -> void:
	if _frame_host == null:
		return
	var bottom_h: float = 84.0
	if _bottom_nav != null:
		bottom_h = maxf(1.0, absf(_bottom_nav.offset_top))
	var area := Rect2(0.0, 0.0, size.x, maxf(1.0, size.y - bottom_h))
	var scale: float = minf(area.size.x / DESIGN_W, area.size.y / DESIGN_H)
	var shown := Vector2(DESIGN_W, DESIGN_H) * scale
	var origin := area.position + (area.size - shown) * 0.5
	_frame_host.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_frame_host.position = origin
	_frame_host.size = shown
	_place_design_rect(_btn_back, SLOT_BACK, scale)
	_place_design_rect(_btn_help, SLOT_HELP, scale)
	_place_design_rect(_label_points, SLOT_POINTS, scale)
	_place_design_rect(_label_unspent, SLOT_UNSPENT, scale)
	_place_design_rect(_btn_reset, SLOT_RESET, scale)
	_place_design_rect(_btn_decide, SLOT_DECIDE, scale)
	for i: int in _CommanderPermitBoost.TRACK_ORDER.size():
		_place_design_rect(_bonus_labels[i], SLOT_BONUS[i], scale)
		_place_design_rect(_minus_btns[i], SLOT_MINUS[i], scale)
		_place_design_rect(_val_labels[i], SLOT_VAL[i], scale)
		_place_design_rect(_plus_btns[i], SLOT_PLUS[i], scale)


func _place_design_rect(ctrl: Control, design: Rect2, scale: float) -> void:
	if ctrl == null:
		return
	ctrl.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	ctrl.position = design.position * scale
	ctrl.size = design.size * scale


func _draft_allocated() -> int:
	var total: int = 0
	for track: String in _CommanderPermitBoost.TRACK_ORDER:
		total += maxi(0, int(_draft.get(track, 0)))
	return total


func _draft_unspent() -> int:
	return maxi(0, _CommanderPermitBoost.points_earned() - _draft_allocated())


func _draft_max_for(track: String) -> int:
	var others: int = 0
	for t: String in _CommanderPermitBoost.TRACK_ORDER:
		if t == track:
			continue
		others += maxi(0, int(_draft.get(t, 0)))
	return maxi(0, _CommanderPermitBoost.points_earned() - others)


func _draft_get(track: String) -> int:
	return maxi(0, int(_draft.get(track, 0)))


func _draft_set(track: String, value: int) -> void:
	_draft[track] = clampi(value, 0, _draft_max_for(track))


func _draft_bonus_caption(track: String) -> String:
	var n: int = _draft_get(track)
	var pct: int = int(round(_CommanderPermitBoost.PERCENT_PER_POINT * 100.0 * float(n)))
	match track:
		_CommanderPermitBoost.TRACK_PLUNDER:
			return "Gold・素材 +%d%%" % pct
		_CommanderPermitBoost.TRACK_GROWTH:
			return "経験値 +%d%%" % pct
		_CommanderPermitBoost.TRACK_POWER:
			return "HP +%d%% / 防御 +%d" % [pct, _CommanderPermitBoost.DEFENSE_FLAT_PER_POINT * n]
		_:
			return ""


func _is_draft_dirty() -> bool:
	for track: String in _CommanderPermitBoost.TRACK_ORDER:
		if _draft_get(track) != _CommanderPermitBoost.get_alloc(track):
			return true
	return false


func _refresh_draft_labels() -> void:
	var earned: int = _CommanderPermitBoost.points_earned()
	var unspent: int = _draft_unspent()
	_label_points.text = "残り許可点 %d ／ 累計 %d" % [unspent, earned]
	_apply_num_style(_label_points, 30)
	_label_unspent.text = str(unspent)
	_apply_num_style(_label_unspent, 36)
	for i: int in _CommanderPermitBoost.TRACK_ORDER.size():
		var track: String = _CommanderPermitBoost.TRACK_ORDER[i]
		var n: int = _draft_get(track)
		_val_labels[i].text = str(n)
		_apply_num_style(_val_labels[i], 28)
		_bonus_labels[i].text = _draft_bonus_caption(track)
		UiTypography.apply_caption(_bonus_labels[i], COLOR_GOLD)
		_bonus_labels[i].add_theme_color_override("font_color", COLOR_GOLD)
		_bonus_labels[i].add_theme_constant_override("outline_size", 4)
		_bonus_labels[i].add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		_minus_btns[i].disabled = n <= 0
		_plus_btns[i].disabled = unspent <= 0 or n >= _draft_max_for(track)
	_btn_decide.disabled = false
	## 変更ありのとき決定文字を強調（枠は焼込のまま）。
	if _is_draft_dirty():
		_btn_decide.add_theme_color_override("font_color", COLOR_NUM)
	else:
		_btn_decide.add_theme_color_override("font_color", COLOR_GOLD)


func _apply_num_style(lbl: Label, size_px: int) -> void:
	var impact: Font = UiTypography.impact_font()
	if impact != null:
		lbl.add_theme_font_override("font", impact)
	lbl.add_theme_font_size_override("font_size", size_px)
	lbl.add_theme_color_override("font_color", COLOR_NUM)
	lbl.add_theme_constant_override("outline_size", 5)
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.92))


func _on_minus_pressed(track: String) -> void:
	AudioManager.play_sfx("ui_click")
	_draft_set(track, _draft_get(track) - 1)
	_refresh_draft_labels()


func _on_plus_pressed(track: String) -> void:
	AudioManager.play_sfx("ui_click")
	_draft_set(track, _draft_get(track) + 1)
	_refresh_draft_labels()


func _on_reset_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	for track: String in _CommanderPermitBoost.TRACK_ORDER:
		_draft[track] = 0
	_refresh_draft_labels()


func _on_decide_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	if _is_draft_dirty():
		_CommanderPermitBoost.apply_alloc_dict(_draft)
		SaveManager.flush_pending_save()
	get_tree().change_scene_to_file(COMMANDER_SCENE)


func _on_help_pressed() -> void:
	AudioManager.play_sfx("ui_click")
	_RoomGuide.show_on(self, _RoomGuide.GUIDE_PERMIT, true)


func _bounce_locked() -> void:
	get_tree().change_scene_to_file(COMMANDER_SCENE)


func _on_back_pressed() -> void:
	AudioManager.play_sfx("ui_cancel")
	## 未決定のドラフトは破棄。
	get_tree().change_scene_to_file(COMMANDER_SCENE)
