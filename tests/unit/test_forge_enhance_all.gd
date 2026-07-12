extends GutTest
## P3-D152 拡張 — 防具・装飾品の炉研ぎ。

const _EquipmentEnhancer = preload("res://scripts/equipment/EquipmentEnhancer.gd")


func before_each() -> void:
	GameState.gold = 9999
	GameState.material_inventory = {
		"relic_shard": 99,
		"ancient_bone": 99,
		"elite_relic_shard": 99,
	}


func test_enhance_armor_increases_defense_and_hp() -> void:
	var armor: Resource = load("res://scripts/domain/ArmorInstance.gd").new()
	armor.armor_id = "leather_armor"
	armor.rolled_defense = 8
	armor.hp_bonus = 10
	armor.is_appraised = true
	var before_def: int = _EquipmentEnhancer.effective_armor_defense(armor)
	var before_hp: int = _EquipmentEnhancer.effective_armor_hp(armor)
	var result: Dictionary = _EquipmentEnhancer.enhance_item(armor)
	assert_true(result.get("ok", false))
	assert_eq(armor.enhance_level, 1)
	assert_eq(_EquipmentEnhancer.effective_armor_defense(armor), before_def + 1)
	assert_eq(_EquipmentEnhancer.effective_armor_hp(armor), before_hp + 1)


func test_enhance_accessory_increases_attack_bonus() -> void:
	var accessory: Resource = load("res://scripts/domain/AccessoryInstance.gd").new()
	accessory.accessory_id = "silver_ring"
	accessory.attack_bonus = 3
	accessory.is_appraised = true
	var acc_data: Resource = DataRegistry.get_accessory_data("silver_ring")
	var before: int = _EquipmentEnhancer.effective_accessory_int_bonus(
		accessory, "attack_bonus", acc_data
	)
	var result: Dictionary = _EquipmentEnhancer.enhance_item(accessory)
	assert_true(result.get("ok", false))
	assert_eq(accessory.enhance_level, 1)
	assert_eq(
		_EquipmentEnhancer.effective_accessory_int_bonus(accessory, "attack_bonus", acc_data),
		before + 1
	)


func test_can_enhance_rejects_unappraised_armor() -> void:
	var armor: Resource = load("res://scripts/domain/ArmorInstance.gd").new()
	armor.armor_id = "leather_armor"
	armor.rolled_defense = 5
	armor.is_appraised = false
	var check: Dictionary = _EquipmentEnhancer.can_enhance(armor)
	assert_false(check.get("ok", true))
	assert_true(str(check.get("reason", "")).contains("未鑑定"))


func test_armor_enhance_level_save_roundtrip() -> void:
	GameState.armor_inventory.clear()
	var armor: Resource = load("res://scripts/domain/ArmorInstance.gd").new()
	armor.instance_id = "test_armor_enhance"
	armor.armor_id = "leather_armor"
	armor.rolled_defense = 6
	armor.hp_bonus = 4
	armor.is_appraised = true
	armor.enhance_level = 3
	GameState.armor_inventory.append(armor)
	var serialized: Array = SaveManager._serialize_armor_inventory()
	var restored_armor: Array = SaveManager._deserialize_armor_inventory(serialized)
	assert_eq(restored_armor.size(), 1)
	assert_eq(int(restored_armor[0].enhance_level), 3)
