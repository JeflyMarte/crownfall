extends Control

## 魔晶石発掘 — 過去ダメージランキング。
## 見出しは Ranking_Banner 画像のみ（「発掘ランキング」「ダメージ順」文言は出さない）。

const _Excavate := preload("res://scripts/excavate/CrystalExcavateSystem.gd")
const _BgHelper := preload("res://scripts/excavate/CrystalExcavateBgHelper.gd")
const _UiTokens := preload("res://scripts/excavate/CrystalExcavateUiTokens.gd")
const _RosterUiHelper := preload("res://scripts/roster/RosterUiHelper.gd")

const BANNER_H: float = 132.0

@onready var _header: PanelContainer = $Header
@onready var _header_row: HBoxContainer = $Header/HeaderRow
@onready var _btn_back: Button = $Header/HeaderRow/ButtonBack
@onready var _label_title: Label = $Header/HeaderRow/LabelTitle
@onready var _main_scroll: ScrollContainer = $MainScroll
@onready var _list: VBoxContainer = $MainScroll/MainVBox


func _ready() -> void:
	_BgHelper.ensure_background(self, _BgHelper.BG_RESULT)
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.NONE)
	_btn_back.pressed.connect(_on_back_pressed)
	_setup_title_banner()
	_build_list()


func _setup_title_banner() -> void:
	## テキスト見出しは出さず、バナー画像に置き換える。
	_label_title.visible = false
	_label_title.text = ""
	_label_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex: Texture2D = _UiTokens.ranking_banner_texture()
	var banner := TextureRect.new()
	banner.name = "RankingBanner"
	banner.texture = tex
	banner.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	banner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	banner.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	banner.custom_minimum_size = Vector2(0.0, BANNER_H)
	banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_header_row.add_child(banner)
	_header_row.move_child(banner, _label_title.get_index())
	_header.offset_bottom = 12.0 + BANNER_H
	_main_scroll.offset_top = 20.0 + BANNER_H


func _build_list() -> void:
	for child: Node in _list.get_children():
		child.queue_free()
	var rows: Array[Dictionary] = _Excavate.ranked_history()
	if rows.is_empty():
		var empty := Label.new()
		empty.text = "まだ発掘記録がありません"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_list.add_child(empty)
		UiTypography.apply_body(empty, UiTypography.SIZE_BODY, UiTypography.COLOR_MUTED)
		return
	for i: int in rows.size():
		_list.add_child(_make_row(i + 1, rows[i]))


func _make_row(rank: int, entry: Dictionary) -> Control:
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.05, 0.12, 0.88)
	sb.border_color = Color(0.78, 0.64, 0.30, 0.75)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 10.0
	sb.content_margin_right = 10.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	panel.add_theme_stylebox_override("panel", sb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	var rank_lbl := Label.new()
	rank_lbl.text = "#%d" % rank
	rank_lbl.custom_minimum_size = Vector2(48, 0)
	rank_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(rank_lbl)
	UiTypography.apply_display(rank_lbl, UiTypography.SIZE_BODY, UiTypography.COLOR_GOLD)
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(56, 56)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var member: Resource = GameState.find_roster_member_by_id(str(entry.get("member_id", "")))
	if member != null:
		portrait.texture = _RosterUiHelper.get_member_portrait_texture(member)
	row.add_child(portrait)
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 2)
	row.add_child(mid)
	var name_lbl := Label.new()
	name_lbl.text = str(entry.get("display_name", "—"))
	mid.add_child(name_lbl)
	UiTypography.apply_body(name_lbl, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_BODY)
	var skill: Resource = DataRegistry.get_skill_data(str(entry.get("skill_id", "")))
	var meta := Label.new()
	var skill_name: String = str(skill.display_name) if skill != null else str(entry.get("skill_id", ""))
	meta.text = "%s ／ %s" % [skill_name, str(entry.get("day_key", ""))]
	mid.add_child(meta)
	UiTypography.apply_caption(meta, UiTypography.COLOR_MUTED)
	var dmg_col := VBoxContainer.new()
	dmg_col.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(dmg_col)
	var dmg := Label.new()
	dmg.text = "%dダメージ" % int(entry.get("dealt_damage", 0))
	dmg.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dmg_col.add_child(dmg)
	UiTypography.apply_display(dmg, UiTypography.SIZE_DISPLAY_TITLE, UiTypography.COLOR_GOLD)
	return panel


func _on_back_pressed() -> void:
	SceneRouter.change_scene(_Excavate.ranking_back_scene())
