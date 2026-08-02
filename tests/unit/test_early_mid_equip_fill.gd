extends GutTest

## P3-EQ-EARLY-MID-FILL-001 — 序盤防飾N／中盤装飾E補充

const ARMOR_N: Array[String] = [
	"wick_padded_coat",
	"trail_twine_wrap",
	"reedmat_vest",
	"netter_smock",
	"drove_wool_coat",
]

const ACC_N: Array[String] = [
	"copper_bell_ring",
	"seed_pouch_charm",
	"clay_bead_band",
	"dock_knot_charm",
	"mitten_pin",
]

const ACC_E: Array[String] = [
	"ashvault_pendant",
	"canopy_ward_talisman",
	"mireglass_brooch",
	"tideledger_charm",
	"rimecrown_seal",
]


func test_new_armor_n_resources() -> void:
	for aid in ARMOR_N:
		var data: Resource = DataRegistry.get_armor_data(aid)
		assert_not_null(data, aid)
		assert_eq(int(data.rarity), Enums.Rarity.COMMON, aid)
		assert_false(str(data.display_name).is_empty(), aid)
		assert_true(str(data.fixed_passive_id).is_empty(), aid)


func test_new_accessory_resources() -> void:
	for aid in ACC_N:
		var data: Resource = DataRegistry.get_accessory_data(aid)
		assert_not_null(data, aid)
		assert_eq(int(data.rarity), Enums.Rarity.COMMON, aid)
		assert_true(str(data.fixed_passive_id).is_empty(), aid)
	for aid in ACC_E:
		var data: Resource = DataRegistry.get_accessory_data(aid)
		assert_not_null(data, aid)
		assert_eq(int(data.rarity), Enums.Rarity.EPIC, aid)
		assert_true(str(data.fixed_passive_id).is_empty(), aid)


func test_biome_pools_include_fill_items() -> void:
	var expect: Dictionary = {
		"mourngate": {"armor": "wick_padded_coat", "acc_n": "copper_bell_ring", "acc_e": "ashvault_pendant"},
		"whisperwood": {"armor": "trail_twine_wrap", "acc_n": "seed_pouch_charm", "acc_e": "canopy_ward_talisman"},
		"mistfen": {"armor": "reedmat_vest", "acc_n": "clay_bead_band", "acc_e": "mireglass_brooch"},
		"blackshore": {"armor": "netter_smock", "acc_n": "dock_knot_charm", "acc_e": "tideledger_charm"},
		"frostridge": {"armor": "drove_wool_coat", "acc_n": "mitten_pin", "acc_e": "rimecrown_seal"},
	}
	for dungeon_id in expect.keys():
		var data: Resource = DataRegistry.get_dungeon_data(dungeon_id)
		assert_not_null(data, dungeon_id)
		var row: Dictionary = expect[dungeon_id]
		assert_true(str(row["armor"]) in data.armor_pool, dungeon_id)
		assert_true(str(row["acc_n"]) in data.accessory_pool, dungeon_id)
		assert_true(str(row["acc_e"]) in data.accessory_pool, dungeon_id)


func test_icon_paths_registered() -> void:
	for aid in ARMOR_N:
		var key: String = "armor:%s" % aid
		assert_false(str(IconPaths.ICON_MAP.get(key, "")).is_empty(), key)
	for aid in ACC_N + ACC_E:
		var key: String = "accessory:%s" % aid
		assert_false(str(IconPaths.ICON_MAP.get(key, "")).is_empty(), key)


func test_catalog_counts_after_fill() -> void:
	## 防N≥12／飾N≥12／飾E≥9（補充後の下限）。
	var arm_n: int = 0
	var acc_n: int = 0
	var acc_e: int = 0
	for data in DataRegistry.get_all_armor_data():
		if data != null and int(data.rarity) == Enums.Rarity.COMMON:
			arm_n += 1
	for data in DataRegistry.get_all_accessory_data():
		if data == null:
			continue
		match int(data.rarity):
			Enums.Rarity.COMMON:
				acc_n += 1
			Enums.Rarity.EPIC:
				acc_e += 1
	assert_gte(arm_n, 12)
	assert_gte(acc_n, 12)
	assert_gte(acc_e, 9)
