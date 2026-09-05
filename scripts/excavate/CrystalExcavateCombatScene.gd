extends Control

## 魔晶石発掘 — 対石の簡易戦闘演出（P3-UX-CRYSTAL-EXCAVATE-001）。
## WALK待機 → TAP → スキルカットイン → 攻撃／ダメージEF → 岩破碎 → 結果。

const _Excavate := preload("res://scripts/excavate/CrystalExcavateSystem.gd")
const _BgHelper := preload("res://scripts/excavate/CrystalExcavateBgHelper.gd")
const _ChrHelper := preload("res://scripts/excavate/CrystalExcavateChrHelper.gd")
const _RosterUiHelper := preload("res://scripts/roster/RosterUiHelper.gd")
const _SkillEffectOneLineHelper := preload("res://scripts/ui/SkillEffectOneLineHelper.gd")
const _UltimatePresentationConfig := preload("res://scripts/combat/UltimatePresentationConfig.gd")

const CHR_TARGET_H: float = 220.0
const CHR_Y_OFFSET: float = 130.0
const TAP_FONT_SIZE: int = 72
const SHARD_GRID: int = 4
const SHARD_COUNT_MIN: int = 6
const SHARD_COUNT_MAX: int = 32
const SPARK_COUNT_MIN: int = 20
const SPARK_COUNT_MAX: int = 72
const HIT_BURST_MIN: int = 18
const HIT_BURST_MAX: int = 56
const CUTIN_FACE_PX: float = 112.0

@onready var _arena: Control = $Arena
@onready var _header: PanelContainer = $Header

var _damage_label: Label
var _tap_label: Label
var _chr_host: Control
var _chr: AnimatedSprite2D
var _rock: TextureRect
var _rock_glow: TextureRect
var _rock_glow_tween: Tween
var _rock_pulse_tween: Tween
var _session: Dictionary = {}
var _awaiting_tap: bool = false
var _attacking: bool = false
var _cutin_root: Control


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
	## 上の「発掘中」ヘッダ／スキル名は出さない。
	if _header != null:
		_header.visible = false
		_header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arena.offset_top = 0.0
	_build_arena(_session)
	_awaiting_tap = true
	_arena.gui_input.connect(_on_arena_gui_input)
	_arena.mouse_filter = Control.MOUSE_FILTER_STOP


func _build_arena(session: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	row.offset_top = CHR_Y_OFFSET
	row.offset_bottom = CHR_Y_OFFSET
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	row.grow_vertical = Control.GROW_DIRECTION_BOTH
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 48)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arena.add_child(row)

	_chr_host = Control.new()
	_chr_host.custom_minimum_size = Vector2(200, 260)
	_chr_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chr_host.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_chr_host)
	_chr = AnimatedSprite2D.new()
	_chr.centered = true
	_chr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_chr_host.add_child(_chr)
	_chr_host.resized.connect(_on_chr_host_resized)
	var member: Resource = GameState.find_roster_member_by_id(str(session.get("member_id", "")))
	_setup_chr_sprite(member)

	_rock = TextureRect.new()
	_rock.custom_minimum_size = Vector2(200, 200)
	_rock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_rock.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_rock.texture = _BgHelper.load_rock_texture()
	_rock.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_rock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rock.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	## 発光は岩の背面に重ねる。
	var rock_stack := Control.new()
	rock_stack.custom_minimum_size = Vector2(200, 200)
	rock_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rock_stack.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(rock_stack)
	_rock_glow = _BgHelper.create_crystal_glow("CombatRockGlow")
	_rock_glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rock_glow.offset_left = -36.0
	_rock_glow.offset_top = -36.0
	_rock_glow.offset_right = 36.0
	_rock_glow.offset_bottom = 36.0
	rock_stack.add_child(_rock_glow)
	rock_stack.add_child(_rock)
	_rock.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rock_glow_tween = _BgHelper.start_glow_pulse(self, _rock_glow)
	_rock_pulse_tween = _BgHelper.start_glow_pulse(
		self,
		_rock,
		_BgHelper.ROCK_GLOW_DIM,
		_BgHelper.ROCK_GLOW_BRIGHT,
		1.0
	)
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

	_tap_label = Label.new()
	_tap_label.text = "TAP"
	_tap_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tap_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tap_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arena.add_child(_tap_label)
	_tap_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_tap_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_tap_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	var impact: Font = UiTypography.impact_font()
	if impact != null:
		_tap_label.add_theme_font_override("font", impact)
	_tap_label.add_theme_font_size_override("font_size", TAP_FONT_SIZE)
	_tap_label.add_theme_color_override("font_color", UiTypography.COLOR_GOLD)
	_tap_label.add_theme_constant_override("outline_size", 8)
	_tap_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	_tap_label.z_index = 5
	_start_tap_pulse()

	_damage_label = Label.new()
	_damage_label.text = ""
	_damage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_damage_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arena.add_child(_damage_label)
	_damage_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_damage_label.offset_top = -40.0 + CHR_Y_OFFSET
	if impact != null:
		_damage_label.add_theme_font_override("font", impact)
	_damage_label.add_theme_font_size_override("font_size", 42)
	_damage_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.35, 1.0))
	_damage_label.add_theme_constant_override("outline_size", 4)
	_damage_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.92))
	_damage_label.z_index = 6


func _setup_chr_sprite(member: Resource) -> void:
	if _chr == null:
		return
	var frames: SpriteFrames = _ChrHelper.load_frames_for_member(member)
	if frames == null:
		return
	_chr.sprite_frames = frames
	_ChrHelper.normalize_scale(_chr, frames, CHR_TARGET_H)
	_on_chr_host_resized()
	if frames.has_animation("idle"):
		_chr.play("idle")
	else:
		var names: PackedStringArray = frames.get_animation_names()
		if not names.is_empty():
			_chr.play(str(names[0]))


func _on_chr_host_resized() -> void:
	if _chr == null or _chr_host == null:
		return
	_chr.position = _chr_host.size * 0.5


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
	var dealt: int = int(_session.get("dealt_damage", 0))
	var intensity: float = _damage_intensity(dealt)
	await _play_skill_cutin()
	_damage_label.text = str(dealt)
	_damage_label.modulate.a = 0.0
	_damage_label.scale = Vector2(0.55, 0.55)
	var dmg_peak: float = lerpf(1.35, 1.85, intensity)
	_damage_label.add_theme_font_size_override("font_size", int(lerpf(42.0, 64.0, intensity)))

	var base_x: float = 0.0
	if _chr != null:
		base_x = _chr.position.x
		if _chr.sprite_frames != null and _chr.sprite_frames.has_animation("attack"):
			_chr.play("attack")
		var lunge := create_tween()
		lunge.tween_property(_chr, "position:x", base_x + 44.0, 0.12).set_trans(Tween.TRANS_SINE)
		lunge.tween_property(_chr, "position:x", base_x, 0.18).set_trans(Tween.TRANS_SINE)

	var dmg_tw := create_tween()
	dmg_tw.tween_property(_damage_label, "modulate:a", 1.0, 0.14)
	dmg_tw.parallel().tween_property(_damage_label, "scale", Vector2(dmg_peak, dmg_peak), 0.22).set_trans(
		Tween.TRANS_BACK
	)

	if _rock != null:
		var rock_base: Vector2 = _rock.scale
		var punch: float = lerpf(1.18, 1.42, intensity)
		var hit := create_tween()
		hit.tween_property(_rock, "modulate", Color(1.7, 1.35, 1.9, 1.0), 0.08)
		hit.parallel().tween_property(_rock, "scale", rock_base * punch, 0.1).set_trans(Tween.TRANS_BACK)
		hit.tween_property(_rock, "modulate", Color.WHITE, 0.1)
		hit.parallel().tween_property(_rock, "scale", rock_base, 0.12)
		_spawn_hit_burst(_rock_center_global(), intensity)

	if _chr != null and _chr.sprite_frames != null and _chr.sprite_frames.has_animation("attack"):
		await _chr.animation_finished
	else:
		await get_tree().create_timer(0.35).timeout

	await _play_rock_shatter(dealt)
	await get_tree().create_timer(0.25).timeout
	SceneRouter.change_scene(_Excavate.RESULT_SCENE)


## 必殺技イメージの横帯カットイン（スキル名＋顔）。
func _play_skill_cutin() -> void:
	_dismiss_skill_cutin()
	var member: Resource = GameState.find_roster_member_by_id(str(_session.get("member_id", "")))
	var skill: Resource = DataRegistry.get_skill_data(str(_session.get("skill_id", "")))
	var skill_name: String = str(skill.display_name) if skill != null else "—"
	var effect_line: String = _SkillEffectOneLineHelper.for_combat_ultimate(skill)
	var accent := Color(0.92, 0.78, 0.42, 1.0)

	var layer := Control.new()
	layer.name = "ExcavateSkillCutin"
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.z_index = 40
	add_child(layer)
	_cutin_root = layer

	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.color = Color(0.02, 0.02, 0.06, 0.0)
	layer.add_child(dim)

	var band := Control.new()
	band.name = "CutinBand"
	band.anchor_left = 0.0
	band.anchor_right = 0.0
	band.anchor_top = 0.5
	band.anchor_bottom = 0.5
	band.offset_left = -560.0
	band.offset_right = 200.0
	var band_half: float = 86.0 if not effect_line.is_empty() else 70.0
	band.offset_top = -band_half
	band.offset_bottom = band_half
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.modulate.a = 0.0
	layer.add_child(band)

	var band_bg := ColorRect.new()
	band_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	band_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band_bg.color = Color(accent.r * 0.22, accent.g * 0.18, accent.b * 0.12, 0.92)
	band.add_child(band_bg)
	var stripe := ColorRect.new()
	stripe.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	stripe.offset_right = 10.0
	stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stripe.color = accent
	band.add_child(stripe)

	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 18.0
	row.offset_right = -18.0
	row.offset_top = 10.0
	row.offset_bottom = -10.0
	row.add_theme_constant_override("separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band.add_child(row)

	var face := TextureRect.new()
	face.custom_minimum_size = Vector2(CUTIN_FACE_PX, CUTIN_FACE_PX)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.clip_contents = false
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if member != null:
		face.texture = _RosterUiHelper.get_member_portrait_texture(member)
	row.add_child(face)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text_col.alignment = BoxContainer.ALIGNMENT_CENTER
	text_col.add_theme_constant_override("separation", 2)
	text_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text_col)

	var tag := Label.new()
	tag.text = "スキル"
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var af: Font = UiTypography.impact_font()
	if af != null:
		tag.add_theme_font_override("font", af)
	tag.add_theme_font_size_override("font_size", 28)
	tag.add_theme_color_override("font_color", Color(1.0, 0.94, 0.7))
	tag.add_theme_color_override("font_outline_color", Color(0.1, 0.04, 0.0, 0.95))
	tag.add_theme_constant_override("outline_size", 6)
	text_col.add_child(tag)

	var name_lbl := Label.new()
	name_lbl.text = skill_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_lbl.clip_text = false
	if af != null:
		name_lbl.add_theme_font_override("font", af)
	name_lbl.add_theme_font_size_override("font_size", 40)
	name_lbl.add_theme_color_override("font_color", accent)
	name_lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.02, 0.0, 0.95))
	name_lbl.add_theme_constant_override("outline_size", 12)
	text_col.add_child(name_lbl)

	if not effect_line.is_empty():
		var effect_lbl := Label.new()
		effect_lbl.text = effect_line
		effect_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		effect_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UiTypography.apply_body(effect_lbl, 22)
		effect_lbl.add_theme_color_override("font_color", Color(0.96, 0.92, 0.82, 0.95))
		effect_lbl.add_theme_color_override("font_outline_color", Color(0.06, 0.02, 0.0, 0.9))
		effect_lbl.add_theme_constant_override("outline_size", 5)
		text_col.add_child(effect_lbl)

	AudioManager.play_sfx("combat_ultimate", 0.92, 0.06)
	var t: Dictionary = _UltimatePresentationConfig.scaled(1.0)
	var fade_in: float = 0.18
	var hold: float = float(t.get("announce", 1.0)) + float(t.get("windup", 0.65)) * 0.55
	var fade_out: float = float(t.get("release", 0.25))

	var enter := create_tween()
	enter.set_parallel(true)
	enter.tween_property(dim, "color:a", 0.58, fade_in).set_trans(Tween.TRANS_QUAD).set_ease(
		Tween.EASE_OUT
	)
	enter.tween_property(band, "offset_left", 16.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(
		Tween.EASE_OUT
	)
	enter.tween_property(band, "offset_right", 776.0, 0.28).set_trans(Tween.TRANS_BACK).set_ease(
		Tween.EASE_OUT
	)
	enter.tween_property(band, "modulate:a", 1.0, 0.14)
	await enter.finished
	await get_tree().create_timer(hold).timeout
	var leave := create_tween()
	leave.tween_property(layer, "modulate:a", 0.0, fade_out)
	await leave.finished
	_dismiss_skill_cutin()


func _dismiss_skill_cutin() -> void:
	if _cutin_root != null and is_instance_valid(_cutin_root):
		_cutin_root.queue_free()
	_cutin_root = null


func _damage_intensity(dealt: int) -> float:
	var tokens: int = _Excavate.damage_to_tokens(dealt)
	return clampf(float(tokens) / float(_Excavate.TOKEN_CAP), 0.08, 1.0)


func _rock_center_global() -> Vector2:
	if _rock == null or not is_instance_valid(_rock):
		return _arena.get_global_rect().get_center()
	return Rect2(_rock.global_position, _rock.size).get_center()


func _spawn_hit_burst(center_global: Vector2, intensity: float) -> void:
	if _arena == null:
		return
	var host := Control.new()
	host.name = "HitBurstHost"
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.z_index = 7
	_arena.add_child(host)
	var burst := CPUParticles2D.new()
	burst.emitting = false
	burst.one_shot = true
	burst.explosiveness = 1.0
	burst.amount = int(lerpf(float(HIT_BURST_MIN), float(HIT_BURST_MAX), intensity))
	burst.lifetime = lerpf(0.45, 0.7, intensity)
	burst.direction = Vector2(0, -1)
	burst.spread = 180.0
	burst.gravity = Vector2(0, 280)
	burst.initial_velocity_min = lerpf(160.0, 280.0, intensity)
	burst.initial_velocity_max = lerpf(280.0, 480.0, intensity)
	burst.scale_amount_min = lerpf(4.0, 8.0, intensity)
	burst.scale_amount_max = lerpf(9.0, 16.0, intensity)
	burst.color = Color(1.0, 0.82, 0.45, 1.0)
	host.add_child(burst)
	burst.global_position = center_global
	burst.emitting = true
	var ring := ColorRect.new()
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ring_px: float = lerpf(70.0, 140.0, intensity)
	ring.size = Vector2(ring_px, ring_px)
	ring.pivot_offset = ring.size * 0.5
	ring.color = Color(1.0, 0.9, 0.55, 0.75)
	host.add_child(ring)
	ring.global_position = center_global - ring.size * 0.5
	var ring_tw := create_tween()
	var ring_scale: float = lerpf(2.2, 3.6, intensity)
	ring_tw.tween_property(ring, "scale", Vector2(ring_scale, ring_scale), 0.35).set_trans(
		Tween.TRANS_QUAD
	).set_ease(Tween.EASE_OUT)
	ring_tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.35)
	ring_tw.tween_callback(host.queue_free)


func _stop_rock_glow() -> void:
	if _rock_glow_tween != null and is_instance_valid(_rock_glow_tween):
		_rock_glow_tween.kill()
	_rock_glow_tween = null
	if _rock_pulse_tween != null and is_instance_valid(_rock_pulse_tween):
		_rock_pulse_tween.kill()
	_rock_pulse_tween = null
	if _rock_glow != null and is_instance_valid(_rock_glow):
		_rock_glow.visible = false
	if _rock != null and is_instance_valid(_rock):
		_rock.modulate = Color.WHITE


func _play_rock_shatter(dealt: int = 0) -> void:
	if _rock == null or not is_instance_valid(_rock):
		return
	_stop_rock_glow()
	var intensity: float = _damage_intensity(dealt)
	var shard_count: int = int(round(lerpf(float(SHARD_COUNT_MIN), float(SHARD_COUNT_MAX), intensity)))
	var spark_count: int = int(round(lerpf(float(SPARK_COUNT_MIN), float(SPARK_COUNT_MAX), intensity)))
	var dist_min: float = lerpf(70.0, 120.0, intensity)
	var dist_max: float = lerpf(160.0, 320.0, intensity)
	var tex: Texture2D = _rock.texture
	var rock_rect := Rect2(_rock.global_position, _rock.size)
	var center_global: Vector2 = rock_rect.get_center()
	_rock.visible = false

	var host := Control.new()
	host.name = "RockShatterHost"
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.z_index = 8
	_arena.add_child(host)

	var sparks := CPUParticles2D.new()
	sparks.emitting = false
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.amount = spark_count
	sparks.lifetime = lerpf(0.5, 0.85, intensity)
	sparks.direction = Vector2(0, -1)
	sparks.spread = 180.0
	sparks.gravity = Vector2(0, 420)
	sparks.initial_velocity_min = lerpf(140.0, 220.0, intensity)
	sparks.initial_velocity_max = lerpf(260.0, 420.0, intensity)
	sparks.scale_amount_min = lerpf(3.0, 6.0, intensity)
	sparks.scale_amount_max = lerpf(6.0, 12.0, intensity)
	sparks.color = Color(0.75, 0.55, 1.0, 1.0)
	host.add_child(sparks)
	sparks.global_position = center_global
	sparks.emitting = true

	if tex == null:
		await get_tree().create_timer(0.55).timeout
		return

	var tw := float(tex.get_width())
	var th := float(tex.get_height())
	var cell_w: float = tw / float(SHARD_GRID)
	var cell_h: float = th / float(SHARD_GRID)
	var shard_draw: float = minf(rock_rect.size.x, rock_rect.size.y) / float(SHARD_GRID) * lerpf(
		1.05, 1.35, intensity
	)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var shatter := create_tween()
	shatter.set_parallel(true)
	for i: int in shard_count:
		var gx: int = i % SHARD_GRID
		var gy: int = int(i / SHARD_GRID) % SHARD_GRID
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(gx * cell_w, gy * cell_h, cell_w, cell_h)
		var shard := TextureRect.new()
		shard.texture = atlas
		shard.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shard.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		shard.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shard.custom_minimum_size = Vector2(shard_draw, shard_draw)
		shard.size = Vector2(shard_draw, shard_draw)
		host.add_child(shard)
		var local_center: Vector2 = host.to_local(center_global)
		shard.position = local_center - shard.size * 0.5
		shard.pivot_offset = shard.size * 0.5
		var angle: float = rng.randf_range(0.0, TAU)
		var dist: float = rng.randf_range(dist_min, dist_max)
		var dest: Vector2 = local_center - shard.size * 0.5 + Vector2(cos(angle), sin(angle)) * dist + Vector2(
			0.0, rng.randf_range(40.0, 140.0)
		)
		var dur: float = rng.randf_range(0.45, 0.8)
		shatter.tween_property(shard, "position", dest, dur).set_trans(Tween.TRANS_QUAD).set_ease(
			Tween.EASE_OUT
		)
		shatter.tween_property(shard, "rotation", rng.randf_range(-2.8, 2.8), dur)
		shatter.tween_property(shard, "modulate:a", 0.0, dur).set_delay(dur * 0.35)
		shatter.tween_property(shard, "scale", Vector2(0.35, 0.35), dur)
	AudioManager.play_sfx("ui_confirm")
	await shatter.finished
	await get_tree().create_timer(0.1).timeout
