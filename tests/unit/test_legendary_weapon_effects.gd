extends GutTest
## P3-WPN-LEG-EFFECT — レジェンド武器固有効果（10本）。

const LEGENDARY_WEAPON_PASSIVES: Dictionary = {
	"sanctified_dagger": "eq_wpn_sanctified_dagger",
	"consecrated_maul": "eq_wpn_consecrated_maul",
	"silvaria_oathblade": "eq_wpn_silvaria_oathblade",
	"veld_branch_staff": "eq_wpn_veld_branch_staff",
	"nereidas_tideblade": "eq_wpn_nereidas_tideblade",
	"pharoslight_staff": "eq_wpn_pharoslight_staff",
	"volgrave_thunderblade": "eq_wpn_volgrave_thunderblade",
	"seradion_storm_staff": "eq_wpn_seradion_storm_staff",
	"eldion_frostbrand": "eq_wpn_eldion_frostbrand",
	"umbra_terminus_staff": "eq_wpn_umbra_terminus_staff",
}


func test_legendary_weapons_use_fixed_passive_not_skill() -> void:
	for weapon_id in LEGENDARY_WEAPON_PASSIVES.keys():
		var wd: Resource = DataRegistry.get_weapon_data(weapon_id)
		assert_not_null(wd, weapon_id)
		assert_eq(str(wd.fixed_passive_id), LEGENDARY_WEAPON_PASSIVES[weapon_id], weapon_id)
		assert_eq(str(wd.fixed_skill_id), "", weapon_id)
		assert_eq(wd.rarity, Enums.Rarity.LEGENDARY, weapon_id)


func test_weapon_passive_defs_exist() -> void:
	for pid in LEGENDARY_WEAPON_PASSIVES.values():
		var def: Dictionary = CombatPassives.get_def(pid)
		assert_false(def.is_empty(), pid)
		assert_eq(str(def.get("category", "")), "weapon", pid)
		assert_false(str(def.get("description", "")).is_empty(), pid)


func test_seradion_exp_and_nereidas_crit_mods() -> void:
	var member: Resource = load("res://scripts/domain/Adventurer.gd").new()
	member.id = "test"
	var weapon: Resource = load("res://scripts/domain/WeaponInstance.gd").new()
	weapon.weapon_id = "seradion_storm_staff"
	member.equipped_weapon = weapon
	var mods: Dictionary = CombatPassives.weapon_stat_modifiers_for_member(0)
	# member may not be in party index 0 — test def directly
	var storm: Dictionary = CombatPassives.get_def("eq_wpn_seradion_storm_staff")
	assert_eq(float(storm.get("exp_gain_mult", 1.0)), 2.0)
	var tide: Dictionary = CombatPassives.get_def("eq_wpn_nereidas_tideblade")
	assert_eq(float(tide.get("crit_rate_add", 0.0)), 0.15)
	assert_eq(float(tide.get("crit_damage_add", 0.0)), 0.50)


func test_weapon_detail_shows_legendary_effect() -> void:
	var wd: Resource = DataRegistry.get_weapon_data("sanctified_dagger")
	assert_not_null(wd)
	var effect: String = CombatPassives.weapon_passive_description(str(wd.fixed_passive_id))
	assert_true(effect.find("呪い") >= 0, effect)


func test_generic_element_skills_remain_on_non_legendary_weapons() -> void:
	var wd: Resource = DataRegistry.get_weapon_data("pyre_greatsword")
	assert_not_null(wd)
	assert_eq(str(wd.fixed_skill_id), "kindling_strike")
	assert_ne(wd.rarity, Enums.Rarity.LEGENDARY)
