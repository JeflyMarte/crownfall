class_name EngineerTraps
extends RefCounted

## 機巧士の仕掛けトークン（P3-JOB-ENGINEER-001）。HPなし・撃破報酬なし。
## kind: "spike" | "snare" | "break"

const PARTY_CAP: int = 3
## 甲砕中の敵への仕掛け作動ダメージ倍率（P3-JOB-ENGINEER-BAL-001・職固有）
const VS_ARMOR_BREAK_MULT: float = 1.15

## slot -> { kind, fires_left, placer_idx, power, status_id, status_chance }
var _traps: Dictionary = {}
## 設置順（古いものから破棄）
var _order: Array[int] = []


func clear() -> void:
	_traps.clear()
	_order.clear()


func count() -> int:
	return _traps.size()


func has_trap(slot: int) -> bool:
	return _traps.has(slot)


func get_trap(slot: int) -> Dictionary:
	if not _traps.has(slot):
		return {}
	return (_traps[slot] as Dictionary).duplicate()


## 設置。同スロットは上書き。パーティ上限超過時は最古を外す。
func place(
	slot: int,
	kind: String,
	placer_idx: int,
	fires: int,
	power: float,
	status_id: String = "",
	status_chance: float = 0.0
) -> Dictionary:
	if slot < 0 or kind.is_empty() or fires <= 0:
		return {"ok": false}
	if _traps.has(slot):
		_order.erase(slot)
	elif _traps.size() >= PARTY_CAP:
		_evict_oldest()
	_traps[slot] = {
		"kind": kind,
		"fires_left": fires,
		"placer_idx": placer_idx,
		"power": power,
		"status_id": status_id,
		"status_chance": status_chance,
	}
	_order.append(slot)
	return {"ok": true, "kind": kind, "fires_left": fires}


func clear_slot(slot: int) -> void:
	if not _traps.has(slot):
		return
	_traps.erase(slot)
	_order.erase(slot)


## 発火1回。残弾0なら削除。戻り値は発火内容（無ければ empty）。
func fire(slot: int) -> Dictionary:
	if not _traps.has(slot):
		return {}
	var t: Dictionary = _traps[slot]
	var fires: int = int(t.get("fires_left", 0)) - 1
	var result: Dictionary = {
		"kind": str(t.get("kind", "")),
		"placer_idx": int(t.get("placer_idx", -1)),
		"power": float(t.get("power", 0.0)),
		"status_id": str(t.get("status_id", "")),
		"status_chance": float(t.get("status_chance", 0.0)),
		"fires_left": maxi(0, fires),
	}
	if fires <= 0:
		clear_slot(slot)
	else:
		t["fires_left"] = fires
		_traps[slot] = t
	return result


func _evict_oldest() -> void:
	while not _order.is_empty() and _traps.size() >= PARTY_CAP:
		var old_slot: int = int(_order[0])
		_order.remove_at(0)
		_traps.erase(old_slot)


static func kind_from_skill(skill_data: Resource) -> String:
	if skill_data == null:
		return ""
	if skill_data.tags.has("trap_spike"):
		return "spike"
	if skill_data.tags.has("trap_snare"):
		return "snare"
	if skill_data.tags.has("trap_break"):
		return "break"
	return ""


static func fires_for_kind(kind: String) -> int:
	match kind:
		"spike":
			return 4
		"snare":
			return 3
		"break":
			return 3
		_:
			return 0


static func power_for_kind(kind: String) -> float:
	match kind:
		"spike":
			return 0.65
		"snare":
			return 0.25
		"break":
			return 0.50
		_:
			return 0.0


## 甲砕中なら作動威力に乗算する倍率（非甲砕は 1.0）。
static func fire_power_mult_vs_status(has_armor_break: bool) -> float:
	return VS_ARMOR_BREAK_MULT if has_armor_break else 1.0


static func status_for_kind(kind: String) -> Dictionary:
	match kind:
		"snare":
			return {"id": "chill", "chance": 1.0}
		"break":
			return {"id": "armor_break", "chance": 1.0}
		_:
			return {"id": "", "chance": 0.0}
