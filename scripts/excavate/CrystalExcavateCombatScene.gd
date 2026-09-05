extends Control

## 魔晶石発掘 — 対石の簡易戦闘演出（P3-UX-CRYSTAL-EXCAVATE-001）。
## WALK(idle)待機 → TAP で攻撃モーション → 岩破碎 → 結果へ。

const _Excavate := preload("res://scripts/excavate/CrystalExcavateSystem.gd")
const _BgHelper := preload("res://scripts/excavate/CrystalExcavateBgHelper.gd")
const _ChrHelper := preload("res://scripts/excavate/CrystalExcavateChrHelper.gd")

const CHR_TARGET_H: float = 220.0
const TAP_FONT_SIZE: int = 72
const SHARD_COUNT: int = 14
const SHARD_GRID: int = 4

@onready var _arena: Control = $Arena

var _damage_label: Label
var _skill_label: Label
var _tap_label: Label
var _chr_host: Control
var _chr: AnimatedSprite2D
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
	_damage_label.offset_top = -80.0
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
	AudioManager.play_sfx("ui_confirm")
	var dealt: int = int(_session.get("dealt_damage", 0))
	_damage_label.text = str(dealt)
	_damage_label.modulate.a = 0.0
	_damage_label.scale = Vector2(0.6, 0.6)

	var base_x: float = 0.0
	if _chr != null:
		base_x = _chr.position.x
		if _chr.sprite_frames != null and _chr.sprite_frames.has_animation("attack"):
			_chr.play("attack")
		var lunge := create_tween()
		lunge.tween_property(_chr, "position:x", base_x + 36.0, 0.12).set_trans(Tween.TRANS_SINE)
		lunge.tween_property(_chr, "position:x", base_x, 0.18).set_trans(Tween.TRANS_SINE)

	var dmg_tw := create_tween()
	dmg_tw.tween_property(_damage_label, "modulate:a", 1.0, 0.18)
	dmg_tw.parallel().tween_property(_damage_label, "scale", Vector2(1.2, 1.2), 0.22).set_trans(
		Tween.TRANS_BACK
	)

	if _rock != null:
		var hit := create_tween()
		hit.tween_property(_rock, "modulate", Color(1.45, 1.2, 1.65, 1.0), 0.1)
		hit.tween_property(_rock, "modulate", Color.WHITE, 0.12)

	if _chr != null and _chr.sprite_frames != null and _chr.sprite_frames.has_animation("attack"):
		await _chr.animation_finished
	else:
		await get_tree().create_timer(0.35).timeout

	await _play_rock_shatter()
	await get_tree().create_timer(0.25).timeout
	SceneRouter.change_scene(_Excavate.RESULT_SCENE)


func _play_rock_shatter() -> void:
	if _rock == null or not is_instance_valid(_rock):
		return
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
	sparks.amount = 28
	sparks.lifetime = 0.55
	sparks.direction = Vector2(0, -1)
	sparks.spread = 180.0
	sparks.gravity = Vector2(0, 420)
	sparks.initial_velocity_min = 120.0
	sparks.initial_velocity_max = 280.0
	sparks.scale_amount_min = 2.0
	sparks.scale_amount_max = 5.0
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
	var shard_draw: float = minf(rock_rect.size.x, rock_rect.size.y) / float(SHARD_GRID) * 1.15
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var shatter := create_tween()
	shatter.set_parallel(true)
	for i: int in SHARD_COUNT:
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
		var dist: float = rng.randf_range(90.0, 220.0)
		var dest: Vector2 = local_center - shard.size * 0.5 + Vector2(cos(angle), sin(angle)) * dist + Vector2(
			0.0, rng.randf_range(40.0, 120.0)
		)
		var dur: float = rng.randf_range(0.45, 0.75)
		shatter.tween_property(shard, "position", dest, dur).set_trans(Tween.TRANS_QUAD).set_ease(
			Tween.EASE_OUT
		)
		shatter.tween_property(shard, "rotation", rng.randf_range(-2.8, 2.8), dur)
		shatter.tween_property(shard, "modulate:a", 0.0, dur).set_delay(dur * 0.35)
		shatter.tween_property(shard, "scale", Vector2(0.35, 0.35), dur)
	AudioManager.play_sfx("ui_confirm")
	await shatter.finished
	await get_tree().create_timer(0.1).timeout
