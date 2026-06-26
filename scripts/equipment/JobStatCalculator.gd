class_name JobStatCalculator
extends RefCounted

## M7 Job modifier 読み取り（P2-Task033）。戦闘反映は Task034（CombatController / DungeonScene）。

const DEFAULT_MULTIPLIER: float = 1.0
const UNKNOWN_DISPLAY_NAME: String = "Unknown"

static func get_member_modifiers(adventurer: Resource) -> Dictionary:
	var calculator: RefCounted = load("res://scripts/equipment/JobStatCalculator.gd").new()
	return calculator._get_member_modifiers(adventurer)

static func empty_modifiers() -> Dictionary:
	return {
		"hp_multiplier": DEFAULT_MULTIPLIER,
		"attack_multiplier": DEFAULT_MULTIPLIER,
		"defense_multiplier": DEFAULT_MULTIPLIER,
		"job_id": "",
		"display_name": "",
		"role": "",
	}

func _get_member_modifiers(adventurer: Resource) -> Dictionary:
	if adventurer == null:
		return empty_modifiers()
	var job_id: String = str(adventurer.job_id)
	if job_id.is_empty():
		return empty_modifiers()
	var job_data: Resource = DataRegistry.get_job_data(job_id)
	if job_data == null:
		return _fallback_for_missing_job(job_id)
	return {
		"hp_multiplier": _safe_multiplier(job_data.base_hp_modifier),
		"attack_multiplier": _safe_multiplier(job_data.base_attack_modifier),
		"defense_multiplier": _safe_multiplier(job_data.base_defense_modifier),
		"job_id": job_id,
		"display_name": _job_display_name(job_data, job_id),
		"role": str(job_data.role),
	}

func _fallback_for_missing_job(job_id: String) -> Dictionary:
	var result: Dictionary = empty_modifiers()
	result["job_id"] = job_id
	result["display_name"] = job_id if not job_id.is_empty() else UNKNOWN_DISPLAY_NAME
	return result

func _job_display_name(job_data: Resource, job_id: String) -> String:
	if job_data != null and not job_data.display_name.is_empty():
		return job_data.display_name
	if not job_id.is_empty():
		return job_id
	return UNKNOWN_DISPLAY_NAME

func _safe_multiplier(value: float) -> float:
	if value <= 0.0:
		return DEFAULT_MULTIPLIER
	return value

static func get_preferred_weapon_multiplier(adventurer: Resource, weapon_data: Resource) -> float:
	if adventurer == null or weapon_data == null:
		return 1.0
	var weapon_type: String = str(weapon_data.weapon_type)
	if weapon_type.is_empty():
		return 1.0
	var job_id: String = str(adventurer.job_id)
	if job_id.is_empty():
		return 1.0
	var job_data: Resource = DataRegistry.get_job_data(job_id)
	if job_data == null:
		return 1.0
	if weapon_type in job_data.preferred_weapon_types:
		return 1.05
	return 1.0
