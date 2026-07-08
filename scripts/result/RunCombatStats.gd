class_name RunCombatStats
extends RefCounted

## 1 ランの味方戦闘統計（P3-UX-RESULT-003）。MVP 画面用。


func reset() -> void:
	_members.clear()


func record_damage(
	member_id: String,
	amount: int,
	skill_id: String = "",
	skill_name: String = ""
) -> void:
	if member_id.is_empty() or amount <= 0:
		return
	var row: Dictionary = _ensure_member(member_id)
	row["damage_total"] = int(row["damage_total"]) + amount
	if amount > int(row["damage_max_hit"]):
		row["damage_max_hit"] = amount
		row["damage_max_skill_id"] = skill_id
		row["damage_max_skill_name"] = skill_name


func record_heal(member_id: String, amount: int) -> void:
	if member_id.is_empty() or amount <= 0:
		return
	var row: Dictionary = _ensure_member(member_id)
	row["heal_total"] = int(row["heal_total"]) + amount


func snapshot() -> Dictionary:
	var out: Dictionary = {}
	for member_id: String in _members.keys():
		out[member_id] = _members[member_id].duplicate(true)
	return out


func _ensure_member(member_id: String) -> Dictionary:
	if not _members.has(member_id):
		_members[member_id] = {
			"damage_total": 0,
			"damage_max_hit": 0,
			"damage_max_skill_id": "",
			"damage_max_skill_name": "",
			"heal_total": 0,
		}
	return _members[member_id]


var _members: Dictionary = {}
