class_name EquipmentPerfectRollHelper
extends RefCounted

## パーフェクトロール⭐️ — UI ステータス行への表示（P3-EQ-STAT-007 拡張）。
## ランダム値の上下限 `(min〜max)` もここで付与する。

const _EquipmentRollHelper = preload("res://scripts/equipment/EquipmentRollHelper.gd")
const _EquipmentEnhancer = preload("res://scripts/equipment/EquipmentEnhancer.gd")
const _WeaponStatResolver = preload("res://scripts/equipment/WeaponStatResolver.gd")
const _ArmorStatResolver = preload("res://scripts/equipment/ArmorStatResolver.gd")
const _AccessoryStatResolver = preload("res://scripts/equipment/AccessoryStatResolver.gd")

const _RATE_EPS: float = 0.0001


static func value_label(value_text: String, is_perfect: bool) -> String:
	if not is_perfect:
		return value_text
	return value_text + _EquipmentRollHelper.PERFECT_STAR


## 例: `30%(10〜40)` / `120(100〜140)`。レンジ無しなら空文字。
static func range_suffix(item: Resource, category: String, stat_key: String) -> String:
	var bounds: Dictionary = roll_bounds_display(item, category, stat_key)
	if bounds.is_empty():
		return ""
	return "(%s〜%s)" % [str(bounds["min"]), str(bounds["max"])]


## UI 表示単位の上下限。キー min/max（String）。対象外は空 Dictionary。
static func roll_bounds_display(item: Resource, category: String, stat_key: String) -> Dictionary:
	if item == null or stat_key.is_empty():
		return {}
	match category:
		"weapon":
			return _weapon_roll_bounds(item, stat_key)
		"armor":
			return _armor_roll_bounds(item, stat_key)
		"accessory":
			return _accessory_roll_bounds(item, stat_key)
	return {}


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


static func _table_number(table: Dictionary, rarity: int) -> Variant:
	if table.has(rarity):
		return table[rarity]
	if rarity >= Enums.Rarity.LEGENDARY and table.has(Enums.Rarity.LEGENDARY):
		return table[Enums.Rarity.LEGENDARY]
	return table.get(Enums.Rarity.COMMON, 0)


static func _bounds_int(lo: int, hi: int) -> Dictionary:
	if hi < lo:
		return {}
	return {"min": str(lo), "max": str(hi)}


static func _bounds_float1(lo: float, hi: float) -> Dictionary:
	if hi + _RATE_EPS < lo:
		return {}
	return {"min": "%.1f" % lo, "max": "%.1f" % hi}


static func _bounds_percent_points(lo_rate: float, hi_rate: float) -> Dictionary:
	if hi_rate + _RATE_EPS < lo_rate:
		return {}
	return {
		"min": str(int(round(lo_rate * 100.0))),
		"max": str(int(round(hi_rate * 100.0))),
	}


static func _weapon_roll_bounds(weapon: Resource, stat_key: String) -> Dictionary:
	var data: Resource = DataRegistry.get_weapon_data(str(weapon.weapon_id))
	if data == null:
		return {}
	var rarity: int = int(data.rarity)
	match stat_key:
		"attack":
			var roll_max: int = int(_table_number(_WeaponStatResolver.ATTACK_ROLL_MAX, rarity))
			var lo_raw: int = int(data.base_attack)
			var hi_raw: int = lo_raw + roll_max
			var lv: int = _EquipmentEnhancer.get_equip_level(weapon)
			var forge: int = _EquipmentEnhancer.get_enhance_level(weapon) * BalanceConfig.EQUIP_FORGE_FLAT_PER_LEVEL
			var lo: int = _EquipmentEnhancer.scale_equip_stat(lo_raw, lv, rarity) + forge
			var hi: int = _EquipmentEnhancer.scale_equip_stat(hi_raw, lv, rarity) + forge
			return _bounds_int(lo, hi)
		"element_power":
			if not _has_rolled_stat(weapon, "element_power"):
				return {}
			var base_power: int = maxi(0, int(data.base_element_power) if "base_element_power" in data else 0)
			var ep_max: int = int(_table_number(_WeaponStatResolver.ELEMENT_POWER_ROLL_MAX, rarity))
			return _bounds_int(base_power, base_power + ep_max)
		"speed":
			if not _has_rolled_stat(weapon, "attack_speed"):
				return {}
			var base_spd: float = float(data.base_attack_speed)
			if base_spd <= 0.0:
				base_spd = BalanceConfig.DEFAULT_WEAPON_ATTACK_SPEED
			var spd_max: float = float(_table_number(_WeaponStatResolver.ATTACK_SPEED_ROLL_MAX, rarity))
			return _bounds_float1(base_spd, base_spd + spd_max)
		"crit_rate":
			if not _has_rolled_stat(weapon, "critical_rate"):
				return {}
			var base_crit: float = float(data.base_critical_rate)
			if base_crit <= 0.0:
				base_crit = BalanceConfig.DEFAULT_WEAPON_CRITICAL_RATE
			var crit_max: float = float(_table_number(_WeaponStatResolver.CRITICAL_RATE_ROLL_MAX, rarity))
			return _bounds_percent_points(base_crit, base_crit + crit_max)
		"on_hit_status":
			if not _has_rolled_stat(weapon, "on_hit_status"):
				return {}
			var cmin: float = float(_table_number(_WeaponStatResolver.STATUS_CHANCE_MIN_BY_RARITY, rarity))
			var cmax: float = float(_table_number(_WeaponStatResolver.STATUS_CHANCE_MAX_BY_RARITY, rarity))
			return _bounds_percent_points(cmin, cmax)
	return {}


static func _armor_roll_bounds(armor: Resource, stat_key: String) -> Dictionary:
	var data: Resource = DataRegistry.get_armor_data(str(armor.armor_id))
	if data == null:
		return {}
	var rarity: int = int(data.rarity)
	match stat_key:
		"defense":
			var roll_max: int = int(_table_number(_ArmorStatResolver.DEFENSE_ROLL_MAX, rarity))
			var lo: int = int(data.base_defense)
			return _bounds_int(lo, lo + roll_max)
		"hp":
			if not _has_rolled_stat(armor, "hp_bonus"):
				return {}
			var base_hp: int = maxi(0, int(data.base_hp_bonus))
			var hp_max: int = int(_table_number(_ArmorStatResolver.HP_ROLL_MAX, rarity))
			return _bounds_int(base_hp, base_hp + hp_max)
		"exp_gain", "gold_gain", "rare_drop":
			if not _has_rolled_stat(armor, _rate_rolled_id(stat_key)):
				return {}
			return _bounds_percent_points(
				float(_table_number(_ArmorStatResolver.RATE_MIN_BY_RARITY, rarity)),
				float(_table_number(_ArmorStatResolver.RATE_MAX_BY_RARITY, rarity))
			)
		"evasion_rate":
			if not _has_rolled_stat(armor, "evasion_rate"):
				return {}
			return _bounds_percent_points(
				float(_table_number(_ArmorStatResolver.EVASION_MIN_BY_RARITY, rarity)),
				float(_table_number(_ArmorStatResolver.EVASION_MAX_BY_RARITY, rarity))
			)
	return {}


static func _accessory_roll_bounds(accessory: Resource, stat_key: String) -> Dictionary:
	var data: Resource = DataRegistry.get_accessory_data(str(accessory.accessory_id))
	if data == null:
		return {}
	var rarity: int = int(data.rarity)
	match stat_key:
		"hp":
			return _accessory_int_bounds(accessory, data, rarity, "hp_bonus", _AccessoryStatResolver.HP_ROLL_MAX)
		"attack":
			return _accessory_int_bounds(accessory, data, rarity, "attack_bonus", _AccessoryStatResolver.ATTACK_ROLL_MAX)
		"defense":
			return _accessory_int_bounds(accessory, data, rarity, "defense_bonus", _AccessoryStatResolver.DEFENSE_ROLL_MAX)
		"crit_rate":
			if not _has_rolled_stat(accessory, "crit_rate_bonus"):
				return {}
			var base_crit: float = maxf(0.0, float(data.crit_rate_bonus))
			var crit_max: float = float(_table_number(_AccessoryStatResolver.CRIT_ROLL_MAX, rarity))
			return _bounds_percent_points(base_crit, base_crit + crit_max)
		"exp_gain", "gold_gain", "rare_drop":
			if not _has_rolled_stat(accessory, _rate_rolled_id(stat_key)):
				return {}
			return _bounds_percent_points(
				float(_table_number(_AccessoryStatResolver.RATE_MIN_BY_RARITY, rarity)),
				float(_table_number(_AccessoryStatResolver.RATE_MAX_BY_RARITY, rarity))
			)
		"evasion_rate":
			if not _has_rolled_stat(accessory, "evasion_rate"):
				return {}
			return _bounds_percent_points(
				float(_table_number(_AccessoryStatResolver.EVASION_MIN_BY_RARITY, rarity)),
				float(_table_number(_AccessoryStatResolver.EVASION_MAX_BY_RARITY, rarity))
			)
	return {}


static func _accessory_int_bounds(
	item: Resource,
	data: Resource,
	rarity: int,
	rolled_id: String,
	roll_table: Dictionary
) -> Dictionary:
	if not _has_rolled_stat(item, rolled_id):
		return {}
	var base_val: int = maxi(0, int(data.get(rolled_id)))
	var roll_max: int = int(_table_number(roll_table, rarity))
	return _bounds_int(base_val, base_val + roll_max)
