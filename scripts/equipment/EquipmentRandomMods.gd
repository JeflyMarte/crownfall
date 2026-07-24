class_name EquipmentRandomMods
extends RefCounted

## P3-EQ-DIABLO-001 — ランダムステ一本化（Affix＋旧任意ロール）。
## インスタンスの random_mods: Array[Dictionary]
## 各要素: id, label, kind, value, min_v, max_v, perfect, meta(Dictionary)

const _EquipmentRollHelper = preload("res://scripts/equipment/EquipmentRollHelper.gd")
const _WeaponStatResolver = preload("res://scripts/equipment/WeaponStatResolver.gd")
const _ArmorStatResolver = preload("res://scripts/equipment/ArmorStatResolver.gd")
const _AccessoryStatResolver = preload("res://scripts/equipment/AccessoryStatResolver.gd")

const KIND_ATTACK_UP: String = "attack_up"
const KIND_DEFENSE_UP: String = "defense_up"
const KIND_HP_UP: String = "hp_up"
const KIND_ATTACK_SPEED: String = "attack_speed"
const KIND_CRIT_RATE: String = "crit_rate"
const KIND_CRIT_DAMAGE: String = "crit_damage"
const KIND_ON_HIT: String = "on_hit_status"
const KIND_ELEMENT_POWER: String = "element_power"
const KIND_BANE: String = "bane"
const KIND_GOLD_GAIN: String = "gold_gain"
const KIND_EXP_GAIN: String = "exp_gain"
const KIND_RARE_DROP: String = "rare_drop"
const KIND_HEALING: String = "healing"
const KIND_EVASION: String = "evasion"
const KIND_RESIST: String = "resist_elements"
const KIND_IMMUNITY: String = "status_immunities"
const KIND_CHILL: String = "chill_chance"
const KIND_SHOCK: String = "shock_chance"
const KIND_IGNITE: String = "ignite_chance"
const KIND_POISON: String = "poison_chance"


static func get_mods(item: Resource) -> Array:
	if item == null:
		return []
	ensure_migrated(item)
	if not ("random_mods" in item):
		return []
	var raw: Variant = item.random_mods
	if raw is Array:
		return raw as Array
	return []


static func sum_kind_int(item: Resource, kind: String) -> int:
	var total: int = 0
	for mod: Variant in get_mods(item):
		if mod is Dictionary and str(mod.get("kind", "")) == kind:
			total += int(mod.get("value", 0))
	return total


static func sum_kind_float(item: Resource, kind: String) -> float:
	var total: float = 0.0
	for mod: Variant in get_mods(item):
		if mod is Dictionary and str(mod.get("kind", "")) == kind:
			total += float(mod.get("value", 0.0))
	return total


## ensure_migrated 経由の再帰を避ける（normalize 用）。
static func _sum_kind_raw(item: Resource, kind: String) -> int:
	if item == null or not ("random_mods" in item):
		return 0
	var raw: Variant = item.random_mods
	if not raw is Array:
		return 0
	var total: int = 0
	for mod: Variant in raw as Array:
		if mod is Dictionary and str(mod.get("kind", "")) == kind:
			total += int(mod.get("value", 0))
	return total


static func apply_weapon_drop(instance: Resource, weapon_data: Resource) -> void:
	if instance == null or weapon_data == null:
		return
	var rarity: int = int(weapon_data.rarity)
	var mods: Array = _roll_weapon_mods(weapon_data, rarity)
	_apply_weapon_mods_to_fields(instance, weapon_data, mods)
	instance.random_mods = mods
	_clear_legacy_affix_ids(instance)
	instance.rolled_bonus_stats = _ids_from_mods(mods)
	instance.perfect_roll_count = _count_perfect(mods)
	instance.is_appraised = true


static func apply_armor_drop(instance: Resource, armor_data: Resource) -> void:
	if instance == null or armor_data == null:
		return
	var rarity: int = int(armor_data.rarity)
	var mods: Array = _roll_armor_mods(armor_data, rarity)
	_apply_armor_mods_to_fields(instance, armor_data, mods)
	instance.random_mods = mods
	_clear_legacy_affix_ids(instance)
	instance.rolled_bonus_stats = _ids_from_mods(mods)
	instance.perfect_roll_count = _count_perfect(mods)
	instance.is_appraised = true


static func apply_accessory_drop(instance: Resource, accessory_data: Resource) -> void:
	if instance == null or accessory_data == null:
		return
	var rarity: int = int(accessory_data.rarity)
	var mods: Array = _roll_accessory_mods(accessory_data, rarity)
	_apply_accessory_mods_to_fields(instance, accessory_data, mods)
	instance.random_mods = mods
	_clear_legacy_affix_ids(instance)
	instance.rolled_bonus_stats = _ids_from_mods(mods)
	instance.perfect_roll_count = _count_perfect(mods)
	instance.is_appraised = true


static func _clear_legacy_affix_ids(instance: Resource) -> void:
	## Array[String] へ素の [] を代入すると Invalid assignment になる。
	var empty: Array[String] = []
	instance.set("prefix_ids", empty.duplicate())
	instance.set("suffix_ids", empty.duplicate())


static func ensure_migrated(item: Resource) -> void:
	if item == null:
		return
	if not ("random_mods" in item):
		item.set("random_mods", [])
	var existing: Array = item.random_mods if item.random_mods is Array else []
	if not existing.is_empty():
		_normalize_fixed_primary(item)
		return
	var category: String = _item_category(item)
	match category:
		"weapon":
			_migrate_weapon(item)
		"armor":
			_migrate_armor(item)
		"accessory":
			_migrate_accessory(item)
		_:
			pass


static func format_mod_line(mod: Dictionary) -> String:
	var label: String = str(mod.get("label", ""))
	var kind: String = str(mod.get("kind", ""))
	var value: float = float(mod.get("value", 0.0))
	var min_v: float = float(mod.get("min_v", value))
	var max_v: float = float(mod.get("max_v", value))
	var star: String = "⭐️" if bool(mod.get("perfect", false)) else ""
	match kind:
		KIND_ATTACK_UP, KIND_DEFENSE_UP, KIND_HP_UP, KIND_HEALING, KIND_ELEMENT_POWER:
			return "%s +%d (%d〜%d)%s" % [label, int(value), int(min_v), int(max_v), star]
		KIND_BANE:
			var bclass: String = str(mod.get("meta", {}).get("bane_class", ""))
			var mult: float = float(mod.get("meta", {}).get("bane_mult", 1.3))
			return "%s %s ×%.1f%s" % [label, bclass, mult, star]
		KIND_ON_HIT:
			var sid: String = str(mod.get("meta", {}).get("status_id", ""))
			var sname: String = sid
			var se: Resource = DataRegistry.get_status_effect(sid)
			if se != null:
				sname = str(se.display_name)
			return "%s %s %.0f%% (%.0f〜%.0f%%)%s" % [
				label, sname, value * 100.0, min_v * 100.0, max_v * 100.0, star
			]
		KIND_RESIST:
			var elems: Array = mod.get("meta", {}).get("elements", [])
			var names: PackedStringArray = PackedStringArray()
			for e: Variant in elems:
				names.append(str(e))
			return "%s %s ×%.2f%s" % [label, "・".join(names), value, star]
		KIND_IMMUNITY:
			var ids: Array = mod.get("meta", {}).get("status_ids", [])
			var labels: PackedStringArray = PackedStringArray()
			for sid2: Variant in ids:
				var se2: Resource = DataRegistry.get_status_effect(str(sid2))
				labels.append(str(se2.display_name) if se2 != null else str(sid2))
			return "%s %s%s" % [label, "・".join(labels), star]
		KIND_ATTACK_SPEED:
			return "%s +%.2f (%.2f〜%.2f)%s" % [label, value, min_v, max_v, star]
		_:
			## 率系
			return "%s +%.0f%% (%.0f〜%.0f%%)%s" % [
				label, value * 100.0, min_v * 100.0, max_v * 100.0, star
			]


static func _roll_weapon_mods(weapon_data: Resource, rarity: int) -> Array:
	var slots: int = _EquipmentRollHelper.random_stat_count(rarity)
	var mods: Array = []
	var used: Dictionary = {}
	## A2: マスタ属性／特攻は必ず枠消費して付与。残りを通常プールから。
	var has_el: bool = not str(weapon_data.element).is_empty()
	var has_bane: bool = not str(weapon_data.bane_class).is_empty()
	var reserved: int = (1 if has_el else 0) + (1 if has_bane else 0)
	if has_el:
		mods.append(_roll_element_power_mod(weapon_data, rarity))
		used[KIND_ELEMENT_POWER] = true
	if has_bane:
		mods.append(_make_bane_mod(weapon_data))
		used[KIND_BANE] = true
	var remain: int = maxi(0, slots - reserved)
	var pool: Array[String] = _weapon_pool_ids(weapon_data, used)
	var picked: Array[String] = _EquipmentRollHelper.pick_random_stats(pool, remain)
	for pid: String in picked:
		var mod: Dictionary = _roll_weapon_pool_mod(pid, weapon_data, rarity)
		if not mod.is_empty():
			mods.append(mod)
	return mods


static func _roll_armor_mods(_armor_data: Resource, rarity: int) -> Array:
	var slots: int = _EquipmentRollHelper.random_stat_count(rarity)
	var pool: Array[String] = [
		KIND_HP_UP, KIND_DEFENSE_UP, KIND_RESIST, KIND_EVASION,
		KIND_EXP_GAIN, KIND_GOLD_GAIN, KIND_RARE_DROP, KIND_IMMUNITY, KIND_HEALING,
	]
	var picked: Array[String] = _EquipmentRollHelper.pick_random_stats(pool, slots)
	var mods: Array = []
	for pid: String in picked:
		var mod: Dictionary = _roll_armor_pool_mod(pid, rarity)
		if not mod.is_empty():
			mods.append(mod)
	return mods


static func _roll_accessory_mods(_accessory_data: Resource, rarity: int) -> Array:
	var slots: int = _EquipmentRollHelper.random_stat_count(rarity)
	var pool: Array[String] = [
		KIND_HP_UP, KIND_ATTACK_UP, KIND_DEFENSE_UP, KIND_CRIT_RATE, KIND_EVASION,
		KIND_EXP_GAIN, KIND_GOLD_GAIN, KIND_RARE_DROP, KIND_HEALING,
	]
	var picked: Array[String] = _EquipmentRollHelper.pick_random_stats(pool, slots)
	var mods: Array = []
	for pid: String in picked:
		var mod: Dictionary = _roll_accessory_pool_mod(pid, rarity)
		if not mod.is_empty():
			mods.append(mod)
	return mods


static func _weapon_pool_ids(weapon_data: Resource, used: Dictionary) -> Array[String]:
	var pool: Array[String] = [
		KIND_ATTACK_UP, KIND_DEFENSE_UP, KIND_ATTACK_SPEED, KIND_CRIT_RATE, KIND_CRIT_DAMAGE,
		KIND_ON_HIT, KIND_GOLD_GAIN, KIND_CHILL, KIND_SHOCK, KIND_IGNITE, KIND_POISON,
	]
	if not str(weapon_data.element).is_empty() and not used.has(KIND_ELEMENT_POWER):
		pool.append(KIND_ELEMENT_POWER)
	if not str(weapon_data.bane_class).is_empty() and not used.has(KIND_BANE):
		pool.append(KIND_BANE)
	var out: Array[String] = []
	for id: String in pool:
		if used.has(id):
			continue
		out.append(id)
	return out


static func _roll_weapon_pool_mod(pid: String, weapon_data: Resource, rarity: int) -> Dictionary:
	match pid:
		KIND_ATTACK_UP:
			return _roll_int_mod(
				KIND_ATTACK_UP, "攻撃力アップ",
				1,
				int(_WeaponStatResolver.ATTACK_ROLL_MAX.get(rarity, 40))
			)
		KIND_DEFENSE_UP:
			return _roll_int_mod(KIND_DEFENSE_UP, "防御力アップ", 8, 16)
		KIND_ATTACK_SPEED:
			var base_spd: float = float(weapon_data.base_attack_speed)
			if base_spd <= 0.0:
				base_spd = BalanceConfig.DEFAULT_WEAPON_ATTACK_SPEED
			var mx: float = float(_WeaponStatResolver.ATTACK_SPEED_ROLL_MAX.get(rarity, 0.1))
			return _roll_float_mod(KIND_ATTACK_SPEED, "攻撃速度", 0.01, mx)
		KIND_CRIT_RATE:
			var mx2: float = float(_WeaponStatResolver.CRITICAL_RATE_ROLL_MAX.get(rarity, 0.05))
			return _roll_float_mod(KIND_CRIT_RATE, "会心率", 0.01, mx2)
		KIND_CRIT_DAMAGE:
			var mx3: float = float(_WeaponStatResolver.CRITICAL_DAMAGE_ROLL_MAX.get(rarity, 0.15))
			return _roll_float_mod(KIND_CRIT_DAMAGE, "会心ダメ", 0.05, mx3)
		KIND_ON_HIT:
			return _roll_on_hit_mod(rarity)
		KIND_GOLD_GAIN:
			return _roll_float_mod(KIND_GOLD_GAIN, "ゴールド獲得", 0.05, 0.10)
		KIND_ELEMENT_POWER:
			return _roll_element_power_mod(weapon_data, rarity)
		KIND_BANE:
			return _make_bane_mod(weapon_data)
		KIND_CHILL:
			return _fixed_rate_mod(KIND_CHILL, "冷却付与", 0.25)
		KIND_SHOCK:
			return _fixed_rate_mod(KIND_SHOCK, "感電付与", 0.30)
		KIND_IGNITE:
			return _fixed_rate_mod(KIND_IGNITE, "炎上付与", 0.25)
		KIND_POISON:
			return _fixed_rate_mod(KIND_POISON, "毒付与", 0.25)
		_:
			return {}


static func _roll_armor_pool_mod(pid: String, rarity: int) -> Dictionary:
	match pid:
		KIND_HP_UP:
			return _roll_int_mod(
				KIND_HP_UP, "HPアップ",
				4,
				int(_ArmorStatResolver.HP_ROLL_MAX.get(rarity, 64))
			)
		KIND_DEFENSE_UP:
			return _roll_int_mod(
				KIND_DEFENSE_UP, "防御力アップ",
				1,
				int(_ArmorStatResolver.DEFENSE_ROLL_MAX.get(rarity, 32))
			)
		KIND_RESIST:
			return _roll_resist_mod(rarity)
		KIND_EVASION:
			return _roll_rate_table_mod(
				KIND_EVASION, "回避率",
				_ArmorStatResolver.EVASION_MIN_BY_RARITY,
				_ArmorStatResolver.EVASION_MAX_BY_RARITY,
				rarity
			)
		KIND_EXP_GAIN:
			return _roll_rate_table_mod(
				KIND_EXP_GAIN, "経験値獲得",
				_ArmorStatResolver.RATE_MIN_BY_RARITY,
				_ArmorStatResolver.RATE_MAX_BY_RARITY,
				rarity
			)
		KIND_GOLD_GAIN:
			return _roll_rate_table_mod(
				KIND_GOLD_GAIN, "ゴールド獲得",
				_ArmorStatResolver.RATE_MIN_BY_RARITY,
				_ArmorStatResolver.RATE_MAX_BY_RARITY,
				rarity
			)
		KIND_RARE_DROP:
			return _roll_rate_table_mod(
				KIND_RARE_DROP, "レアドロップ",
				_ArmorStatResolver.RATE_MIN_BY_RARITY,
				_ArmorStatResolver.RATE_MAX_BY_RARITY,
				rarity
			)
		KIND_IMMUNITY:
			return _roll_immunity_mod(rarity)
		KIND_HEALING:
			return _roll_int_mod(KIND_HEALING, "回復量アップ", 20, 40)
		_:
			return {}


static func _roll_accessory_pool_mod(pid: String, rarity: int) -> Dictionary:
	match pid:
		KIND_HP_UP:
			return _roll_int_mod(
				KIND_HP_UP, "HPアップ",
				4,
				int(_AccessoryStatResolver.HP_ROLL_MAX.get(rarity, 48))
			)
		KIND_ATTACK_UP:
			return _roll_int_mod(
				KIND_ATTACK_UP, "攻撃力アップ",
				1,
				int(_AccessoryStatResolver.ATTACK_ROLL_MAX.get(rarity, 24))
			)
		KIND_DEFENSE_UP:
			return _roll_int_mod(
				KIND_DEFENSE_UP, "防御力アップ",
				1,
				int(_AccessoryStatResolver.DEFENSE_ROLL_MAX.get(rarity, 24))
			)
		KIND_CRIT_RATE:
			var mx: float = float(_AccessoryStatResolver.CRIT_ROLL_MAX.get(rarity, 0.03))
			return _roll_float_mod(KIND_CRIT_RATE, "会心率", 0.01, mx)
		KIND_EVASION:
			return _roll_rate_table_mod(
				KIND_EVASION, "回避率",
				_AccessoryStatResolver.EVASION_MIN_BY_RARITY,
				_AccessoryStatResolver.EVASION_MAX_BY_RARITY,
				rarity
			)
		KIND_EXP_GAIN:
			return _roll_rate_table_mod(
				KIND_EXP_GAIN, "経験値獲得",
				_AccessoryStatResolver.RATE_MIN_BY_RARITY,
				_AccessoryStatResolver.RATE_MAX_BY_RARITY,
				rarity
			)
		KIND_GOLD_GAIN:
			return _roll_rate_table_mod(
				KIND_GOLD_GAIN, "ゴールド獲得",
				_AccessoryStatResolver.RATE_MIN_BY_RARITY,
				_AccessoryStatResolver.RATE_MAX_BY_RARITY,
				rarity
			)
		KIND_RARE_DROP:
			return _roll_rate_table_mod(
				KIND_RARE_DROP, "レアドロップ",
				_AccessoryStatResolver.RATE_MIN_BY_RARITY,
				_AccessoryStatResolver.RATE_MAX_BY_RARITY,
				rarity
			)
		KIND_HEALING:
			return _roll_int_mod(KIND_HEALING, "回復量アップ", 20, 40)
		_:
			return {}


static func _roll_int_mod(kind: String, label: String, min_v: int, max_v: int) -> Dictionary:
	max_v = maxi(min_v, max_v)
	var roll: Dictionary = _EquipmentRollHelper.roll_int_bonus(max_v - min_v)
	var value: int = min_v + int(roll.get("value", 0))
	var perfect: bool = value >= max_v
	return {
		"id": kind,
		"label": label,
		"kind": kind,
		"value": value,
		"min_v": min_v,
		"max_v": max_v,
		"perfect": perfect,
		"meta": {},
	}


static func _roll_float_mod(kind: String, label: String, min_v: float, max_v: float) -> Dictionary:
	max_v = maxf(min_v, max_v)
	var roll: Dictionary = _EquipmentRollHelper.roll_float_bonus(max_v - min_v)
	var value: float = min_v + float(roll.get("value", 0.0))
	var perfect: bool = value >= max_v - 0.0001
	return {
		"id": kind,
		"label": label,
		"kind": kind,
		"value": value,
		"min_v": min_v,
		"max_v": max_v,
		"perfect": perfect,
		"meta": {},
	}


static func _roll_rate_table_mod(
	kind: String, label: String, min_table: Dictionary, max_table: Dictionary, rarity: int
) -> Dictionary:
	var roll: Dictionary = _EquipmentRollHelper.roll_rate_value(rarity, min_table, max_table)
	var value: float = float(roll.get("value", 0.0))
	var min_v: float = float(min_table.get(rarity, 0.01))
	var max_v: float = float(max_table.get(rarity, 0.02))
	return {
		"id": kind,
		"label": label,
		"kind": kind,
		"value": value,
		"min_v": min_v,
		"max_v": max_v,
		"perfect": bool(roll.get("perfect", false)),
		"meta": {},
	}


static func _fixed_rate_mod(kind: String, label: String, value: float) -> Dictionary:
	return {
		"id": kind,
		"label": label,
		"kind": kind,
		"value": value,
		"min_v": value,
		"max_v": value,
		"perfect": true,
		"meta": {},
	}


static func _roll_element_power_mod(weapon_data: Resource, rarity: int) -> Dictionary:
	var base_power: int = maxi(0, int(weapon_data.base_element_power) if "base_element_power" in weapon_data else 0)
	var roll_max: int = int(_WeaponStatResolver.ELEMENT_POWER_ROLL_MAX.get(rarity, 5))
	var roll: Dictionary = _EquipmentRollHelper.roll_int_bonus(roll_max)
	var bonus: int = int(roll.get("value", 0))
	var value: int = base_power + bonus
	return {
		"id": KIND_ELEMENT_POWER,
		"label": "属性値",
		"kind": KIND_ELEMENT_POWER,
		"value": value,
		"min_v": base_power,
		"max_v": base_power + roll_max,
		"perfect": bonus >= roll_max,
		"meta": {"element": str(weapon_data.element)},
	}


static func _make_bane_mod(weapon_data: Resource) -> Dictionary:
	return {
		"id": KIND_BANE,
		"label": "種族特攻",
		"kind": KIND_BANE,
		"value": 1.0,
		"min_v": 1.0,
		"max_v": 1.0,
		"perfect": false,
		"meta": {
			"bane_class": str(weapon_data.bane_class),
			"bane_mult": float(weapon_data.bane_multiplier) if float(weapon_data.bane_multiplier) > 0.0 else 1.3,
		},
	}


static func _roll_on_hit_mod(rarity: int) -> Dictionary:
	var pool: Array[String] = _WeaponStatResolver.WEAPON_STATUS_POOL
	var sid: String = pool[randi() % pool.size()]
	var roll: Dictionary = _EquipmentRollHelper.roll_rate_value(
		rarity,
		_WeaponStatResolver.STATUS_CHANCE_MIN_BY_RARITY,
		_WeaponStatResolver.STATUS_CHANCE_MAX_BY_RARITY
	)
	var value: float = float(roll.get("value", 0.15))
	return {
		"id": KIND_ON_HIT,
		"label": "状態付与",
		"kind": KIND_ON_HIT,
		"value": value,
		"min_v": float(_WeaponStatResolver.STATUS_CHANCE_MIN_BY_RARITY.get(rarity, 0.15)),
		"max_v": float(_WeaponStatResolver.STATUS_CHANCE_MAX_BY_RARITY.get(rarity, 0.25)),
		"perfect": bool(roll.get("perfect", false)),
		"meta": {"status_id": sid},
	}


static func _roll_resist_mod(rarity: int) -> Dictionary:
	## 旧 ArmorStatResolver._roll_resist_multiplier と同レンジ（弱い〜強い＝min〜ARMOR_RESIST）。
	var roll: Dictionary = _ArmorStatResolver._roll_resist_multiplier(rarity)
	var mult: float = float(roll.get("value", BalanceConfig.ARMOR_RESIST_MULTIPLIER))
	var weak: float = float(
		_ArmorStatResolver.RESIST_MULT_MIN_BY_RARITY.get(rarity, 0.88)
	)
	var count_max: int = int(_ArmorStatResolver.RESIST_ELEM_COUNT_MAX.get(rarity, 1))
	var n: int = maxi(1, mini(count_max, 1 + randi() % maxi(1, count_max)))
	var elems: Array[String] = []
	var all_e: Array[String] = ["fire", "ice", "lightning", "dark", "holy"]
	all_e.shuffle()
	for i in n:
		elems.append(all_e[i])
	return {
		"id": KIND_RESIST,
		"label": "属性耐性",
		"kind": KIND_RESIST,
		"value": mult,
		"min_v": BalanceConfig.ARMOR_RESIST_MULTIPLIER,
		"max_v": weak,
		"perfect": bool(roll.get("perfect", false)),
		"meta": {"elements": elems},
	}


static func _roll_immunity_mod(rarity: int) -> Dictionary:
	var count_max: int = int(_ArmorStatResolver.STATUS_IMMUNITY_COUNT_MAX.get(rarity, 1))
	var n: int = maxi(1, mini(count_max, 1))
	var pool: Array[String] = _ArmorStatResolver.STATUS_IMMUNITY_POOL.duplicate()
	pool.shuffle()
	var ids: Array[String] = []
	for i in n:
		ids.append(pool[i])
	return {
		"id": KIND_IMMUNITY,
		"label": "状態異常無効",
		"kind": KIND_IMMUNITY,
		"value": 1.0,
		"min_v": 1.0,
		"max_v": 1.0,
		"perfect": false,
		"meta": {"status_ids": ids},
	}


static func _apply_weapon_mods_to_fields(instance: Resource, weapon_data: Resource, mods: Array) -> void:
	_WeaponStatResolver._reset_bonus_stats(instance)
	instance.element = str(weapon_data.element)
	instance.element_power = 0
	for mod: Variant in mods:
		if not mod is Dictionary:
			continue
		var kind: String = str(mod.get("kind", ""))
		var value: float = float(mod.get("value", 0.0))
		var meta: Dictionary = mod.get("meta", {}) if mod.get("meta", {}) is Dictionary else {}
		match kind:
			KIND_ATTACK_SPEED:
				instance.attack_speed = float(weapon_data.base_attack_speed) + value
			KIND_CRIT_RATE:
				instance.critical_rate = float(weapon_data.base_critical_rate) + value
			KIND_CRIT_DAMAGE:
				instance.critical_damage = BalanceConfig.DEFAULT_WEAPON_CRITICAL_DAMAGE + value
			KIND_ON_HIT:
				instance.on_hit_status_id = str(meta.get("status_id", ""))
				instance.on_hit_status_chance = value
			KIND_ELEMENT_POWER:
				instance.element_power = int(value)
			KIND_BANE:
				instance.bane_class = str(meta.get("bane_class", ""))
				instance.bane_multiplier = float(meta.get("bane_mult", 1.3))
			KIND_CHILL, KIND_SHOCK, KIND_IGNITE, KIND_POISON:
				## 戦闘側は AffixStatCalculator 経由。フィールドには書かない。
				pass
			_:
				pass


static func _apply_armor_mods_to_fields(instance: Resource, _armor_data: Resource, mods: Array) -> void:
	_ArmorStatResolver._reset_bonus_stats(instance)
	for mod: Variant in mods:
		if not mod is Dictionary:
			continue
		var kind: String = str(mod.get("kind", ""))
		var value: float = float(mod.get("value", 0.0))
		var meta: Dictionary = mod.get("meta", {}) if mod.get("meta", {}) is Dictionary else {}
		match kind:
			KIND_HP_UP:
				instance.hp_bonus = int(value)
			KIND_DEFENSE_UP:
				## 固定防御とは別に mods で保持。フィールドには積まない。
				pass
			KIND_EVASION:
				instance.evasion_rate = value
			KIND_EXP_GAIN:
				instance.exp_gain_rate = value
			KIND_GOLD_GAIN:
				instance.gold_gain_rate = value
			KIND_RARE_DROP:
				instance.rare_drop_rate = value
			KIND_RESIST:
				var elems_raw: Variant = meta.get("elements", [])
				var elems: Array[String] = []
				if elems_raw is Array:
					for e: Variant in elems_raw:
						elems.append(str(e))
				instance.resist_elements = elems
				instance.resist_multiplier = value
			KIND_IMMUNITY:
				var ids_raw: Variant = meta.get("status_ids", [])
				var ids: Array[String] = []
				if ids_raw is Array:
					for sid: Variant in ids_raw:
						ids.append(str(sid))
				instance.status_immunities = ids
			_:
				pass


static func _apply_accessory_mods_to_fields(instance: Resource, _accessory_data: Resource, mods: Array) -> void:
	_AccessoryStatResolver._reset_bonus_stats(instance)
	## ドロップ時はマスタ基礎を載せず、ランダム枠のみ（P3-EQ-STAT-008／DIABLO）。
	for mod: Variant in mods:
		if not mod is Dictionary:
			continue
		var kind: String = str(mod.get("kind", ""))
		var value: float = float(mod.get("value", 0.0))
		match kind:
			KIND_HP_UP:
				instance.hp_bonus += int(value)
			KIND_ATTACK_UP:
				instance.attack_bonus += int(value)
			KIND_DEFENSE_UP:
				instance.defense_bonus += int(value)
			KIND_CRIT_RATE:
				instance.crit_rate_bonus += value
			KIND_EVASION:
				instance.evasion_rate += value
			KIND_EXP_GAIN:
				instance.exp_gain_rate += value
			KIND_GOLD_GAIN:
				instance.gold_gain_rate += value
			KIND_RARE_DROP:
				instance.rare_drop_rate += value
			KIND_HEALING:
				## 戦闘側 AffixStatCalculator。
				pass
			_:
				pass


static func _migrate_weapon(item: Resource) -> void:
	var data: Resource = DataRegistry.get_weapon_data(str(item.weapon_id))
	var mods: Array = []
	if data != null:
		var base_atk: int = int(data.base_attack)
		var rolled: int = int(item.rolled_attack)
		if rolled > base_atk:
			var up: int = rolled - base_atk
			mods.append({
				"id": KIND_ATTACK_UP,
				"label": "攻撃力アップ",
				"kind": KIND_ATTACK_UP,
				"value": up,
				"min_v": 1,
				"max_v": maxi(up, int(_WeaponStatResolver.ATTACK_ROLL_MAX.get(int(data.rarity), up))),
				"perfect": false,
				"meta": {},
			})
		item.rolled_attack = base_atk
	mods.append_array(_mods_from_legacy_affixes(item))
	mods.append_array(_mods_from_weapon_rolled_fields(item, data))
	item.random_mods = mods
	_clear_legacy_affix_ids(item)


static func _migrate_armor(item: Resource) -> void:
	var data: Resource = DataRegistry.get_armor_data(str(item.armor_id))
	var mods: Array = []
	if data != null:
		var base_def: int = int(data.base_defense)
		var rolled: int = int(item.rolled_defense)
		if rolled > base_def:
			var up: int = rolled - base_def
			mods.append({
				"id": KIND_DEFENSE_UP,
				"label": "防御力アップ",
				"kind": KIND_DEFENSE_UP,
				"value": up,
				"min_v": 1,
				"max_v": maxi(up, int(_ArmorStatResolver.DEFENSE_ROLL_MAX.get(int(data.rarity), up))),
				"perfect": false,
				"meta": {},
			})
		item.rolled_defense = base_def
	mods.append_array(_mods_from_legacy_affixes(item))
	mods.append_array(_mods_from_armor_rolled_fields(item))
	item.random_mods = mods
	_clear_legacy_affix_ids(item)


static func _migrate_accessory(item: Resource) -> void:
	var mods: Array = []
	mods.append_array(_mods_from_legacy_affixes(item))
	## 装飾の個体ボーナスはフィールド上に既にあるので、差分抽出は簡易に rolled_bonus_stats 名だけ。
	mods.append_array(_mods_from_accessory_rolled_fields(item))
	item.random_mods = mods
	_clear_legacy_affix_ids(item)


static func _normalize_fixed_primary(item: Resource) -> void:
	var category: String = _item_category(item)
	if category == "weapon":
		var data: Resource = DataRegistry.get_weapon_data(str(item.weapon_id))
		if data != null:
			var base_atk: int = int(data.base_attack)
			if int(item.rolled_attack) != base_atk and _sum_kind_raw(item, KIND_ATTACK_UP) > 0:
				item.rolled_attack = base_atk
	elif category == "armor":
		var adata: Resource = DataRegistry.get_armor_data(str(item.armor_id))
		if adata != null:
			var base_def: int = int(adata.base_defense)
			if int(item.rolled_defense) != base_def and _sum_kind_raw(item, KIND_DEFENSE_UP) > 0:
				item.rolled_defense = base_def


static func _mods_from_legacy_affixes(item: Resource) -> Array:
	var mods: Array = []
	var ids: Array = []
	if "prefix_ids" in item:
		ids.append_array(item.prefix_ids)
	if "suffix_ids" in item:
		ids.append_array(item.suffix_ids)
	for affix_id: Variant in ids:
		var data: Resource = DataRegistry.get_affix_data(str(affix_id))
		if data == null:
			continue
		mods.append(_affix_data_to_mod(data))
	return mods


static func _affix_data_to_mod(data: Resource) -> Dictionary:
	var st: String = str(data.stat_type)
	var value: float = float(data.value)
	var kind: String = KIND_ATTACK_UP
	var label: String = str(data.display_name)
	match st:
		"Attack":
			kind = KIND_ATTACK_UP
			label = "攻撃力アップ"
		"Defense":
			kind = KIND_DEFENSE_UP
			label = "防御力アップ"
		"HP":
			kind = KIND_HP_UP
			label = "HPアップ"
		"Attack Speed":
			kind = KIND_ATTACK_SPEED
			label = "攻撃速度"
		"Critical":
			kind = KIND_CRIT_RATE
			label = "会心率"
		"Gold Gain":
			kind = KIND_GOLD_GAIN
			label = "ゴールド獲得"
		"EXP Gain":
			kind = KIND_EXP_GAIN
			label = "経験値獲得"
		"Rare Drop":
			kind = KIND_RARE_DROP
			label = "レアドロップ"
		"Healing":
			kind = KIND_HEALING
			label = "回復量アップ"
		"Chill":
			kind = KIND_CHILL
			label = "冷却付与"
		"Shock":
			kind = KIND_SHOCK
			label = "感電付与"
		"Ignite":
			kind = KIND_IGNITE
			label = "炎上付与"
		"Poison":
			kind = KIND_POISON
			label = "毒付与"
		_:
			pass
	return {
		"id": str(data.id),
		"label": label,
		"kind": kind,
		"value": value,
		"min_v": value,
		"max_v": value,
		"perfect": false,
		"meta": {},
	}


static func _mods_from_weapon_rolled_fields(item: Resource, data: Resource) -> Array:
	var mods: Array = []
	if data == null:
		return mods
	if float(item.attack_speed) > 0.0:
		var base_spd: float = float(data.base_attack_speed)
		var bonus: float = float(item.attack_speed) - base_spd
		if bonus > 0.001:
			mods.append({
				"id": KIND_ATTACK_SPEED, "label": "攻撃速度", "kind": KIND_ATTACK_SPEED,
				"value": bonus, "min_v": 0.01, "max_v": maxf(bonus, 0.1), "perfect": false, "meta": {},
			})
	if float(item.critical_rate) > 0.0:
		var base_c: float = float(data.base_critical_rate)
		var cb: float = float(item.critical_rate) - base_c
		if cb > 0.001:
			mods.append({
				"id": KIND_CRIT_RATE, "label": "会心率", "kind": KIND_CRIT_RATE,
				"value": cb, "min_v": 0.01, "max_v": maxf(cb, 0.05), "perfect": false, "meta": {},
			})
	if float(item.critical_damage) > BalanceConfig.DEFAULT_WEAPON_CRITICAL_DAMAGE + 0.001:
		var db: float = float(item.critical_damage) - BalanceConfig.DEFAULT_WEAPON_CRITICAL_DAMAGE
		mods.append({
			"id": KIND_CRIT_DAMAGE, "label": "会心ダメ", "kind": KIND_CRIT_DAMAGE,
			"value": db, "min_v": 0.05, "max_v": maxf(db, 0.15), "perfect": false, "meta": {},
		})
	if not str(item.on_hit_status_id).is_empty() and float(item.on_hit_status_chance) > 0.0:
		mods.append({
			"id": KIND_ON_HIT, "label": "状態付与", "kind": KIND_ON_HIT,
			"value": float(item.on_hit_status_chance),
			"min_v": 0.15, "max_v": maxf(float(item.on_hit_status_chance), 0.25),
			"perfect": false, "meta": {"status_id": str(item.on_hit_status_id)},
		})
	if int(item.element_power) > 0 and not str(item.element).is_empty():
		mods.append({
			"id": KIND_ELEMENT_POWER, "label": "属性値", "kind": KIND_ELEMENT_POWER,
			"value": int(item.element_power), "min_v": 0, "max_v": int(item.element_power),
			"perfect": false, "meta": {"element": str(item.element)},
		})
	if not str(item.bane_class).is_empty():
		mods.append(_make_bane_mod(data) if data != null else {
			"id": KIND_BANE, "label": "種族特攻", "kind": KIND_BANE, "value": 1.0,
			"min_v": 1.0, "max_v": 1.0, "perfect": false,
			"meta": {"bane_class": str(item.bane_class), "bane_mult": float(item.bane_multiplier)},
		})
	return mods


static func _mods_from_armor_rolled_fields(item: Resource) -> Array:
	var mods: Array = []
	if int(item.hp_bonus) > 0:
		mods.append({
			"id": KIND_HP_UP, "label": "HPアップ", "kind": KIND_HP_UP,
			"value": int(item.hp_bonus), "min_v": 1, "max_v": int(item.hp_bonus),
			"perfect": false, "meta": {},
		})
	if float(item.evasion_rate) > 0.0:
		mods.append({
			"id": KIND_EVASION, "label": "回避率", "kind": KIND_EVASION,
			"value": float(item.evasion_rate), "min_v": 0.02, "max_v": float(item.evasion_rate),
			"perfect": false, "meta": {},
		})
	if float(item.exp_gain_rate) > 0.0:
		mods.append({
			"id": KIND_EXP_GAIN, "label": "経験値獲得", "kind": KIND_EXP_GAIN,
			"value": float(item.exp_gain_rate), "min_v": 0.01, "max_v": float(item.exp_gain_rate),
			"perfect": false, "meta": {},
		})
	if float(item.gold_gain_rate) > 0.0:
		mods.append({
			"id": KIND_GOLD_GAIN, "label": "ゴールド獲得", "kind": KIND_GOLD_GAIN,
			"value": float(item.gold_gain_rate), "min_v": 0.01, "max_v": float(item.gold_gain_rate),
			"perfect": false, "meta": {},
		})
	if float(item.rare_drop_rate) > 0.0:
		mods.append({
			"id": KIND_RARE_DROP, "label": "レアドロップ", "kind": KIND_RARE_DROP,
			"value": float(item.rare_drop_rate), "min_v": 0.01, "max_v": float(item.rare_drop_rate),
			"perfect": false, "meta": {},
		})
	if "resist_elements" in item and item.resist_elements is Array and not item.resist_elements.is_empty():
		mods.append({
			"id": KIND_RESIST, "label": "属性耐性", "kind": KIND_RESIST,
			"value": float(item.resist_multiplier), "min_v": float(item.resist_multiplier),
			"max_v": float(item.resist_multiplier), "perfect": false,
			"meta": {"elements": item.resist_elements},
		})
	if "status_immunities" in item and item.status_immunities is Array and not item.status_immunities.is_empty():
		mods.append({
			"id": KIND_IMMUNITY, "label": "状態異常無効", "kind": KIND_IMMUNITY,
			"value": 1.0, "min_v": 1.0, "max_v": 1.0, "perfect": false,
			"meta": {"status_ids": item.status_immunities},
		})
	return mods


static func _mods_from_accessory_rolled_fields(item: Resource) -> Array:
	## 既存フィールドはそのまま戦闘に使う。表示用にランダム由来だけ mods へ（Affix分は別途）。
	## ここでは rolled_bonus_stats がある場合の最低限の行を作る。
	var mods: Array = []
	var bonuses: Array = item.rolled_bonus_stats if "rolled_bonus_stats" in item else []
	for bid: Variant in bonuses:
		var id: String = str(bid)
		match id:
			"hp_bonus":
				if int(item.hp_bonus) > 0:
					mods.append({
						"id": KIND_HP_UP, "label": "HPアップ", "kind": KIND_HP_UP,
						"value": int(item.hp_bonus), "min_v": 1, "max_v": int(item.hp_bonus),
						"perfect": false, "meta": {},
					})
			"attack_bonus":
				if int(item.attack_bonus) > 0:
					mods.append({
						"id": KIND_ATTACK_UP, "label": "攻撃力アップ", "kind": KIND_ATTACK_UP,
						"value": int(item.attack_bonus), "min_v": 1, "max_v": int(item.attack_bonus),
						"perfect": false, "meta": {},
					})
			"defense_bonus":
				if int(item.defense_bonus) > 0:
					mods.append({
						"id": KIND_DEFENSE_UP, "label": "防御力アップ", "kind": KIND_DEFENSE_UP,
						"value": int(item.defense_bonus), "min_v": 1, "max_v": int(item.defense_bonus),
						"perfect": false, "meta": {},
					})
			"crit_rate_bonus":
				if float(item.crit_rate_bonus) > 0.0:
					mods.append({
						"id": KIND_CRIT_RATE, "label": "会心率", "kind": KIND_CRIT_RATE,
						"value": float(item.crit_rate_bonus), "min_v": 0.01,
						"max_v": float(item.crit_rate_bonus), "perfect": false, "meta": {},
					})
			_:
				pass
	return mods


static func _ids_from_mods(mods: Array) -> Array[String]:
	var out: Array[String] = []
	for mod: Variant in mods:
		if mod is Dictionary:
			out.append(str(mod.get("id", "")))
	return out


static func _count_perfect(mods: Array) -> int:
	var n: int = 0
	for mod: Variant in mods:
		if mod is Dictionary and bool(mod.get("perfect", false)):
			n += 1
	return n


static func _item_category(item: Resource) -> String:
	if item == null:
		return ""
	if "weapon_id" in item and not str(item.weapon_id).is_empty():
		return "weapon"
	if "armor_id" in item and not str(item.armor_id).is_empty():
		return "armor"
	if "accessory_id" in item and not str(item.accessory_id).is_empty():
		return "accessory"
	return ""
