extends GutTest
## P3-EQ-STAT-005 — 属性値（案A）・武器ステータス解決。

const _WeaponStatResolver = preload("res://scripts/equipment/WeaponStatResolver.gd")
const _WeaponInstance = preload("res://scripts/domain/WeaponInstance.gd")
const _WeaponData = preload("res://scripts/data/WeaponData.gd")
const _EnemyData = preload("res://scripts/data/EnemyData.gd")

func test_element_power_label_includes_element_name() -> void:
	var _ERM = preload("res://scripts/equipment/EquipmentRandomMods.gd")
	assert_eq(_ERM.element_power_label("fire"), "炎属性値")
	assert_eq(_ERM.element_power_label("ice"), "氷属性値")
	assert_eq(_ERM.element_power_label(""), "属性値")
	var line: String = _ERM.format_mod_line({
		"label": "属性値",
		"kind": "element_power",
		"value": 5,
		"min_v": 0,
		"max_v": 12,
		"perfect": false,
		"meta": {"element": "fire"},
	})
	assert_true(line.begins_with("炎属性値"), line)


func test_element_power_roll_never_zero_when_element_set() -> void:
	var data: Resource = _WeaponData.new()
	data.id = "t_fire"
	data.element = "fire"
	data.base_element_power = 0
	data.rarity = Enums.Rarity.COMMON
	for _i in 40:
		var rolled: int = _WeaponStatResolver.roll_element_power(data)
		assert_gte(rolled, 1, "属性付き武器の属性値ロールは最低1")
	var _ERM = preload("res://scripts/equipment/EquipmentRandomMods.gd")
	for _j in 40:
		var mod: Dictionary = _ERM._roll_element_power_mod(data, Enums.Rarity.EPIC)
		assert_gte(int(mod.get("value", 0)), 1)
		assert_gte(int(mod.get("min_v", 0)), 1)


func test_sanitize_zero_int_up_mod() -> void:
	var _ERM = preload("res://scripts/equipment/EquipmentRandomMods.gd")
	var inst: Resource = _WeaponInstance.new()
	inst.weapon_id = "heater_blade"
	inst.element = "fire"
	inst.element_power = 0
	inst.random_mods = [{
		"id": "element_power",
		"label": "炎属性値",
		"kind": "element_power",
		"value": 0,
		"min_v": 0,
		"max_v": 5,
		"perfect": false,
		"meta": {"element": "fire"},
	}]
	var mods: Array = _ERM.get_mods(inst)
	assert_eq(mods.size(), 1)
	assert_eq(int(mods[0].get("value", -1)), 1)
	assert_eq(int(inst.element_power), 1)


func test_element_power_multiplier_plan_a() -> void:
	assert_eq(_WeaponStatResolver.element_power_multiplier(0), 1.0)
	assert_almost_eq(_WeaponStatResolver.element_power_multiplier(10), 1.1, 0.001)

func test_resolve_element_unset_is_neutral() -> void:
	var inst: Resource = _WeaponInstance.new()
	inst.weapon_id = "iron_sword"
	inst.element = ""
	assert_eq(_WeaponStatResolver.resolve_element(inst), "")

func test_resolve_element_power_zero_when_neutral() -> void:
	var inst: Resource = _WeaponInstance.new()
	inst.weapon_id = "iron_sword"
	inst.element = ""
	inst.element_power = 8
	assert_eq(_WeaponStatResolver.resolve_element_power(inst), 0)

func test_apply_drop_stats_rolls_element_power_for_fire_weapon() -> void:
	var data: Resource = _WeaponData.new()
	data.id = "test_fire"
	data.base_attack = 10
	data.element = "fire"
	data.base_element_power = 2
	data.rarity = Enums.Rarity.RARE
	var rolled: int = _WeaponStatResolver.roll_element_power(data)
	assert_true(rolled >= 2)
	assert_true(rolled <= 2 + 8)

func test_apply_element_power_bonus_plan_a() -> void:
	var member: Resource = GameState.party_members[0]
	var weapon: Resource = _WeaponInstance.new()
	weapon.weapon_id = "ember_fang"
	weapon.element = "fire"
	weapon.element_power = 10
	member.equipped_weapon = weapon
	assert_eq(DamageCalculator.apply_element_power_bonus(100, "fire", 0), 110)
	assert_eq(DamageCalculator.apply_element_power_bonus(100, "", 0), 100)

func test_weapon_display_name_element_prefix() -> void:
	var weapon: Resource = _WeaponInstance.new()
	weapon.weapon_id = "ember_fang"
	weapon.element = "fire"
	assert_true(EquipmentEnhancer.get_display_name(weapon).begins_with("炎の"))
	weapon.element = "ice"
	assert_true(EquipmentEnhancer.get_display_name(weapon).begins_with("氷の"))
	weapon.element = ""
	assert_false(EquipmentEnhancer.get_display_name(weapon).begins_with("炎の"))
