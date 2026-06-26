class_name StatusResolver
extends RefCounted

const MAX_DISTINCT_STATUSES: int = 3

var _active: Dictionary = {}  # unit_id -> Array[StatusInstance]

func clear_all() -> void:
	_active.clear()

func apply_status(
	unit_id: String,
	effect_id: String,
	stacks_to_add: int = 1,
	source_attack: int = 0
) -> bool:
	if effect_id.is_empty():
		return false
	var effect: Resource = DataRegistry.get_status_effect(effect_id)
	if effect == null:
		return false
	stacks_to_add = maxi(1, stacks_to_add)
	if not _active.has(unit_id):
		_active[unit_id] = []
	var instances: Array = _active[unit_id]
	for inst: StatusInstance in instances:
		if inst.effect_id == effect_id:
			inst.stacks = mini(effect.max_stacks, inst.stacks + stacks_to_add)
			inst.remaining_ticks = effect.duration_ticks
			if source_attack > 0:
				inst.source_attack = source_attack
			return true
	if instances.size() >= MAX_DISTINCT_STATUSES:
		return false
	var new_inst := StatusInstance.new()
	new_inst.effect_id = effect_id
	new_inst.stacks = mini(stacks_to_add, effect.max_stacks)
	new_inst.remaining_ticks = effect.duration_ticks
	new_inst.source_attack = source_attack
	instances.append(new_inst)
	return true

func tick_unit(unit_id: String) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	if not _active.has(unit_id):
		return results
	var instances: Array = _active[unit_id]
	var survivors: Array = []
	for inst: StatusInstance in instances:
		var effect: Resource = DataRegistry.get_status_effect(inst.effect_id)
		if effect == null:
			continue
		if effect.effect_type == "dot":
			var dmg: int = 0
			if effect.dot_percent_of_attack > 0.0:
				dmg += int(inst.source_attack * effect.dot_percent_of_attack * inst.stacks)
			if effect.dot_flat > 0:
				dmg += effect.dot_flat * inst.stacks
			if dmg > 0:
				results.append({
					"effect_id": inst.effect_id,
					"display_name": effect.display_name,
					"damage": dmg,
					"unit_id": unit_id,
				})
		inst.remaining_ticks -= 1
		if inst.remaining_ticks > 0:
			survivors.append(inst)
	if survivors.is_empty():
		_active.erase(unit_id)
	else:
		_active[unit_id] = survivors
	return results

func should_skip_action(unit_id: String) -> bool:
	if not _active.has(unit_id):
		return false
	for inst: StatusInstance in _active[unit_id]:
		var effect: Resource = DataRegistry.get_status_effect(inst.effect_id)
		if effect == null:
			continue
		if effect.skip_action_chance > 0.0 and randf() < effect.skip_action_chance:
			return true
		if effect.effect_type == "stat_mod" and effect.interval_multiplier > 1.0:
			if randf() < 0.5:
				return true
	return false

func get_skip_action_label(unit_id: String) -> String:
	if not _active.has(unit_id):
		return ""
	for inst: StatusInstance in _active[unit_id]:
		var effect: Resource = DataRegistry.get_status_effect(inst.effect_id)
		if effect == null:
			continue
		if effect.skip_action_chance > 0.0 or (
			effect.effect_type == "stat_mod" and effect.interval_multiplier > 1.0
		):
			return effect.display_name
	return ""

func get_outgoing_damage_multiplier(unit_id: String) -> float:
	var mult: float = 1.0
	if not _active.has(unit_id):
		return mult
	for inst: StatusInstance in _active[unit_id]:
		var effect: Resource = DataRegistry.get_status_effect(inst.effect_id)
		if effect == null:
			continue
		if effect.outgoing_damage_multiplier > 0.0:
			mult *= effect.outgoing_damage_multiplier
	return mult

func get_incoming_damage_multiplier(unit_id: String) -> float:
	var mult: float = 1.0
	if not _active.has(unit_id):
		return mult
	for inst: StatusInstance in _active[unit_id]:
		var effect: Resource = DataRegistry.get_status_effect(inst.effect_id)
		if effect == null:
			continue
		if effect.incoming_damage_multiplier > 0.0:
			mult *= effect.incoming_damage_multiplier
	return mult

func should_skip_enemy_action(unit_id: String = "enemy") -> bool:
	return should_skip_action(unit_id)

func get_active_status_summary(unit_id: String) -> String:
	if not _active.has(unit_id):
		return ""
	var instances: Array = _active[unit_id]
	if instances.is_empty():
		return ""
	var parts: PackedStringArray = []
	for inst: StatusInstance in instances:
		var effect: Resource = DataRegistry.get_status_effect(inst.effect_id)
		var label: String = inst.effect_id
		if effect != null:
			label = effect.display_name
		if inst.stacks > 1:
			label += "×%d" % inst.stacks
		parts.append(label)
	return " ".join(parts)

func get_active_status_list(unit_id: String) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	if not _active.has(unit_id):
		return results
	for inst: StatusInstance in _active[unit_id]:
		var effect: Resource = DataRegistry.get_status_effect(inst.effect_id)
		var display_name: String = inst.effect_id
		if effect != null:
			display_name = effect.display_name
		results.append({
			"effect_id": inst.effect_id,
			"display_name": display_name,
			"stacks": inst.stacks,
			"remaining_ticks": inst.remaining_ticks,
		})
	return results
