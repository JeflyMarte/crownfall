class_name ExplorationSkills
extends RefCounted

## 探索スキル群（P3-D117）。編成ロールが特定部屋で自動発動し、報酬/安全にボーナス。
## 戦闘スキルとは別枠。ロール判定は CombatSynergy と同型（1人以上で発動可）。
## 罠ダメージは最大HP割合（P3-TRAP-PCT-001 → P3-BAL-TRAP-TIER-001）。
## 報酬4種はオミット（P3-BAL-OMIT-EXPLORE-REWARD-001）。罠解除のみ有効。

## 後方互換: ハード帯の探索罠発生率。
const TRAP_CHANCE: float = 0.20

## 採取／採掘／鍵開け／解読。false でプレイから外す（罠解除は別）。
const REWARD_BONUSES_ENABLED: bool = false
const REWARD_SKILL_IDS: Array[String] = ["gather", "mine", "lockpick", "decipher"]

const _SKILLS: Dictionary = {
	"gather": {
		"label": "採取",
		"roles": ["scout", "support"],
		"room_types": [],
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

static func is_reward_skill(skill_id: String) -> bool:
	return skill_id in REWARD_SKILL_IDS

static func has_skill_for_room(members: Array, skill_id: String, room_type: int) -> bool:
	if is_reward_skill(skill_id) and not REWARD_BONUSES_ENABLED:
		return false
	var def: Dictionary = _SKILLS.get(skill_id, {})
	if def.is_empty():
		return false
	if room_type not in def.get("room_types", []):
		return false
	return _roles_match(def.get("roles", []), _party_roles(members))

static func can_disarm(members: Array) -> bool:
	return has_skill_for_room(members, "disarm", Enums.RoomType.COMBAT)

static func should_roll_trap(tier: int = 0) -> bool:
	return randf() < BalanceConfig.trap_explore_chance(tier)

static func roll_trap_aoe(rng: RandomNumberGenerator = null, tier: int = 0) -> bool:
	var roll: float = rng.randf() if rng != null else randf()
	return roll < BalanceConfig.trap_aoe_chance(tier)

static func trap_max_hp_fraction(trap_room: bool, aoe: bool, tier: int = 0) -> float:
	if trap_room:
		return (
			BalanceConfig.trap_max_hp_frac_room_aoe(tier)
			if aoe
			else BalanceConfig.trap_max_hp_frac_room_single(tier)
		)
	return (
		BalanceConfig.trap_max_hp_frac_combat_aoe(tier)
		if aoe
		else BalanceConfig.trap_max_hp_frac_combat_single(tier)
	)

## 対象の最大HPに対する罠ダメージ（最低1）。
static func trap_damage_for_max_hp(
	max_hp: int, trap_room: bool, aoe: bool, tier: int = 0
) -> int:
	var frac: float = trap_max_hp_fraction(trap_room, aoe, tier)
	return maxi(1, int(round(float(maxi(1, max_hp)) * frac)))

## 被弾時の状態異常 id（空文字＝付与なし）。毒／出血から抽選。
static func roll_trap_status(
	tier: int = 0, rng: RandomNumberGenerator = null
) -> String:
	var chance: float = BalanceConfig.trap_status_chance(tier)
	if chance <= 0.0:
		return ""
	var roll: float = rng.randf() if rng != null else randf()
	if roll >= chance:
		return ""
	var pool: Array[String] = BalanceConfig.TRAP_STATUS_POOL
	if pool.is_empty():
		return ""
	var idx: int = rng.randi() % pool.size() if rng != null else randi() % pool.size()
	return str(pool[idx])

# 装備画面用：編成で使える探索スキル一覧。
static func active_labels(members: Array) -> PackedStringArray:
	var roles: Dictionary = _party_roles(members)
	var out: PackedStringArray = []
	for skill_id: String in _SKILLS:
		if is_reward_skill(skill_id) and not REWARD_BONUSES_ENABLED:
			continue
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
