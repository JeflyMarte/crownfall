extends GutTest
## P3-BAL-LEG-ATTR-B001 — 属性レジェンドの平％を状態／列の条件付き個性へ。


func _equip(weapon_id: String) -> void:
	var member: Resource = load("res://scripts/domain/Adventurer.gd").new()
	member.id = "leg_attr_b"
	var weapon: Resource = load("res://scripts/domain/WeaponInstance.gd").new()
	weapon.weapon_id = weapon_id
	member.equipped_weapon = weapon
	GameState.party_members = [member]


func after_each() -> void:
	GameState.party_members = []


func test_attribute_legendaries_use_status_synergy() -> void:
	var thunder: Dictionary = CombatPassives.get_def("eq_wpn_volgrave_thunderblade")
	assert_almost_eq(float(thunder["element_outgoing_mult"]["thunder"]), 1.10, 0.001)
	assert_almost_eq(float(thunder.get("outgoing_vs_status_mult", 1.0)), 1.40, 0.001)
	assert_true(thunder.get("outgoing_vs_status_ids", []).has("shock"))
	assert_eq(str(thunder.get("status_id", "")), "shock")
	assert_almost_eq(float(thunder.get("status_chance", 0.0)), 0.25, 0.001)

	var frost: Dictionary = CombatPassives.get_def("eq_wpn_eldion_frostbrand")
	assert_almost_eq(float(frost["element_outgoing_mult"]["ice"]), 1.10, 0.001)
	assert_almost_eq(float(frost.get("outgoing_vs_status_mult", 1.0)), 1.40, 0.001)
	assert_true(frost.get("outgoing_vs_status_ids", []).has("chill"))
	assert_eq(str(frost.get("status_id", "")), "chill")

	var fang: Dictionary = CombatPassives.get_def("eq_wpn_silvaria_fang")
	assert_almost_eq(float(fang["element_outgoing_mult"]["fire"]), 1.10, 0.001)
	assert_almost_eq(float(fang.get("outgoing_vs_status_mult", 1.0)), 1.40, 0.001)
	assert_true(fang.get("outgoing_vs_status_ids", []).has("ignite"))
	assert_eq(str(fang.get("status_id", "")), "ignite")


func test_ice_cluster_roles_diverge() -> void:
	var brand: Dictionary = CombatPassives.get_def("eq_wpn_eldion_frostbrand")
	var spine: Dictionary = CombatPassives.get_def("eq_wpn_eldion_spine")
	var claw: Dictionary = CombatPassives.get_def("eq_wpn_eldion_claw")
	assert_eq(str(brand.get("status_id", "")), "chill")
	assert_almost_eq(float(spine.get("back_row_basic_attack_mult", 1.0)), 1.25, 0.001)
	assert_eq(int(claw.get("every_n", 0)), 3)
	assert_true(float(brand["element_outgoing_mult"]["ice"]) < 1.20)
	assert_true(float(spine["element_outgoing_mult"]["ice"]) < 1.20)
	assert_true(float(claw["element_outgoing_mult"]["ice"]) < 1.10)


func test_runtime_vs_status_from_equipped_weapon() -> void:
	_equip("volgrave_thunderblade")
	assert_almost_eq(CombatPassives.outgoing_vs_status_mult_for_member(0, ["shock"]), 1.40, 0.001)
	assert_almost_eq(CombatPassives.outgoing_vs_status_mult_for_member(0, ["poison"]), 1.0, 0.001)
	_equip("silvaria_fang")
	assert_almost_eq(CombatPassives.outgoing_vs_status_mult_for_member(0, ["ignite"]), 1.40, 0.001)
	_equip("eldion_frostbrand")
	assert_almost_eq(CombatPassives.outgoing_vs_status_mult_for_member(0, ["chill"]), 1.40, 0.001)


func test_eldion_glacier_armor_adds_damage_reduction() -> void:
	var glacier: Dictionary = CombatPassives.get_def("eq_eldion_glacier")
	assert_almost_eq(float(glacier.get("incoming_mult", 1.0)), 0.92, 0.001)
	assert_eq(str(glacier.get("status_id", "")), "chill")
	assert_ne(str(glacier.get("description", "")).find("8%"), -1)
