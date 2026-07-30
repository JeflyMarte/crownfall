extends GutTest

## P3-EQ-MYTHIC-001 — 神話装備ドロップ／錬成禁止。

const _DungeonController = preload("res://scripts/dungeon/DungeonController.gd")
const _DungeonTierConfig = preload("res://scripts/dungeon/DungeonTierConfig.gd")
const _MythicLoot = preload("res://scripts/equipment/MythicLoot.gd")
const _EquipmentEnhancer = preload("res://scripts/equipment/EquipmentEnhancer.gd")

func test_mythic_resources_exist() -> void:
	for wid: String in _MythicLoot.WEAPON_IDS:
		assert_true(ResourceLoader.exists("res://resources/weapons/%s.tres" % wid), wid)
		var w: Resource = DataRegistry.get_weapon_data(wid)
		assert_not_null(w, wid)
		assert_eq(int(w.rarity), Enums.Rarity.MYTHIC, wid)
	assert_true(ResourceLoader.exists("res://resources/armors/%s.tres" % _MythicLoot.ARMOR_ID))
	assert_true(ResourceLoader.exists("res://resources/accessories/%s.tres" % _MythicLoot.ACCESSORY_ID))
	assert_eq(Enums.Rarity.MYTHIC, 4)
	var sword: Resource = DataRegistry.get_weapon_data(_MythicLoot.WEAPON_ID)
	assert_eq(str(sword.display_name), "継承剣レガート")
	assert_eq(str(sword.weapon_type), "sword")
	assert_eq(str(DataRegistry.get_weapon_data("pilgrim_bow_lumen").weapon_type), "bow")
	assert_eq(str(DataRegistry.get_weapon_data("wisdom_staff_noesis").weapon_type), "staff")
	assert_eq(str(DataRegistry.get_weapon_data("abyss_fangs_lucian").weapon_type), "dual_blades")

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
	assert_false(CombatPassives.get_def("eq_mythic_lumen").is_empty())
	assert_false(CombatPassives.get_def("eq_mythic_noesis").is_empty())
	assert_false(CombatPassives.get_def("eq_mythic_lucian").is_empty())
	assert_false(CombatPassives.get_def("eq_mythic_cenotaph").is_empty())
	assert_false(CombatPassives.get_def("eq_mythic_hegemony").is_empty())
	assert_true(bool(CombatPassives.get_def("eq_mythic_cenotaph").get("death_save_once", false)))
	assert_eq(str(CombatPassives.get_def("eq_mythic_burial_crown").get("display_name", "")), "レガートの継承")
	assert_almost_eq(float(CombatPassives.get_def("eq_mythic_lumen").get("outgoing_mult", 0.0)), 1.20, 0.001)
	assert_almost_eq(float(CombatPassives.get_def("eq_mythic_noesis").get("skill_power_mult", 0.0)), 1.25, 0.001)
	assert_eq(str(CombatPassives.get_def("eq_mythic_lucian").get("status_id", "")), "bleed")


func test_mythic_pool_covers_four_weapon_types() -> void:
	assert_eq(_MythicLoot.POOL.size(), 6)
	var weapon_entries: int = 0
	for entry: Dictionary in _MythicLoot.POOL:
		if str(entry.get("category", "")) == "weapon":
			weapon_entries += 1
			assert_true(_MythicLoot.is_mythic_id(str(entry.get("id", ""))))
	assert_eq(weapon_entries, 4)

func test_mythic_icons_and_cyan_frame_exist() -> void:
	assert_true(ResourceLoader.exists("res://assets/ui/equipment/ICO_WPN_BurialCrownGreatsword.png"))
	assert_true(ResourceLoader.exists("res://assets/ui/equipment/ICO_WPN_VolleyHorizonBow.png"))
	assert_true(ResourceLoader.exists("res://assets/ui/equipment/ICO_WPN_SeradionStormStaff.png"))
	assert_true(ResourceLoader.exists("res://assets/ui/equipment/ICO_WPN_NoctumbraFang.png"))
	assert_true(ResourceLoader.exists("res://assets/ui/equipment/ICO_ARM_ImmortalCenotaphPlate.png"))
	assert_true(ResourceLoader.exists("res://assets/ui/equipment/ICO_ACC_CouncilHegemonySeal.png"))
	assert_true(ResourceLoader.exists(EquipmentUiTokens.INV_CELLS[Enums.Rarity.MYTHIC]))
	assert_true(ResourceLoader.exists(EquipmentUiTokens.MYTHIC_BADGE))
	assert_eq(
		EquipmentUiTokens.INV_CELLS[Enums.Rarity.MYTHIC],
		"res://assets/ui/equipment_ui/UI_Equip_InvCell_MYTHIC.png"
	)
	assert_not_null(IconPaths.get_icon_texture("burial_crown_greatsword", "weapon"))
	assert_not_null(IconPaths.get_icon_texture("pilgrim_bow_lumen", "weapon"))
	assert_not_null(IconPaths.get_icon_texture("wisdom_staff_noesis", "weapon"))
	assert_not_null(IconPaths.get_icon_texture("abyss_fangs_lucian", "weapon"))
