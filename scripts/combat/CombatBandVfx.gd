class_name CombatBandVfx
extends RefCounted

## 戦闘の帯・波動・霧など「画面を横切る」系 VFX（P3-UX-COMBAT-BAND-001）。
## 専用スプライト無しで ColorRect／簡易リングを procedurally 生成する。

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

const ELEMENT_COLOR: Dictionary = {
	"fire": Color(1.0, 0.42, 0.12, 0.72),
	"ice": Color(0.45, 0.82, 1.0, 0.7),
	"thunder": Color(1.0, 0.92, 0.28, 0.68),
	"dark": Color(0.62, 0.28, 0.92, 0.7),
	"holy": Color(1.0, 0.94, 0.7, 0.68),
	"": Color(0.9, 0.55, 0.35, 0.65),
}


static func element_color(element: String) -> Color:
	return ELEMENT_COLOR.get(element, ELEMENT_COLOR[""]) as Color


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


## 敵→味方帯。from=敵位置、band=味方帯の中心帯 Rect（グローバル）。
## 戻り値は演出尺（秒）。
static func play_enemy_band(
	host: Node,
	layer: Node,
	from: Vector2,
	band: Rect2,
	style: String,
	element: String,
	speed_mult: float = 1.0
) -> float:
	if host == null or layer == null or style.is_empty() or from == Vector2.ZERO:
		return 0.0
	var spd: float = maxf(0.35, speed_mult)
	var tint: Color = element_color(element)
	match style:
		STYLE_BREATH:
			return _spawn_breath(host, layer, from, band, tint, spd, true)
		STYLE_PULSE:
			return _spawn_pulse(host, layer, from, band, tint, spd)
		STYLE_TIDE:
			return _spawn_tide(host, layer, band, tint, spd)
		STYLE_MIST:
			return _spawn_mist(host, layer, band, tint, spd)
		_:
			return _spawn_pulse(host, layer, from, band, tint, spd)


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
	if host == null or layer == null or style.is_empty() or from == Vector2.ZERO:
		return 0.0
	var spd: float = maxf(0.35, speed_mult)
	var tint: Color = element_color(element)
	if tint.a < 0.5:
		tint = Color(0.95, 0.78, 0.35, 0.7)
	match style:
		STYLE_QUAKE:
			return _spawn_quake(host, layer, enemy_band, tint, spd)
		STYLE_VOLLEY:
			return _spawn_volley(host, layer, from, enemy_band, tint, spd)
		STYLE_MIST:
			return _spawn_mist(host, layer, enemy_band, tint, spd)
		STYLE_FAN:
			return _spawn_breath(host, layer, from, enemy_band, tint, spd, false)
		_:
			return _spawn_breath(host, layer, from, enemy_band, tint, spd, false)


## 必殺の追加帯（既存リング／フラッシュと併用）。
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
	var spd: float = maxf(0.35, speed_mult)
	var tint: Color = element_color(element)
	if tint.a < 0.4:
		tint = Color(1.0, 0.82, 0.28, 0.75)
	match style:
		STYLE_SHOT:
			return _spawn_shot_beam(host, layer, from, focus, tint, spd)
		STYLE_ROAR:
			return _spawn_roar_rings(host, layer, from, tint, spd)
		STYLE_SLASH:
			return _spawn_slash_arc(host, layer, from, focus, tint, spd)
		_:
			return 0.0


static func _spawn_breath(
	host: Node,
	layer: Node,
	from: Vector2,
	band: Rect2,
	tint: Color,
	spd: float,
	enemy_to_party: bool
) -> float:
	var dest: Vector2 = band.get_center()
	var dur: float = 0.42 / spd
	var bar := ColorRect.new()
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.z_index = 18
	var h: float = maxf(72.0, band.size.y * 0.85)
	var w0: float = 36.0
	bar.size = Vector2(w0, h)
	bar.pivot_offset = Vector2(w0 * 0.5, h * 0.5)
	bar.global_position = Vector2(from.x - w0 * 0.5, from.y - h * 0.5)
	bar.color = Color(tint.r, tint.g, tint.b, 0.0)
	layer.add_child(bar)
	var end_w: float = maxf(band.size.x * 0.95, 220.0)
	var end_x: float = dest.x - end_w * 0.5
	var end_y: float = dest.y - h * 0.5
	if not enemy_to_party:
		end_x = band.position.x
		end_y = band.position.y + band.size.y * 0.1
		end_w = maxf(band.size.x, 260.0)
		h = maxf(band.size.y * 0.9, 100.0)
		bar.size = Vector2(w0, h)
		bar.pivot_offset = Vector2(w0 * 0.5, h * 0.5)
	var tw: Tween = host.create_tween()
	tw.set_parallel(true)
	tw.tween_property(bar, "color:a", tint.a, 0.08)
	tw.tween_property(bar, "global_position", Vector2(end_x, end_y), dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(bar, "size", Vector2(end_w, h), dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(bar, "color:a", 0.0, 0.18)
	tw.chain().tween_callback(bar.queue_free)
	return dur + 0.18


static func _spawn_pulse(
	host: Node,
	layer: Node,
	from: Vector2,
	band: Rect2,
	tint: Color,
	spd: float
) -> float:
	var dur: float = 0.48 / spd
	var rings: int = 3
	for i: int in rings:
		var ring := ColorRect.new()
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ring.z_index = 17
		var side0: float = 28.0
		ring.size = Vector2(side0, side0)
		ring.pivot_offset = Vector2(side0 * 0.5, side0 * 0.5)
		ring.global_position = from - Vector2(side0 * 0.5, side0 * 0.5)
		ring.color = Color(tint.r, tint.g, tint.b, 0.0)
		layer.add_child(ring)
		var reach: float = maxf(band.size.x, band.size.y) * (1.1 + float(i) * 0.15)
		var delay: float = float(i) * (0.07 / spd)
		var tw: Tween = host.create_tween()
		tw.tween_interval(delay)
		tw.set_parallel(true)
		tw.tween_property(ring, "color:a", tint.a * (0.85 - float(i) * 0.18), 0.06)
		tw.tween_property(ring, "size", Vector2(reach, reach), dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(
			ring,
			"global_position",
			from - Vector2(reach * 0.5, reach * 0.5),
			dur
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.chain().tween_property(ring, "color:a", 0.0, 0.16)
		tw.chain().tween_callback(ring.queue_free)
	return dur + 0.22


static func _spawn_tide(
	host: Node,
	layer: Node,
	band: Rect2,
	tint: Color,
	spd: float
) -> float:
	var dur: float = 0.5 / spd
	var wave := ColorRect.new()
	wave.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wave.z_index = 17
	var w: float = maxf(band.size.x * 1.15, 280.0)
	var h0: float = 24.0
	wave.size = Vector2(w, h0)
	wave.global_position = Vector2(band.position.x - 20.0, band.end.y - 8.0)
	wave.color = Color(tint.r, tint.g, tint.b, 0.0)
	layer.add_child(wave)
	var h1: float = maxf(band.size.y * 1.05, 140.0)
	var tw: Tween = host.create_tween()
	tw.set_parallel(true)
	tw.tween_property(wave, "color:a", tint.a, 0.1)
	tw.tween_property(wave, "size:y", h1, dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(wave, "global_position:y", band.position.y - 12.0, dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(wave, "color:a", 0.0, 0.22)
	tw.chain().tween_callback(wave.queue_free)
	return dur + 0.22


static func _spawn_mist(
	host: Node,
	layer: Node,
	band: Rect2,
	tint: Color,
	spd: float
) -> float:
	var dur: float = 0.55 / spd
	var fog := ColorRect.new()
	fog.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fog.z_index = 16
	fog.size = Vector2(maxf(band.size.x * 1.2, 300.0), maxf(band.size.y * 1.15, 120.0))
	fog.global_position = band.position - Vector2(24.0, 16.0)
	fog.color = Color(tint.r, tint.g, tint.b, 0.0)
	layer.add_child(fog)
	var tw: Tween = host.create_tween()
	tw.tween_property(fog, "color:a", minf(0.55, tint.a), 0.18)
	tw.tween_property(fog, "color:a", 0.0, dur).set_delay(0.12)
	tw.chain().tween_callback(fog.queue_free)
	return dur + 0.2


static func _spawn_quake(
	host: Node,
	layer: Node,
	band: Rect2,
	tint: Color,
	spd: float
) -> float:
	var dur: float = 0.4 / spd
	var plate := ColorRect.new()
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.z_index = 16
	var w: float = maxf(band.size.x * 1.1, 260.0)
	plate.size = Vector2(w, 34.0)
	plate.global_position = Vector2(band.get_center().x - w * 0.5, band.end.y - 20.0)
	plate.color = Color(tint.r, tint.g, tint.b, 0.0)
	layer.add_child(plate)
	var tw: Tween = host.create_tween()
	tw.set_parallel(true)
	tw.tween_property(plate, "color:a", tint.a, 0.06)
	tw.tween_property(plate, "size:y", 90.0, dur).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(plate, "global_position:y", band.position.y + band.size.y * 0.25, dur)
	tw.chain().tween_property(plate, "color:a", 0.0, 0.18)
	tw.chain().tween_callback(plate.queue_free)
	return dur + 0.18


static func _spawn_volley(
	host: Node,
	layer: Node,
	from: Vector2,
	band: Rect2,
	tint: Color,
	spd: float
) -> float:
	var bolts: int = 5
	var dur: float = 0.38 / spd
	for i: int in bolts:
		var bolt := ColorRect.new()
		bolt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bolt.z_index = 18
		bolt.size = Vector2(18.0, 8.0)
		bolt.pivot_offset = Vector2(9.0, 4.0)
		var start: Vector2 = from + Vector2(-8.0, float(i - 2) * 10.0)
		var end: Vector2 = Vector2(
			band.position.x + band.size.x * (0.15 + float(i) * 0.18),
			band.position.y + band.size.y * (0.2 + float(i % 3) * 0.25)
		)
		bolt.global_position = start
		bolt.color = Color(tint.r, tint.g, tint.b, 0.0)
		bolt.rotation = (end - start).angle()
		layer.add_child(bolt)
		var delay: float = float(i) * (0.04 / spd)
		var tw: Tween = host.create_tween()
		tw.tween_interval(delay)
		tw.set_parallel(true)
		tw.tween_property(bolt, "color:a", tint.a, 0.05)
		tw.tween_property(bolt, "global_position", end, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.chain().tween_property(bolt, "color:a", 0.0, 0.1)
		tw.chain().tween_callback(bolt.queue_free)
	return dur + 0.25


static func _spawn_slash_arc(
	host: Node,
	layer: Node,
	from: Vector2,
	focus: Vector2,
	tint: Color,
	spd: float
) -> float:
	var dur: float = 0.34 / spd
	var blade := ColorRect.new()
	blade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blade.z_index = 19
	blade.size = Vector2(28.0, 120.0)
	blade.pivot_offset = Vector2(14.0, 60.0)
	blade.global_position = from - Vector2(14.0, 60.0)
	blade.rotation_degrees = -55.0
	blade.color = Color(tint.r, tint.g, tint.b, 0.0)
	layer.add_child(blade)
	var mid: Vector2 = focus if focus != Vector2.ZERO else from + Vector2(180.0, -20.0)
	var tw: Tween = host.create_tween()
	tw.set_parallel(true)
	tw.tween_property(blade, "color:a", tint.a, 0.05)
	tw.tween_property(blade, "global_position", mid - Vector2(14.0, 60.0), dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(blade, "rotation_degrees", 50.0, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(blade, "size", Vector2(40.0, 200.0), dur)
	tw.chain().tween_property(blade, "color:a", 0.0, 0.14)
	tw.chain().tween_callback(blade.queue_free)
	return dur + 0.14


static func _spawn_shot_beam(
	host: Node,
	layer: Node,
	from: Vector2,
	focus: Vector2,
	tint: Color,
	spd: float
) -> float:
	var dur: float = 0.28 / spd
	var to: Vector2 = focus if focus != Vector2.ZERO else from + Vector2(220.0, 0.0)
	var beam := ColorRect.new()
	beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	beam.z_index = 19
	var length: float = from.distance_to(to)
	beam.size = Vector2(maxf(length, 40.0), 10.0)
	beam.pivot_offset = Vector2(0.0, 5.0)
	beam.global_position = from - Vector2(0.0, 5.0)
	beam.rotation = (to - from).angle()
	beam.color = Color(tint.r, tint.g, tint.b, 0.0)
	layer.add_child(beam)
	var tw: Tween = host.create_tween()
	tw.set_parallel(true)
	tw.tween_property(beam, "color:a", tint.a, 0.04)
	tw.tween_property(beam, "size:y", 22.0, dur * 0.5)
	tw.chain().tween_property(beam, "color:a", 0.0, 0.16)
	tw.chain().tween_callback(beam.queue_free)
	return dur + 0.16


static func _spawn_roar_rings(
	host: Node,
	layer: Node,
	from: Vector2,
	tint: Color,
	spd: float
) -> float:
	return _spawn_pulse(host, layer, from, Rect2(from - Vector2(80, 80), Vector2(160, 160)), tint, spd)
