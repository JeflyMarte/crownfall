extends GutTest

## P3-BAL-LEG-WPN-A001 — ビルド穴埋めレジェンド4本。

const NEW_LEGENDARIES: Dictionary = {
	"packbond_staff": {"passive": "eq_wpn_packbond_staff", "type": "staff"},
	"blightcord_bow": {"passive": "eq_wpn_blightcord_bow", "type": "bow"},
	"pulsekeen_edge": {"passive": "eq_wpn_pulsekeen_edge", "type": "sword"},
	"aegis_line_sword": {"passive": "eq_wpn_aegis_line_sword", "type": "sword"},
}


func _equip(weapon_id: String, back_row: bool = false) -> void:
	var member: Resource = load("res://scripts/domain/Adventurer.gd").new()
	member.id = "leg_wpn_a"
	member.formation_row = GameState.FORMATION_BACK if back_row else GameState.FORMATION_FRONT
	var weapon: Resource = load("res://scripts/domain/WeaponInstance.gd").new()
	weapon.weapon_id = weapon_id
	member.equipped_weapon = weapon
	GameState.party_members = [member]


func after_each() -> void:
	GameState.party_members = []


func test_build_gap_legendaries_exist() -> void:
	for weapon_id in NEW_LEGENDARIES.keys():
		var meta: Dictionary = NEW_LEGENDARIES[weapon_id]
		var wd: Resource = DataRegistry.get_weapon_data(weapon_id)
		assert_not_null(wd, weapon_id)
		assert_eq(wd.rarity, Enums.Rarity.LEGENDARY, weapon_id)
		assert_eq(str(wd.weapon_type), str(meta["type"]), weapon_id)
		assert_eq(str(wd.fixed_passive_id), str(meta["passive"]), weapon_id)
		assert_eq(str(wd.fixed_skill_id), "", weapon_id)
		var def: Dictionary = CombatPassives.get_def(str(meta["passive"]))
		assert_false(def.is_empty(), str(meta["passive"]))
		assert_eq(str(def.get("category", "")), "weapon")
		assert_false(str(def.get("description", "")).is_empty())


func test_passive_numbers() -> void:
	var pack: Dictionary = CombatPassives.get_def("eq_wpn_packbond_staff")
	assert_almost_eq(float(pack.get("pet_outgoing_mult", 1.0)), 1.30, 0.001)
	assert_almost_eq(float(pack.get("pet_defense_mult", 1.0)), 1.10, 0.001)
	var blight: Dictionary = CombatPassives.get_def("eq_wpn_blightcord_bow")
	assert_almost_eq(float(blight.get("outgoing_vs_status_mult", 1.0)), 1.35, 0.001)
	assert_true(blight.get("outgoing_vs_status_ids", []).has("poison"))
	assert_true(blight.get("outgoing_vs_status_ids", []).has("bleed"))
	assert_eq(str(blight.get("effect", "")), "random_enemy_status")
	assert_almost_eq(float(blight.get("status_chance", 0.0)), 0.25, 0.001)
	var pulse: Dictionary = CombatPassives.get_def("eq_wpn_pulsekeen_edge")
	assert_eq(str(pulse.get("condition", "")), "is_critical")
	assert_eq(str(pulse.get("effect", "")), "crit_pulse")
	assert_almost_eq(float(pulse.get("ultimate_charge_flat", 0.0)), 8.0, 0.001)
	assert_almost_eq(float(pulse.get("bonus_damage_fraction", 0.0)), 0.35, 0.001)
	var aegis: Dictionary = CombatPassives.get_def("eq_wpn_aegis_line_sword")
	assert_almost_eq(float(aegis.get("counter_damage_mult", 1.0)), 1.30, 0.001)
	assert_eq(str(aegis.get("effect", "")), "grant_counter_charges")
	assert_eq(int(aegis.get("counter_charges", 0)), 1)
	assert_almost_eq(float(aegis.get("threat_base_add", 0.0)), 80.0, 0.001)


func test_plan_a_weapon_retunes() -> void:
	var spine: Dictionary = CombatPassives.get_def("eq_wpn_eldion_spine")
	assert_almost_eq(float(spine.get("back_row_basic_attack_mult", 1.0)), 1.25, 0.001)
	var flare: Dictionary = CombatPassives.get_def("eq_wpn_pharos_flare")
	assert_almost_eq(float(flare.get("ultimate_charge_dealt_mult", 1.0)), 1.75, 0.001)
	assert_almost_eq(float(flare.get("skill_power_mult", 1.0)), 1.15, 0.001)
	var cord: Dictionary = CombatPassives.get_def("eq_wpn_shadowcord")
	assert_eq(str(cord.get("trigger", "")), "on_kill")
	assert_eq(str(cord.get("status_id", "")), "empower")
	var claw: Dictionary = CombatPassives.get_def("eq_wpn_eldion_claw")
	assert_almost_eq(float(claw["element_outgoing_mult"]["ice"]), 1.05, 0.001)
	assert_eq(int(claw.get("every_n", 0)), 3)
	var war: Dictionary = CombatPassives.get_def("eq_wpn_vanguard_war_bow")
	assert_eq(str(war.get("status_id", "")), "mark")
	assert_almost_eq(float(war.get("outgoing_vs_status_mult", 1.0)), 1.20, 0.001)


func test_runtime_helpers() -> void:
	_equip("packbond_staff")
	assert_almost_eq(CombatPassives.pet_outgoing_mult_from_party(), 1.30, 0.001)
	assert_almost_eq(CombatPassives.pet_defense_mult_from_party(), 1.10, 0.001)
	_equip("aegis_line_sword")
	assert_almost_eq(CombatPassives.counter_damage_mult_for_member(0), 1.30, 0.001)
	assert_almost_eq(CombatPassives.threat_base_add_for_member(GameState.party_members[0]), 80.0, 0.001)
	_equip("pharos_flare")
	assert_almost_eq(CombatPassives.weapon_ultimate_charge_dealt_mult(0), 1.75, 0.001)
	_equip("eldion_spine")
	assert_almost_eq(CombatPassives.weapon_basic_attack_mult(0), 1.0, 0.001)
	_equip("eldion_spine", true)
	assert_almost_eq(CombatPassives.weapon_basic_attack_mult(0), 1.25, 0.001)
	_equip("vanguard_war_bow")
	assert_almost_eq(CombatPassives.outgoing_vs_status_mult_for_member(0, ["mark"]), 1.20, 0.001)
	_equip("blightcord_bow")
	assert_almost_eq(CombatPassives.outgoing_vs_status_mult_for_member(0, ["poison"]), 1.35, 0.001)
	assert_almost_eq(CombatPassives.outgoing_vs_status_mult_for_member(0, ["stun"]), 1.0, 0.001)
	assert_almost_eq(CombatPassives.outgoing_vs_status_mult_for_member(0, []), 1.0, 0.001)


func test_icons_and_pools() -> void:
	for weapon_id in NEW_LEGENDARIES.keys():
		assert_true(IconPaths.ICON_MAP.has("weapon:%s" % weapon_id), weapon_id)
		assert_not_null(IconPaths.get_icon_texture(weapon_id, "weapon"), weapon_id)
	var ww: Resource = DataRegistry.get_dungeon_data("whisperwood")
	assert_true(ww.weapon_pool.has("packbond_staff"))
	assert_true(ww.weapon_pool.has("pulsekeen_edge"))
	var mf: Resource = DataRegistry.get_dungeon_data("mistfen")
	assert_true(mf.weapon_pool.has("packbond_staff"))
	assert_true(mf.weapon_pool.has("blightcord_bow"))
	var bs: Resource = DataRegistry.get_dungeon_data("blackshore")
	assert_true(bs.weapon_pool.has("blightcord_bow"))
	var mg: Resource = DataRegistry.get_dungeon_data("mourngate")
	assert_true(mg.weapon_pool.has("pulsekeen_edge"))
	assert_true(mg.weapon_pool.has("aegis_line_sword"))
