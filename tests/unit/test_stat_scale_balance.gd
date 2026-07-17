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


func test_exploration_and_dot_follow_scale() -> void:
	assert_eq(BalanceConfig.ROOM_HEAL_AMOUNT, 10 * BalanceConfig.STAT_SCALE)
	assert_eq(BalanceConfig.TRAP_DAMAGE_COMBAT, 10 * BalanceConfig.STAT_SCALE)
	assert_eq(BalanceConfig.TRAP_DAMAGE_ROOM, 15 * BalanceConfig.STAT_SCALE)
	assert_eq(BalanceConfig.SPARE_VIAL_HEAL, 12 * BalanceConfig.STAT_SCALE)
	assert_eq(BalanceConfig.DOT_FLAT_POISON, 4 * BalanceConfig.STAT_SCALE)
	assert_eq(BalanceConfig.DOT_FLAT_IGNITE, 3 * BalanceConfig.STAT_SCALE)
	assert_eq(BalanceConfig.COMBO_POISON_PER_STACK, 8 * BalanceConfig.STAT_SCALE)
	assert_eq(BalanceConfig.COMBO_BLEED_PER_STACK, 6 * BalanceConfig.STAT_SCALE)
	assert_eq(BalanceConfig.THREAT_TAUNT, 40.0 * float(BalanceConfig.STAT_SCALE))
	var poison: Resource = DataRegistry.get_status_effect("poison")
	var ignite: Resource = DataRegistry.get_status_effect("ignite")
	assert_not_null(poison)
	assert_not_null(ignite)
	assert_eq(int(poison.dot_flat), BalanceConfig.DOT_FLAT_POISON)
	assert_eq(int(ignite.dot_flat), BalanceConfig.DOT_FLAT_IGNITE)
	var vial: Dictionary = CombatPassives.get_def("spare_vial")
	assert_eq(int(vial.get("heal_value", 0)), BalanceConfig.SPARE_VIAL_HEAL)


func test_guide_catalog_uses_scaled_numbers() -> void:
	var desc: String = ""
	for entry: Dictionary in GuideCatalog.get_entries():
		if str(entry.get("id", "")) == "EQUIP-G005":
			desc = str(entry.get("description", ""))
			break
	assert_false(desc.is_empty(), "EQUIP-G005 が存在する")
	assert_true(
		desc.contains("攻撃力 +%d" % BalanceConfig.EQUIP_FORGE_FLAT_PER_LEVEL),
		"炉研ぎ手引きが現行加算を含む"
	)
	assert_false(desc.contains("攻撃力 +1（"), "旧 +1 表記が残っていない")


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
