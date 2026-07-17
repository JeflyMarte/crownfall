extends GutTest
## P3-BAL-STAT-SCALE-001 — 装備・敵・成長の共通スケール。


func test_stat_scale_constant() -> void:
	assert_eq(BalanceConfig.STAT_SCALE, 8)


func test_equipment_masters_scaled() -> void:
	var sword: Resource = DataRegistry.get_weapon_data("iron_sword")
	assert_not_null(sword)
	assert_eq(int(sword.base_attack), 80)
	var armor: Resource = DataRegistry.get_armor_data("leather_armor")
	assert_not_null(armor)
	assert_eq(int(armor.base_defense), 40)
	assert_eq(int(armor.base_hp_bonus), 120)


func test_enemy_masters_scaled() -> void:
	var boar: Resource = DataRegistry.get_enemy_data("moss_boar")
	assert_not_null(boar)
	assert_eq(int(boar.max_hp), 600)
	assert_eq(int(boar.attack), 128)
	assert_eq(int(boar.defense), 32)


func test_roll_and_forge_follow_scale() -> void:
	assert_eq(
		int(WeaponStatResolver.ATTACK_ROLL_MAX[Enums.Rarity.COMMON]),
		5 * BalanceConfig.STAT_SCALE
	)
	assert_eq(BalanceConfig.EQUIP_FORGE_FLAT_PER_LEVEL, BalanceConfig.STAT_SCALE)
	assert_eq(BalanceConfig.EQUIP_FORGE_HP_PER_LEVEL, BalanceConfig.STAT_SCALE * 2)
	assert_eq(BalanceConfig.HEAL_SKILL_BASE, 14 * BalanceConfig.STAT_SCALE)
	assert_eq(BalanceConfig.DEFENSE_MITIGATION_K, 100.0 * float(BalanceConfig.STAT_SCALE))


func test_save_v5_to_v6_scales_inventory_flats() -> void:
	var raw: Dictionary = {
		"save_version": 5,
		"inventory": [{"instance_id": "w1", "weapon_id": "iron_sword", "rolled_attack": 10}],
		"armor_inventory": [{
			"instance_id": "a1",
			"armor_id": "leather_armor",
			"rolled_defense": 5,
			"hp_bonus": 15,
		}],
		"accessory_inventory": [{
			"instance_id": "c1",
			"accessory_id": "silver_ring",
			"hp_bonus": 8,
			"attack_bonus": 2,
			"defense_bonus": 1,
		}],
	}
	var migrated: Dictionary = SaveManager._migrate_save_v5_to_v6(raw.duplicate(true))
	assert_eq(int(migrated["inventory"][0]["rolled_attack"]), 80)
	assert_eq(int(migrated["armor_inventory"][0]["rolled_defense"]), 40)
	assert_eq(int(migrated["armor_inventory"][0]["hp_bonus"]), 120)
	assert_eq(int(migrated["accessory_inventory"][0]["hp_bonus"]), 64)
	assert_eq(int(migrated["accessory_inventory"][0]["attack_bonus"]), 16)
	assert_eq(int(migrated["accessory_inventory"][0]["defense_bonus"]), 8)
