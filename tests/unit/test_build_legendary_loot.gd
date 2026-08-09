extends GutTest
## P3-EQ-LEG-BUILD-001 — ビルド拡張レジェンド防具・装飾。

const _BuildLegendaryLoot = preload("res://scripts/equipment/BuildLegendaryLoot.gd")
const _DungeonController = preload("res://scripts/dungeon/DungeonController.gd")
const _DungeonTierConfig = preload("res://scripts/dungeon/DungeonTierConfig.gd")

const BUILD_ARMORS: Array[String] = [
	"bloodpact_plate",
	"flurry_light_mail",
	"bulwark_role_plate",
	"cover_aegis_cloak",
	"hexweave_robe",
	"beastcall_mantle",
	"field_salve_robe",
]

const BUILD_ACCESSORIES: Array[String] = [
	"blade_dance_ring",
	"pierce_charm",
	"pulse_amulet",
	"beastlord_fang",
	"apothecary_vial",
]

const BUILD_WEAPONS: Array[String] = [
	"mendweaver_staff",
]

const PASSIVE_BY_ID: Dictionary = {
	"bloodpact_plate": "eq_bloodpact_plate",
	"flurry_light_mail": "eq_flurry_mail",
	"bulwark_role_plate": "eq_bulwark_role",
	"cover_aegis_cloak": "eq_cover_aegis",
	"hexweave_robe": "eq_hexweave_robe",
	"beastcall_mantle": "eq_beastcall_mantle",
	"field_salve_robe": "eq_field_salve_robe",
	"blade_dance_ring": "eq_blade_dance_ring",
	"pierce_charm": "eq_pierce_charm",
	"pulse_amulet": "eq_pulse_amulet",
	"beastlord_fang": "eq_beastlord_fang",
	"apothecary_vial": "eq_apothecary_vial",
	"mendweaver_staff": "eq_wpn_mendweaver_staff",
}


func test_build_legendary_defs_and_passives() -> void:
	for aid: String in BUILD_ARMORS:
		var armor_data: Resource = DataRegistry.get_armor_data(aid)
		assert_not_null(armor_data, aid)
		assert_eq(int(armor_data.rarity), 3, aid)
		assert_eq(str(armor_data.fixed_passive_id), str(PASSIVE_BY_ID[aid]), aid)
		var def: Dictionary = CombatPassives.get_def(str(PASSIVE_BY_ID[aid]))
		assert_false(def.is_empty(), str(PASSIVE_BY_ID[aid]))
		assert_false(str(def.get("description", "")).is_empty(), str(PASSIVE_BY_ID[aid]))
	for cid: String in BUILD_ACCESSORIES:
		var acc_data: Resource = DataRegistry.get_accessory_data(cid)
		assert_not_null(acc_data, cid)
		assert_eq(int(acc_data.rarity), 3, cid)
		assert_eq(str(acc_data.fixed_passive_id), str(PASSIVE_BY_ID[cid]), cid)
		var def2: Dictionary = CombatPassives.get_def(str(PASSIVE_BY_ID[cid]))
		assert_false(def2.is_empty(), str(PASSIVE_BY_ID[cid]))
	for wid: String in BUILD_WEAPONS:
		var wpn_data: Resource = DataRegistry.get_weapon_data(wid)
		assert_not_null(wpn_data, wid)
		assert_eq(int(wpn_data.rarity), 3, wid)
		assert_eq(str(wpn_data.fixed_passive_id), str(PASSIVE_BY_ID[wid]), wid)
		var def3: Dictionary = CombatPassives.get_def(str(PASSIVE_BY_ID[wid]))
		assert_false(def3.is_empty(), str(PASSIVE_BY_ID[wid]))


func test_build_passive_helpers() -> void:
	assert_eq(CombatPassives.pierce_secondary_damage_mult(-1), 1.0)
	assert_eq(CombatPassives.heal_power_mult_for_member(-1), 1.0)
	assert_false(CombatPassives.heal_applies_guard_for_member(-1))
	assert_eq(CombatPassives.hexweave_incoming_mult_for_member(-1, 5), 1.0)
	assert_eq(CombatPassives.cover_ally_incoming_mult_for(0, -1), 1.0)
	assert_eq(CombatPassives.counter_damage_mult_for_member(-1), 1.0)
	var hex_def: Dictionary = CombatPassives.get_def("eq_hexweave_robe")
	assert_eq(float(hex_def.get("incoming_per_enemy_debuff", 0.0)), 0.03)
	var pierce_def: Dictionary = CombatPassives.get_def("eq_pierce_charm")
	assert_eq(float(pierce_def.get("crit_damage_add", 0.0)), 0.15)
	assert_false(pierce_def.has("pierce_secondary_damage_mult"))
	var cover_def: Dictionary = CombatPassives.get_def("eq_cover_aegis")
	assert_eq(float(cover_def.get("counter_damage_mult", 1.0)), 1.25)
	assert_eq(str(cover_def.get("effect", "")), "grant_counter_charges")
	var flurry_def: Dictionary = CombatPassives.get_def("eq_flurry_mail")
	assert_eq(float(flurry_def.get("outgoing_vs_status_mult", 1.0)), 1.20)
	assert_eq(str(flurry_def.get("status_id", "")), "slow")
	var ring_def: Dictionary = CombatPassives.get_def("eq_blade_dance_ring")
	assert_eq(float(ring_def.get("elemental_outgoing_mult", 1.0)), 1.18)
	var pulse_def: Dictionary = CombatPassives.get_def("eq_pulse_amulet")
	assert_eq(float(pulse_def.get("first_attack_mult", 1.0)), 1.40)
	## 装飾の会心ダメ加算が weapon_stat_modifiers 経由で戦闘に届く。
	var adv := Adventurer.new()
	adv.id = "test_pierce_charm_crit"
	adv.job_id = "swordsman"
	adv.level = 10
	var acc := AccessoryInstance.new()
	acc.accessory_id = "pierce_charm"
	adv.equipped_accessory = acc
	var prev_party: Array = GameState.party_members.duplicate()
	GameState.party_members = [adv]
	var mods: Dictionary = CombatPassives.weapon_stat_modifiers_for_member(0)
	assert_eq(float(mods.get("crit_damage_add", 0.0)), 0.15)
	## 初撃アクセは character_stat_modifiers に載る（他パッシブと乗算）。
	var pulse_acc := AccessoryInstance.new()
	pulse_acc.accessory_id = "pulse_amulet"
	adv.equipped_accessory = null
	var base_first: float = float(
		CombatPassives.character_stat_modifiers_for_member(0).get("first_attack_mult", 1.0)
	)
	adv.equipped_accessory = pulse_acc
	var with_pulse: float = float(
		CombatPassives.character_stat_modifiers_for_member(0).get("first_attack_mult", 1.0)
	)
	assert_almost_eq(with_pulse, base_first * 1.40, 0.001)
	GameState.party_members = prev_party


func test_roll_one_returns_unowned() -> void:
	GameState.armor_inventory.clear()
	GameState.accessory_inventory.clear()
	GameState.inventory.clear()
	for m: Resource in GameState.party_members:
		if m == null:
			continue
		m.equipped_armor = null
		m.equipped_accessory = null
		m.equipped_weapon = null
	var rolled: Dictionary = _BuildLegendaryLoot.roll_one()
	assert_false(rolled.is_empty())
	assert_true(str(rolled.get("category", "")) in ["armor", "accessory", "weapon"])
	assert_false(str(rolled.get("id", "")).is_empty())


func test_boss_loot_grants_build_extra() -> void:
	GameState.stage_progress.erase("mourngate_1_5")
	GameState.armor_inventory.clear()
	GameState.accessory_inventory.clear()
	GameState.inventory.clear()
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NORMAL
	var dc: Node = _DungeonController.new()
	add_child_autofree(dc)
	dc.start_stage("mourngate_1_5")
	var bonus: Dictionary = dc.apply_boss_legendary_loot(dc.current_stage_data, "serdion")
	assert_eq(str(bonus["armor_id"]), "serdion_ward_plate")
	assert_eq(str(bonus["accessory_id"]), "mourngate_royal_seal")
	assert_false(str(bonus.get("build_id", "")).is_empty(), "ビルドLが追加付与される")
	assert_true(str(bonus.get("build_category", "")) in ["armor", "accessory", "weapon"])
	var total: int = (
		GameState.armor_inventory.size()
		+ GameState.accessory_inventory.size()
		+ GameState.inventory.size()
	)
	assert_eq(total, 3, "Biome固定2＋ビルド1")


func test_build_legendaries_excluded_from_normal_legendary_pool() -> void:
	var dc: Node = _DungeonController.new()
	add_child_autofree(dc)
	for aid: String in BUILD_ARMORS:
		assert_false(aid in dc._all_legendary_ids("armor"), aid)
	for cid: String in BUILD_ACCESSORIES:
		assert_false(cid in dc._all_legendary_ids("accessory"), cid)
	for wid: String in BUILD_WEAPONS:
		assert_false(wid in dc._all_legendary_ids("weapon"), wid)


func test_detail_text_for_build_armor() -> void:
	var armor_inst: Resource = load("res://scripts/domain/ArmorInstance.gd").new()
	armor_inst.armor_id = "cover_aegis_cloak"
	var text: String = EquipmentItemDetailHelper.equipment_legendary_effect_text(armor_inst, "armor")
	assert_false(text.is_empty())
	assert_true(text.contains("反撃") or text.contains("応撃"))
