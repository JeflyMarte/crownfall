extends Control

## 魔晶石発掘 — 選択画面。
## 見た目は Select_Frame 背景のみ。コード側の枠は作らず、焼込位置に操作／数値だけ重ねる。

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const _Excavate := preload("res://scripts/excavate/CrystalExcavateSystem.gd")
const _DamageHelper := preload("res://scripts/excavate/CrystalExcavateDamageHelper.gd")
const _BgHelper := preload("res://scripts/excavate/CrystalExcavateBgHelper.gd")
const _UiTokens := preload("res://scripts/excavate/CrystalExcavateUiTokens.gd")
const _HeaderCurrencyHelper := preload("res://scripts/ui/HeaderCurrencyHelper.gd")

## フレーム原寸（assets の Select_Frame = 720×1231）。
const DESIGN_W: float = 720.0
const DESIGN_H: float = 1231.0

## デザイン座標（焼込枠の内側）。Downloads 原寸 959×1639 からスケール。
const SLOT_MEMBER := Rect2(137, 243, 536, 71)
const SLOT_SKILL := Rect2(137, 342, 536, 72)
const SLOT_DMG := Rect2(150, 448, 200, 60)
const SLOT_TOKENS := Rect2(400, 448, 170, 60)
const SLOT_EXCAVATE := Rect2(60, 552, 600, 64)
const SLOT_REMAIN := Rect2(36, 188, 280, 36)

@onready var _header: PanelContainer = $Header
@onready var _header_row: HBoxContainer = $Header/HeaderRow
@onready var _btn_back: Button = $Header/HeaderRow/ButtonBack
@onready var _label_title: Label = $Header/HeaderRow/LabelTitle
@onready var _main_scroll: ScrollContainer = $MainScroll
@onready var _bottom_nav: PanelContainer = $BottomNav

var _frame_host: Control
var _bg: TextureRect
var _member_option: OptionButton
var _skill_option: OptionButton
var _label_dmg: Label
var _label_tokens: Label
var _label_remain: Label
var _remain_panel: PanelContainer
var _btn_excavate: Button
var _members: Array[Resource] = []
var _skill_rows: Array[Dictionary] = []


func _ready() -> void:
	_Excavate.ensure_refreshed()
	if _Excavate.is_used_today():
		SceneRouter.change_scene(_Excavate.RESULT_SCENE)
		return
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.NONE)
	_btn_back.pressed.connect(_on_back_pressed)
	## タイトル／説明／枠は背景焼込。ヘッダは戻る＋魔晶石のみ。
	_label_title.visible = false
	_label_title.text = ""
	_main_scroll.visible = false
	_main_scroll.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_back_over_frame()
	_ensure_header_token_chip()
	_build_frame_overlay()
	_refresh_members()
	_refresh_remain()
	resized.connect(_layout_frame_host)
	call_deferred("_layout_frame_host")


func _style_back_over_frame() -> void:
	var empty := StyleBoxEmpty.new()
	_btn_back.add_theme_stylebox_override("normal", empty)
	_btn_back.add_theme_stylebox_override("hover", empty)
	_btn_back.add_theme_stylebox_override("pressed", empty)
	_btn_back.add_theme_stylebox_override("focus", empty)
	_btn_back.text = ""
	_btn_back.custom_minimum_size = Vector2(56, 48)
	_btn_back.focus_mode = Control.FOCUS_NONE


func _ensure_header_token_chip() -> void:
	if _header_row.get_node_or_null("TokenChip") != null:
		return
	var chip := PanelContainer.new()
	chip.name = "TokenChip"
	chip.add_theme_stylebox_override("panel", _HeaderCurrencyHelper.chip_style())
	var inner := HBoxContainer.new()
	inner.name = "TokenRow"
	inner.add_theme_constant_override("separation", _HeaderCurrencyHelper.ROW_SEP)
	chip.add_child(inner)
	var icon := TextureRect.new()
	icon.name = "TokenIcon"
	icon.custom_minimum_size = Vector2(
		_HeaderCurrencyHelper.TOKEN_ICON_PX, _HeaderCurrencyHelper.TOKEN_ICON_PX
	)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = CurrencyHelper.get_icon_texture()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(icon)
	var label := Label.new()
	label.name = "LabelToken"
	label.text = str(GameState.gacha_token)
	inner.add_child(label)
	_header_row.add_child(chip)
	_HeaderCurrencyHelper.apply_to_row(_header_row)


func _build_frame_overlay() -> void:
	_frame_host = Control.new()
	_frame_host.name = "ExcavateFrameHost"
	_frame_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame_host)
	move_child(_frame_host, 0)

	_bg = TextureRect.new()
	_bg.name = "BgTexture"
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg.stretch_mode = TextureRect.STRETCH_SCALE
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex: Texture2D = _UiTokens.select_frame_texture()
	if tex == null and ResourceLoader.exists(_BgHelper.BG_SELECT_FALLBACK):
		tex = load(_BgHelper.BG_SELECT_FALLBACK) as Texture2D
	_bg.texture = tex
	_frame_host.add_child(_bg)

	_member_option = _make_flat_option()
	_member_option.item_selected.connect(_on_member_selected)
	_frame_host.add_child(_member_option)

	_skill_option = _make_flat_option()
	_skill_option.item_selected.connect(_on_skill_selected)
	_frame_host.add_child(_skill_option)

	_label_dmg = _make_value_label(HORIZONTAL_ALIGNMENT_RIGHT)
	_frame_host.add_child(_label_dmg)

	_label_tokens = _make_value_label(HORIZONTAL_ALIGNMENT_LEFT)
	_label_tokens.add_theme_color_override("font_color", _UiTokens.PREVIEW_TOKEN)
	_frame_host.add_child(_label_tokens)

	_remain_panel = PanelContainer.new()
	_remain_panel.name = "RemainPanel"
	var remain_bg := StyleBoxFlat.new()
	remain_bg.bg_color = Color(0.04, 0.03, 0.08, 0.92)
	remain_bg.set_corner_radius_all(4)
	remain_bg.content_margin_left = 6.0
	remain_bg.content_margin_right = 6.0
	remain_bg.content_margin_top = 2.0
	remain_bg.content_margin_bottom = 2.0
	_remain_panel.add_theme_stylebox_override("panel", remain_bg)
	_label_remain = Label.new()
	_label_remain.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_label_remain.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_remain_panel.add_child(_label_remain)
	_frame_host.add_child(_remain_panel)
	UiTypography.apply_caption(_label_remain)
	_label_remain.add_theme_color_override("font_color", UiTypography.COLOR_GOLD)

	_btn_excavate = Button.new()
	_btn_excavate.text = ""
	_btn_excavate.focus_mode = Control.FOCUS_NONE
	var empty := StyleBoxEmpty.new()
	_btn_excavate.add_theme_stylebox_override("normal", empty)
	_btn_excavate.add_theme_stylebox_override("hover", empty)
	_btn_excavate.add_theme_stylebox_override("pressed", empty)
	_btn_excavate.add_theme_stylebox_override("disabled", empty)
	_btn_excavate.add_theme_stylebox_override("focus", empty)
	_btn_excavate.pressed.connect(_on_excavate_pressed)
	_frame_host.add_child(_btn_excavate)

	## ヘッダを前面に（戻る／所持石）。
	_header.z_index = 20
	_bottom_nav.z_index = 20


func _make_flat_option() -> OptionButton:
	var opt := OptionButton.new()
	opt.focus_mode = Control.FOCUS_NONE
	var empty := StyleBoxEmpty.new()
	opt.add_theme_stylebox_override("normal", empty)
	opt.add_theme_stylebox_override("hover", empty)
	opt.add_theme_stylebox_override("pressed", empty)
	opt.add_theme_stylebox_override("disabled", empty)
	opt.add_theme_stylebox_override("focus", empty)
	opt.add_theme_color_override("font_color", Color(0.95, 0.92, 0.85, 1.0))
	opt.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.8, 1.0))
	opt.add_theme_color_override("font_pressed_color", UiTypography.COLOR_GOLD)
	return opt


func _make_value_label(align: HorizontalAlignment) -> Label:
	var lbl := Label.new()
	lbl.horizontal_alignment = align
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	UiTypography.apply_body(lbl, UiTypography.SIZE_BODY, UiTypography.COLOR_GOLD)
	return lbl


func _layout_frame_host() -> void:
	if _frame_host == null:
		return
	var top: float = 46.0
	if _header != null:
		top = maxf(top, _header.size.y)
		if _header.offset_bottom > 1.0:
			top = _header.offset_bottom
	var bottom_h: float = 84.0
	if _bottom_nav != null:
		bottom_h = maxf(1.0, absf(_bottom_nav.offset_top))
	var area := Rect2(0.0, top, size.x, maxf(1.0, size.y - top - bottom_h))
	var scale: float = minf(area.size.x / DESIGN_W, area.size.y / DESIGN_H)
	var shown := Vector2(DESIGN_W, DESIGN_H) * scale
	var origin := area.position + (area.size - shown) * 0.5
	_frame_host.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_frame_host.position = origin
	_frame_host.size = shown
	_place_design_rect(_member_option, SLOT_MEMBER, scale)
	_place_design_rect(_skill_option, SLOT_SKILL, scale)
	_place_design_rect(_label_dmg, SLOT_DMG, scale)
	_place_design_rect(_label_tokens, SLOT_TOKENS, scale)
	_place_design_rect(_remain_panel, SLOT_REMAIN, scale)
	_place_design_rect(_btn_excavate, SLOT_EXCAVATE, scale)


func _place_design_rect(ctrl: Control, design: Rect2, scale: float) -> void:
	if ctrl == null:
		return
	ctrl.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	ctrl.position = design.position * scale
	ctrl.size = design.size * scale


func _refresh_remain() -> void:
	if _label_remain == null:
		return
	_label_remain.text = _Excavate.entry_status_label()


func _refresh_members() -> void:
	_members = _Excavate.list_adventurers()
	_member_option.clear()
	for i in _members.size():
		var member: Resource = _members[i]
		var name: String = str(member.display_name if "display_name" in member else member.id)
		_member_option.add_item(name, i)
	if _members.is_empty():
		_btn_excavate.disabled = true
		_label_dmg.text = "—"
		_label_tokens.text = "—"
		return
	_member_option.select(0)
	_refresh_skills()


func _refresh_skills() -> void:
	_skill_option.clear()
	_skill_rows.clear()
	if _members.is_empty():
		return
	var idx: int = _member_option.selected
	if idx < 0 or idx >= _members.size():
		idx = 0
	var member: Resource = _members[idx]
	var candidates: Array[Dictionary] = _Excavate.skill_candidates_for_member(member)
	for row: Dictionary in candidates:
		var skill: Resource = row.get("skill") as Resource
		if skill == null:
			continue
		var tag: String = "（装備）" if bool(row.get("equipped", false)) else ""
		var label: String = "%s%s" % [str(skill.display_name), tag]
		_skill_option.add_item(label, _skill_rows.size())
		_skill_rows.append(row)
	if _skill_rows.is_empty():
		_btn_excavate.disabled = true
		_label_dmg.text = "—"
		_label_tokens.text = "—"
		return
	_skill_option.select(0)
	_btn_excavate.disabled = false
	_update_preview()


func _update_preview() -> void:
	if _members.is_empty() or _skill_rows.is_empty():
		return
	var member: Resource = _members[_member_option.selected]
	var row: Dictionary = _skill_rows[_skill_option.selected]
	var skill: Resource = row.get("skill") as Resource
	var dealt: int = _DamageHelper.preview_damage(member, skill)
	var tokens: int = _Excavate.damage_to_tokens(dealt)
	_label_dmg.text = str(dealt)
	_label_tokens.text = str(tokens)


func _on_member_selected(_index: int) -> void:
	_refresh_skills()


func _on_skill_selected(_index: int) -> void:
	_update_preview()


func _on_excavate_pressed() -> void:
	if _members.is_empty() or _skill_rows.is_empty():
		return
	var member: Resource = _members[_member_option.selected]
	var row: Dictionary = _skill_rows[_skill_option.selected]
	var result: Dictionary = _Excavate.begin_excavate(str(member.id), str(row.get("id", "")))
	if not bool(result.get("ok", false)):
		return
	SceneRouter.change_scene(_Excavate.COMBAT_SCENE)


func _on_back_pressed() -> void:
	SceneRouter.change_scene(HOME_SCENE)
