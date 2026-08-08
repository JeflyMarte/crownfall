extends GutTest
## P3-EQ-CLASSIC-L-ACC-001 — クラシックL装飾補充（通常レジェンド母数）
## 2026-08-08: 職テーマ網羅差し替え（95）

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
	assert_almost_eq(float(blood.get("lifesteal_ratio", 0.0)), 0.10, 0.001)
	var iron: Dictionary = CombatPassives.get_def("eq_ironvow_amulet")
	assert_almost_eq(float(iron.get("exploration_damage_party_mult", 1.0)), 0.75, 0.001)
	var quick: Dictionary = CombatPassives.get_def("eq_quicksigil_charm")
	assert_almost_eq(float(quick.get("outgoing_vs_status_mult", 1.0)), 1.15, 0.001)
	assert_eq(str(quick.get("status_id", "")), "chill")
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
