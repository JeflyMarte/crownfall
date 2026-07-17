extends GutTest

## P3-EQ-MYTHIC-001 — 神話装備ドロップ／錬成禁止。

const _DungeonController = preload("res://scripts/dungeon/DungeonController.gd")
const _DungeonTierConfig = preload("res://scripts/dungeon/DungeonTierConfig.gd")
const _MythicLoot = preload("res://scripts/equipment/MythicLoot.gd")
const _EquipmentEnhancer = preload("res://scripts/equipment/EquipmentEnhancer.gd")

func test_mythic_resources_exist() -> void:
	assert_true(ResourceLoader.exists("res://resources/weapons/%s.tres" % _MythicLoot.WEAPON_ID))
	assert_true(ResourceLoader.exists("res://resources/armors/%s.tres" % _MythicLoot.ARMOR_ID))
	assert_true(ResourceLoader.exists("res://resources/accessories/%s.tres" % _MythicLoot.ACCESSORY_ID))
	var w: Resource = DataRegistry.get_weapon_data(_MythicLoot.WEAPON_ID)
	assert_eq(int(w.rarity), Enums.Rarity.MYTHIC)
	assert_eq(Enums.Rarity.MYTHIC, 4)

func test_first_clear_skips_mythic() -> void:
	GameState.stage_progress.erase("mourngate_1_5")
	GameState.current_dungeon_id = "mourngate"
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NORMAL
	GameState.inventory.clear()
	GameState.armor_inventory.clear()
	GameState.accessory_inventory.clear()
	var dc: Node = _DungeonController.new()
	add_child_autofree(dc)
	dc.start_stage("mourngate_1_5")
	var bonus: Dictionary = dc.apply_boss_mythic_loot(dc.current_stage_data)
	assert_true(str(bonus.get("id", "")).is_empty(), "初回クリアでは神話なし")

func test_reclear_can_roll_mythic_with_forced_rng() -> void:
	GameState.stage_progress.erase("mourngate_1_5")
	GameState.mark_stage_cleared("mourngate_1_5", _DungeonTierConfig.TIER_NORMAL)
	GameState.current_dungeon_id = "mourngate"
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NORMAL
	GameState.inventory.clear()
	GameState.armor_inventory.clear()
	GameState.accessory_inventory.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	# CHANCE=0.01 のため、randf が十分小さいまで回す
	var hit: Dictionary = {}
	for _i in 5000:
		var probe := RandomNumberGenerator.new()
		probe.seed = rng.randi()
		hit = _MythicLoot.roll_for_boss_reclear(
			DataRegistry.get_stage_data("mourngate_1_5"),
			probe
		)
		if not hit.is_empty():
			break
	assert_false(hit.is_empty(), "再クリア＋低確率でいつか当たる")
	assert_true(_MythicLoot.is_mythic_id(str(hit.get("id", ""))))

func test_alchemy_blocks_mythic_fodder() -> void:
	var inst_class = load("res://scripts/domain/ArmorInstance.gd")
	var mythic = inst_class.new()
	mythic.armor_id = _MythicLoot.ARMOR_ID
	mythic.rarity = Enums.Rarity.MYTHIC
	mythic.equip_level = 1
	var common = inst_class.new()
	common.armor_id = "leather_armor"
	common.rarity = Enums.Rarity.COMMON
	common.equip_level = 1
	var check: Dictionary = _EquipmentEnhancer.can_alchemy(common, mythic)
	assert_false(bool(check.get("ok", true)))
	assert_true(str(check.get("reason", "")).find("神話") >= 0)

func test_mythic_passive_defs_exist() -> void:
	assert_false(CombatPassives.get_def("eq_mythic_burial_crown").is_empty())
	assert_false(CombatPassives.get_def("eq_mythic_cenotaph").is_empty())
	assert_false(CombatPassives.get_def("eq_mythic_hegemony").is_empty())
	assert_true(bool(CombatPassives.get_def("eq_mythic_cenotaph").get("death_save_once", false)))
