class_name AccessoryStatResolver
extends RefCounted

const _EquipmentRollHelper = preload("res://scripts/equipment/EquipmentRollHelper.gd")

## P3-EQ-STAT-008 — 装飾品個体ステータス解決。必須なし。レア度でランダム1〜4種。

## 平坦ロール上限（P3-BAL-STAT-SCALE-001: ×STAT_SCALE）。率系は据置。
const HP_ROLL_MAX: Dictionary = {
	Enums.Rarity.COMMON: 6 * BalanceConfig.STAT_SCALE,
	Enums.Rarity.RARE: 10 * BalanceConfig.STAT_SCALE,
	Enums.Rarity.EPIC: 14 * BalanceConfig.STAT_SCALE,
	Enums.Rarity.LEGENDARY: 20 * BalanceConfig.STAT_SCALE,
}

const ATTACK_ROLL_MAX: Dictionary = {
	Enums.Rarity.COMMON: 3 * BalanceConfig.STAT_SCALE,
	Enums.Rarity.RARE: 5 * BalanceConfig.STAT_SCALE,
	Enums.Rarity.EPIC: 8 * BalanceConfig.STAT_SCALE,
	Enums.Rarity.LEGENDARY: 12 * BalanceConfig.STAT_SCALE,
}

const DEFENSE_ROLL_MAX: Dictionary = {
	Enums.Rarity.COMMON: 3 * BalanceConfig.STAT_SCALE,
	Enums.Rarity.RARE: 5 * BalanceConfig.STAT_SCALE,
	Enums.Rarity.EPIC: 8 * BalanceConfig.STAT_SCALE,
	Enums.Rarity.LEGENDARY: 12 * BalanceConfig.STAT_SCALE,
}

const CRIT_ROLL_MAX: Dictionary = {
	Enums.Rarity.COMMON: 0.03,
	Enums.Rarity.RARE: 0.05,
	Enums.Rarity.EPIC: 0.07,
	Enums.Rarity.LEGENDARY: 0.10,
}

const RATE_MIN_BY_RARITY: Dictionary = {
	Enums.Rarity.COMMON: 0.01,
	Enums.Rarity.RARE: 0.015,
	Enums.Rarity.EPIC: 0.02,
	Enums.Rarity.LEGENDARY: 0.025,
}

const RATE_MAX_BY_RARITY: Dictionary = {
	Enums.Rarity.COMMON: 0.02,
	Enums.Rarity.RARE: 0.03,
	Enums.Rarity.EPIC: 0.04,
	Enums.Rarity.LEGENDARY: 0.05,
}

const EVASION_MIN_BY_RARITY: Dictionary = {
	Enums.Rarity.COMMON: 0.02,
	Enums.Rarity.RARE: 0.03,
	Enums.Rarity.EPIC: 0.05,
	Enums.Rarity.LEGENDARY: 0.08,
}

const EVASION_MAX_BY_RARITY: Dictionary = {
	Enums.Rarity.COMMON: 0.05,
	Enums.Rarity.RARE: 0.07,
	Enums.Rarity.EPIC: 0.10,
	Enums.Rarity.LEGENDARY: 0.15,
}

const ACCESSORY_BONUS_POOL: Array[String] = [
	"hp_bonus",
	"attack_bonus",
	"defense_bonus",
	"crit_rate_bonus",
	"evasion_rate",
	"exp_gain_rate",
	"gold_gain_rate",
	"rare_drop_rate",
]

static func apply_drop_stats(instance: Resource, accessory_data: Resource) -> void:
	if instance == null or accessory_data == null:
		return
	var rarity: int = int(accessory_data.rarity)
	_reset_bonus_stats(instance)
	var picked: Array[String] = _EquipmentRollHelper.pick_random_stats(
		ACCESSORY_BONUS_POOL,
		_EquipmentRollHelper.random_stat_count(rarity)
	)
	var perfect: int = 0
	for stat_id: String in picked:
		if _roll_bonus_stat(instance, accessory_data, rarity, stat_id):
			perfect += 1
	instance.rolled_bonus_stats = picked
	instance.perfect_roll_count = perfect

static func backfill_from_master(instance: Resource) -> void:
	var data: Resource = _accessory_data(instance)
	if data == null:
		return
	for field: String in ["hp_bonus", "attack_bonus", "defense_bonus"]:
		if field in instance and int(instance.get(field)) > 0:
			continue
		instance.set(field, int(data.get(field)))
	if "crit_rate_bonus" in instance and float(instance.crit_rate_bonus) <= 0.0:
		instance.crit_rate_bonus = float(data.crit_rate_bonus)
	for field: String in ["exp_gain_rate", "gold_gain_rate", "rare_drop_rate"]:
		if field in instance and float(instance.get(field)) > 0.0:
			continue
		instance.set(field, float(data.get(field)))
	if not ("rolled_bonus_stats" in instance):
		var empty_stats: Array[String] = []
		instance.rolled_bonus_stats = empty_stats
	if not ("perfect_roll_count" in instance):
		instance.perfect_roll_count = 0
	if not ("evasion_rate" in instance):
		instance.evasion_rate = 0.0

static func resolve_evasion_rate(instance: Resource, data: Resource = null) -> float:
	return resolve_float_stat(instance, "evasion_rate", data)

static func resolve_int_stat(
	instance: Resource,
	field: String,
	accessory_data: Resource = null
) -> int:
	if instance != null and field in instance:
		return maxi(0, int(instance.get(field)))
	var data: Resource = accessory_data if accessory_data != null else _accessory_data(instance)
	if data != null and field in data:
		return maxi(0, int(data.get(field)))
	return 0

static func resolve_float_stat(
	instance: Resource,
	field: String,
	accessory_data: Resource = null
) -> float:
	if instance != null and field in instance:
		return maxf(0.0, float(instance.get(field)))
	var data: Resource = accessory_data if accessory_data != null else _accessory_data(instance)
	if data != null and field in data:
		return maxf(0.0, float(data.get(field)))
	return 0.0

static func resolve_hp_bonus(instance: Resource, data: Resource = null) -> int:
	return resolve_int_stat(instance, "hp_bonus", data)

static func resolve_attack_bonus(instance: Resource, data: Resource = null) -> int:
	return resolve_int_stat(instance, "attack_bonus", data)

static func resolve_defense_bonus(instance: Resource, data: Resource = null) -> int:
	return resolve_int_stat(instance, "defense_bonus", data)

static func resolve_crit_rate_bonus(instance: Resource, data: Resource = null) -> float:
	return resolve_float_stat(instance, "crit_rate_bonus", data)

static func resolve_exp_gain_rate(instance: Resource, data: Resource = null) -> float:
	return resolve_float_stat(instance, "exp_gain_rate", data)

static func resolve_gold_gain_rate(instance: Resource, data: Resource = null) -> float:
	return resolve_float_stat(instance, "gold_gain_rate", data)

static func resolve_rare_drop_rate(instance: Resource, data: Resource = null) -> float:
	return resolve_float_stat(instance, "rare_drop_rate", data)

static func _reset_bonus_stats(instance: Resource) -> void:
	instance.hp_bonus = 0
	instance.attack_bonus = 0
	instance.defense_bonus = 0
	instance.crit_rate_bonus = 0.0
	instance.evasion_rate = 0.0
	instance.exp_gain_rate = 0.0
	instance.gold_gain_rate = 0.0
	instance.rare_drop_rate = 0.0

static func _roll_bonus_stat(
	instance: Resource,
	accessory_data: Resource,
	rarity: int,
	stat_id: String
) -> bool:
	match stat_id:
		"hp_bonus":
			return _roll_int_bonus_stat(
				instance, "hp_bonus", accessory_data, HP_ROLL_MAX, rarity
			)
		"attack_bonus":
			return _roll_int_bonus_stat(
				instance, "attack_bonus", accessory_data, ATTACK_ROLL_MAX, rarity
			)
		"defense_bonus":
			return _roll_int_bonus_stat(
				instance, "defense_bonus", accessory_data, DEFENSE_ROLL_MAX, rarity
			)
		"crit_rate_bonus":
			return _roll_crit_bonus_stat(instance, accessory_data, rarity)
		"evasion_rate":
			return _roll_evasion_rate_stat(instance, rarity)
		"exp_gain_rate":
			return _roll_rate_stat(instance, "exp_gain_rate", rarity)
		"gold_gain_rate":
			return _roll_rate_stat(instance, "gold_gain_rate", rarity)
		"rare_drop_rate":
			return _roll_rate_stat(instance, "rare_drop_rate", rarity)
		_:
			return false

static func _roll_int_bonus_stat(
	instance: Resource,
	field: String,
	accessory_data: Resource,
	roll_table: Dictionary,
	rarity: int
) -> bool:
	var roll_max: int = int(roll_table.get(rarity, roll_table[Enums.Rarity.COMMON]))
	var roll: Dictionary = _EquipmentRollHelper.roll_int_bonus(roll_max)
	var base: int = maxi(0, int(accessory_data.get(field)))
	instance.set(field, base + int(roll.get("value", 0)))
	return bool(roll.get("perfect", false))

static func _roll_crit_bonus_stat(
	instance: Resource,
	accessory_data: Resource,
	rarity: int
) -> bool:
	var max_bonus: float = float(CRIT_ROLL_MAX.get(rarity, CRIT_ROLL_MAX[Enums.Rarity.COMMON]))
	var roll: Dictionary = _EquipmentRollHelper.roll_float_bonus(max_bonus)
	var base: float = maxf(0.0, float(accessory_data.crit_rate_bonus))
	instance.crit_rate_bonus = base + float(roll.get("value", 0.0))
	return bool(roll.get("perfect", false))

static func _roll_evasion_rate_stat(instance: Resource, rarity: int) -> bool:
	var roll: Dictionary = _EquipmentRollHelper.roll_rate_value(
		rarity, EVASION_MIN_BY_RARITY, EVASION_MAX_BY_RARITY
	)
	instance.evasion_rate = float(roll.get("value", 0.0))
	return bool(roll.get("perfect", false))

static func _roll_rate_stat(instance: Resource, field: String, rarity: int) -> bool:
	var roll: Dictionary = _EquipmentRollHelper.roll_rate_value(
		rarity, RATE_MIN_BY_RARITY, RATE_MAX_BY_RARITY
	)
	instance.set(field, float(roll.get("value", 0.0)))
	return bool(roll.get("perfect", false))

static func _accessory_data(instance: Resource) -> Resource:
	if instance == null or str(instance.accessory_id).is_empty():
		return null
	return DataRegistry.get_accessory_data(str(instance.accessory_id))
