extends Control

## 魔晶石発掘 — 結果表示（P3-UX-CRYSTAL-EXCAVATE-001）。

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const _Excavate := preload("res://scripts/excavate/CrystalExcavateSystem.gd")
const _BgHelper := preload("res://scripts/excavate/CrystalExcavateBgHelper.gd")
const _UiTokens := preload("res://scripts/excavate/CrystalExcavateUiTokens.gd")

const BANNER_H: float = 320.0
const RECORD_DMG_COLOR := Color(1.0, 0.42, 0.28, 1.0)
const NORMAL_DMG_COLOR := Color(1.0, 0.88, 0.55, 1.0)

@onready var _main: VBoxContainer = $MainVBox


func _ready() -> void:
	_BgHelper.ensure_background(self, _BgHelper.BG_RESULT)
	_Excavate.ensure_refreshed()
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.NONE)
	$Header/HeaderRow/ButtonBack.pressed.connect(_on_back_pressed)
	## 上部タイトル「発掘結果」は出さない（戻るのみ残す）。
	$Header/HeaderRow/LabelTitle.visible = false
	_build_result()


func _build_result() -> void:
	var result: Dictionary = _Excavate.last_result()
	var tokens: int = int(result.get("tokens", 0))
	var dealt: int = int(result.get("dealt_damage", 0))
	var was_record: bool = bool(result.get("was_record", false))

	var banner_tex: Texture2D = _UiTokens.result_banner_texture()
	if banner_tex != null:
		var banner := TextureRect.new()
		banner.texture = banner_tex
		banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		banner.custom_minimum_size = Vector2(0, BANNER_H)
		banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		banner.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_main.add_child(banner)

	var status := Label.new()
	status.text = "本日の発掘：済（残り0/1）"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_main.add_child(status)
	UiTypography.apply_body(status, UiTypography.SIZE_BODY, UiTypography.COLOR_MUTED)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	_main.add_child(row)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(40, 40)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = CurrencyHelper.get_icon_texture()
	row.add_child(icon)
	var amount := Label.new()
	amount.text = "+%d %s" % [tokens, CurrencyHelper.DISPLAY_NAME]
	row.add_child(amount)
	UiTypography.apply_display(amount, UiTypography.SIZE_DISPLAY_TITLE, UiTypography.COLOR_GOLD)

	var dmg_row := HBoxContainer.new()
	dmg_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dmg_row.add_theme_constant_override("separation", 8)
	_main.add_child(dmg_row)
	if was_record:
		var badge := Label.new()
		badge.text = "記録更新！"
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dmg_row.add_child(badge)
		UiTypography.apply_display(badge, 30, UiTypography.COLOR_GOLD)
		badge.add_theme_constant_override("outline_size", 6)
	var detail := Label.new()
	detail.text = "与ダメージ%d" % dealt
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dmg_row.add_child(detail)
	var dmg_color: Color = RECORD_DMG_COLOR if was_record else NORMAL_DMG_COLOR
	var impact: Font = UiTypography.impact_font()
	if impact != null:
		detail.add_theme_font_override("font", impact)
	detail.add_theme_font_size_override("font_size", 40 if was_record else 36)
	detail.add_theme_color_override("font_color", dmg_color)
	detail.add_theme_constant_override("outline_size", 6)
	detail.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.92))

	var btn_rank := Button.new()
	btn_rank.text = "ダメージランキング"
	btn_rank.custom_minimum_size = Vector2(0, 48)
	btn_rank.pressed.connect(_on_ranking_pressed)
	_main.add_child(btn_rank)
	UiTypography.apply_menu_button(btn_rank)

	var btn := Button.new()
	btn.text = "拠点へ戻る"
	btn.custom_minimum_size = Vector2(0, 48)
	btn.pressed.connect(_on_back_pressed)
	_main.add_child(btn)


func _on_ranking_pressed() -> void:
	_Excavate.open_ranking(_Excavate.RESULT_SCENE)


func _on_back_pressed() -> void:
	SceneRouter.change_scene(HOME_SCENE)
