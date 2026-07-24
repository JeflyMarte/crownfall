class_name JobStatCalculator
extends RefCounted

## M7 Job modifier 読み取り（P2-Task033）。戦闘反映は Task034（CombatController / DungeonScene）。

const DEFAULT_MULTIPLIER: float = 1.0
const UNKNOWN_DISPLAY_NAME: String = "不明"
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
	result["display_name"] = UNKNOWN_DISPLAY_NAME
	return result

func _job_display_name(job_data: Resource, _job_id: String) -> String:
	if job_data != null and not job_data.display_name.is_empty():
		return job_data.display_name
	return UNKNOWN_DISPLAY_NAME

func _safe_multiplier(value: float) -> float:
	if value <= 0.0:
		return DEFAULT_MULTIPLIER
	return value

static func get_preferred_weapon_multiplier(adventurer: Resource, weapon_data: Resource) -> float:
	if adventurer == null or weapon_data == null:
		return 1.0
	if not can_equip_weapon_data(adventurer, weapon_data):
		return 1.0
	return 1.05


## P3-EQ-JOB-WPN-001 — preferred_weapon_types を装備可能リストとして扱う。
static func allowed_weapon_types(job_id: String) -> Array[String]:
	var out: Array[String] = []
	if job_id.is_empty():
		return out
	var job_data: Resource = DataRegistry.get_job_data(job_id)
	if job_data == null or not ("preferred_weapon_types" in job_data):
		return out
	for raw: Variant in job_data.preferred_weapon_types:
		var t: String = str(raw)
		if not t.is_empty() and t not in out:
			out.append(t)
	return out


static func weapon_type_of_item(weapon_item: Resource) -> String:
	if weapon_item == null:
		return ""
	var weapon_id: String = str(weapon_item.weapon_id) if "weapon_id" in weapon_item else ""
	if weapon_id.is_empty():
		return ""
	var data: Resource = DataRegistry.get_weapon_data(weapon_id)
	if data == null:
		return ""
	return str(data.weapon_type)


static func can_equip_weapon_data(adventurer: Resource, weapon_data: Resource) -> bool:
	if adventurer == null or weapon_data == null:
		return false
	var weapon_type: String = str(weapon_data.weapon_type)
	if weapon_type.is_empty():
		return false
	var allowed: Array[String] = allowed_weapon_types(str(adventurer.job_id))
	return weapon_type in allowed


static func can_equip_weapon(adventurer: Resource, weapon_item: Resource) -> bool:
	if adventurer == null or weapon_item == null:
		return false
	var weapon_id: String = str(weapon_item.weapon_id) if "weapon_id" in weapon_item else ""
	if weapon_id.is_empty():
		return false
	var data: Resource = DataRegistry.get_weapon_data(weapon_id)
	return can_equip_weapon_data(adventurer, data)


static func unequip_reason_weapon(adventurer: Resource, weapon_item: Resource) -> String:
	if can_equip_weapon(adventurer, weapon_item):
		return ""
	return "この職では装備できません"
