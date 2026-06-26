class_name SkillExecutor
extends RefCounted

## M5 最小 SkillExecutor。effect_type = damage のみ実行。heal / buff / none は無視。

var _cooldown_remaining: Dictionary = {}

func reset() -> void:
	_cooldown_remaining.clear()

func tick(delta_seconds: float) -> void:
	for skill_id in _cooldown_remaining.keys():
		_cooldown_remaining[skill_id] = max(0.0, _cooldown_remaining[skill_id] - delta_seconds)

func can_cast(skill_data: Resource) -> bool:
	if skill_data == null:
		return false
	if skill_data.effect_type != "damage":
		return false
	if skill_data.trigger_type != "cooldown":
		return false
	return _cooldown_remaining.get(skill_data.id, 0.0) <= 0.0

func calculate_damage(
	skill_data: Resource,
	base_damage: int,
	is_critical: bool,
	critical_multiplier: float,
	run_multiplier: float
) -> int:
	if skill_data == null or skill_data.effect_type != "damage":
		return 0
	var damage: int = int(float(base_damage) * skill_data.power_multiplier)
	if is_critical:
		damage = int(float(damage) * critical_multiplier)
	damage = int(float(damage) * run_multiplier)
	return max(0, damage)

func execute_damage_skill(
	skill_data: Resource,
	base_damage: int,
	is_critical: bool,
	critical_multiplier: float,
	run_multiplier: float
) -> Dictionary:
	if not can_cast(skill_data):
		return {"executed": false}
	var damage: int = calculate_damage(
		skill_data, base_damage, is_critical, critical_multiplier, run_multiplier
	)
	_cooldown_remaining[skill_data.id] = skill_data.cooldown
	return {
		"executed": true,
		"damage": damage,
		"display_name": skill_data.display_name,
		"skill_id": skill_data.id,
		"is_critical": is_critical,
	}
