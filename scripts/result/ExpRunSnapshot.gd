class_name ExpRunSnapshot
extends RefCounted

## EXP 付与前スナップショット + シミュレーション（P3-UX-RESULT-002）。


## 人間パーティ + 随伴オトモ（P3-PET-OTOMO-001 共有EXP）
static func exp_recipients() -> Array:
	var out: Array = []
	for member: Resource in GameState.party_members:
		if member != null:
			out.append(member)
	if GameState.active_pet != null:
		out.append(GameState.active_pet)
	return out


static func build_party_snapshots(exp_amount: int) -> Dictionary:
	var out: Dictionary = {}
	if exp_amount <= 0:
		return out
	for member: Resource in exp_recipients():
		var member_id: String = str(member.id)
		if member_id.is_empty():
			continue
		var sim: Dictionary = simulate_member_exp(member, exp_amount)
		out[member_id] = {
			"member_id": member_id,
			"display_name": str(member.display_name),
			"job_id": str(member.job_id),
			"level_before": int(member.level),
			"exp_before": int(member.exp),
			"exp_gained": exp_amount,
			"levels_gained": int(sim.get("levels_gained", 0)),
			"level_after": int(sim.get("level_after", int(member.level))),
			"exp_after": int(sim.get("exp_after", int(member.exp))),
		}
	return out


static func simulate_member_exp(member: Resource, amount: int) -> Dictionary:
	if member == null or amount <= 0:
		return {
			"levels_gained": 0,
			"level_after": int(member.level) if member != null else 1,
			"exp_after": int(member.exp) if member != null else 0,
		}
	var lv: int = int(member.level)
	var exp: int = int(member.exp)
	var gained_levels: int = 0
	var pool: int = amount
	if lv >= LevelSystem.MAX_LEVEL:
		return {"levels_gained": 0, "level_after": lv, "exp_after": 0}
	while lv < LevelSystem.MAX_LEVEL and pool > 0:
		var need: int = LevelSystem.exp_to_next(lv) - exp
		if pool < need:
			exp += pool
			pool = 0
			break
		pool -= need
		exp = 0
		lv += 1
		gained_levels += 1
	if lv >= LevelSystem.MAX_LEVEL:
		exp = 0
	return {
		"levels_gained": gained_levels,
		"level_after": lv,
		"exp_after": exp,
	}


static func exp_ratio(level: int, exp: int) -> float:
	var cap: int = LevelSystem.exp_to_next(level)
	if cap <= 0:
		return 0.0
	return clampf(float(exp) / float(cap), 0.0, 1.0)
