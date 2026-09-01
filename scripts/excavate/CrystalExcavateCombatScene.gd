extends Control

## 魔晶石発掘 — 対石の簡易戦闘演出（P3-UX-CRYSTAL-EXCAVATE-001）。

const _Excavate := preload("res://scripts/excavate/CrystalExcavateSystem.gd")
const _ChrIdlePortraitView := preload("res://scripts/ui/ChrIdlePortraitView.gd")
const _BgHelper := preload("res://scripts/excavate/CrystalExcavateBgHelper.gd")

@onready var _arena: Control = $Arena

var _damage_label: Label
var _skill_label: Label
var _portrait: ChrIdlePortraitView
var _rock: TextureRect


func _ready() -> void:
	_BgHelper.ensure_background(self, _BgHelper.BG_COMBAT)
	var session: Dictionary = _Excavate.session()
	if session.is_empty():
		if _Excavate.is_used_today():
			SceneRouter.change_scene(_Excavate.RESULT_SCENE)
		else:
			SceneRouter.change_scene(_Excavate.SELECT_SCENE)
		return
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.NONE)
	UiTypography.apply_screen_title($Header/HeaderRow/LabelTitle)
	_build_arena(session)
	call_deferred("_play_sequence", session)


func _build_arena(session: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	row.grow_vertical = Control.GROW_DIRECTION_BOTH
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	_arena.add_child(row)
	_portrait = _ChrIdlePortraitView.new()
	_portrait.custom_minimum_size = Vector2(160, 200)
	row.add_child(_portrait)
	var member: Resource = GameState.find_roster_member_by_id(str(session.get("member_id", "")))
	if member != null:
		_portrait.set_from_member(member)
	_rock = TextureRect.new()
	_rock.custom_minimum_size = Vector2(180, 180)
	_rock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_rock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_rock.texture = _BgHelper.load_rock_texture()
	_rock.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	row.add_child(_rock)
	if _rock.texture == null:
		var rock_panel := PanelContainer.new()
		rock_panel.custom_minimum_size = Vector2(140, 140)
		rock_panel.add_theme_stylebox_override(
			"panel", CombatUiFrames.panel_style(CombatUiFrames.TIER_ELITE)
		)
		row.add_child(rock_panel)
		var rock_lbl := Label.new()
		rock_lbl.text = "魔晶\nの岩"
		rock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rock_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		rock_panel.add_child(rock_lbl)
		UiTypography.apply_display(rock_lbl, UiTypography.SIZE_BODY, UiTypography.COLOR_GOLD)
	var skill: Resource = DataRegistry.get_skill_data(str(session.get("skill_id", "")))
	_skill_label = Label.new()
	_skill_label.text = str(skill.display_name) if skill != null else "—"
	_skill_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_arena.add_child(_skill_label)
	_skill_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_skill_label.offset_top = 24.0
	UiTypography.apply_body(_skill_label, UiTypography.SIZE_BODY, UiTypography.COLOR_GOLD)
	_damage_label = Label.new()
	_damage_label.text = ""
	_damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_arena.add_child(_damage_label)
	_damage_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_damage_label.offset_top = 120.0
	var impact: Font = UiTypography.impact_font()
	if impact != null:
		_damage_label.add_theme_font_override("font", impact)
	_damage_label.add_theme_font_size_override("font_size", 36)
	_damage_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.35, 1.0))
	_damage_label.add_theme_constant_override("outline_size", 4)
	_damage_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.92))


func _play_sequence(session: Dictionary) -> void:
	await get_tree().create_timer(0.35).timeout
	var dealt: int = int(session.get("dealt_damage", 0))
	_damage_label.text = str(dealt)
	_damage_label.modulate.a = 0.0
	_damage_label.scale = Vector2(0.6, 0.6)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_damage_label, "modulate:a", 1.0, 0.18)
	tween.tween_property(_damage_label, "scale", Vector2(1.15, 1.15), 0.22).set_trans(Tween.TRANS_BACK)
	if _portrait != null:
		tween.tween_property(_portrait, "position:x", _portrait.position.x + 12.0, 0.08).set_trans(Tween.TRANS_SINE)
	if _rock != null:
		tween.tween_property(_rock, "modulate", Color(1.35, 1.15, 1.55, 1.0), 0.12)
		tween.chain().tween_property(_rock, "modulate", Color.WHITE, 0.28)
	await tween.finished
	await get_tree().create_timer(0.55).timeout
	SceneRouter.change_scene(_Excavate.RESULT_SCENE)
