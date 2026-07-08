class_name CombatRelics
extends RefCounted

## レリック互換ファサード（P3-RELIC-PASSIVE）。定義本体は CombatPassives。

const NONE_ID: String = ""

static func all_ids() -> Array:
	return CombatPassives.relic_passive_ids()

static func normalize_id(relic_id: String) -> String:
	return CombatPassives.migrate_relic_passive_id(relic_id)

static func display_name(relic_id: String) -> String:
	return CombatPassives.relic_display_name(relic_id)

static func description(relic_id: String) -> String:
	return CombatPassives.relic_description(relic_id)

static func relic_list() -> Array:
	var out: Array = []
	out.append({"id": "", "display_name": display_name("")})
	for rid: String in CombatPassives.relic_passive_ids():
		out.append({"id": rid, "display_name": display_name(rid)})
	return out

static func effects_for(relic_id: String) -> Dictionary:
	var eff: Dictionary = {"outgoing_mult": 1.0, "incoming_mult": 1.0, "speed_mult": 1.0}
	var pid: String = normalize_id(relic_id)
	if pid.is_empty():
		return eff
	var def: Dictionary = CombatPassives.get_def(pid)
	if def.is_empty():
		return eff
	for key: String in eff.keys():
		if def.has(key):
			eff[key] = float(def[key])
	return eff

static func has_trigger(relic_id: String) -> bool:
	var def: Dictionary = CombatPassives.get_def(normalize_id(relic_id))
	return not str(def.get("trigger", "")).is_empty()

static func trigger_def(relic_id: String) -> Dictionary:
	var pid: String = normalize_id(relic_id)
	if pid.is_empty() or not has_trigger(pid):
		return {}
	var out: Dictionary = CombatPassives.get_def(pid).duplicate()
	out["id"] = pid
	return out
