class_name MvpScore
extends RefCounted

## MVP 選出（P3-UX-RESULT-004）。score = damage + heal×0.5。

const HEAL_WEIGHT: float = 0.5


static func rank_members(stats: Dictionary, party_members: Array) -> Array:
	var entries: Array = []
	for member: Resource in party_members:
		if member == null:
			continue
		var member_id: String = str(member.id)
		var row: Dictionary = stats.get(member_id, {})
		var damage_total: int = int(row.get("damage_total", 0))
		var heal_total: int = int(row.get("heal_total", 0))
		var max_hit: int = int(row.get("damage_max_hit", 0))
		entries.append({
			"member_id": member_id,
			"display_name": str(member.display_name),
			"job_id": str(member.job_id),
			"damage_total": damage_total,
			"damage_max_hit": max_hit,
			"damage_max_skill_id": str(row.get("damage_max_skill_id", "")),
			"damage_max_skill_name": str(row.get("damage_max_skill_name", "")),
			"heal_total": heal_total,
			"score": float(damage_total) + float(heal_total) * HEAL_WEIGHT,
		})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("score", 0)) != int(b.get("score", 0)):
			return float(a.get("score", 0)) > float(b.get("score", 0))
		if int(a.get("damage_max_hit", 0)) != int(b.get("damage_max_hit", 0)):
			return int(a.get("damage_max_hit", 0)) > int(b.get("damage_max_hit", 0))
		return int(a.get("damage_total", 0)) > int(b.get("damage_total", 0))
	)
	return entries


static func pick_mvp(stats: Dictionary, party_members: Array) -> Dictionary:
	var ranked: Array = rank_members(stats, party_members)
	if ranked.is_empty():
		return {}
	return ranked[0]
