class_name CombatVfxManager
extends RefCounted

## 状態異常・属性の戦闘 VFX（P3-VFX-STATUS-001）。
## 付与バースト（ワンショット CPUParticles2D）と常駐オーラを管理する。

const AURA_STATUS_IDS: Array[String] = [
	"poison", "chill", "shock", "ignite", "curse", "bleed", "stun", "fear",
]

const STATUS_COLOR: Dictionary = {
	"poison": Color(0.25, 0.75, 0.3),
	"chill": Color(0.35, 0.65, 0.95),
	"shock": Color(0.95, 0.85, 0.2),
	"ignite": Color(0.95, 0.4, 0.15),
	"curse": Color(0.55, 0.25, 0.75),
	"stun": Color(0.7, 0.7, 0.75),
	"fear": Color(0.55, 0.35, 0.6),
	"vulnerable": Color(0.95, 0.45, 0.45),
	"armor_break": Color(0.8, 0.6, 0.3),
	"mark": Color(0.95, 0.35, 0.55),
	"empower": Color(0.95, 0.55, 0.2),
	"guard": Color(0.4, 0.55, 0.85),
	"bleed": Color(0.9, 0.28, 0.28),
}

## DoT ダメージテロップ用（視認性優先の明るめ色）。
const DOT_TELOP_COLOR: Dictionary = {
	"poison": Color(0.42, 0.96, 0.38),
	"ignite": Color(0.98, 0.32, 0.22),
	"bleed": Color(0.95, 0.35, 0.35),
	"chill": Color(0.55, 0.82, 1.0),
	"shock": Color(0.98, 0.9, 0.35),
	"curse": Color(0.78, 0.48, 0.95),
}

## 状態異常中ユニットのスプライト着色（複数時は優先度で1色）。
const STATUS_UNIT_TINT: Dictionary = {
	"stun": Color(0.82, 0.82, 0.88),
	"fear": Color(0.78, 0.62, 0.82),
	"ignite": Color(1.0, 0.62, 0.52),
	"poison": Color(0.72, 1.0, 0.72),
	"bleed": Color(1.0, 0.72, 0.72),
	"chill": Color(0.72, 0.88, 1.0),
	"shock": Color(1.0, 0.95, 0.62),
	"curse": Color(0.82, 0.62, 0.95),
	"vulnerable": Color(1.0, 0.78, 0.78),
	"armor_break": Color(0.95, 0.82, 0.62),
	"mark": Color(1.0, 0.72, 0.82),
}

const STATUS_TINT_PRIORITY: Array[String] = [
	"stun", "fear", "ignite", "poison", "bleed", "chill", "shock", "curse", "vulnerable", "armor_break", "mark",
]

const STATUS_ELEMENT: Dictionary = {
	"ignite": "fire",
	"chill": "ice",
	"shock": "thunder",
	"curse": "dark",
}

var _aura_nodes: Dictionary = {}  # unit_key -> { status_id: CPUParticles2D }


static func status_color(status_id: String) -> Color:
	return STATUS_COLOR.get(status_id, Color(0.75, 0.75, 0.75))


static func dot_telop_color(status_id: String) -> Color:
	if status_id.is_empty():
		return Color(1.0, 0.55, 0.2)
	return DOT_TELOP_COLOR.get(status_id, status_color(status_id).lightened(0.25))


static func unit_tint_from_statuses(statuses: Array) -> Color:
	var active: Dictionary = {}
	for entry: Variant in statuses:
		if entry is Dictionary:
			var effect_id: String = str(entry.get("effect_id", ""))
			if not effect_id.is_empty():
				active[effect_id] = true
	for effect_id: String in STATUS_TINT_PRIORITY:
		if active.has(effect_id):
			return STATUS_UNIT_TINT.get(effect_id, Color.WHITE)
	return Color.WHITE


static func is_buff_status(status_id: String) -> bool:
	if status_id.is_empty():
		return false
	if status_id == "empower" or status_id == "guard":
		return true
	var data: Resource = DataRegistry.get_status_effect(status_id)
	if data == null:
		return false
	if str(data.effect_type) == "dot" or float(data.skip_action_chance) > 0.0:
		return false
	if float(data.incoming_damage_multiplier) > 1.0 or float(data.defense_reduction) > 0.0:
		return false
	if float(data.outgoing_damage_multiplier) > 1.0:
		return true
	if float(data.incoming_damage_multiplier) > 0.0 and float(data.incoming_damage_multiplier) < 1.0:
		return true
	return false


static func apply_flash_color(status_id: String) -> Color:
	var base: Color = status_color(status_id)
	if is_buff_status(status_id):
		return base.lightened(0.35)
	return base.lightened(0.12)


static func status_element(status_id: String) -> String:
	return str(STATUS_ELEMENT.get(status_id, ""))


func clear_all() -> void:
	for unit_key: String in _aura_nodes.keys():
		var per_status: Dictionary = _aura_nodes[unit_key]
		for status_id: String in per_status.keys():
			var node: Node = per_status[status_id]
			if is_instance_valid(node):
				node.queue_free()
	_aura_nodes.clear()


func spawn_apply_burst(scene_root: Node, world_pos: Vector2, status_id: String) -> void:
	if scene_root == null or status_id.is_empty():
		return
	var parts := _build_burst_particles(status_color(status_id), _apply_burst_profile(status_id))
	parts.global_position = world_pos
	scene_root.add_child(parts)
	parts.emitting = true
	parts.finished.connect(parts.queue_free)


func spawn_dot_tick(scene_root: Node, world_pos: Vector2, status_id: String) -> void:
	if scene_root == null or status_id.is_empty():
		return
	var color: Color = status_color(status_id)
	color.a = 0.85
	var parts := _build_burst_particles(color, _dot_tick_profile(status_id))
	parts.global_position = world_pos + Vector2(0.0, -8.0)
	parts.amount = maxi(6, parts.amount / 2)
	scene_root.add_child(parts)
	parts.emitting = true
	parts.finished.connect(parts.queue_free)


func sync_unit_auras(
	unit_key: String,
	anchor: Node2D,
	statuses: Array,
	anchor_visible: bool = true
) -> void:
	if unit_key.is_empty() or anchor == null or not is_instance_valid(anchor):
		return
	if not anchor_visible or not anchor.visible:
		_remove_unit_auras(unit_key)
		return
	var active_ids: Dictionary = {}
	for entry: Variant in statuses:
		if entry is Dictionary:
			var effect_id: String = str(entry.get("effect_id", ""))
			if effect_id in AURA_STATUS_IDS:
				active_ids[effect_id] = true
	if active_ids.is_empty():
		_remove_unit_auras(unit_key)
		return
	if not _aura_nodes.has(unit_key):
		_aura_nodes[unit_key] = {}
	var per_status: Dictionary = _aura_nodes[unit_key]
	var host: Node2D = _ensure_aura_host(anchor)
	for existing_id: String in per_status.keys():
		if not active_ids.has(existing_id):
			var stale: Node = per_status[existing_id]
			if is_instance_valid(stale):
				stale.queue_free()
			per_status.erase(existing_id)
	for effect_id: String in active_ids.keys():
		if per_status.has(effect_id):
			var live: Node = per_status[effect_id]
			if is_instance_valid(live):
				continue
			per_status.erase(effect_id)
		var aura := _build_loop_aura(effect_id)
		host.add_child(aura)
		per_status[effect_id] = aura
		aura.emitting = true


func _remove_unit_auras(unit_key: String) -> void:
	if not _aura_nodes.has(unit_key):
		return
	var per_status: Dictionary = _aura_nodes[unit_key]
	for status_id: String in per_status.keys():
		var node: Node = per_status[status_id]
		if is_instance_valid(node):
			node.queue_free()
	_aura_nodes.erase(unit_key)


func _ensure_aura_host(anchor: Node2D) -> Node2D:
	var host: Node2D = anchor.get_node_or_null("StatusAuraHost") as Node2D
	if host == null:
		host = Node2D.new()
		host.name = "StatusAuraHost"
		host.position = Vector2(0.0, -18.0)
		host.z_index = 4
		anchor.add_child(host)
	return host


func _apply_burst_profile(status_id: String) -> Dictionary:
	match status_id:
		"ignite":
			return {"amount": 28, "spread": 35.0, "velocity_min": 60.0, "velocity_max": 140.0, "gravity_y": -40.0}
		"chill":
			return {"amount": 24, "spread": 50.0, "velocity_min": 30.0, "velocity_max": 90.0, "gravity_y": 35.0}
		"shock":
			return {"amount": 32, "spread": 180.0, "velocity_min": 90.0, "velocity_max": 220.0, "gravity_y": 0.0}
		"poison":
			return {"amount": 26, "spread": 40.0, "velocity_min": 40.0, "velocity_max": 110.0, "gravity_y": -25.0}
		"curse", "fear":
			return {"amount": 22, "spread": 120.0, "velocity_min": 50.0, "velocity_max": 130.0, "gravity_y": 20.0}
		"stun":
			return {"amount": 30, "spread": 180.0, "velocity_min": 70.0, "velocity_max": 160.0, "gravity_y": -10.0}
		"bleed":
			return {"amount": 20, "spread": 55.0, "velocity_min": 50.0, "velocity_max": 120.0, "gravity_y": 90.0}
		_:
			return {"amount": 20, "spread": 80.0, "velocity_min": 60.0, "velocity_max": 150.0, "gravity_y": 30.0}


func _dot_tick_profile(status_id: String) -> Dictionary:
	var profile: Dictionary = _apply_burst_profile(status_id)
	profile["amount"] = maxi(8, int(profile.get("amount", 16)) / 2)
	profile["velocity_max"] = float(profile.get("velocity_max", 120.0)) * 0.65
	return profile


func _aura_profile(status_id: String) -> Dictionary:
	match status_id:
		"ignite":
			return {"amount": 10, "lifetime": 0.55, "velocity_min": 18.0, "velocity_max": 42.0, "gravity_y": -35.0, "spread": 25.0}
		"chill":
			return {"amount": 8, "lifetime": 0.9, "velocity_min": 8.0, "velocity_max": 22.0, "gravity_y": 18.0, "spread": 40.0}
		"shock":
			return {"amount": 12, "lifetime": 0.35, "velocity_min": 30.0, "velocity_max": 70.0, "gravity_y": 0.0, "spread": 180.0}
		"poison":
			return {"amount": 9, "lifetime": 0.75, "velocity_min": 10.0, "velocity_max": 28.0, "gravity_y": -22.0, "spread": 30.0}
		"curse":
			return {"amount": 8, "lifetime": 0.8, "velocity_min": 12.0, "velocity_max": 30.0, "gravity_y": 15.0, "spread": 120.0}
		"bleed":
			return {"amount": 7, "lifetime": 0.65, "velocity_min": 20.0, "velocity_max": 45.0, "gravity_y": 55.0, "spread": 35.0}
		"stun":
			return {"amount": 10, "lifetime": 0.45, "velocity_min": 25.0, "velocity_max": 55.0, "gravity_y": -5.0, "spread": 180.0}
		"fear":
			return {"amount": 8, "lifetime": 0.7, "velocity_min": 14.0, "velocity_max": 36.0, "gravity_y": 10.0, "spread": 100.0}
		_:
			return {"amount": 8, "lifetime": 0.6, "velocity_min": 12.0, "velocity_max": 30.0, "gravity_y": 0.0, "spread": 60.0}


func _build_burst_particles(color: Color, profile: Dictionary) -> CPUParticles2D:
	var parts := CPUParticles2D.new()
	parts.one_shot = true
	parts.explosiveness = 0.9
	parts.lifetime = 0.55
	parts.amount = int(profile.get("amount", 20))
	parts.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	parts.emission_sphere_radius = 10.0
	parts.direction = Vector2(0.0, -1.0)
	parts.spread = float(profile.get("spread", 80.0))
	parts.gravity = Vector2(0.0, float(profile.get("gravity_y", 30.0)))
	parts.initial_velocity_min = float(profile.get("velocity_min", 60.0))
	parts.initial_velocity_max = float(profile.get("velocity_max", 150.0))
	parts.scale_amount_min = 2.0
	parts.scale_amount_max = 3.5
	parts.modulate = color
	return parts


func _build_loop_aura(status_id: String) -> CPUParticles2D:
	var profile: Dictionary = _aura_profile(status_id)
	var parts := CPUParticles2D.new()
	parts.one_shot = false
	parts.explosiveness = 0.0
	parts.lifetime = float(profile.get("lifetime", 0.6))
	parts.amount = int(profile.get("amount", 8))
	parts.preprocess = parts.lifetime
	parts.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	parts.emission_sphere_radius = 14.0
	parts.direction = Vector2(0.0, -1.0)
	parts.spread = float(profile.get("spread", 60.0))
	parts.gravity = Vector2(0.0, float(profile.get("gravity_y", 0.0)))
	parts.initial_velocity_min = float(profile.get("velocity_min", 12.0))
	parts.initial_velocity_max = float(profile.get("velocity_max", 30.0))
	parts.scale_amount_min = 1.5
	parts.scale_amount_max = 2.5
	parts.modulate = status_color(status_id)
	if status_id == "shock":
		parts.hue_variation_min = -0.05
		parts.hue_variation_max = 0.05
	return parts
