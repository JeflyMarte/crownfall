extends Control

## 魔晶石発掘 — 結果表示。
## 見た目は Result_Frame 背景のみ。焼込位置に数値／ヒット領域だけ重ねる。

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const _Excavate := preload("res://scripts/excavate/CrystalExcavateSystem.gd")
const _UiTokens := preload("res://scripts/excavate/CrystalExcavateUiTokens.gd")

## フレーム原寸（assets の Result_Frame = 720×1205）。
const DESIGN_W: float = 720.0
const DESIGN_H: float = 1205.0

## デザイン座標（焼込枠の内側）。Downloads 原寸 969×1622 からスケール。
const SLOT_BACK := Rect2(23, 23, 90, 90)
## 画面中央（中央帯）：獲得数。
const SLOT_TOKEN := Rect2(180, 628, 360, 52)
const SLOT_RECORD := Rect2(60, 708, 600, 36)
const SLOT_DMG := Rect2(60, 740, 600, 60)
const SLOT_RANK := Rect2(48, 855, 624, 95)
const SLOT_HOME := Rect2(48, 965, 624, 100)

const RECORD_DMG_COLOR := Color(1.0, 0.42, 0.28, 1.0)
const NORMAL_DMG_COLOR := Color(1.0, 0.88, 0.55, 1.0)

@onready var _header: PanelContainer = $Header
@onready var _btn_back_header: Button = $Header/HeaderRow/ButtonBack
@onready var _label_title: Label = $Header/HeaderRow/LabelTitle
@onready var _main: VBoxContainer = $MainVBox
@onready var _bottom_nav: PanelContainer = $BottomNav

var _letterbox: ColorRect
var _frame_host: Control
var _bg: TextureRect
var _btn_back: Button
var _label_tokens: Label
var _label_record: Label
var _label_dmg: Label
var _btn_rank: Button
var _btn_home: Button


func _ready() -> void:
	_Excavate.ensure_refreshed()
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.NONE)
	## タイトル／ヘッダ／旧 MainVBox はフレーム焼込に任せ、シーン側は畳む。
	_header.visible = false
	_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_btn_back_header.visible = false
	_label_title.visible = false
	_main.visible = false
	_main.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_letterbox()
	_build_frame_overlay()
	_apply_result_values()
	resized.connect(_layout_frame_host)
	call_deferred("_layout_frame_host")


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
	_frame_host.name = "ExcavateResultFrameHost"
	_frame_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame_host)
	move_child(_frame_host, 1)

	_bg = TextureRect.new()
	_bg.name = "BgTexture"
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg.stretch_mode = TextureRect.STRETCH_SCALE
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg.texture = _UiTokens.result_frame_texture()
	_frame_host.add_child(_bg)

	_btn_back = _make_hit_button()
	_btn_back.pressed.connect(_on_back_pressed)
	_frame_host.add_child(_btn_back)

	_label_tokens = Label.new()
	_label_tokens.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_tokens.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label_tokens.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame_host.add_child(_label_tokens)

	_label_record = Label.new()
	_label_record.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_record.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label_record.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label_record.text = "記録更新！"
	_frame_host.add_child(_label_record)
	UiTypography.apply_display(_label_record, 28, UiTypography.COLOR_GOLD)
	_label_record.add_theme_constant_override("outline_size", 6)

	_label_dmg = Label.new()
	_label_dmg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label_dmg.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label_dmg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame_host.add_child(_label_dmg)

	_btn_rank = _make_hit_button()
	_btn_rank.pressed.connect(_on_ranking_pressed)
	_frame_host.add_child(_btn_rank)

	_btn_home = _make_hit_button()
	_btn_home.pressed.connect(_on_back_pressed)
	_frame_host.add_child(_btn_home)

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
	_place_design_rect(_label_tokens, SLOT_TOKEN, scale)
	_place_design_rect(_label_record, SLOT_RECORD, scale)
	_place_design_rect(_label_dmg, SLOT_DMG, scale)
	_place_design_rect(_btn_rank, SLOT_RANK, scale)
	_place_design_rect(_btn_home, SLOT_HOME, scale)


func _place_design_rect(ctrl: Control, design: Rect2, scale: float) -> void:
	if ctrl == null:
		return
	ctrl.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	ctrl.position = design.position * scale
	ctrl.size = design.size * scale


func _apply_result_values() -> void:
	var result: Dictionary = _Excavate.last_result()
	var tokens: int = int(result.get("tokens", 0))
	var dealt: int = int(result.get("dealt_damage", 0))
	var was_record: bool = bool(result.get("was_record", false))

	_label_tokens.text = "+%d" % tokens
	var impact: Font = UiTypography.impact_font()
	if impact != null:
		_label_tokens.add_theme_font_override("font", impact)
	_label_tokens.add_theme_font_size_override("font_size", 34)
	_label_tokens.add_theme_color_override("font_color", UiTypography.COLOR_GOLD)
	_label_tokens.add_theme_constant_override("outline_size", 5)
	_label_tokens.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.92))

	_label_record.visible = was_record

	_label_dmg.text = "与ダメージ%d" % dealt
	var dmg_color: Color = RECORD_DMG_COLOR if was_record else NORMAL_DMG_COLOR
	if impact != null:
		_label_dmg.add_theme_font_override("font", impact)
	_label_dmg.add_theme_font_size_override("font_size", 40 if was_record else 36)
	_label_dmg.add_theme_color_override("font_color", dmg_color)
	_label_dmg.add_theme_constant_override("outline_size", 6)
	_label_dmg.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.92))


func _on_ranking_pressed() -> void:
	_Excavate.open_ranking(_Excavate.RESULT_SCENE)


func _on_back_pressed() -> void:
	SceneRouter.change_scene(HOME_SCENE)
