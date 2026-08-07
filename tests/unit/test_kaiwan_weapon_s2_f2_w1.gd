extends GutTest
## 灰冠武器 S2/F2/W1 差し替え（裂鍵／偽星／枯翠）。


func _equip_weapon(member: Resource, weapon_id: String) -> void:
	var wpn: Resource = load("res://scripts/domain/WeaponInstance.gd").new()
	wpn.weapon_id = weapon_id
	member.equipped_weapon = wpn


func _equip_armor(member: Resource, armor_id: String) -> void:
	var arm: Resource = load("res://scripts/domain/ArmorInstance.gd").new()
	arm.armor_id = armor_id
	member.equipped_armor = arm


func test_tres_fixed_passive_ids() -> void:
	assert_eq(str(DataRegistry.get_weapon_data("kaiwan_silent").fixed_passive_id), "eq_wpn_kaiwan_silent")
	assert_eq(str(DataRegistry.get_weapon_data("kaiwan_false").fixed_passive_id), "eq_wpn_kaiwan_false")
	assert_eq(str(DataRegistry.get_weapon_data("kaiwan_wiltes").fixed_passive_id), "eq_wpn_kaiwan_wiltes")
	assert_eq(str(DataRegistry.get_armor_data("kaiwan_thornmail").fixed_passive_id), "eq_kaiwan_thornmail")


func test_passive_defs_match_s2_f2_w1() -> void:
	var silent: Dictionary = CombatPassives.get_def("eq_wpn_kaiwan_silent")
	assert_almost_eq(float(silent.get("outgoing_vs_buff_mult", 1.0)), 1.25, 0.001)
	assert_almost_eq(float(silent.get("skill_cd_mult", 1.0)), 1.10, 0.001)
	var false_w: Dictionary = CombatPassives.get_def("eq_wpn_kaiwan_false")
	assert_almost_eq(float(false_w.get("crit_damage_add", 0.0)), 0.30, 0.001)
	assert_almost_eq(float(false_w.get("incoming_crit_rate_add", 0.0)), 0.10, 0.001)
	var wiltes: Dictionary = CombatPassives.get_def("eq_wpn_kaiwan_wiltes")
	assert_almost_eq(float(wiltes.get("heal_skill_spill_damage_fraction", 0.0)), 0.40, 0.001)
	assert_almost_eq(float(wiltes.get("heal_received_mult", 1.0)), 0.80, 0.001)
	var thorn: Dictionary = CombatPassives.get_def("eq_kaiwan_thornmail")
	assert_almost_eq(float(thorn.get("heal_skill_spill_damage_add", 0.0)), 0.15, 0.001)
	assert_almost_eq(float(thorn.get("heal_received_mult", 1.0)), 0.80, 0.001)


func test_pool_copy_matches_new_effects() -> void:
	const _Gacha := preload("res://scripts/gacha/GachaEquipSystem.gd")
	var silent: Dictionary = _Gacha.pool_entry_by_id("kaiwan_silent")
	assert_true(str(silent.get("inventory_effect", "")).contains("バフ中"))
	assert_true(str(silent.get("inventory_effect", "")).contains("25%"))
	var false_e: Dictionary = _Gacha.pool_entry_by_id("kaiwan_false")
	assert_true(str(false_e.get("inventory_effect", "")).contains("会心ダメージ"))
	assert_true(str(false_e.get("inventory_effect", "")).contains("30%"))
	var wiltes: Dictionary = _Gacha.pool_entry_by_id("kaiwan_wiltes")
	assert_true(str(wiltes.get("inventory_effect", "")).contains("最弱"))
	assert_true(str(wiltes.get("inventory_effect", "")).contains("40%"))
	var thorn: Dictionary = _Gacha.pool_entry_by_id("kaiwan_thornmail")
	assert_true(str(thorn.get("inventory_effect", "")).contains("追撃"))


func test_silent_skill_cd_and_buff_mult_resolve() -> void:
	var member: Resource = load("res://scripts/domain/Adventurer.gd").new()
	member.id = "kaiwan_test_silent"
	_equip_weapon(member, "kaiwan_silent")
	GameState.party_members = [member]
	assert_almost_eq(CombatPassives.relic_skill_cd_mult(0), 1.10, 0.001)
	assert_almost_eq(CombatPassives.outgoing_vs_buff_mult_for_member(0), 1.25, 0.001)
	GameState.party_members = []


func test_false_crit_mods_resolve() -> void:
	var member: Resource = load("res://scripts/domain/Adventurer.gd").new()
	member.id = "kaiwan_test_false"
	_equip_weapon(member, "kaiwan_false")
	GameState.party_members = [member]
	var mods: Dictionary = CombatPassives.weapon_stat_modifiers_for_member(0)
	assert_almost_eq(float(mods.get("crit_damage_add", 0.0)), 0.30, 0.001)
	assert_almost_eq(CombatPassives.incoming_crit_rate_add_for_member(0), 0.10, 0.001)
	GameState.party_members = []


func test_wiltes_spill_and_heal_received() -> void:
	var member: Resource = load("res://scripts/domain/Adventurer.gd").new()
	member.id = "kaiwan_test_wiltes"
	_equip_weapon(member, "kaiwan_wiltes")
	GameState.party_members = [member]
	assert_almost_eq(CombatPassives.heal_skill_spill_damage_fraction(0), 0.40, 0.001)
	assert_almost_eq(CombatPassives.relic_heal_received_mult(0), 0.80, 0.001)
	_equip_armor(member, "kaiwan_thornmail")
	assert_almost_eq(CombatPassives.heal_skill_spill_damage_fraction(0), 0.55, 0.001)
	assert_almost_eq(CombatPassives.relic_heal_received_mult(0), 0.64, 0.001)
	GameState.party_members = []
