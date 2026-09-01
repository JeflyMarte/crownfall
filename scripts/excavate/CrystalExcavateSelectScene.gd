extends Control

## 魔晶石発掘 — キャラ＋スキル選択（P3-UX-CRYSTAL-EXCAVATE-001）。

const HOME_SCENE: String = "res://scenes/base/BaseScene.tscn"
const _Excavate := preload("res://scripts/excavate/CrystalExcavateSystem.gd")
const _DamageHelper := preload("res://scripts/excavate/CrystalExcavateDamageHelper.gd")
const _BgHelper := preload("res://scripts/excavate/CrystalExcavateBgHelper.gd")

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
	UiTypography.apply_screen_title($Header/HeaderRow/LabelTitle)
	_build_ui()
	_refresh_members()
	_apply_typography()


func _build_ui() -> void:
	var lead := Label.new()
	lead.text = "隊員とスキルを選んで岩を掘ります。\n必殺は使えません。1日1回・上限300魔晶石。"
	lead.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(lead)
	UiTypography.apply_body(lead, UiTypography.SIZE_BODY_SMALL, UiTypography.COLOR_MUTED)
	_label_hint = Label.new()
	_label_hint.text = "残り1回"
	_content.add_child(_label_hint)
	UiTypography.apply_caption(_label_hint)
	_label_hint.add_theme_color_override("font_color", UiTypography.COLOR_GOLD)
	var member_row := HBoxContainer.new()
	member_row.add_theme_constant_override("separation", 8)
	_content.add_child(member_row)
	var member_lbl := Label.new()
	member_lbl.text = "隊員"
	member_lbl.custom_minimum_size = Vector2(72, 0)
	member_row.add_child(member_lbl)
	UiTypography.apply_body(member_lbl)
	_member_option = OptionButton.new()
	_member_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_member_option.item_selected.connect(_on_member_selected)
	member_row.add_child(_member_option)
	var skill_row := HBoxContainer.new()
	skill_row.add_theme_constant_override("separation", 8)
	_content.add_child(skill_row)
	var skill_lbl := Label.new()
	skill_lbl.text = "スキル"
	skill_lbl.custom_minimum_size = Vector2(72, 0)
	skill_row.add_child(skill_lbl)
	UiTypography.apply_body(skill_lbl)
	_skill_option = OptionButton.new()
	_skill_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_skill_option.item_selected.connect(_on_skill_selected)
	skill_row.add_child(_skill_option)
	_label_preview = Label.new()
	_label_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_content.add_child(_label_preview)
	UiTypography.apply_body(_label_preview, UiTypography.SIZE_BODY, UiTypography.COLOR_GOLD)
	_btn_excavate = Button.new()
	_btn_excavate.text = "発掘"
	_btn_excavate.custom_minimum_size = Vector2(0, 48)
	_btn_excavate.pressed.connect(_on_excavate_pressed)
	_content.add_child(_btn_excavate)


func _apply_typography() -> void:
	pass


func _refresh_members() -> void:
	_members = _Excavate.list_adventurers()
	_member_option.clear()
	for i in _members.size():
		var member: Resource = _members[i]
		var name: String = str(member.display_name if "display_name" in member else member.id)
		_member_option.add_item(name, i)
	if _members.is_empty():
		_btn_excavate.disabled = true
		_label_preview.text = "発掘できる隊員がいません。"
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
		_label_preview.text = "ダメージ系スキルがありません。"
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
	_label_preview.text = "見込みダメージ %d → 魔晶石 %d" % [dealt, tokens]


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
