class_name AffixStatCalculator
extends RefCounted

## M6 Affix stat 集計（P2-Task031）。装備の prefix/suffix のみ反映。
## P3-EQ-002: member_index >= 0 はそのメンバーの装備のみ。-1 は全員分を合算（Gold/Healing 等）。

const STAT_ATTACK: String = "Attack"
const STAT_DEFENSE: String = "Defense"
const STAT_HP: String = "HP"
const STAT_CRITICAL: String = "Critical"
const STAT_GOLD_GAIN: String = "Gold Gain"
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
		"material_gain_bonus": 0,
		"healing_bonus": 0,
		"shock_chance": 0.0,
		"ignite_chance": 0.0,
		"chill_chance": 0.0,
		"poison_chance": 0.0,
		"attack_speed_mult_add": 0.0,
	}
	for affix_data: Resource in _collect_equipped_affix_data(member_index):
		_apply_affix_to_bonuses(affix_data, bonuses)
	return bonuses

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
