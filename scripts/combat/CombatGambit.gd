class_name CombatGambit
extends RefCounted

## カスタム戦術（ガンビット）のメタデータ（A1）。

const PLAN_ROW_COUNT: int = 5
const RANGE_VALUE_IDS: Array[String] = ["melee", "mid", "long"]

const SLOT_IDS: Array[String] = ["ultimate", "defend", "skill", "attack"]
const CONDITION_IDS: Array[String] = [
	"always", "self_hp_below", "enemy_is_boss", "enemy_is_elite", "enemy_count_gte",
	"ally_dead", "enemy_has_bleed", "enemy_has_poison", "enemy_has_mark",
	"enemy_has_stun", "enemy_has_vulnerable", "enemy_has_armor_break", "enemy_has_fear",
	"ultimate_ready", "self_range", "ally_injured",
]

const _SLOT_NAMES: Dictionary = {
	"ultimate": "必殺", "defend": "防御", "skill": "スキル", "attack": "通常攻撃",
}
const _CONDITION_NAMES: Dictionary = {
	"always": "常時",
	"self_hp_below": "自HPが%未満",
	"enemy_is_boss": "ボス戦",
	"enemy_is_elite": "エリート戦",
	"enemy_count_gte": "敵数≧",
	"ally_dead": "味方戦闘不能",
	"enemy_has_bleed": "敵が出血",
	"enemy_has_poison": "敵が毒",
	"enemy_has_mark": "敵が標的",
	"enemy_has_stun": "敵がスタン",
	"enemy_has_vulnerable": "敵が脆弱",
	"enemy_has_armor_break": "敵が防御DOWN",
	"enemy_has_fear": "敵が恐怖",
	"ultimate_ready": "必殺準備完了",
	"self_range": "射程が",
	"ally_injured": "味方負傷",
}
const _TARGET_NAMES: Dictionary = {
	"front": "前衛優先", "lowest_hp": "HP最低", "highest_hp": "HP最高",
	"highest_atk": "攻撃最高", "enemy_with_status": "状態異常優先",
	"enemy_marked": "標的優先", "enemy_with_debuff": "デバフ優先", "back": "後衛優先",
}

static func slot_label(slot_id: String) -> String:
	return str(_SLOT_NAMES.get(slot_id, slot_id))

static func condition_label(condition_id: String) -> String:
	return str(_CONDITION_NAMES.get(condition_id, condition_id))

static func target_label(target_id: String) -> String:
	return str(_TARGET_NAMES.get(target_id, target_id))

static func condition_needs_value(condition_id: String) -> bool:
	return condition_id in ["self_hp_below", "enemy_count_gte", "self_range"]

static func default_value_for(condition_id: String) -> String:
	match condition_id:
		"self_hp_below":
			return "0.30"
		"enemy_count_gte":
			return "2"
		"self_range":
			return "long"
		_:
			return ""

static func default_plan_row(index: int) -> Dictionary:
	match index:
		0:
			return {"slot": "ultimate", "condition": "ultimate_ready"}
		1:
			return {"slot": "defend", "condition": "self_hp_below", "value": 0.30}
		2:
			return {"slot": "skill", "condition": "always"}
		3:
			return {"slot": "attack", "condition": "always"}
		_:
			return {"slot": "attack", "condition": "always"}

static func plan_row_count() -> int:
	return PLAN_ROW_COUNT

static func normalize_plan(raw_plan: Array) -> Array:
	var out: Array = []
	for entry in raw_plan:
		if not entry is Dictionary:
			continue
		var slot: String = str(entry.get("slot", ""))
		if slot not in SLOT_IDS:
			continue
		var cond: String = str(entry.get("condition", "always"))
		if cond not in CONDITION_IDS:
			cond = "always"
		var rule: Dictionary = {"slot": slot, "condition": cond}
		if condition_needs_value(cond) and entry.has("value"):
			var raw_val: String = str(entry.get("value", ""))
			if not raw_val.is_empty():
				if cond == "self_hp_below" or cond == "enemy_count_gte":
					rule["value"] = float(raw_val) if raw_val.is_valid_float() else default_value_for(cond)
				else:
					rule["value"] = raw_val
		out.append(rule)
	return out

static func plan_from_member(member: Resource) -> Array:
	if member == null:
		return []
	if bool(member.get("tactics_custom_enabled")):
		var custom: Array = member.get("tactics_custom_plan") if "tactics_custom_plan" in member else []
		var normalized: Array = normalize_plan(custom)
		if not normalized.is_empty():
			return normalized
	var tid: String = CombatTactics.normalize_id(str(member.get("tactics_id") if "tactics_id" in member else ""))
	return CombatTactics.get_slot_plan(tid)

static func target_from_member(member: Resource) -> String:
	if member != null and bool(member.get("tactics_custom_enabled")):
		var custom_target: String = str(member.get("tactics_custom_target") if "tactics_custom_target" in member else "")
		if custom_target in CombatTactics.TARGET_RULES:
			return custom_target
	if member == null:
		return CombatTactics.DEFAULT_TARGET
	return CombatTactics.get_target_rule(CombatTactics.normalize_id(str(member.get("tactics_id") if "tactics_id" in member else "")))
