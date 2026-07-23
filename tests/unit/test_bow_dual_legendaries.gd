extends GutTest

## P3-EQ-LEG-WPN-BOW-DUAL-001 — 弓／双刃レジェンド拡充。

const NEW_LEGENDARIES: Dictionary = {
	"eldion_spine": {"passive": "eq_wpn_eldion_spine", "type": "bow", "element": "ice"},
	"pharos_flare": {"passive": "eq_wpn_pharos_flare", "type": "bow", "element": "fire"},
	"shadowcord": {"passive": "eq_wpn_shadowcord", "type": "bow", "element": "dark"},
	"silvaria_fang": {"passive": "eq_wpn_silvaria_fang", "type": "dual_blades", "element": "fire"},
	"eldion_claw": {"passive": "eq_wpn_eldion_claw", "type": "dual_blades", "element": "ice"},
}


func test_bow_and_dual_legendaries_exist() -> void:
	for weapon_id in NEW_LEGENDARIES.keys():
		var meta: Dictionary = NEW_LEGENDARIES[weapon_id]
		var wd: Resource = DataRegistry.get_weapon_data(weapon_id)
		assert_not_null(wd, weapon_id)
		assert_eq(wd.rarity, Enums.Rarity.LEGENDARY, weapon_id)
		assert_eq(str(wd.weapon_type), str(meta["type"]), weapon_id)
		assert_eq(str(wd.element), str(meta["element"]), weapon_id)
		assert_eq(str(wd.fixed_passive_id), str(meta["passive"]), weapon_id)
		assert_eq(str(wd.fixed_skill_id), "", weapon_id)
		var def: Dictionary = CombatPassives.get_def(str(meta["passive"]))
		assert_false(def.is_empty(), str(meta["passive"]))
		assert_eq(str(def.get("category", "")), "weapon")
		assert_false(str(def.get("description", "")).is_empty())


func test_new_legendary_icons_resolve() -> void:
	for weapon_id in NEW_LEGENDARIES.keys():
		var key: String = "weapon:%s" % weapon_id
		assert_true(IconPaths.ICON_MAP.has(key), key)
		var path: String = str(IconPaths.ICON_MAP[key])
		assert_true(ResourceLoader.exists(path), "%s -> %s" % [weapon_id, path])
		var tex: Texture2D = IconPaths.get_icon_texture(weapon_id, "weapon")
		assert_not_null(tex, weapon_id)


func test_biome_pools_include_new_legendaries() -> void:
	var mg: Resource = DataRegistry.get_dungeon_data("mourngate")
	assert_true(mg.weapon_pool.has("shadowcord"), "mourngate has shadowcord")
	var ww: Resource = DataRegistry.get_dungeon_data("whisperwood")
	assert_true(ww.weapon_pool.has("silvaria_fang"), "whisperwood has silvaria_fang")
	var bs: Resource = DataRegistry.get_dungeon_data("blackshore")
	assert_true(bs.weapon_pool.has("pharos_flare"), "blackshore has pharos_flare")
	var fr: Resource = DataRegistry.get_dungeon_data("frostridge")
	assert_true(fr.weapon_pool.has("eldion_spine"), "frostridge has eldion_spine")
	assert_true(fr.weapon_pool.has("eldion_claw"), "frostridge has eldion_claw")


func test_passive_effects_match_brief() -> void:
	var spine: Dictionary = CombatPassives.get_def("eq_wpn_eldion_spine")
	assert_almost_eq(float(spine["element_outgoing_mult"]["ice"]), 1.25, 0.001)
	var flare: Dictionary = CombatPassives.get_def("eq_wpn_pharos_flare")
	assert_almost_eq(float(flare.get("skill_power_mult", 1.0)), 1.35, 0.001)
	var cord: Dictionary = CombatPassives.get_def("eq_wpn_shadowcord")
	assert_almost_eq(float(cord.get("crit_rate_add", 0.0)), 0.10, 0.001)
	assert_almost_eq(float(cord.get("crit_damage_add", 0.0)), 0.40, 0.001)
	var fang: Dictionary = CombatPassives.get_def("eq_wpn_silvaria_fang")
	assert_almost_eq(float(fang["element_outgoing_mult"]["fire"]), 1.25, 0.001)
	var claw: Dictionary = CombatPassives.get_def("eq_wpn_eldion_claw")
	assert_almost_eq(float(claw["element_outgoing_mult"]["ice"]), 1.25, 0.001)
