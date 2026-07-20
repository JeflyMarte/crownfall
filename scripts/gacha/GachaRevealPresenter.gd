class_name GachaRevealPresenter
extends RefCounted

## 招待状開封リビール（P3-GACHA-REVEAL-001）。GachaScene から Tween を駆動する。

enum Phase { IDLE, SEALED, OPENING, PORTRAIT, DONE }

const DUR_SEALED: Dictionary = {2: 0.70, 3: 0.95, 4: 1.20}
const DUR_OPENING: Dictionary = {2: 1.10, 3: 1.45, 4: 1.90}
const DUR_PORTRAIT: Dictionary = {2: 0.40, 3: 0.50, 4: 0.60}
const GLOW_ALPHA: Dictionary = {2: 0.35, 3: 0.55, 4: 0.85}

var phase: int = Phase.IDLE
var rarity: int = 2

var _host: Node = null
var _tween: Tween = null
var _dim: CanvasItem = null
var _panel: CanvasItem = null
var _glow: CanvasItem = null
var _invite: TextureRect = null
var _flash: CanvasItem = null
var _portrait: CanvasItem = null
var _labels: Array = []
var _tex_sealed: Texture2D = null
var _tex_sealed_star2: Texture2D = null
var _tex_opening: Texture2D = null
var _on_done: Callable = Callable()
var _on_portrait: Callable = Callable()
var _portrait_fired: bool = false
var _skip_requested: bool = false


static func clamp_rarity(r: int) -> int:
	return clampi(r, 2, 4)


static func duration_for(table: Dictionary, r: int) -> float:
	var key: int = clamp_rarity(r)
	return float(table.get(key, table.get(3, 0.3)))


static func glow_alpha_for(r: int) -> float:
	return float(GLOW_ALPHA.get(clamp_rarity(r), 0.55))


func bind(
	host: Node,
	dim: CanvasItem,
	panel: CanvasItem,
	glow: CanvasItem,
	invite: TextureRect,
	flash: CanvasItem,
	portrait: CanvasItem,
	labels: Array,
	tex_sealed: Texture2D,
	tex_sealed_star2: Texture2D,
	tex_opening: Texture2D
) -> void:
	_host = host
	_dim = dim
	_panel = panel
	_glow = glow
	_invite = invite
	_flash = flash
	_portrait = portrait
	_labels = labels
	_tex_sealed = tex_sealed
	_tex_sealed_star2 = tex_sealed_star2
	_tex_opening = tex_opening


func kill() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	phase = Phase.IDLE
	_skip_requested = false
	_portrait_fired = false
	_on_portrait = Callable()


func request_skip() -> bool:
	## 演出中なら最終状態へジャンプ。完了後は false（dismiss 側で扱う）。
	if phase == Phase.IDLE or phase == Phase.DONE:
		return false
	_skip_requested = true
	_finish_immediately()
	return true


func play(rarity_in: int, on_done: Callable, on_portrait: Callable = Callable()) -> void:
	kill()
	rarity = clamp_rarity(rarity_in)
	_on_done = on_done
	_on_portrait = on_portrait
	_portrait_fired = false
	phase = Phase.SEALED
	_reset_visuals()
	if _invite != null:
		_invite.pivot_offset = _invite.custom_minimum_size * 0.5
		_invite.texture = _tex_sealed_star2 if rarity <= 2 else _tex_sealed
		_invite.visible = true
		_invite.modulate = Color(1, 1, 1, 0)
		_invite.scale = Vector2(0.85, 0.85)
	if _portrait is Control:
		(_portrait as Control).pivot_offset = (_portrait as Control).custom_minimum_size * 0.5
	if _glow != null:
		_glow.visible = true
		_glow.modulate = Color(1, 1, 1, 0)
	if _flash != null:
		_flash.visible = false
	if _portrait != null:
		_portrait.visible = false
	for lab in _labels:
		if lab != null:
			lab.visible = false

	_tween = _host.create_tween()
	_tween.set_parallel(false)
	var d_seal: float = duration_for(DUR_SEALED, rarity)
	var d_open: float = duration_for(DUR_OPENING, rarity)
	var d_port: float = duration_for(DUR_PORTRAIT, rarity)
	var glow_a: float = glow_alpha_for(rarity)

	_tween.tween_property(_dim, "modulate:a", 1.0, 0.18)
	_tween.parallel().tween_property(_panel, "modulate:a", 1.0, 0.16)
	_tween.tween_property(_invite, "modulate:a", 1.0, d_seal * 0.55)
	_tween.parallel().tween_property(_invite, "scale", Vector2.ONE, d_seal).set_trans(Tween.TRANS_BACK)
	_tween.tween_callback(func() -> void:
		phase = Phase.OPENING
		if _invite != null and _tex_opening != null:
			_invite.texture = _tex_opening
	)
	_tween.tween_property(_glow, "modulate:a", glow_a, d_open * 0.45)
	_tween.parallel().tween_property(_invite, "scale", Vector2(1.06, 1.06), d_open * 0.5)
	_tween.tween_property(_invite, "scale", Vector2.ONE, d_open * 0.35)
	_tween.tween_callback(func() -> void:
		phase = Phase.PORTRAIT
		if _invite != null:
			_invite.visible = false
		if _flash != null:
			_flash.visible = false
		if _portrait != null:
			_portrait.visible = true
			_portrait.scale = Vector2(0.55, 0.55)
			_portrait.modulate.a = 0.0
		_fire_portrait()
	)
	_tween.tween_property(_portrait, "scale", Vector2.ONE, d_port).set_trans(Tween.TRANS_BACK)
	_tween.parallel().tween_property(_portrait, "modulate:a", 1.0, d_port * 0.85)
	_tween.tween_callback(func() -> void:
		_complete()
	)


func _reset_visuals() -> void:
	if _dim != null:
		_dim.modulate = Color(1, 1, 1, 0)
	if _panel != null:
		_panel.modulate = Color(1, 1, 1, 0)
	if _glow != null:
		_glow.modulate = Color(1, 1, 1, 0)
		_glow.visible = false
	if _invite != null:
		_invite.visible = false
		_invite.scale = Vector2.ONE
		_invite.modulate = Color(1, 1, 1, 1)
	if _flash != null:
		_flash.visible = false
	if _portrait != null:
		_portrait.visible = false
		_portrait.scale = Vector2.ONE
		_portrait.modulate = Color(1, 1, 1, 1)
	for lab in _labels:
		if lab != null:
			lab.visible = false


func _finish_immediately() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = null
	if _dim != null:
		_dim.modulate = Color(1, 1, 1, 1)
	if _panel != null:
		_panel.modulate = Color(1, 1, 1, 1)
	if _glow != null:
		_glow.visible = true
		_glow.modulate = Color(1, 1, 1, glow_alpha_for(rarity))
	if _invite != null:
		_invite.visible = false
	if _flash != null:
		_flash.visible = false
	if _portrait != null:
		_portrait.visible = true
		_portrait.scale = Vector2.ONE
		_portrait.modulate = Color(1, 1, 1, 1)
	_fire_portrait()
	_complete()


func _fire_portrait() -> void:
	if _portrait_fired:
		return
	_portrait_fired = true
	if _on_portrait.is_valid():
		_on_portrait.call()


func _complete() -> void:
	phase = Phase.DONE
	for lab in _labels:
		if lab == null:
			continue
		## 空文言のバナー等は出さない（限界突破時の「重ねた推薦」撤去など）。
		if lab is Label and str((lab as Label).text).is_empty():
			lab.visible = false
		else:
			lab.visible = true
	if _on_done.is_valid():
		_on_done.call()
