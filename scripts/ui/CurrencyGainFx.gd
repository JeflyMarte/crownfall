class_name CurrencyGainFx
extends RefCounted

## 報酬受取時の「チャリン」演出。アイコンが起点から通貨チップへ飛び込む。

const ICON_PX: float = 28.0
const MAX_MOTES_PER_KIND: int = 6
const FLIGHT_SEC: float = 0.55
const STAGGER_SEC: float = 0.07
const ARC_PX: float = 52.0


## rewards: [{ "texture": Texture2D, "target": Control, "amount": int }, ...]
static func play(
	host: Control,
	from_global: Vector2,
	rewards: Array,
	on_complete: Callable = Callable()
) -> void:
	if host == null or not host.is_inside_tree():
		if on_complete.is_valid():
			on_complete.call()
		return
	var layer := Control.new()
	layer.name = "CurrencyGainFxLayer"
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.z_index = 80
	host.add_child(layer)

	var state: Dictionary = {"finished": 0, "expected": 0, "on_complete": on_complete}
	var inv: Transform2D = layer.get_global_transform_with_canvas().affine_inverse()
	var from_local: Vector2 = inv * from_global

	for raw in rewards:
		if not raw is Dictionary:
			continue
		var entry: Dictionary = raw
		var tex: Texture2D = entry.get("texture") as Texture2D
		var target: Control = entry.get("target") as Control
		var amount: int = maxi(0, int(entry.get("amount", 0)))
		if tex == null or target == null or amount <= 0:
			continue
		var count: int = mini(MAX_MOTES_PER_KIND, maxi(1, amount))
		state["expected"] = int(state["expected"]) + count
		var to_local: Vector2 = inv * _control_center_global(target)
		for i in count:
			_spawn_mote(layer, tex, from_local, to_local, i, count, target, state)

	if int(state["expected"]) <= 0:
		layer.queue_free()
		if on_complete.is_valid():
			on_complete.call()


static func _spawn_mote(
	layer: Control,
	tex: Texture2D,
	from_local: Vector2,
	to_local: Vector2,
	index: int,
	total: int,
	target: Control,
	state: Dictionary
) -> void:
	var half := Vector2(ICON_PX * 0.5, ICON_PX * 0.5)
	var icon := TextureRect.new()
	icon.texture = tex
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.custom_minimum_size = Vector2(ICON_PX, ICON_PX)
	icon.size = Vector2(ICON_PX, ICON_PX)
	icon.pivot_offset = half
	icon.modulate = Color(1.2, 1.1, 0.85, 0.0)
	layer.add_child(icon)

	var spread: float = (float(index) - float(total - 1) * 0.5) * 16.0
	var p0: Vector2 = from_local + Vector2(spread, -8.0 - float(index % 3) * 5.0)
	var p2: Vector2 = to_local
	var p1: Vector2 = p0.lerp(p2, 0.4) + Vector2(spread * 0.4, -ARC_PX - float(index % 2) * 12.0)
	icon.position = p0 - half
	icon.scale = Vector2(0.7, 0.7)

	var delay: float = float(index) * STAGGER_SEC
	var sign_rot: float = 1.0 if index % 2 == 0 else -1.0
	var tw: Tween = layer.create_tween()
	tw.tween_interval(delay)
	tw.tween_property(icon, "modulate:a", 1.0, 0.08)
	tw.parallel().tween_property(icon, "scale", Vector2(1.2, 1.2), 0.12).set_trans(
		Tween.TRANS_BACK
	).set_ease(Tween.EASE_OUT)
	tw.tween_method(
		_make_flight_updater(icon, p0, p1, p2, half, sign_rot),
		0.0,
		1.0,
		FLIGHT_SEC
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(icon, "scale", Vector2(0.5, 0.5), FLIGHT_SEC).set_delay(0.1)
	tw.tween_callback(_make_finish_callback(layer, icon, target, state))


static func _make_flight_updater(
	icon: TextureRect,
	p0: Vector2,
	p1: Vector2,
	p2: Vector2,
	half: Vector2,
	sign_rot: float
) -> Callable:
	return func(t: float) -> void:
		if not is_instance_valid(icon):
			return
		var u: float = 1.0 - t
		var pos: Vector2 = u * u * p0 + 2.0 * u * t * p1 + t * t * p2
		icon.position = pos - half
		icon.rotation = lerpf(-0.3, 0.4, t) * sign_rot


static func _make_finish_callback(
	layer: Control,
	icon: TextureRect,
	target: Control,
	state: Dictionary
) -> Callable:
	return func() -> void:
		_pulse_target(target)
		if is_instance_valid(icon):
			icon.queue_free()
		state["finished"] = int(state["finished"]) + 1
		if int(state["finished"]) < int(state["expected"]):
			return
		if is_instance_valid(layer):
			layer.queue_free()
		var done: Variant = state.get("on_complete", null)
		if done is Callable and (done as Callable).is_valid():
			(done as Callable).call()


static func _control_center_global(ctrl: Control) -> Vector2:
	if ctrl == null:
		return Vector2.ZERO
	var r: Rect2 = ctrl.get_global_rect()
	return r.position + r.size * 0.5


static func _pulse_target(target: Control) -> void:
	if target == null or not is_instance_valid(target) or not target.is_inside_tree():
		return
	var base: Vector2 = target.scale
	var tw: Tween = target.create_tween()
	tw.tween_property(target, "scale", base * 1.14, 0.07).set_trans(Tween.TRANS_BACK).set_ease(
		Tween.EASE_OUT
	)
	tw.tween_property(target, "scale", base, 0.12).set_trans(Tween.TRANS_SINE).set_ease(
		Tween.EASE_IN_OUT
	)
