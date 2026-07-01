class_name CombatRange
extends RefCounted

## 射程カテゴリ解決（P3-D106b）。戦術 self_range と与ダメ陣形補正の SSOT。

const VALID_RANGES: Array[String] = ["melee", "mid", "long", "global"]

static func resolve_for_action(member_index: int, skill: Resource = null) -> String:
	if skill != null and "range_type" in skill:
		var rt := str(skill.range_type)
		if rt in VALID_RANGES:
			return rt
	return resolve_member_default(member_index)

static func resolve_member_default(member_index: int) -> String:
	var member: Resource = GameState.get_combatant(member_index)
	if member != null:
		for sid: String in GameState.get_equipped_skill_ids(member):
			var sd: Resource = DataRegistry.get_skill_data(sid)
			if sd == null:
				continue
			if str(sd.range_type) in ["long", "global"]:
				return "long"
			if "ranged" in sd.tags:
				return "long"
	var winst: Resource = GameState.get_member_equipped_weapon(member_index)
	if winst != null and not str(winst.weapon_id).is_empty():
		var wd: Resource = DataRegistry.get_weapon_data(winst.weapon_id)
		if wd != null and str(wd.weapon_type) in ["bow", "staff"]:
			return "long"
	return "melee"
