class_name EquipmentPerfectRollHelper
extends RefCounted

## パーフェクトロール⭐️ — UI ステータス行への表示（P3-EQ-STAT-007 拡張）。

const _EquipmentRollHelper = preload("res://scripts/equipment/EquipmentRollHelper.gd")
const _WeaponStatResolver = preload("res://scripts/equipment/WeaponStatResolver.gd")
const _ArmorStatResolver = preload("res://scripts/equipment/ArmorStatResolver.gd")
const _AccessoryStatResolver = preload("res://scripts/equipment/AccessoryStatResolver.gd")

const _RATE_EPS: float = 0.0001


static func value_label(value_text: String, is_perfect: bool) -> String:
	if not is_perfect:
		return value_text
	return value_text + _EquipmentRollHelper.PERFECT_STAR


static func is_ui_stat_perfect(item: Resource, category: String, stat_key: String) -> bool:
	if item == null or stat_key.is_empty():
		return false
	match category:
		"weapon":
			return _weapon_ui_stat_perfect(item, stat_key)
		"armor":
			return _armor_ui_stat_perfect(item, stat_key)
		"accessory":
			return _accessory_ui_stat_perfect(item, stat_key)
	return false


static func _weapon_ui_stat_perfect(weapon: Resource, stat_key: String) -> bool:
	var data: Resource = DataRegistry.get_weapon_data(str(weapon.weapon_id))
	if data == null:
		return false
	var rarity: int = int(data.rarity)
	match stat_key:
		"attack":
			var roll_max: int = int(
				_WeaponStatResolver.ATTACK_ROLL_MAX.get(rarity, _WeaponStatResolver.ATTACK_ROLL_MAX[Enums.Rarity.COMMON])
			)
			var bonus: int = int(weapon.rolled_attack) - int(data.base_attack)
			return bonus >= roll_max
		"element_power":
			if not _has_rolled_stat(weapon, "element_power"):
				return false
			var base_power: int = maxi(0, int(data.base_element_power) if "base_element_power" in data else 0)
			var ep_max: int = int(
				_WeaponStatResolver.ELEMENT_POWER_ROLL_MAX.get(
					rarity, _WeaponStatResolver.ELEMENT_POWER_ROLL_MAX[Enums.Rarity.COMMON]
				)
			)
			return int(weapon.element_power) - base_power >= ep_max
		"speed":
			if not _has_rolled_stat(weapon, "attack_speed"):
				return false
			var spd_max: float = float(
				_WeaponStatResolver.ATTACK_SPEED_ROLL_MAX.get(
					rarity, _WeaponStatResolver.ATTACK_SPEED_ROLL_MAX[Enums.Rarity.COMMON]
				)
			)
			var spd_bonus: float = float(weapon.attack_speed) - float(data.base_attack_speed)
			return spd_bonus >= spd_max - _RATE_EPS
		"crit_rate":
			if not _has_rolled_stat(weapon, "critical_rate"):
				return false
			var crit_max: float = float(
				_WeaponStatResolver.CRITICAL_RATE_ROLL_MAX.get(
					rarity, _WeaponStatResolver.CRITICAL_RATE_ROLL_MAX[Enums.Rarity.COMMON]
				)
			)
			var crit_bonus: float = float(weapon.critical_rate) - float(data.base_critical_rate)
			return crit_bonus >= crit_max - _RATE_EPS
		"on_hit_status":
			if not _has_rolled_stat(weapon, "on_hit_status"):
				return false
			var chance_max: float = float(
				_WeaponStatResolver.STATUS_CHANCE_MAX_BY_RARITY.get(
					rarity, _WeaponStatResolver.STATUS_CHANCE_MAX_BY_RARITY[Enums.Rarity.COMMON]
				)
			)
			return float(weapon.on_hit_status_chance) >= chance_max - _RATE_EPS
	return false


static func _armor_ui_stat_perfect(armor: Resource, stat_key: String) -> bool:
	var data: Resource = DataRegistry.get_armor_data(str(armor.armor_id))
	if data == null:
		return false
	var rarity: int = int(data.rarity)
	match stat_key:
		"defense":
			var roll_max: int = int(
				_ArmorStatResolver.DEFENSE_ROLL_MAX.get(rarity, _ArmorStatResolver.DEFENSE_ROLL_MAX[Enums.Rarity.COMMON])
			)
			var bonus: int = int(armor.rolled_defense) - int(data.base_defense)
			return bonus >= roll_max
		"hp":
			if not _has_rolled_stat(armor, "hp_bonus"):
				return false
			var hp_max: int = int(
				_ArmorStatResolver.HP_ROLL_MAX.get(rarity, _ArmorStatResolver.HP_ROLL_MAX[Enums.Rarity.COMMON])
			)
			var base_hp: int = maxi(0, int(data.base_hp_bonus))
			return int(armor.hp_bonus) - base_hp >= hp_max
		"resist":
			if not _has_rolled_stat(armor, "resist_elements"):
				return false
			var count_max: int = int(
				_ArmorStatResolver.RESIST_ELEM_COUNT_MAX.get(
					rarity, _ArmorStatResolver.RESIST_ELEM_COUNT_MAX[Enums.Rarity.COMMON]
				)
			)
			var count_ok: bool = armor.resist_elements.size() >= count_max
			var mult_ok: bool = float(armor.resist_multiplier) <= BalanceConfig.ARMOR_RESIST_MULTIPLIER + _RATE_EPS
			return count_ok and mult_ok
		"exp_gain", "gold_gain", "rare_drop":
			return _rate_stat_perfect(armor, stat_key, rarity, _ArmorStatResolver.RATE_MAX_BY_RARITY)
		"status_immunity":
			if not _has_rolled_stat(armor, "status_immunities"):
				return false
			var imm_max: int = int(
				_ArmorStatResolver.STATUS_IMMUNITY_COUNT_MAX.get(
					rarity, _ArmorStatResolver.STATUS_IMMUNITY_COUNT_MAX[Enums.Rarity.COMMON]
				)
			)
			return armor.status_immunities.size() >= imm_max
		"evasion_rate":
			return _rate_stat_perfect(armor, stat_key, rarity, _ArmorStatResolver.EVASION_MAX_BY_RARITY)
	return false


static func _accessory_ui_stat_perfect(accessory: Resource, stat_key: String) -> bool:
	var data: Resource = DataRegistry.get_accessory_data(str(accessory.accessory_id))
	if data == null:
		return false
	var rarity: int = int(data.rarity)
	match stat_key:
		"hp":
			return _accessory_int_perfect(accessory, data, rarity, "hp_bonus", _AccessoryStatResolver.HP_ROLL_MAX)
		"attack":
			return _accessory_int_perfect(accessory, data, rarity, "attack_bonus", _AccessoryStatResolver.ATTACK_ROLL_MAX)
		"defense":
			return _accessory_int_perfect(accessory, data, rarity, "defense_bonus", _AccessoryStatResolver.DEFENSE_ROLL_MAX)
		"crit_rate":
			if not _has_rolled_stat(accessory, "crit_rate_bonus"):
				return false
			var crit_max: float = float(
				_AccessoryStatResolver.CRIT_ROLL_MAX.get(rarity, _AccessoryStatResolver.CRIT_ROLL_MAX[Enums.Rarity.COMMON])
			)
			var base_crit: float = maxf(0.0, float(data.crit_rate_bonus))
			return float(accessory.crit_rate_bonus) - base_crit >= crit_max - _RATE_EPS
		"exp_gain", "gold_gain", "rare_drop":
			return _rate_stat_perfect(accessory, stat_key, rarity, _AccessoryStatResolver.RATE_MAX_BY_RARITY)
		"evasion_rate":
			return _rate_stat_perfect(accessory, stat_key, rarity, _AccessoryStatResolver.EVASION_MAX_BY_RARITY)
	return false


static func _accessory_int_perfect(
	item: Resource,
	data: Resource,
	rarity: int,
	rolled_id: String,
	roll_table: Dictionary
) -> bool:
	if not _has_rolled_stat(item, rolled_id):
		return false
	var roll_max: int = int(roll_table.get(rarity, roll_table[Enums.Rarity.COMMON]))
	var base_val: int = maxi(0, int(data.get(rolled_id)))
	return int(item.get(rolled_id)) - base_val >= roll_max


static func _rate_stat_perfect(
	item: Resource,
	stat_key: String,
	rarity: int,
	max_table: Dictionary
) -> bool:
	var rolled_id: String = _rate_rolled_id(stat_key)
	if rolled_id.is_empty() or not _has_rolled_stat(item, rolled_id):
		return false
	var max_rate: float = float(max_table.get(rarity, max_table[Enums.Rarity.COMMON]))
	return float(item.get(rolled_id)) >= max_rate - _RATE_EPS


static func _rate_rolled_id(stat_key: String) -> String:
	match stat_key:
		"exp_gain":
			return "exp_gain_rate"
		"gold_gain":
			return "gold_gain_rate"
		"rare_drop":
			return "rare_drop_rate"
		"evasion_rate":
			return "evasion_rate"
	return ""


static func _has_rolled_stat(item: Resource, stat_id: String) -> bool:
	if item == null or not ("rolled_bonus_stats" in item):
		return false
	return stat_id in item.rolled_bonus_stats
