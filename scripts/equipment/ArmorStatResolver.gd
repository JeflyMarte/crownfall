class_name ArmorStatResolver
extends RefCounted

const _EquipmentRollHelper = preload("res://scripts/equipment/EquipmentRollHelper.gd")

## P3-EQ-STAT-006 — 防具個体ステータス解決。必須=防御力。レア度でランダム1〜4種。

## 平坦DEF/HPロール上限（P3-BAL-STAT-SCALE-001: ×STAT_SCALE）
const DEFENSE_ROLL_MAX: Dictionary = {
	Enums.Rarity.COMMON: 4 * BalanceConfig.STAT_SCALE,
	Enums.Rarity.RARE: 6 * BalanceConfig.STAT_SCALE,
	Enums.Rarity.EPIC: 9 * BalanceConfig.STAT_SCALE,
	Enums.Rarity.LEGENDARY: 14 * BalanceConfig.STAT_SCALE,
}

const HP_ROLL_MAX: Dictionary = {
	Enums.Rarity.COMMON: 8 * BalanceConfig.STAT_SCALE,
	Enums.Rarity.RARE: 12 * BalanceConfig.STAT_SCALE,
	Enums.Rarity.EPIC: 18 * BalanceConfig.STAT_SCALE,
	Enums.Rarity.LEGENDARY: 25 * BalanceConfig.STAT_SCALE,
}

const RESIST_ELEM_COUNT_MAX: Dictionary = {
	Enums.Rarity.COMMON: 1,
	Enums.Rarity.RARE: 1,
	Enums.Rarity.EPIC: 2,
	Enums.Rarity.LEGENDARY: 3,
}

const RESIST_MULT_MIN_BY_RARITY: Dictionary = {
	Enums.Rarity.COMMON: 0.88,
	Enums.Rarity.RARE: 0.85,
	Enums.Rarity.EPIC: 0.82,
	Enums.Rarity.LEGENDARY: 0.80,
}

const STATUS_IMMUNITY_COUNT_MAX: Dictionary = {
	Enums.Rarity.COMMON: 1,
	Enums.Rarity.RARE: 1,
	Enums.Rarity.EPIC: 2,
	Enums.Rarity.LEGENDARY: 2,
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

const ARMOR_BONUS_POOL: Array[String] = [
	"hp_bonus",
	"resist_elements",
	"evasion_rate",
	"exp_gain_rate",
	"gold_gain_rate",
	"rare_drop_rate",
	"status_immunities",
]

const STATUS_IMMUNITY_POOL: Array[String] = [
	"poison", "chill", "shock", "ignite", "curse", "stun",
]

static func apply_drop_stats(instance: Resource, armor_data: Resource) -> void:
	if instance == null or armor_data == null:
		return
	_reset_bonus_stats(instance)
	instance.resistance = float(armor_data.base_resistance)
	instance.weight = float(armor_data.weight)
	## P3-EQ-DIABLO-001: 基礎防御は固定。
	instance.rolled_defense = int(armor_data.base_defense)
	if "rarity" in instance:
		instance.rarity = int(armor_data.rarity)
	var _EquipmentRandomMods = load("res://scripts/equipment/EquipmentRandomMods.gd")
	_EquipmentRandomMods.apply_armor_drop(instance, armor_data)

static func backfill_from_master(instance: Resource) -> void:
	var armor_data: Resource = _armor_data(instance)
	if armor_data == null:
		return
	if not ("resist_elements" in instance) or instance.resist_elements.is_empty():
		instance.resist_elements = _copy_string_array(armor_data.resist_elements)
	if not ("resist_multiplier" in instance) or float(instance.resist_multiplier) <= 0.0:
		if not instance.resist_elements.is_empty():
			instance.resist_multiplier = BalanceConfig.ARMOR_RESIST_MULTIPLIER
	if not ("hp_bonus" in instance) or int(instance.hp_bonus) <= 0:
		instance.hp_bonus = int(armor_data.base_hp_bonus)
	for field: String in ["exp_gain_rate", "gold_gain_rate", "rare_drop_rate"]:
		if field in instance and float(instance.get(field)) > 0.0:
			continue
		instance.set(field, 0.0)
	if not ("status_immunities" in instance):
		instance.status_immunities = _copy_string_array([])
	if not ("rolled_bonus_stats" in instance):
		instance.rolled_bonus_stats = _copy_string_array([])
	if not ("perfect_roll_count" in instance):
		instance.perfect_roll_count = 0
	if not ("evasion_rate" in instance):
		instance.evasion_rate = 0.0

static func resolve_evasion_rate(armor: Resource) -> float:
	return _resolve_rate(armor, "evasion_rate")

static func resolve_resist_elements(armor: Resource, armor_data: Resource = null) -> Array[String]:
	if armor != null and "resist_elements" in armor and not armor.resist_elements.is_empty():
		return _copy_string_array(armor.resist_elements)
	var data: Resource = armor_data if armor_data != null else _armor_data(armor)
	if data != null and "resist_elements" in data:
		return _copy_string_array(data.resist_elements)
	return []

static func resolve_resist_multiplier(armor: Resource) -> float:
	if armor == null or resolve_resist_elements(armor).is_empty():
		return 1.0
	if "resist_multiplier" in armor and float(armor.resist_multiplier) > 0.0:
		return clampf(float(armor.resist_multiplier), 0.1, 1.0)
	return BalanceConfig.ARMOR_RESIST_MULTIPLIER

static func resolve_hp_bonus(armor: Resource, armor_data: Resource = null) -> int:
	if armor != null and "hp_bonus" in armor and int(armor.hp_bonus) > 0:
		return int(armor.hp_bonus)
	var data: Resource = armor_data if armor_data != null else _armor_data(armor)
	if data != null:
		return maxi(0, int(data.base_hp_bonus))
	return 0

static func resolve_exp_gain_rate(armor: Resource) -> float:
	return _resolve_rate(armor, "exp_gain_rate")

static func resolve_gold_gain_rate(armor: Resource) -> float:
	return _resolve_rate(armor, "gold_gain_rate")

static func resolve_rare_drop_rate(armor: Resource) -> float:
	return _resolve_rate(armor, "rare_drop_rate")

static func resolve_status_immunities(armor: Resource) -> Array[String]:
	if armor == null or not ("status_immunities" in armor):
		return []
	return _copy_string_array(armor.status_immunities)

static func member_immune_to_status(member_index: int, effect_id: String) -> bool:
	if effect_id.is_empty():
		return false
	var armor: Resource = GameState.get_member_equipped_armor(member_index)
	if armor == null:
		return false
	return effect_id in resolve_status_immunities(armor)

static func member_resists_element(target_index: int, attack_element: String) -> bool:
	if attack_element.is_empty():
		return false
	return attack_element in resolve_resist_elements(GameState.get_member_equipped_armor(target_index))

static func member_element_resist_multiplier(target_index: int, attack_element: String) -> float:
	if not member_resists_element(target_index, attack_element):
		return 1.0
	return resolve_resist_multiplier(GameState.get_member_equipped_armor(target_index))

static func _reset_bonus_stats(instance: Resource) -> void:
	instance.hp_bonus = 0
	instance.resist_elements = _copy_string_array([])
	instance.resist_multiplier = 0.0
	instance.exp_gain_rate = 0.0
	instance.gold_gain_rate = 0.0
	instance.rare_drop_rate = 0.0
	instance.evasion_rate = 0.0
	instance.status_immunities = _copy_string_array([])

static func _roll_bonus_stat(
	instance: Resource,
	armor_data: Resource,
	rarity: int,
	stat_id: String
) -> bool:
	match stat_id:
		"hp_bonus":
			return _roll_hp_bonus(instance, armor_data, rarity)
		"resist_elements":
			return _roll_resist_elements(instance, armor_data, rarity)
		"evasion_rate":
			return _roll_evasion_rate(instance, rarity)
		"exp_gain_rate":
			return _roll_rate_stat(instance, "exp_gain_rate", rarity)
		"gold_gain_rate":
			return _roll_rate_stat(instance, "gold_gain_rate", rarity)
		"rare_drop_rate":
			return _roll_rate_stat(instance, "rare_drop_rate", rarity)
		"status_immunities":
			return _roll_status_immunities(instance, rarity)
		_:
			return false

static func _roll_hp_bonus(instance: Resource, armor_data: Resource, rarity: int) -> bool:
	var roll_max: int = int(HP_ROLL_MAX.get(rarity, HP_ROLL_MAX[Enums.Rarity.COMMON]))
	var roll: Dictionary = _EquipmentRollHelper.roll_int_bonus(roll_max)
	var base: int = maxi(0, int(armor_data.base_hp_bonus))
	instance.hp_bonus = base + int(roll.get("value", 0))
	return bool(roll.get("perfect", false))

static func _roll_resist_elements(instance: Resource, armor_data: Resource, rarity: int) -> bool:
	var max_count: int = int(RESIST_ELEM_COUNT_MAX.get(rarity, RESIST_ELEM_COUNT_MAX[Enums.Rarity.COMMON]))
	var count_roll: Dictionary = _EquipmentRollHelper.roll_int_bonus(maxi(0, max_count - 1))
	var count: int = 1 + int(count_roll.get("value", 0))
	var candidate_pool: Array[String] = _resist_candidate_pool(armor_data)
	instance.resist_elements = _pick_unique_strings(candidate_pool, count)
	var mult_roll: Dictionary = _roll_resist_multiplier(rarity)
	instance.resist_multiplier = float(mult_roll.get("value", BalanceConfig.ARMOR_RESIST_MULTIPLIER))
	var count_perfect: bool = int(count_roll.get("value", 0)) >= maxi(0, max_count - 1)
	return count_perfect and bool(mult_roll.get("perfect", false))

static func _roll_resist_multiplier(rarity: int) -> Dictionary:
	var weak: float = float(
		RESIST_MULT_MIN_BY_RARITY.get(rarity, RESIST_MULT_MIN_BY_RARITY[Enums.Rarity.COMMON])
	)
	var strong: float = BalanceConfig.ARMOR_RESIST_MULTIPLIER
	const STEPS: int = 10
	var step: int = randi() % (STEPS + 1)
	var span: float = weak - strong
	var value: float = weak - span * float(step) / float(STEPS)
	return {"value": value, "perfect": step >= STEPS}

static func _roll_status_immunities(instance: Resource, rarity: int) -> bool:
	var max_count: int = int(
		STATUS_IMMUNITY_COUNT_MAX.get(rarity, STATUS_IMMUNITY_COUNT_MAX[Enums.Rarity.COMMON])
	)
	var count_roll: Dictionary = _EquipmentRollHelper.roll_int_bonus(maxi(0, max_count - 1))
	var count: int = 1 + int(count_roll.get("value", 0))
	instance.status_immunities = _pick_unique_strings(STATUS_IMMUNITY_POOL, count)
	return int(count_roll.get("value", 0)) >= maxi(0, max_count - 1)

static func _resist_candidate_pool(armor_data: Resource) -> Array[String]:
	if armor_data.resist_elements.size() > 0:
		return _copy_string_array(armor_data.resist_elements)
	var pool: Array[String] = []
	for key in ElementResolver.ELEMENT_NAMES.keys():
		pool.append(str(key))
	return pool

static func _pick_unique_strings(pool: Array[String], count: int) -> Array[String]:
	if pool.is_empty() or count <= 0:
		return []
	var available: Array[String] = pool.duplicate()
	available.shuffle()
	var take: int = mini(count, available.size())
	return available.slice(0, take)

static func _roll_evasion_rate(instance: Resource, rarity: int) -> bool:
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

static func _resolve_rate(armor: Resource, field: String) -> float:
	if armor != null and field in armor:
		return maxf(0.0, float(armor.get(field)))
	return 0.0

static func _copy_string_array(source: Array) -> Array[String]:
	var out: Array[String] = []
	for item in source:
		out.append(str(item))
	return out

static func _armor_data(armor: Resource) -> Resource:
	if armor == null or str(armor.armor_id).is_empty():
		return null
	return DataRegistry.get_armor_data(str(armor.armor_id))
