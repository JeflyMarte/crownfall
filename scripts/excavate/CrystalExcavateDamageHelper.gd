class_name CrystalExcavateDamageHelper
extends RefCounted

const _RosterUiHelper := preload("res://scripts/roster/RosterUiHelper.gd")
const _SkillExecutor := preload("res://scripts/combat/SkillExecutor.gd")

## 魔晶石発掘用の1撃ダメージ見積もり（装備・パッシブ込み・非必殺）。
## 確定ダメは preview ± DAMAGE_VARIANCE（選択画面は中央値表示）。
const DAMAGE_VARIANCE: float = 0.15


static func preview_damage(member: Resource, skill_data: Resource) -> int:
	if member == null or skill_data == null:
		return 0
	if str(skill_data.slot_type) == "ultimate":
		return 0
	if str(skill_data.effect_type) != "damage":
		return 0
	var stats: Dictionary = _RosterUiHelper.compute_member_stats(member)
	var base_atk: int = int(stats.get("attack", 0))
	if base_atk <= 0:
		return 0
	var executor := _SkillExecutor.new()
	var raw: int = executor.calculate_damage(skill_data, base_atk, false, 1.5, 1.0)
	var mult: float = _roster_skill_outgoing_mult(member, skill_data)
	return maxi(0, int(round(float(raw) * mult)))


## 確定用。中央値 × [1−V, 1+V] の一様乱数。
static func roll_damage(member: Resource, skill_data: Resource) -> int:
	var base: int = preview_damage(member, skill_data)
	if base <= 0:
		return 0
	var factor: float = randf_range(1.0 - DAMAGE_VARIANCE, 1.0 + DAMAGE_VARIANCE)
	return apply_variance(base, factor)


static func apply_variance(base_damage: int, factor: float) -> int:
	if base_damage <= 0:
		return 0
	return maxi(0, int(round(float(base_damage) * factor)))


static func variance_bounds(base_damage: int) -> Vector2i:
	if base_damage <= 0:
		return Vector2i(0, 0)
	var lo: int = apply_variance(base_damage, 1.0 - DAMAGE_VARIANCE)
	var hi: int = apply_variance(base_damage, 1.0 + DAMAGE_VARIANCE)
	return Vector2i(lo, hi)


static func _roster_skill_outgoing_mult(member: Resource, skill_data: Resource) -> float:
	var mult: float = 1.0
	for raw_def: Variant in CombatPassives.for_member(member):
		if raw_def is not Dictionary:
			continue
		var def: Dictionary = raw_def
		if def.has("outgoing_mult"):
			mult *= float(def["outgoing_mult"])
		if def.has("skill_power_mult"):
			mult *= float(def["skill_power_mult"])
		var min_cd: float = float(def.get("long_cd_skill_min_cooldown", 0.0))
		if skill_data != null and min_cd > 0.0 and float(skill_data.cooldown) >= min_cd:
			if def.has("long_cd_skill_power_mult"):
				mult *= float(def["long_cd_skill_power_mult"])
	return mult
