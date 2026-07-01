class_name CombatRange
extends RefCounted

## 射程カテゴリ解決（P3-D106b/f）。戦術 self_range と与ダメ陣形補正の SSOT。

const VALID_RANGES: Array[String] = ["melee", "mid", "long", "global"]

## 数値射程→カテゴリ閾値（P3-D106f）。Combat Vision 理想距離の Alpha 代理。
const MELEE_RANGE_MAX: float = 1.5
const MID_RANGE_MAX: float = 2.5

static func attack_range_to_category(range_value: float) -> String:
	if range_value <= MELEE_RANGE_MAX:
		return "melee"
	if range_value <= MID_RANGE_MAX:
		return "mid"
	return "long"

static func is_melee_attack_range(range_value: float) -> bool:
	return range_value <= MID_RANGE_MAX

static func get_member_weapon_attack_range(member_index: int) -> float:
	var winst: Resource = GameState.get_member_equipped_weapon(member_index)
	if winst == null:
		return 1.0
	if "attack_range" in winst and float(winst.attack_range) > 0.0:
		return float(winst.attack_range)
	if not str(winst.weapon_id).is_empty():
		var wd: Resource = DataRegistry.get_weapon_data(winst.weapon_id)
		if wd != null and "base_attack_range" in wd:
			return float(wd.base_attack_range)
	return 1.0

static func resolve_for_action(member_index: int, skill: Resource = null) -> String:
	if skill != null and "range_type" in skill:
		var rt := str(skill.range_type)
		if rt in VALID_RANGES:
			return rt
	return resolve_member_default(member_index)

static func resolve_member_default(member_index: int) -> String:
	var winst: Resource = GameState.get_member_equipped_weapon(member_index)
	if winst != null and not str(winst.weapon_id).is_empty():
		return attack_range_to_category(get_member_weapon_attack_range(member_index))
	return _resolve_skill_meta_fallback(member_index)

static func _resolve_skill_meta_fallback(member_index: int) -> String:
	var member: Resource = GameState.get_combatant(member_index)
	if member != null:
		for sid: String in GameState.get_equipped_skill_ids(member):
			var sd: Resource = DataRegistry.get_skill_data(sid)
			if sd == null:
				continue
			var rt := str(sd.range_type)
			if rt in VALID_RANGES:
				return rt
			if "ranged" in sd.tags:
				return "long"
	return "melee"
