class_name ExplorationSkills
extends RefCounted

## 探索スキル群（P3-D117）。編成ロールが特定部屋で自動発動し、報酬/安全にボーナス。
## 戦闘スキルとは別枠。ロール判定は CombatSynergy と同型（1人以上で発動可）。

const TRAP_CHANCE: float = 0.20
const TRAP_DAMAGE: int = 8

const _SKILLS: Dictionary = {
	"gather": {
		"label": "採取",
		"roles": ["scout", "support"],
		"room_types": [Enums.RoomType.EVENT],
	},
	"mine": {
		"label": "採掘",
		"roles": ["scout", "dps"],
		"room_types": [Enums.RoomType.TREASURE],
	},
	"lockpick": {
		"label": "鍵開け",
		"roles": ["scout", "dps"],
		"room_types": [Enums.RoomType.TREASURE],
	},
	"decipher": {
		"label": "解読",
		"roles": ["support", "scout"],
		"room_types": [Enums.RoomType.EVENT],
		"outcome_type": "lore",
	},
	"disarm": {
		"label": "罠解除",
		"roles": ["scout", "tank"],
		"room_types": [Enums.RoomType.COMBAT, Enums.RoomType.ELITE],
	},
}

static func skill_ids() -> Array:
	return _SKILLS.keys()

static func label(skill_id: String) -> String:
	return str(_SKILLS.get(skill_id, {}).get("label", skill_id))

static func has_skill_for_room(members: Array, skill_id: String, room_type: int) -> bool:
	var def: Dictionary = _SKILLS.get(skill_id, {})
	if def.is_empty():
		return false
	if room_type not in def.get("room_types", []):
		return false
	return _roles_match(def.get("roles", []), _party_roles(members))

static func can_disarm(members: Array) -> bool:
	return has_skill_for_room(members, "disarm", Enums.RoomType.COMBAT)

static func should_roll_trap() -> bool:
	return randf() < TRAP_CHANCE

static func trap_damage() -> int:
	return TRAP_DAMAGE

# 装備画面用：編成で使える探索スキル一覧。
static func active_labels(members: Array) -> PackedStringArray:
	var roles: Dictionary = _party_roles(members)
	var out: PackedStringArray = []
	for skill_id: String in _SKILLS:
		if _roles_match(_SKILLS[skill_id].get("roles", []), roles):
			out.append(label(skill_id))
	return out

static func _party_roles(members: Array) -> Dictionary:
	var counts: Dictionary = {}
	for m in members:
		if m == null:
			continue
		var role: String = str(JobStatCalculator.get_member_modifiers(m).get("role", ""))
		if role.is_empty():
			continue
		counts[role] = int(counts.get(role, 0)) + 1
	return counts

static func _roles_match(required: Array, roles_present: Dictionary) -> bool:
	for r in required:
		if int(roles_present.get(str(r), 0)) >= 1:
			return true
	return false
