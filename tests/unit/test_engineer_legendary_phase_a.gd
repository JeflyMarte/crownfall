extends GutTest

## 機巧士ビルドL Phase A（P3-EQ-ENGINEER-LEG-001 / `130`）。

const _AccessoryInstance = preload("res://scripts/domain/AccessoryInstance.gd")
const _WeaponInstance = preload("res://scripts/domain/WeaponInstance.gd")


func _equip_engineer(accessory_id: String = "", weapon_id: String = "") -> void:
	var member: Resource = Adventurer.new()
	member.id = "adventurer_0"
	member.job_id = "engineer"
	if not accessory_id.is_empty():
		var acc: Resource = _AccessoryInstance.new()
		acc.accessory_id = accessory_id
		member.equipped_accessory = acc
	if not weapon_id.is_empty():
		var weapon: Resource = _WeaponInstance.new()
		weapon.weapon_id = weapon_id
		member.equipped_weapon = weapon
	GameState.party_members = [member]


func after_each() -> void:
	GameState.party_members = []


func test_engineer_legendary_items_exist() -> void:
	assert_not_null(DataRegistry.get_weapon_data("coil_spring_dual"))
	assert_not_null(DataRegistry.get_weapon_data("pyrebrand_maul"))
	assert_not_null(DataRegistry.get_accessory_data("trapgear_charm"))
	assert_not_null(DataRegistry.get_accessory_data("overheat_amulet"))
	assert_not_null(DataRegistry.get_accessory_data("seam_focus_sigil"))


func test_engineer_legendary_passive_defs() -> void:
	var coil: Dictionary = CombatPassives.get_def("eq_wpn_coil_spring_dual")
	assert_eq(int(coil.get("engineer_trap_fires_add", 0)), 1)
	var trap_charm: Dictionary = CombatPassives.get_def("eq_trapgear_charm")
	assert_almost_eq(float(trap_charm.get("trap_skill_cd_mult", 1.0)), 0.88, 0.001)
	var pyre: Dictionary = CombatPassives.get_def("eq_wpn_pyrebrand_maul")
	assert_almost_eq(float(pyre.get("outgoing_vs_status_mult", 1.0)), 1.20, 0.001)
	assert_true(pyre.get("outgoing_vs_status_ids", []).has("ignite"))
	var overheat: Dictionary = CombatPassives.get_def("eq_overheat_amulet")
	assert_almost_eq(float(overheat.get("long_cd_skill_power_mult", 1.0)), 1.15, 0.001)
	assert_almost_eq(float(overheat.get("long_cd_skill_min_cooldown", 0.0)), 12.0, 0.001)
	var sigil: Dictionary = CombatPassives.get_def("eq_seam_focus_sigil")
	assert_almost_eq(float(sigil.get("outgoing_vs_status_max_mult", 0.0)), 1.35, 0.001)


func test_long_cd_power_mult_for_charge_shot() -> void:
	_equip_engineer("overheat_amulet")
	var charge: Resource = DataRegistry.get_skill_data("eng_charge_shot")
	assert_not_null(charge)
	assert_almost_eq(
		CombatPassives.long_cd_skill_power_mult_for_member(0, charge),
		1.15,
		0.001
	)
	var spike: Resource = DataRegistry.get_skill_data("eng_spike_trap")
	assert_almost_eq(
		CombatPassives.long_cd_skill_power_mult_for_member(0, spike),
		1.0,
		0.001
	)


func test_armor_break_outgoing_cap_stacks_with_seam_breaker_and_sigil() -> void:
	_equip_engineer("seam_focus_sigil")
	assert_almost_eq(
		CombatPassives.outgoing_vs_status_mult_for_member(0, ["armor_break"]),
		1.15,
		0.001
	)
	_equip_engineer("seam_focus_sigil", "seam_breaker_maul")
	assert_almost_eq(
		CombatPassives.outgoing_vs_status_mult_for_member(0, ["armor_break"]),
		1.35,
		0.001
	)


func test_weapon_pools_include_new_legendaries() -> void:
	var stage: Resource = load("res://resources/dungeons/mistfen.tres")
	assert_not_null(stage)
	var pool: Array = stage.weapon_pool
	assert_true(pool.has("coil_spring_dual"))
	assert_true(pool.has("pyrebrand_maul"))


func test_engineer_legendary_icons_exist_and_unique() -> void:
	var ids: Array[String] = [
		"coil_spring_dual",
		"pyrebrand_maul",
		"trapgear_charm",
		"overheat_amulet",
		"seam_focus_sigil",
	]
	var seen: Dictionary = {}
	for item_id in ids:
		var kind: String = "weapon" if item_id.ends_with("_dual") or item_id.ends_with("_maul") else "accessory"
		var key: String = "%s:%s" % [kind, item_id]
		var path: String = str(IconPaths.ICON_MAP.get(key, ""))
		assert_false(path.is_empty(), item_id)
		assert_true(FileAccess.file_exists(path), "%s missing %s" % [item_id, path])
		assert_not_null(IconPaths.get_icon_texture(item_id, kind), item_id)
		var md5: String = FileAccess.get_md5(path)
		assert_false(seen.has(md5), "duplicate icon: %s" % item_id)
		seen[md5] = item_id
