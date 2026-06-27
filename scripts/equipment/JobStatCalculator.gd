class_name JobStatCalculator
extends RefCounted

## M7 Job modifier 読み取り（P2-Task033）。戦闘反映は Task034（CombatController / DungeonScene）。

const DEFAULT_MULTIPLIER: float = 1.0
const UNKNOWN_DISPLAY_NAME: String = "Unknown"
## ジョブ進化の専門深化係数（P3-D037 / P3-D052-1）。
## 進化後補正 = 1.0 + (基礎補正 - 1.0) × EVOLUTION_FACTOR。
const EVOLUTION_FACTOR: float = 1.3

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
	var evolved: bool = bool(adventurer.is_evolved)
	var hp_mult: float = _safe_multiplier(job_data.base_hp_modifier)
	var atk_mult: float = _safe_multiplier(job_data.base_attack_modifier)
	var def_mult: float = _safe_multiplier(job_data.base_defense_modifier)
	var display: String = _job_display_name(job_data, job_id)
	if evolved:
		hp_mult = _deepen(hp_mult)
		atk_mult = _deepen(atk_mult)
		def_mult = _deepen(def_mult)
		if not job_data.evolved_display_name.is_empty():
			display = job_data.evolved_display_name
	return {
		"hp_multiplier": hp_mult,
		"attack_multiplier": atk_mult,
		"defense_multiplier": def_mult,
		"job_id": job_id,
		"display_name": display,
		"role": str(job_data.role),
		"is_evolved": evolved,
	}

## 専門深化: 1.0 からの乖離（強み/弱み）を EVOLUTION_FACTOR 倍に拡大する。
func _deepen(value: float) -> float:
	return 1.0 + (value - 1.0) * EVOLUTION_FACTOR

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
