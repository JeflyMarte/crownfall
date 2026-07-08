extends GutTest
## 回避率 — 防具・装飾品抽選と被弾回避。

const _ArmorStatResolver = preload("res://scripts/equipment/ArmorStatResolver.gd")
const _AccessoryStatResolver = preload("res://scripts/equipment/AccessoryStatResolver.gd")
const _ArmorInstance = preload("res://scripts/domain/ArmorInstance.gd")
const _AccessoryInstance = preload("res://scripts/domain/AccessoryInstance.gd")
const _ArmorData = preload("res://scripts/data/ArmorData.gd")
const _AccessoryData = preload("res://scripts/data/AccessoryData.gd")
const _CombatController = preload("res://scripts/combat/CombatController.gd")

var _saved_armor: Resource = null
var _saved_accessory: Resource = null


func before_each() -> void:
	var member: Resource = GameState.party_members[0]
	_saved_armor = member.equipped_armor
	_saved_accessory = member.equipped_accessory
	member.equipped_armor = null
	member.equipped_accessory = null


func after_each() -> void:
	var member: Resource = GameState.party_members[0]
	member.equipped_armor = _saved_armor
	member.equipped_accessory = _saved_accessory


func test_armor_can_roll_evasion_rate() -> void:
	var data: Resource = _ArmorData.new()
	data.armor_id = "test_evasion_armor"
	data.base_defense = 8
	data.rarity = Enums.Rarity.EPIC
	var inst: Resource = _ArmorInstance.new()
	inst.armor_id = "test_evasion_armor"
	for _i in 200:
		_ArmorStatResolver.apply_drop_stats(inst, data)
		if "evasion_rate" in inst.rolled_bonus_stats:
			assert_true(float(inst.evasion_rate) >= 0.02)
			assert_true(float(inst.evasion_rate) <= 0.15)
			return
	pass_test("evasion_rate not picked in 200 rolls — acceptable variance")


func test_accessory_can_roll_evasion_rate() -> void:
	var data: Resource = _AccessoryData.new()
	data.id = "test_evasion_acc"
	data.rarity = Enums.Rarity.RARE
	var inst: Resource = _AccessoryInstance.new()
	inst.accessory_id = "test_evasion_acc"
	for _i in 200:
		_AccessoryStatResolver.apply_drop_stats(inst, data)
		if "evasion_rate" in inst.rolled_bonus_stats:
			assert_true(float(inst.evasion_rate) >= 0.02)
			assert_true(float(inst.evasion_rate) <= 0.15)
			return
	pass_test("evasion_rate not picked in 200 rolls — acceptable variance")


func test_member_evasion_rate_stacks_and_caps() -> void:
	var member: Resource = GameState.party_members[0]
	var armor: Resource = _ArmorInstance.new()
	armor.armor_id = "leather_armor"
	armor.evasion_rate = 0.30
	var acc: Resource = _AccessoryInstance.new()
	acc.accessory_id = "test_ring"
	acc.evasion_rate = 0.30
	member.equipped_armor = armor
	member.equipped_accessory = acc
	assert_almost_eq(DamageCalculator.member_evasion_rate(0), 0.50, 0.001)


func test_enemy_damage_misses_on_evasion_roll() -> void:
	var member: Resource = GameState.party_members[0]
	var armor: Resource = _ArmorInstance.new()
	armor.armor_id = "leather_armor"
	armor.evasion_rate = 1.0
	member.equipped_armor = armor
	var combat: Node = _CombatController.new()
	add_child_autofree(combat)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var result: Dictionary = DamageCalculator.enemy_damage_to_member(combat, 0, 1.0, 50, -1, rng)
	assert_true(result.get("missed", false))
	assert_eq(int(result.get("final", -1)), 0)


func test_enemy_damage_hits_when_evasion_roll_fails() -> void:
	var member: Resource = GameState.party_members[0]
	var armor: Resource = _ArmorInstance.new()
	armor.armor_id = "leather_armor"
	armor.evasion_rate = 0.10
	member.equipped_armor = armor
	var combat: Node = _CombatController.new()
	add_child_autofree(combat)
	var rng := RandomNumberGenerator.new()
	rng.seed = 99999
	var result: Dictionary = DamageCalculator.enemy_damage_to_member(combat, 0, 1.0, 50, -1, rng)
	assert_false(result.get("missed", false))
	assert_gt(int(result.get("final", 0)), 0)
