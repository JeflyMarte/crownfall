class_name CombatBandVfx
extends RefCounted

## 戦闘の帯・波動・霧など「画面を横切る」系 VFX（P3-UX-COMBAT-BAND-001／ART-001）。
## ColorRect 仮置きは廃止。SpriteFrames があるスタイルのみ再生し、無ければ無演出。

const STYLE_BREATH := "breath"
const STYLE_PULSE := "pulse"
const STYLE_TIDE := "tide"
const STYLE_MIST := "mist"
const STYLE_FAN := "fan"
const STYLE_VOLLEY := "volley"
const STYLE_QUAKE := "quake"
const STYLE_SLASH := "slash"
const STYLE_SHOT := "shot"
const STYLE_ROAR := "roar"

## P0 本番シート（未配置時は無演出）。命名: FX_Band_{Style}.tres
const FRAMES_PATH: Dictionary = {
	STYLE_BREATH: "res://resources/animation/FX_Band_Breath.tres",
	STYLE_PULSE: "res://resources/animation/FX_Band_Pulse.tres",
	STYLE_SLASH: "res://resources/animation/FX_Band_Slash.tres",
}

## P1 以降。未配置の間は空＝無演出（四角フォールバック禁止）。
const FRAMES_PATH_P1: Dictionary = {
	STYLE_TIDE: "res://resources/animation/FX_Band_Tide.tres",
	STYLE_MIST: "res://resources/animation/FX_Band_Mist.tres",
	STYLE_FAN: "res://resources/animation/FX_Band_Fan.tres",
	STYLE_VOLLEY: "res://resources/animation/FX_Band_Volley.tres",
	STYLE_QUAKE: "res://resources/animation/FX_Band_Quake.tres",
	STYLE_SHOT: "res://resources/animation/FX_Band_Shot.tres",
	STYLE_ROAR: "res://resources/animation/FX_Band_Roar.tres",
}

## 属性は別シート必須にせずティント（Hit VFX と同方針）。
const ELEMENT_COLOR: Dictionary = {
	"fire": Color(1.0, 0.42, 0.12, 0.92),
	"ice": Color(0.45, 0.82, 1.0, 0.9),
	"thunder": Color(1.0, 0.92, 0.28, 0.9),
	"dark": Color(0.72, 0.42, 1.0, 0.9),
	"holy": Color(1.0, 0.94, 0.7, 0.9),
	"": Color(1.0, 1.0, 1.0, 0.95),
}

const ANIM_NAME := &"default"
const DEFAULT_FPS: float = 12.0


static func element_color(element: String) -> Color:
	return ELEMENT_COLOR.get(element, ELEMENT_COLOR[""]) as Color


static func frames_path_for_style(style: String) -> String:
	if FRAMES_PATH.has(style):
		return str(FRAMES_PATH[style])
	if FRAMES_PATH_P1.has(style):
		return str(FRAMES_PATH_P1[style])
	return ""


static func has_band_frames(style: String) -> bool:
	var path: String = frames_path_for_style(style)
	return not path.is_empty() and ResourceLoader.exists(path)


static func load_band_frames(style: String) -> SpriteFrames:
	var path: String = frames_path_for_style(style)
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as SpriteFrames


## 敵ダメージスキル → 帯スタイル。単体は空（帯VFXなし）。
static func classify_enemy_skill(skill: Resource) -> String:
	if skill == null:
		return ""
	var target: String = str(skill.target_type)
	var sid: String = str(skill.id)
	var name: String = str(skill.display_name)
	var element: String = str(skill.element)
	var cast: float = float(skill.cast_time)
	var is_aoe: bool = (
		target == "all_party"
		or target == "party_front"
		or target == "party_back"
		or cast > 0.0
	)
	if not is_aoe:
		return ""
	if _id_has_any(sid, name, ["breath", "吐息", "howl", "blizzard", "slag", "ash_veil", "scale_storm", "white_silence", "mist_breath", "glacial", "吹雪"]):
		return STYLE_BREATH
	if _id_has_any(sid, name, ["tide", "surge", "泥濤", "潮", "慟哭", "engulf", "呑込", "void_coil", "abyss", "mire"]):
		return STYLE_TIDE
	if _id_has_any(sid, name, ["veil", "帳", "spore", "胞子", "spray", "飛沫", "fog", "mist", "霧", "ink", "墨", "bloom"]):
		return STYLE_MIST
	if _id_has_any(sid, name, ["wave", "波動", "resonance", "共鳴", "roar", "咆哮", "quake", "震動", "rampart", "城壁", "decree", "断罪"]):
		return STYLE_PULSE
	if element in ["fire", "ice"]:
		return STYLE_BREATH
	if element in ["thunder", "holy", "dark"] and (cast > 0.0 or target == "all_party"):
		return STYLE_PULSE
	if target == "all_party":
		return STYLE_PULSE
	if target in ["party_front", "party_back"]:
		return STYLE_BREATH
	return STYLE_PULSE


## 味方全体ダメージスキル。
static func classify_ally_aoe_skill(skill: Resource) -> String:
	if skill == null:
		return ""
	if str(skill.target_type) != "all_enemies":
		return ""
	var sid: String = str(skill.id)
	var name: String = str(skill.display_name)
	if _id_has_any(sid, name, ["shield_quake", "盾撃", "quake"]):
		return STYLE_QUAKE
	if _id_has_any(sid, name, ["volley", "斉射"]):
		return STYLE_VOLLEY
	if _id_has_any(sid, name, ["miasma", "瘴気", "venom", "毒", "mist", "霧", "hunting_ground", "狩場"]):
		return STYLE_MIST
	if _id_has_any(sid, name, ["blade_tempest", "剣嵐", "blood_mist", "血煙", "slash"]):
		return STYLE_FAN
	return STYLE_FAN


## 必殺ダメージの追加スタイル。
static func classify_ultimate(skill: Resource) -> String:
	if skill == null or str(skill.slot_type) != "ultimate":
		return ""
	if str(skill.effect_type) == "heal":
		return ""
	var sid: String = str(skill.id)
	var name: String = str(skill.display_name)
	if _id_has_any(sid, name, ["dead_eye", "デッドアイ"]):
		return STYLE_SHOT
	if _id_has_any(sid, name, ["titan_roar", "タイタン", "beast_dominion", "ビースト", "roar"]):
		return STYLE_ROAR
	return STYLE_SLASH


static func _id_has_any(sid: String, display_name: String, keys: Array) -> bool:
	var hay: String = ("%s %s" % [sid, display_name]).to_lower()
	for k in keys:
		if hay.find(str(k).to_lower()) >= 0:
			return true
	return false


## 敵→味方帯。from=敵位置、band=味方帯 Rect（グローバル）。
## 戻り値は演出尺（秒）。シート未配置なら 0（無演出）。
static func play_enemy_band(
	host: Node,
	layer: Node,
	from: Vector2,
	band: Rect2,
	style: String,
	element: String,
	speed_mult: float = 1.0
) -> float:
	if host == null or layer == null or style.is_empty():
		return 0.0
	var frames: SpriteFrames = load_band_frames(style)
	if frames == null:
		return 0.0
	var spd: float = maxf(0.35, speed_mult)
	var tint: Color = element_color(element)
	var dest: Vector2 = band.get_center() if band.size != Vector2.ZERO else from
	var pos: Vector2 = dest if style != STYLE_PULSE else from
	if pos == Vector2.ZERO:
		pos = from if from != Vector2.ZERO else dest
	var scale: Vector2 = _scale_for_style(style, band, true)
	return _play_frames(host, layer, frames, pos, tint, scale, spd)


## 味方→敵帯。
static func play_ally_band(
	host: Node,
	layer: Node,
	from: Vector2,
	enemy_band: Rect2,
	style: String,
	element: String,
	speed_mult: float = 1.0
) -> float:
	if host == null or layer == null or style.is_empty():
		return 0.0
	var frames: SpriteFrames = load_band_frames(style)
	if frames == null:
		return 0.0
	var spd: float = maxf(0.35, speed_mult)
	var tint: Color = element_color(element)
	if tint.a < 0.5:
		tint = Color(0.95, 0.78, 0.35, 0.92)
	var dest: Vector2 = enemy_band.get_center() if enemy_band.size != Vector2.ZERO else from
	var pos: Vector2 = dest
	if style == STYLE_VOLLEY or style == STYLE_FAN:
		pos = dest
	elif from != Vector2.ZERO:
		pos = from.lerp(dest, 0.55)
	var scale: Vector2 = _scale_for_style(style, enemy_band, false)
	return _play_frames(host, layer, frames, pos, tint, scale, spd)


## 必殺の追加帯（既存リング／フラッシュと併用）。シート未配置なら 0。
static func play_ultimate_band(
	host: Node,
	layer: Node,
	from: Vector2,
	focus: Vector2,
	style: String,
	element: String,
	speed_mult: float = 1.0
) -> float:
	if host == null or layer == null or style.is_empty():
		return 0.0
	var frames: SpriteFrames = load_band_frames(style)
	if frames == null:
		return 0.0
	var spd: float = maxf(0.35, speed_mult)
	var tint: Color = element_color(element)
	if tint.a < 0.4:
		tint = Color(1.0, 0.82, 0.28, 0.95)
	var pos: Vector2 = focus if focus != Vector2.ZERO else from
	if style == STYLE_ROAR:
		pos = from if from != Vector2.ZERO else focus
	elif style == STYLE_SLASH and from != Vector2.ZERO and focus != Vector2.ZERO:
		pos = from.lerp(focus, 0.55)
	var band := Rect2(pos - Vector2(120, 80), Vector2(240, 160))
	var scale: Vector2 = _scale_for_style(style, band, false)
	return _play_frames(host, layer, frames, pos, tint, scale, spd)


static func _scale_for_style(style: String, band: Rect2, _enemy_to_party: bool) -> Vector2:
	var base: float = 2.8
	match style:
		STYLE_BREATH, STYLE_FAN, STYLE_TIDE:
			base = 3.4
		STYLE_PULSE, STYLE_ROAR, STYLE_QUAKE:
			base = 3.0
		STYLE_MIST:
			base = 3.6
		STYLE_VOLLEY, STYLE_SHOT:
			base = 2.4
		STYLE_SLASH:
			base = 2.6
		_:
			base = 2.8
	if band.size.x > 1.0:
		base = clampf(band.size.x / 96.0, 2.2, 4.2)
	return Vector2(base, base)


static func _play_frames(
	host: Node,
	layer: Node,
	frames: SpriteFrames,
	pos: Vector2,
	tint: Color,
	scale: Vector2,
	spd: float
) -> float:
	if frames == null or not frames.has_animation(ANIM_NAME):
		return 0.0
	var spr := AnimatedSprite2D.new()
	spr.sprite_frames = frames
	spr.animation = ANIM_NAME
	spr.centered = true
	spr.z_index = 18
	spr.modulate = tint
	spr.scale = scale
	spr.global_position = pos
	spr.speed_scale = spd
	layer.add_child(spr)
	spr.play(ANIM_NAME)
	var fps: float = frames.get_animation_speed(ANIM_NAME)
	if fps <= 0.0:
		fps = DEFAULT_FPS
	var frame_n: int = frames.get_frame_count(ANIM_NAME)
	var dur: float = float(frame_n) / maxf(fps * spd, 0.1)
	spr.animation_finished.connect(func() -> void:
		if is_instance_valid(spr):
			spr.queue_free()
	)
	## animation_finished 欠落時の安全弁
	var timer: SceneTreeTimer = host.get_tree().create_timer(dur + 0.35)
	timer.timeout.connect(func() -> void:
		if is_instance_valid(spr):
			spr.queue_free()
	)
	return dur
