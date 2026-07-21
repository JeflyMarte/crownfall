class_name SkillExecutor
extends RefCounted

## SkillExecutor。effect_type = damage / heal / buff を実行（cooldown管理）。none は無視。

var _cooldown_remaining: Dictionary = {}

func reset() -> void:
	_cooldown_remaining.clear()

func tick(delta_seconds: float) -> void:
	for skill_id in _cooldown_remaining.keys():
		_cooldown_remaining[skill_id] = max(0.0, _cooldown_remaining[skill_id] - delta_seconds)

func can_cast(skill_data: Resource, cooldown_key: String = "") -> bool:
	if skill_data == null:
		return false
	if skill_data.effect_type == "none":
		return false
	if skill_data.trigger_type != "cooldown":
		return false
	# 必殺はチャージ制（P3-COMBAT-GAUGE-001）。CD ゲートは使わない。
	if str(skill_data.slot_type) == "ultimate":
		return true
	var key: String = cooldown_key if not cooldown_key.is_empty() else skill_data.id
	return _cooldown_remaining.get(key, 0.0) <= 0.0

## 残りCD秒（0=使用可）。パーティカード表示用（P3-FIX-008）。
func get_cooldown_remaining(cooldown_key: String) -> float:
	if cooldown_key.is_empty():
		return 0.0
	return maxf(0.0, float(_cooldown_remaining.get(cooldown_key, 0.0)))

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
	run_multiplier: float,
	cooldown_key: String = ""
) -> Dictionary:
	var key: String = cooldown_key if not cooldown_key.is_empty() else skill_data.id
	if not can_cast(skill_data, key):
		return {"executed": false}
	var damage: int = calculate_damage(
		skill_data, base_damage, is_critical, critical_multiplier, run_multiplier
	)
	if str(skill_data.slot_type) != "ultimate":
		_cooldown_remaining[key] = skill_data.cooldown
	return {
		"executed": true,
		"damage": damage,
		"display_name": skill_data.display_name,
		"skill_id": skill_data.id,
		"is_critical": is_critical,
	}

## heal / buff など非ダメージスキルの発動。CD判定→CDセットのみ行う。
## 効果の適用（回復量・状態付与）は呼び出し側（DungeonScene）で行う。
func execute_support_skill(skill_data: Resource, cooldown_key: String = "") -> Dictionary:
	if skill_data == null:
		return {"executed": false}
	var key: String = cooldown_key if not cooldown_key.is_empty() else skill_data.id
	if not can_cast(skill_data, key):
		return {"executed": false}
	if str(skill_data.slot_type) != "ultimate":
		_cooldown_remaining[key] = skill_data.cooldown
	return {
		"executed": true,
		"display_name": skill_data.display_name,
		"skill_id": skill_data.id,
		"effect_type": skill_data.effect_type,
	}
