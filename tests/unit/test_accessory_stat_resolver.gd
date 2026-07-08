extends GutTest
## P3-EQ-STAT-008 — 装飾品全ランダム抽選。

const _AccessoryStatResolver = preload("res://scripts/equipment/AccessoryStatResolver.gd")
const _AccessoryInstance = preload("res://scripts/domain/AccessoryInstance.gd")
const _AccessoryData = preload("res://scripts/data/AccessoryData.gd")
const _EquipmentRollHelper = preload("res://scripts/equipment/EquipmentRollHelper.gd")
const _EquipmentDisplayNames = preload("res://scripts/equipment/EquipmentDisplayNames.gd")

func test_apply_drop_stats_assigns_rarity_count() -> void:
	var data: Resource = _AccessoryData.new()
	data.id = "test_acc"
	data.rarity = Enums.Rarity.LEGENDARY
	var inst: Resource = _AccessoryInstance.new()
	inst.accessory_id = "test_acc"
	_AccessoryStatResolver.apply_drop_stats(inst, data)
	assert_eq(inst.rolled_bonus_stats.size(), 4)

func test_no_mandatory_stats_when_common() -> void:
	var data: Resource = _AccessoryData.new()
	data.id = "test_common"
	data.rarity = Enums.Rarity.COMMON
	data.hp_bonus = 10
	data.attack_bonus = 5
	var inst: Resource = _AccessoryInstance.new()
	inst.accessory_id = "test_common"
	_AccessoryStatResolver.apply_drop_stats(inst, data)
	assert_eq(inst.rolled_bonus_stats.size(), 1)
	var active: int = 0
	if int(inst.hp_bonus) > 0:
		active += 1
	if int(inst.attack_bonus) > 0:
		active += 1
	if int(inst.defense_bonus) > 0:
		active += 1
	if float(inst.crit_rate_bonus) > 0.0:
		active += 1
	if float(inst.exp_gain_rate) > 0.0:
		active += 1
	if float(inst.gold_gain_rate) > 0.0:
		active += 1
	if float(inst.rare_drop_rate) > 0.0:
		active += 1
	assert_eq(active, 1)

func test_perfect_roll_suffix_on_accessory_name() -> void:
	var inst: Resource = _AccessoryInstance.new()
	inst.accessory_id = "silver_ring"
	inst.perfect_roll_count = 2
	var name: String = _EquipmentDisplayNames.get_instance_name(inst, "accessory")
	assert_true(name.ends_with("⭐️⭐️"))

func test_resolve_uses_instance_over_master() -> void:
	var data: Resource = _AccessoryData.new()
	data.id = "ring"
	data.hp_bonus = 5
	var inst: Resource = _AccessoryInstance.new()
	inst.accessory_id = "ring"
	inst.hp_bonus = 12
	assert_eq(_AccessoryStatResolver.resolve_hp_bonus(inst, data), 12)
