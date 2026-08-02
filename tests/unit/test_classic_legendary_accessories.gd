extends GutTest
## P3-EQ-CLASSIC-L-ACC-001 — クラシックL装飾補充（通常レジェンド母数）

const _DungeonController = preload("res://scripts/dungeon/DungeonController.gd")
const _BuildLegendaryLoot = preload("res://scripts/equipment/BuildLegendaryLoot.gd")

const CLASSIC_IDS: Array[String] = [
	"bloodvein_signet",
	"ironvow_amulet",
	"quicksigil_charm",
	"dawnrally_brooch",
]

const PASSIVE_BY_ID: Dictionary = {
	"bloodvein_signet": "eq_bloodvein_signet",
	"ironvow_amulet": "eq_ironvow_amulet",
	"quicksigil_charm": "eq_quicksigil_charm",
	"dawnrally_brooch": "eq_dawnrally_brooch",
}


func test_classic_defs_and_passives() -> void:
	for cid: String in CLASSIC_IDS:
		var data: Resource = DataRegistry.get_accessory_data(cid)
		assert_not_null(data, cid)
		assert_eq(int(data.rarity), Enums.Rarity.LEGENDARY, cid)
		assert_eq(str(data.fixed_passive_id), str(PASSIVE_BY_ID[cid]), cid)
		var def: Dictionary = CombatPassives.get_def(str(PASSIVE_BY_ID[cid]))
		assert_false(def.is_empty(), str(PASSIVE_BY_ID[cid]))
		assert_false(str(def.get("description", "")).is_empty(), str(PASSIVE_BY_ID[cid]))


func test_classic_passive_numbers() -> void:
	var blood: Dictionary = CombatPassives.get_def("eq_bloodvein_signet")
	assert_eq(float(blood.get("outgoing_mult", 1.0)), 1.12)
	assert_eq(float(blood.get("incoming_mult", 1.0)), 1.05)
	var iron: Dictionary = CombatPassives.get_def("eq_ironvow_amulet")
	assert_eq(float(iron.get("incoming_mult", 1.0)), 0.88)
	var quick: Dictionary = CombatPassives.get_def("eq_quicksigil_charm")
	assert_eq(float(quick.get("skill_cd_mult", 1.0)), 0.85)
	var dawn: Dictionary = CombatPassives.get_def("eq_dawnrally_brooch")
	assert_eq(str(dawn.get("effect", "")), "party_rally")
	assert_eq(str(dawn.get("status_id", "")), "empower")


func test_included_in_normal_legendary_pool() -> void:
	var dc: Node = _DungeonController.new()
	add_child_autofree(dc)
	var pool: Array[String] = dc._all_legendary_ids("accessory")
	for cid: String in CLASSIC_IDS:
		assert_true(cid in pool, cid)
	assert_true(pool.size() >= 9, "通常L飾は Biome5＋クラシック4 以上")


func test_excluded_from_build_and_sealed_prefixes() -> void:
	for cid: String in CLASSIC_IDS:
		assert_false(cid in _BuildLegendaryLoot.all_ids(), cid)
		assert_false(cid.begins_with("kaiwan_"), cid)


func test_icon_paths_registered() -> void:
	for cid: String in CLASSIC_IDS:
		var key: String = "accessory:%s" % cid
		assert_false(str(IconPaths.ICON_MAP.get(key, "")).is_empty(), key)
