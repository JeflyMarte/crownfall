extends GutTest
## P3-EQ-LEG-002 — レジェンド防具・装飾のデータと固有パッシブ。

const LEGENDARY_PAIRS: Array = [
	{
		"stage_id": "mourngate_1_5",
		"armor_id": "serdion_ward_plate",
		"accessory_id": "mourngate_royal_seal",
		"armor_passive": "eq_serdion_ward",
		"accessory_passive": "eq_mourngate_royal",
	},
	{
		"stage_id": "whisperwood_2_5",
		"armor_id": "granvel_bark_plate",
		"accessory_id": "silvaria_covenant_ring",
		"armor_passive": "eq_granvel_bark",
		"accessory_passive": "eq_silvaria_covenant",
	},
	{
		"stage_id": "mistfen_3_5",
		"armor_id": "moldgar_abyss_mail",
		"accessory_id": "seradis_archive_seal",
		"armor_passive": "eq_moldgar_abyss",
		"accessory_passive": "eq_seradis_archive",
	},
	{
		"stage_id": "blackshore_4_5",
		"armor_id": "nereion_tide_plate",
		"accessory_id": "pharos_beacon_ring",
		"armor_passive": "eq_nereion_tide",
		"accessory_passive": "eq_pharos_beacon",
	},
	{
		"stage_id": "frostridge_5_5",
		"armor_id": "eldion_glacier_aegis",
		"accessory_id": "frostridge_boundary_signet",
		"armor_passive": "eq_eldion_glacier",
		"accessory_passive": "eq_frostridge_boundary",
	},
]


func test_legendary_armor_accessory_defs_exist() -> void:
	for pair in LEGENDARY_PAIRS:
		var armor_data: Resource = DataRegistry.get_armor_data(str(pair["armor_id"]))
		assert_not_null(armor_data, str(pair["armor_id"]))
		assert_eq(int(armor_data.rarity), 3)
		assert_eq(str(armor_data.fixed_passive_id), str(pair["armor_passive"]))
		var acc_data: Resource = DataRegistry.get_accessory_data(str(pair["accessory_id"]))
		assert_not_null(acc_data, str(pair["accessory_id"]))
		assert_eq(int(acc_data.rarity), 3)
		assert_eq(str(acc_data.fixed_passive_id), str(pair["accessory_passive"]))


func test_legendary_passives_have_descriptions() -> void:
	for pair in LEGENDARY_PAIRS:
		for key in ["armor_passive", "accessory_passive"]:
			var pid: String = str(pair[key])
			var def: Dictionary = CombatPassives.get_def(pid)
			assert_false(def.is_empty(), pid)
			assert_false(str(def.get("description", "")).is_empty(), pid)


func test_equipment_detail_shows_legendary_effect() -> void:
	var armor_inst: Resource = load("res://scripts/domain/ArmorInstance.gd").new()
	armor_inst.armor_id = "granvel_bark_plate"
	var text: String = EquipmentItemDetailHelper.equipment_legendary_effect_text(armor_inst, "armor")
	assert_false(text.is_empty())
	assert_true(text.contains("4%"))
	var acc_inst: Resource = load("res://scripts/domain/AccessoryInstance.gd").new()
	acc_inst.accessory_id = "pharos_beacon_ring"
	text = EquipmentItemDetailHelper.equipment_legendary_effect_text(acc_inst, "accessory")
	assert_false(text.is_empty())
	assert_true(text.contains("標的"))


func test_stage_registers_legendary_loot() -> void:
	for pair in LEGENDARY_PAIRS:
		var stage: Resource = DataRegistry.get_stage_data(str(pair["stage_id"]))
		assert_not_null(stage, str(pair["stage_id"]))
		assert_eq(str(stage.legendary_armor_id), str(pair["armor_id"]))
		assert_eq(str(stage.legendary_accessory_id), str(pair["accessory_id"]))
