extends GutTest

## P3-EQ-LEG-WPN-FILL-001 — 弓3／杖2 レジェンド固有効果。

const FILL_LEGENDARIES: Dictionary = {
	"volley_horizon_bow": {"passive": "eq_wpn_volley_horizon_bow", "type": "bow"},
	"vanguard_war_bow": {"passive": "eq_wpn_vanguard_war_bow", "type": "bow"},
	"regicide_longbow": {"passive": "eq_wpn_regicide_longbow", "type": "bow"},
	"amplify_orb_staff": {"passive": "eq_wpn_amplify_orb_staff", "type": "staff"},
	"silent_rite_staff": {"passive": "eq_wpn_silent_rite_staff", "type": "staff"},
}


func _equip(weapon_id: String) -> void:
	var member: Resource = load("res://scripts/domain/Adventurer.gd").new()
	member.id = "fill_leg"
	member.formation_row = GameState.FORMATION_FRONT
	var weapon: Resource = load("res://scripts/domain/WeaponInstance.gd").new()
	weapon.weapon_id = weapon_id
	member.equipped_weapon = weapon
	GameState.party_members = [member]


func after_each() -> void:
	GameState.party_members = []


func test_fill_legendaries_exist() -> void:
	for weapon_id in FILL_LEGENDARIES.keys():
		var meta: Dictionary = FILL_LEGENDARIES[weapon_id]
		var wd: Resource = DataRegistry.get_weapon_data(weapon_id)
		assert_not_null(wd, weapon_id)
		assert_eq(wd.rarity, Enums.Rarity.LEGENDARY, weapon_id)
		assert_eq(str(wd.weapon_type), str(meta["type"]), weapon_id)
		assert_eq(str(wd.fixed_passive_id), str(meta["passive"]), weapon_id)
		assert_eq(str(wd.fixed_skill_id), "", weapon_id)
		var def: Dictionary = CombatPassives.get_def(str(meta["passive"]))
		assert_false(def.is_empty(), str(meta["passive"]))
		assert_eq(str(def.get("category", "")), "weapon")


func test_passive_numbers() -> void:
	var volley: Dictionary = CombatPassives.get_def("eq_wpn_volley_horizon_bow")
	assert_true(bool(volley.get("basic_attack_hits_all", false)))
	assert_almost_eq(float(volley.get("basic_aoe_splash_mult", 1.0)), 0.55, 0.001)
	var war: Dictionary = CombatPassives.get_def("eq_wpn_vanguard_war_bow")
	assert_almost_eq(float(war.get("outgoing_mult", 1.0)), 2.0, 0.001)
	assert_almost_eq(float(war.get("incoming_mult", 1.0)), 1.5, 0.001)
	assert_eq(str(war.get("passive_condition", "")), "front_row_only")
	var reg: Dictionary = CombatPassives.get_def("eq_wpn_regicide_longbow")
	assert_almost_eq(float(reg.get("outgoing_vs_boss_mult", 1.0)), 1.5, 0.001)
	var amp: Dictionary = CombatPassives.get_def("eq_wpn_amplify_orb_staff")
	assert_almost_eq(float(amp.get("basic_attack_mult", 1.0)), 1.35, 0.001)
	var silent: Dictionary = CombatPassives.get_def("eq_wpn_silent_rite_staff")
	assert_true(bool(silent.get("disable_basic_attack", false)))
	assert_almost_eq(float(silent.get("skill_power_mult", 1.0)), 2.0, 0.001)


func test_vanguard_war_bow_front_only() -> void:
	_equip("vanguard_war_bow")
	var front: Dictionary = CombatPassives.character_stat_modifiers_for_member(0)
	assert_almost_eq(float(front.get("outgoing_mult", 1.0)), 2.0, 0.001)
	assert_almost_eq(float(front.get("incoming_mult", 1.0)), 1.5, 0.001)
	GameState.party_members[0].formation_row = GameState.FORMATION_BACK
	var back: Dictionary = CombatPassives.character_stat_modifiers_for_member(0)
	assert_almost_eq(float(back.get("outgoing_mult", 1.0)), 1.0, 0.001)
	assert_almost_eq(float(back.get("incoming_mult", 1.0)), 1.0, 0.001)


func test_helpers_expose_flags() -> void:
	_equip("silent_rite_staff")
	assert_true(CombatPassives.weapon_disables_basic_attack(0))
	assert_almost_eq(CombatPassives.weapon_basic_attack_mult(0), 1.0, 0.001)
	_equip("amplify_orb_staff")
	assert_false(CombatPassives.weapon_disables_basic_attack(0))
	assert_almost_eq(CombatPassives.weapon_basic_attack_mult(0), 1.35, 0.001)
	_equip("volley_horizon_bow")
	assert_true(CombatPassives.weapon_basic_hits_all(0))
	assert_almost_eq(CombatPassives.weapon_basic_aoe_splash_mult(0), 0.55, 0.001)
	_equip("regicide_longbow")
	assert_almost_eq(CombatPassives.weapon_outgoing_vs_boss_mult(0), 1.5, 0.001)


func test_icons_and_pools() -> void:
	for weapon_id in FILL_LEGENDARIES.keys():
		assert_true(IconPaths.ICON_MAP.has("weapon:%s" % weapon_id), weapon_id)
		assert_not_null(IconPaths.get_icon_texture(weapon_id, "weapon"), weapon_id)
	var mf: Resource = DataRegistry.get_dungeon_data("mistfen")
	assert_true(mf.weapon_pool.has("volley_horizon_bow"))
	assert_true(mf.weapon_pool.has("silent_rite_staff"))
	var ww: Resource = DataRegistry.get_dungeon_data("whisperwood")
	assert_true(ww.weapon_pool.has("vanguard_war_bow"))
	assert_true(ww.weapon_pool.has("amplify_orb_staff"))
	var bs: Resource = DataRegistry.get_dungeon_data("blackshore")
	assert_true(bs.weapon_pool.has("regicide_longbow"))
