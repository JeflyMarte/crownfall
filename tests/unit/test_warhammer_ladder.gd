extends GutTest

## P3-EQ-WARHAMMER-001-A — 戦鎚章梯子＋破砕L

const LADDER: Dictionary = {
	"mistfen": ["mire_warhammer", "storm_maul", "thunderfen_maul"],
	"whisperwood": ["verdant_maul", "pyre_maul", "symbiont_maul"],
	"frostridge": ["ridge_maul", "glacier_maul", "permafrost_maul"],
	"blackshore": ["black_sand_maul", "lighthouse_maul", "sanctum_tide_maul"],
}

const ALL_HAMMERS: Array[String] = [
	"iron_warhammer",
	"mire_warhammer", "verdant_maul", "ridge_maul", "black_sand_maul",
	"storm_maul", "pyre_maul", "glacier_maul", "lighthouse_maul",
	"thunderfen_maul", "symbiont_maul", "permafrost_maul", "sanctum_tide_maul",
	"seam_breaker_maul",
]


func test_all_hammers_are_hammer_type() -> void:
	for wid in ALL_HAMMERS:
		var wd: Resource = DataRegistry.get_weapon_data(wid)
		assert_not_null(wd, wid)
		assert_eq(str(wd.weapon_type), "hammer", wid)
		assert_almost_eq(float(wd.base_attack_speed), 0.8, 0.001, wid)


func test_ladder_rarities() -> void:
	assert_eq(DataRegistry.get_weapon_data("mire_warhammer").rarity, Enums.Rarity.COMMON)
	assert_eq(DataRegistry.get_weapon_data("storm_maul").rarity, Enums.Rarity.RARE)
	assert_eq(DataRegistry.get_weapon_data("thunderfen_maul").rarity, Enums.Rarity.EPIC)
	assert_eq(DataRegistry.get_weapon_data("seam_breaker_maul").rarity, Enums.Rarity.LEGENDARY)


func test_biome_pools_include_ladder_and_leg() -> void:
	for dungeon_id in LADDER.keys():
		var dd: Resource = DataRegistry.get_dungeon_data(dungeon_id)
		assert_not_null(dd, dungeon_id)
		for wid in LADDER[dungeon_id]:
			assert_true(wid in dd.weapon_pool, "%s missing %s" % [dungeon_id, wid])
		assert_true("seam_breaker_maul" in dd.weapon_pool, dungeon_id)
	var mg: Resource = DataRegistry.get_dungeon_data("mourngate")
	assert_true("iron_warhammer" in mg.weapon_pool)
	assert_true("seam_breaker_maul" in mg.weapon_pool)


func test_seam_breaker_legendary_passive() -> void:
	var wd: Resource = DataRegistry.get_weapon_data("seam_breaker_maul")
	assert_eq(str(wd.fixed_passive_id), "eq_wpn_seam_breaker_maul")
	var def: Dictionary = CombatPassives.get_def("eq_wpn_seam_breaker_maul")
	assert_false(def.is_empty())
	assert_almost_eq(float(def.get("outgoing_vs_status_mult", 1.0)), 1.25, 0.001)
	assert_true("armor_break" in def.get("outgoing_vs_status_ids", []))
	assert_eq(str(def.get("status_id", "")), "armor_break")
	assert_almost_eq(float(def.get("status_chance", 0.0)), 0.25, 0.001)


func test_warhammer_icons_registered_and_exist() -> void:
	var seen_md5: Dictionary = {}
	var consecrated_path: String = ProjectSettings.globalize_path(
		"res://assets/ui/equipment/ICO_WPN_ConsecratedMaul.png"
	)
	for wid in ALL_HAMMERS:
		var path: String = str(IconPaths.ICON_MAP.get("weapon:%s" % wid, ""))
		assert_false(path.is_empty(), wid)
		var local: String = ProjectSettings.globalize_path(path)
		assert_true(FileAccess.file_exists(local), "%s -> %s" % [wid, local])
		var md5: String = FileAccess.get_md5(local)
		assert_false(md5.is_empty(), "%s md5 empty" % wid)
		if wid == "seam_breaker_maul":
			assert_ne(md5, FileAccess.get_md5(consecrated_path))
		assert_false(seen_md5.has(md5), "duplicate icon bytes: %s vs %s" % [wid, seen_md5.get(md5, "")])
		seen_md5[md5] = wid


func test_engineer_can_equip_ladder_hammers() -> void:
	var host: Resource = null
	GameState.seed_all_starters_unlocked()
	for m: Resource in GameState.roster:
		if m != null and str(m.job_id) == "swordsman":
			host = m
			break
	assert_not_null(host)
	var saved: String = str(host.job_id)
	host.job_id = "engineer"
	var calc = preload("res://scripts/equipment/JobStatCalculator.gd")
	for wid in ALL_HAMMERS:
		var inst: Resource = WeaponInstance.new()
		inst.instance_id = "t_%s" % wid
		inst.weapon_id = wid
		inst.is_appraised = true
		assert_true(calc.can_equip_weapon(host, inst), wid)
	host.job_id = saved
