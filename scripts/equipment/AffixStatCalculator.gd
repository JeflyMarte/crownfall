class_name AffixStatCalculator
extends RefCounted

const _ArmorStatResolver = preload("res://scripts/equipment/ArmorStatResolver.gd")
const _AccessoryStatResolver = preload("res://scripts/equipment/AccessoryStatResolver.gd")

## M6 Affix stat 集計（P2-Task031）。装備の prefix/suffix + 装飾ベース報酬率。
## P3-EQ-002: member_index >= 0 はそのメンバーの装備のみ。-1 は全員分を合算（Gold/Healing 等）。

const STAT_ATTACK: String = "Attack"
const STAT_DEFENSE: String = "Defense"
const STAT_HP: String = "HP"
const STAT_CRITICAL: String = "Critical"
const STAT_GOLD_GAIN: String = "Gold Gain"
const STAT_EXP_GAIN: String = "EXP Gain"
const STAT_RARE_DROP: String = "Rare Drop"
const STAT_MATERIAL_GAIN: String = "Material Gain"
const STAT_HEALING: String = "Healing"
const STAT_SHOCK: String = "Shock"
const STAT_IGNITE: String = "Ignite"
const STAT_CHILL: String = "Chill"
const STAT_POISON: String = "Poison"
const STAT_ATTACK_SPEED: String = "Attack Speed"

static func get_bonuses(member_index: int = -1) -> Dictionary:
	var calculator: RefCounted = load("res://scripts/equipment/AffixStatCalculator.gd").new()
	return calculator._compute_bonuses(member_index)

static func apply_gold_bonus(base_gold: int) -> int:
	if base_gold <= 0:
		return base_gold
	var mult: float = float(get_bonuses().get("gold_gain_mult", 1.0))
	return maxi(0, int(round(float(base_gold) * mult)))

static func apply_exp_bonus(base_exp: int) -> int:
	if base_exp <= 0:
		return base_exp
	var mult: float = float(get_bonuses().get("exp_gain_mult", 1.0))
	return maxi(0, int(round(float(base_exp) * mult)))

static func apply_rarity_drop_weight(base_weight: int, rarity: int) -> int:
	if base_weight <= 0:
		return base_weight
	var add: float = float(get_bonuses().get("rare_drop_add", 0.0))
	if is_zero_approx(add):
		return base_weight
	var tier: float = float(clampi(rarity, Enums.Rarity.COMMON, Enums.Rarity.LEGENDARY))
	return maxi(1, int(round(float(base_weight) * (1.0 + add * tier))))

static func apply_healing_bonus(base_amount: int) -> int:
	if base_amount <= 0:
		return base_amount
	var bonus: int = int(get_bonuses().get("healing_bonus", 0))
	return maxi(0, base_amount + bonus)

static func apply_material_bonus(base_amount: int) -> int:
	if base_amount <= 0:
		return base_amount
	var bonus: int = int(get_bonuses().get("material_gain_bonus", 0))
	return maxi(0, base_amount + bonus)

func _compute_bonuses(member_index: int = -1) -> Dictionary:
	var bonuses: Dictionary = {
		"attack_flat": 0,
		"defense_flat": 0,
		"hp_flat": 0,
		"crit_rate_add": 0.0,
		"gold_gain_mult": 1.0,
		"exp_gain_mult": 1.0,
		"rare_drop_add": 0.0,
		"material_gain_bonus": 0,
		"healing_bonus": 0,
		"shock_chance": 0.0,
		"ignite_chance": 0.0,
		"chill_chance": 0.0,
		"poison_chance": 0.0,
		"attack_speed_mult_add": 0.0,
	}
	if member_index >= 0:
		var member: Resource = GameState.get_member(member_index)
		if member != null:
			_apply_accessory_base_rates(member, bonuses)
			_apply_armor_base_rates(member, bonuses)
			for affix_data: Resource in _affixes_from_member(member):
				_apply_affix_to_bonuses(affix_data, bonuses)
			_apply_random_mods_from_member(member, bonuses)
		return bonuses
	for i in GameState.party_members.size():
		var member_all: Resource = GameState.party_members[i]
		if member_all == null:
			continue
		_apply_accessory_base_rates(member_all, bonuses)
		_apply_armor_base_rates(member_all, bonuses)
		for affix_data: Resource in _affixes_from_member(member_all):
			_apply_affix_to_bonuses(affix_data, bonuses)
		_apply_random_mods_from_member(member_all, bonuses)
	return bonuses

func _apply_accessory_base_rates(member: Resource, bonuses: Dictionary) -> void:
	var accessory: Resource = member.equipped_accessory if "equipped_accessory" in member else null
	if accessory == null:
		return
	bonuses["gold_gain_mult"] += _AccessoryStatResolver.resolve_gold_gain_rate(accessory)
	bonuses["exp_gain_mult"] += _AccessoryStatResolver.resolve_exp_gain_rate(accessory)
	bonuses["rare_drop_add"] += _AccessoryStatResolver.resolve_rare_drop_rate(accessory)

func _apply_armor_base_rates(member: Resource, bonuses: Dictionary) -> void:
	var armor: Resource = member.equipped_armor if "equipped_armor" in member else null
	if armor == null:
		return
	bonuses["gold_gain_mult"] += _ArmorStatResolver.resolve_gold_gain_rate(armor)
	bonuses["exp_gain_mult"] += _ArmorStatResolver.resolve_exp_gain_rate(armor)
	bonuses["rare_drop_add"] += _ArmorStatResolver.resolve_rare_drop_rate(armor)

func _collect_equipped_affix_data(member_index: int = -1) -> Array[Resource]:
	var affixes: Array[Resource] = []
	if member_index >= 0:
		var member: Resource = GameState.get_member(member_index)
		if member == null:
			return affixes
		affixes.append_array(_affixes_from_member(member))
		return affixes
	for i in GameState.party_members.size():
		var member_all: Resource = GameState.party_members[i]
		if member_all == null:
			continue
		affixes.append_array(_affixes_from_member(member_all))
	return affixes

func _affixes_from_member(member: Resource) -> Array[Resource]:
	var affixes: Array[Resource] = []
	_append_instance_affixes(affixes, member.equipped_weapon, true, true)
	_append_instance_affixes(affixes, member.equipped_armor, true, false)
	_append_instance_affixes(affixes, member.equipped_accessory, true, false)
	return affixes

func _append_instance_affixes(
	target: Array[Resource],
	item: Resource,
	include_prefix: bool,
	include_suffix: bool
) -> void:
	if item == null or not item.is_appraised:
		return
	## レガシー Affix ID（未移行時のみ）。移行後は random_mods を _compute 側で直接適用。
	if include_prefix:
		for affix_id in item.prefix_ids:
			_append_affix_data(target, str(affix_id))
	if include_suffix and "suffix_ids" in item:
		for affix_id in item.suffix_ids:
			_append_affix_data(target, str(affix_id))

func _append_affix_data(target: Array[Resource], affix_id: String) -> void:
	if affix_id.is_empty():
		return
	var affix_data: Resource = DataRegistry.get_affix_data(affix_id)
	if affix_data != null:
		target.append(affix_data)

func _apply_affix_to_bonuses(affix_data: Resource, bonuses: Dictionary) -> void:
	match affix_data.stat_type:
		STAT_ATTACK:
			bonuses["attack_flat"] += int(affix_data.value)
		STAT_DEFENSE:
			bonuses["defense_flat"] += int(affix_data.value)
		STAT_HP:
			bonuses["hp_flat"] += int(affix_data.value)
		STAT_CRITICAL:
			bonuses["crit_rate_add"] += float(affix_data.value)
		STAT_GOLD_GAIN:
			bonuses["gold_gain_mult"] += float(affix_data.value)
		STAT_EXP_GAIN:
			bonuses["exp_gain_mult"] += float(affix_data.value)
		STAT_RARE_DROP:
			bonuses["rare_drop_add"] += float(affix_data.value)
		STAT_MATERIAL_GAIN:
			bonuses["material_gain_bonus"] += int(affix_data.value)
		STAT_HEALING:
			bonuses["healing_bonus"] += int(affix_data.value)
		STAT_SHOCK:
			bonuses["shock_chance"] += float(affix_data.value)
		STAT_IGNITE:
			bonuses["ignite_chance"] += float(affix_data.value)
		STAT_CHILL:
			bonuses["chill_chance"] += float(affix_data.value)
		STAT_POISON:
			bonuses["poison_chance"] += float(affix_data.value)
		STAT_ATTACK_SPEED:
			bonuses["attack_speed_mult_add"] += float(affix_data.value)
		_:
			pass


func _apply_random_mods_from_member(member: Resource, bonuses: Dictionary) -> void:
	var _EquipmentRandomMods = load("res://scripts/equipment/EquipmentRandomMods.gd")
	for item: Resource in [
		member.equipped_weapon if "equipped_weapon" in member else null,
		member.equipped_armor if "equipped_armor" in member else null,
		member.equipped_accessory if "equipped_accessory" in member else null,
	]:
		if item == null or not bool(item.is_appraised):
			continue
		var category: String = _EquipmentRandomMods._item_category(item)
		for mod: Variant in _EquipmentRandomMods.get_mods(item):
			if mod is Dictionary:
				_apply_random_mod_to_bonuses(mod as Dictionary, category, bonuses)


func _apply_random_mod_to_bonuses(mod: Dictionary, category: String, bonuses: Dictionary) -> void:
	var kind: String = str(mod.get("kind", ""))
	var value: float = float(mod.get("value", 0.0))
	## フィールド／固定行に既に載るものは二重加算しない。
	match kind:
		"attack_up":
			if category == "weapon" or category == "accessory":
				return
			bonuses["attack_flat"] += int(value)
		"defense_up":
			if category == "armor" or category == "accessory":
				return
			bonuses["defense_flat"] += int(value)
		"hp_up":
			if category == "armor" or category == "accessory":
				return
			bonuses["hp_flat"] += int(value)
		"crit_rate":
			if category == "weapon" or category == "accessory":
				return
			bonuses["crit_rate_add"] += value
		"attack_speed":
			if category == "weapon":
				return
			bonuses["attack_speed_mult_add"] += value
		"gold_gain":
			## 防具／装飾はフィールド経由。武器 Fortune のみここ。
			if category != "weapon":
				return
			bonuses["gold_gain_mult"] += value
		"exp_gain", "rare_drop", "evasion":
			return
		"healing":
			bonuses["healing_bonus"] += int(value)
		"chill_chance":
			bonuses["chill_chance"] += value
		"shock_chance":
			bonuses["shock_chance"] += value
		"ignite_chance":
			bonuses["ignite_chance"] += value
		"poison_chance":
			bonuses["poison_chance"] += value
		_:
			pass
