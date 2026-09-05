extends Control

## 魔晶石発掘 — キャラ＋スキル選択（P3-UX-CRYSTAL-EXCAVATE-001）。
## レイアウト正: Downloads「魔晶石発掘参考」／枠は Select_Frame 背景。

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const _Excavate := preload("res://scripts/excavate/CrystalExcavateSystem.gd")
const _DamageHelper := preload("res://scripts/excavate/CrystalExcavateDamageHelper.gd")
const _BgHelper := preload("res://scripts/excavate/CrystalExcavateBgHelper.gd")
const _UiTokens := preload("res://scripts/excavate/CrystalExcavateUiTokens.gd")
const _HeaderCurrencyHelper := preload("res://scripts/ui/HeaderCurrencyHelper.gd")

@onready var _content: VBoxContainer = $MainScroll/MainVBox/ContentHost

var _member_option: OptionButton
var _skill_option: OptionButton
var _label_preview: Label
var _label_hint: Label
var _btn_excavate: Button
var _members: Array[Resource] = []
var _skill_rows: Array[Dictionary] = []


func _ready() -> void:
	_BgHelper.ensure_background(self, _BgHelper.BG_SELECT)
	_Excavate.ensure_refreshed()
	if _Excavate.is_used_today():
		SceneRouter.change_scene(_Excavate.RESULT_SCENE)
		return
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.NONE)
	$Header/HeaderRow/ButtonBack.pressed.connect(_on_back_pressed)
	ScrollTouchHelper.enable($MainScroll)
	$Header/HeaderRow/LabelTitle.text = "魔晶石の発掘"
	UiTypography.apply_screen_title($Header/HeaderRow/LabelTitle)
	_ensure_header_token_chip()
	_build_ui()
	_refresh_members()
	_refresh_hint()


func _ensure_header_token_chip() -> void:
	var row: HBoxContainer = $Header/HeaderRow as HBoxContainer
	if row == null or row.get_node_or_null("TokenChip") != null:
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
	row.add_child(chip)
	_HeaderCurrencyHelper.apply_to_row(row)


func _build_ui() -> void:
	_content.add_theme_constant_override("separation", 12)
	var lead := Label.new()
	lead.text = "隊員とスキルを選んで岩を掘ります。\n必殺は使えません。1日1回・上限300魔晶石。"
	lead.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(lead)
	UiTypography.apply_body(lead, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_MUTED)

	_label_hint = Label.new()
	_label_hint.text = "残り1回"
	_label_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_content.add_child(_label_hint)
	UiTypography.apply_caption(_label_hint)
	_label_hint.add_theme_color_override("font_color", UiTypography.COLOR_GOLD)

	_content.add_child(_make_labeled_option_row("隊員", true))
	_content.add_child(_make_labeled_option_row("スキル", false))
	_content.add_child(_make_preview_row())

	var btn_wrap := CenterContainer.new()
	btn_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_child(btn_wrap)
	_btn_excavate = Button.new()
	_btn_excavate.text = "発掘"
	_btn_excavate.custom_minimum_size = Vector2(280, _UiTokens.EXCAVATE_BTN_H)
	_btn_excavate.pressed.connect(_on_excavate_pressed)
	_UiTokens.apply_excavate_button(_btn_excavate)
	btn_wrap.add_child(_btn_excavate)


func _make_labeled_option_row(label_text: String, is_member: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _UiTokens.gold_row_style())
	panel.custom_minimum_size = Vector2(0, _UiTokens.ROW_MIN_H)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(72, 0)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)
	UiTypography.apply_body(lbl, UiTypography.SIZE_BODY, UiTypography.COLOR_GOLD)
	var opt := OptionButton.new()
	opt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opt.custom_minimum_size = Vector2(0, 36)
	row.add_child(opt)
	if is_member:
		_member_option = opt
		_member_option.item_selected.connect(_on_member_selected)
	else:
		_skill_option = opt
		_skill_option.item_selected.connect(_on_skill_selected)
	return panel


func _make_preview_row() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _UiTokens.gold_row_style())
	panel.custom_minimum_size = Vector2(0, _UiTokens.ROW_MIN_H)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	var lbl := Label.new()
	lbl.text = "見込みダメージ"
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(lbl)
	UiTypography.apply_body(lbl, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_GOLD)
	_label_preview = Label.new()
	_label_preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label_preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label_preview.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label_preview.autowrap_mode = TextServer.AUTOWRAP_OFF
	row.add_child(_label_preview)
	UiTypography.apply_body(_label_preview, UiTypography.SIZE_BODY, UiTypography.COLOR_GOLD)
	var crystal := TextureRect.new()
	crystal.custom_minimum_size = Vector2(28, 28)
	crystal.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	crystal.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	crystal.texture = CurrencyHelper.get_icon_texture()
	crystal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(crystal)
	var token_lbl := Label.new()
	token_lbl.text = "魔晶石"
	token_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(token_lbl)
	UiTypography.apply_caption(token_lbl, _UiTokens.PREVIEW_TOKEN)
	return panel


func _refresh_hint() -> void:
	if _label_hint == null:
		return
	_label_hint.text = _Excavate.entry_status_label()


func _refresh_members() -> void:
	_members = _Excavate.list_adventurers()
	_member_option.clear()
	for i in _members.size():
		var member: Resource = _members[i]
		var name: String = str(member.display_name if "display_name" in member else member.id)
		_member_option.add_item(name, i)
	if _members.is_empty():
		_btn_excavate.disabled = true
		_label_preview.text = "—"
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
		_label_preview.text = "—"
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
	_label_preview.text = "%d → %d" % [dealt, tokens]
	_label_preview.add_theme_color_override("font_color", _UiTokens.PREVIEW_TOKEN)


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
