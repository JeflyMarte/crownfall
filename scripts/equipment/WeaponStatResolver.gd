class_name WeaponStatResolver
extends RefCounted

const _EquipmentRollHelper = preload("res://scripts/equipment/EquipmentRollHelper.gd")

## P3-EQ-STAT-005 — 武器個体ステータス解決。必須=攻撃力。レア度でランダム1〜4種。

## 平坦ATKロール上限（P3-BAL-STAT-SCALE-001: ×STAT_SCALE）。属性値は%のため据置。
const ATTACK_ROLL_MAX: Dictionary = {
	Enums.Rarity.COMMON: 5 * BalanceConfig.STAT_SCALE,
	Enums.Rarity.RARE: 7 * BalanceConfig.STAT_SCALE,
	Enums.Rarity.EPIC: 10 * BalanceConfig.STAT_SCALE,
	Enums.Rarity.LEGENDARY: 14 * BalanceConfig.STAT_SCALE,
}

const ELEMENT_POWER_ROLL_MAX: Dictionary = {
	Enums.Rarity.COMMON: 5,
	Enums.Rarity.RARE: 8,
	Enums.Rarity.EPIC: 12,
	Enums.Rarity.LEGENDARY: 18,
}

const ATTACK_SPEED_ROLL_MAX: Dictionary = {
	Enums.Rarity.COMMON: 0.10,
	Enums.Rarity.RARE: 0.15,
	Enums.Rarity.EPIC: 0.20,
	Enums.Rarity.LEGENDARY: 0.25,
}

const CRITICAL_RATE_ROLL_MAX: Dictionary = {
	Enums.Rarity.COMMON: 0.05,
	Enums.Rarity.RARE: 0.08,
	Enums.Rarity.EPIC: 0.10,
	Enums.Rarity.LEGENDARY: 0.12,
}

const CRITICAL_DAMAGE_ROLL_MAX: Dictionary = {
	Enums.Rarity.COMMON: 0.15,
	Enums.Rarity.RARE: 0.20,
	Enums.Rarity.EPIC: 0.25,
	Enums.Rarity.LEGENDARY: 0.30,
}

const STATUS_CHANCE_MIN_BY_RARITY: Dictionary = {
	Enums.Rarity.COMMON: 0.15,
	Enums.Rarity.RARE: 0.20,
	Enums.Rarity.EPIC: 0.25,
	Enums.Rarity.LEGENDARY: 0.30,
}

const STATUS_CHANCE_MAX_BY_RARITY: Dictionary = {
	Enums.Rarity.COMMON: 0.25,
	Enums.Rarity.RARE: 0.30,
	Enums.Rarity.EPIC: 0.35,
	Enums.Rarity.LEGENDARY: 0.40,
}

const WEAPON_STATUS_POOL: Array[String] = [
	"poison", "chill", "shock", "ignite", "curse",
]

static func apply_drop_stats(instance: Resource, weapon_data: Resource) -> void:
	if instance == null or weapon_data == null:
		return
	_reset_bonus_stats(instance)
	instance.element = str(weapon_data.element)
	instance.knockback = float(weapon_data.base_knockback)
	instance.stagger_power = float(weapon_data.base_stagger_power)
	instance.attack_range = float(weapon_data.base_attack_range)
	instance.weight = float(weapon_data.weight)
	## P3-EQ-DIABLO-001: 基礎攻撃は固定（個体ブレなし）。
	instance.rolled_attack = int(weapon_data.base_attack)
	var passive_def: Dictionary = CombatPassives.get_def(str(weapon_data.fixed_passive_id)) if "fixed_passive_id" in weapon_data else {}
	if not str(passive_def.get("forced_element", "")).is_empty():
		instance.element = str(passive_def.get("forced_element", ""))
	var _EquipmentRandomMods = load("res://scripts/equipment/EquipmentRandomMods.gd")
	_EquipmentRandomMods.apply_weapon_drop(instance, weapon_data)
	## 天候レジェンド等: 属性値枠が必須なら不足時に追加。
	if bool(passive_def.get("guaranteed_element_power_roll", false)):
		var mods: Array = instance.random_mods if "random_mods" in instance else []
		var has_ep: bool = false
		for m: Variant in mods:
			if m is Dictionary and str(m.get("kind", "")) == "element_power":
				has_ep = true
				break
		if not has_ep and not str(instance.element).is_empty():
			var rarity: int = int(weapon_data.rarity)
			var em: Dictionary = _EquipmentRandomMods._roll_element_power_mod(weapon_data, rarity)
			mods.append(em)
			instance.element_power = int(em.get("value", 0))
			instance.random_mods = mods
			instance.perfect_roll_count = int(instance.perfect_roll_count) + (1 if bool(em.get("perfect", false)) else 0)

static func backfill_from_master(instance: Resource) -> void:
	var weapon_data: Resource = _weapon_data(instance)
	if weapon_data == null:
		return
	instance.element = str(weapon_data.element)
	var elem: String = str(weapon_data.element)
	instance.element_power = int(weapon_data.base_element_power) if not elem.is_empty() else 0
	instance.bane_class = str(weapon_data.bane_class)
	if instance.bane_class.is_empty():
		instance.bane_multiplier = 0.0
	else:
		instance.bane_multiplier = float(weapon_data.bane_multiplier)
	if not ("rolled_bonus_stats" in instance):
		var empty_stats: Array[String] = []
		instance.rolled_bonus_stats = empty_stats
	if not ("perfect_roll_count" in instance):
		instance.perfect_roll_count = 0
	if not ("on_hit_status_id" in instance):
		instance.on_hit_status_id = ""
	if not ("on_hit_status_chance" in instance):
		instance.on_hit_status_chance = 0.0

static func resolve_on_hit_status_id(weapon: Resource) -> String:
	if weapon == null or not ("on_hit_status_id" in weapon):
		return ""
	var status_id: String = str(weapon.on_hit_status_id)
	if status_id.is_empty() or not is_valid_weapon_status(status_id):
		return ""
	return status_id

static func resolve_on_hit_status_chance(weapon: Resource) -> float:
	if resolve_on_hit_status_id(weapon).is_empty():
		return 0.0
	if weapon != null and "on_hit_status_chance" in weapon:
		return clampf(float(weapon.on_hit_status_chance), 0.0, 1.0)
	return 0.0

static func is_valid_weapon_status(status_id: String) -> bool:
	return status_id in WEAPON_STATUS_POOL

static func roll_element_power(weapon_data: Resource) -> int:
	var roll: Dictionary = _roll_element_power_result(weapon_data, int(weapon_data.rarity))
	return int(roll.get("value", 0))

static func resolve_element(weapon: Resource, weapon_data: Resource = null) -> String:
	if weapon == null:
		return ""
	var data: Resource = weapon_data if weapon_data != null else _weapon_data(weapon)
	if "element" in weapon:
		return str(weapon.element)
	return str(data.element) if data != null else ""

static func resolve_element_power(weapon: Resource, weapon_data: Resource = null) -> int:
	if resolve_element(weapon, weapon_data).is_empty():
		return 0
	if weapon != null and "element_power" in weapon and int(weapon.element_power) >= 0:
		return int(weapon.element_power)
	var data: Resource = weapon_data if weapon_data != null else _weapon_data(weapon)
	if data == null:
		return 0
	return maxi(0, int(data.base_element_power) if "base_element_power" in data else 0)

static func resolve_bane(weapon: Resource, weapon_data: Resource = null) -> Dictionary:
	if weapon == null:
		return {"class": "", "mult": 1.0}
	var data: Resource = weapon_data if weapon_data != null else _weapon_data(weapon)
	var bane_class: String = ""
	if "bane_class" in weapon:
		bane_class = str(weapon.bane_class)
	elif data != null:
		bane_class = str(data.bane_class)
	if bane_class.is_empty():
		return {"class": "", "mult": 1.0}
	var mult: float = BalanceConfig.DEFAULT_BANE_MULTIPLIER
	if weapon != null and "bane_multiplier" in weapon and float(weapon.bane_multiplier) > 0.0:
		mult = float(weapon.bane_multiplier)
	elif data != null:
		mult = float(data.bane_multiplier)
	return {"class": bane_class, "mult": mult}

static func resolve_attack_speed(weapon: Resource, weapon_data: Resource = null) -> float:
	if weapon != null and float(weapon.attack_speed) > 0.0:
		return float(weapon.attack_speed)
	var data: Resource = weapon_data if weapon_data != null else _weapon_data(weapon)
	if data != null and float(data.base_attack_speed) > 0.0:
		return float(data.base_attack_speed)
	return BalanceConfig.DEFAULT_WEAPON_ATTACK_SPEED

static func resolve_critical_rate(weapon: Resource, weapon_data: Resource = null) -> float:
	if weapon != null and float(weapon.critical_rate) > 0.0:
		return float(weapon.critical_rate)
	var data: Resource = weapon_data if weapon_data != null else _weapon_data(weapon)
	if data != null and float(data.base_critical_rate) > 0.0:
		return float(data.base_critical_rate)
	return BalanceConfig.DEFAULT_WEAPON_CRITICAL_RATE

static func resolve_critical_damage(weapon: Resource) -> float:
	if weapon != null and "critical_damage" in weapon and float(weapon.critical_damage) > 0.0:
		return float(weapon.critical_damage)
	return BalanceConfig.DEFAULT_WEAPON_CRITICAL_DAMAGE

static func element_power_multiplier(element_power: int) -> float:
	if element_power <= 0:
		return 1.0
	return 1.0 + float(element_power) * BalanceConfig.ELEMENT_POWER_K

static func _build_bonus_pool(weapon_data: Resource) -> Array[String]:
	var pool: Array[String] = []
	if not str(weapon_data.element).is_empty():
		pool.append("element_power")
	if not str(weapon_data.bane_class).is_empty():
		pool.append("bane")
	pool.append("attack_speed")
	pool.append("critical_rate")
	pool.append("critical_damage")
	pool.append("on_hit_status")
	return pool

static func _reset_bonus_stats(instance: Resource) -> void:
	instance.element_power = 0
	instance.bane_class = ""
	instance.bane_multiplier = 0.0
	instance.attack_speed = 0.0
	instance.critical_rate = 0.0
	instance.critical_damage = 0.0
	instance.on_hit_status_id = ""
	instance.on_hit_status_chance = 0.0

static func _roll_bonus_stat(
	instance: Resource,
	weapon_data: Resource,
	rarity: int,
	stat_id: String
) -> bool:
	match stat_id:
		"element_power":
			return _roll_element_power_stat(instance, weapon_data, rarity)
		"bane":
			instance.bane_class = str(weapon_data.bane_class)
			instance.bane_multiplier = float(weapon_data.bane_multiplier)
			return false
		"attack_speed":
			return _roll_attack_speed_stat(instance, weapon_data, rarity)
		"critical_rate":
			return _roll_critical_rate_stat(instance, weapon_data, rarity)
		"critical_damage":
			return _roll_critical_damage_stat(instance, rarity)
		"on_hit_status":
			return _roll_on_hit_status_stat(instance, rarity)
		_:
			return false

static func _roll_element_power_stat(instance: Resource, weapon_data: Resource, rarity: int) -> bool:
	var roll: Dictionary = _roll_element_power_result(weapon_data, rarity)
	instance.element_power = int(roll.get("value", 0))
	return bool(roll.get("perfect", false))

static func _roll_element_power_result(weapon_data: Resource, rarity: int) -> Dictionary:
	var elem: String = str(weapon_data.element)
	if elem.is_empty() or not ElementResolver.is_valid_element(elem):
		return {"value": 0, "perfect": false}
	var base: int = int(weapon_data.base_element_power) if "base_element_power" in weapon_data else 0
	var roll_max: int = int(ELEMENT_POWER_ROLL_MAX.get(rarity, ELEMENT_POWER_ROLL_MAX[Enums.Rarity.COMMON]))
	var bonus_roll: Dictionary = _EquipmentRollHelper.roll_int_bonus(roll_max)
	return {
		"value": base + int(bonus_roll.get("value", 0)),
		"perfect": bool(bonus_roll.get("perfect", false)),
	}

static func _roll_attack_speed_stat(instance: Resource, weapon_data: Resource, rarity: int) -> bool:
	var max_bonus: float = float(
		ATTACK_SPEED_ROLL_MAX.get(rarity, ATTACK_SPEED_ROLL_MAX[Enums.Rarity.COMMON])
	)
	var roll: Dictionary = _EquipmentRollHelper.roll_float_bonus(max_bonus)
	instance.attack_speed = float(weapon_data.base_attack_speed) + float(roll.get("value", 0.0))
	return bool(roll.get("perfect", false))

static func _roll_critical_rate_stat(instance: Resource, weapon_data: Resource, rarity: int) -> bool:
	var max_bonus: float = float(
		CRITICAL_RATE_ROLL_MAX.get(rarity, CRITICAL_RATE_ROLL_MAX[Enums.Rarity.COMMON])
	)
	var roll: Dictionary = _EquipmentRollHelper.roll_float_bonus(max_bonus)
	instance.critical_rate = float(weapon_data.base_critical_rate) + float(roll.get("value", 0.0))
	return bool(roll.get("perfect", false))

static func _roll_critical_damage_stat(instance: Resource, rarity: int) -> bool:
	var max_bonus: float = float(
		CRITICAL_DAMAGE_ROLL_MAX.get(rarity, CRITICAL_DAMAGE_ROLL_MAX[Enums.Rarity.LEGENDARY])
	)
	var roll: Dictionary = _EquipmentRollHelper.roll_float_bonus(max_bonus)
	instance.critical_damage = BalanceConfig.DEFAULT_WEAPON_CRITICAL_DAMAGE + float(roll.get("value", 0.0))
	return bool(roll.get("perfect", false))

static func _roll_on_hit_status_stat(instance: Resource, rarity: int) -> bool:
	var pool: Array[String] = WEAPON_STATUS_POOL.duplicate()
	instance.on_hit_status_id = pool[randi() % pool.size()]
	var roll: Dictionary = _EquipmentRollHelper.roll_rate_value(
		rarity, STATUS_CHANCE_MIN_BY_RARITY, STATUS_CHANCE_MAX_BY_RARITY
	)
	instance.on_hit_status_chance = float(roll.get("value", 0.0))
	return bool(roll.get("perfect", false))

static func _weapon_data(weapon: Resource) -> Resource:
	if weapon == null or str(weapon.weapon_id).is_empty():
		return null
	return DataRegistry.get_weapon_data(str(weapon.weapon_id))
