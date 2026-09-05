extends Control

## 魔晶石発掘 — 対石の簡易戦闘演出（P3-UX-CRYSTAL-EXCAVATE-001）。
## TAP で攻撃→ダメージ表示→結果へ。

const _Excavate := preload("res://scripts/excavate/CrystalExcavateSystem.gd")
const _ChrIdlePortraitView := preload("res://scripts/ui/ChrIdlePortraitView.gd")
const _BgHelper := preload("res://scripts/excavate/CrystalExcavateBgHelper.gd")

@onready var _arena: Control = $Arena

var _damage_label: Label
var _skill_label: Label
var _tap_label: Label
var _portrait: ChrIdlePortraitView
var _rock: TextureRect
var _session: Dictionary = {}
var _awaiting_tap: bool = false
var _attacking: bool = false


func _ready() -> void:
	_BgHelper.ensure_background(self, _BgHelper.BG_COMBAT)
	_session = _Excavate.session()
	if _session.is_empty():
		if _Excavate.is_used_today():
			SceneRouter.change_scene(_Excavate.RESULT_SCENE)
		else:
			SceneRouter.change_scene(_Excavate.SELECT_SCENE)
		return
	BottomNavHelper.setup($BottomNav/NavRow, BottomNavHelper.Tab.NONE)
	UiTypography.apply_screen_title($Header/HeaderRow/LabelTitle)
	_build_arena(_session)
	_awaiting_tap = true
	_arena.gui_input.connect(_on_arena_gui_input)
	_arena.mouse_filter = Control.MOUSE_FILTER_STOP


func _build_arena(session: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	row.grow_vertical = Control.GROW_DIRECTION_BOTH
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	_rock.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	_skill_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arena.add_child(_skill_label)
	_skill_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_skill_label.offset_top = 24.0
	UiTypography.apply_body(_skill_label, UiTypography.SIZE_BODY, UiTypography.COLOR_GOLD)
	_tap_label = Label.new()
	_tap_label.text = "TAP"
	_tap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tap_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arena.add_child(_tap_label)
	_tap_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_tap_label.offset_bottom = -28.0
	UiTypography.apply_display(_tap_label, UiTypography.SIZE_BODY, UiTypography.COLOR_GOLD)
	_start_tap_pulse()
	_damage_label = Label.new()
	_damage_label.text = ""
	_damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_damage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
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


func _start_tap_pulse() -> void:
	if _tap_label == null:
		return
	var tw := create_tween().set_loops()
	tw.tween_property(_tap_label, "modulate:a", 0.35, 0.55).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_tap_label, "modulate:a", 1.0, 0.55).set_trans(Tween.TRANS_SINE)
	_tap_label.set_meta("pulse_tween", tw)


func _stop_tap_pulse() -> void:
	if _tap_label == null:
		return
	if _tap_label.has_meta("pulse_tween"):
		var tw: Tween = _tap_label.get_meta("pulse_tween") as Tween
		if tw != null and is_instance_valid(tw):
			tw.kill()
		_tap_label.remove_meta("pulse_tween")
	_tap_label.visible = false


func _on_arena_gui_input(event: InputEvent) -> void:
	if not _awaiting_tap or _attacking:
		return
	var tapped: bool = false
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			tapped = true
	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		if st.pressed:
			tapped = true
	if not tapped:
		return
	_awaiting_tap = false
	accept_event()
	_play_attack()


func _play_attack() -> void:
	if _attacking:
		return
	_attacking = true
	_stop_tap_pulse()
	AudioManager.play_sfx("ui_confirm")
	var dealt: int = int(_session.get("dealt_damage", 0))
	_damage_label.text = str(dealt)
	_damage_label.modulate.a = 0.0
	_damage_label.scale = Vector2(0.6, 0.6)
	var base_x: float = _portrait.position.x if _portrait != null else 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	if _portrait != null:
		tween.tween_property(_portrait, "position:x", base_x + 28.0, 0.1).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_damage_label, "modulate:a", 1.0, 0.18)
	tween.tween_property(_damage_label, "scale", Vector2(1.15, 1.15), 0.22).set_trans(Tween.TRANS_BACK)
	if _rock != null:
		tween.tween_property(_rock, "modulate", Color(1.35, 1.15, 1.55, 1.0), 0.12)
	await tween.finished
	var recover := create_tween()
	recover.set_parallel(true)
	if _portrait != null:
		recover.tween_property(_portrait, "position:x", base_x, 0.16).set_trans(Tween.TRANS_SINE)
	if _rock != null:
		recover.tween_property(_rock, "modulate", Color.WHITE, 0.28)
	await recover.finished
	await get_tree().create_timer(0.45).timeout
	SceneRouter.change_scene(_Excavate.RESULT_SCENE)
