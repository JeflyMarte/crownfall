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
]

const BUILD_ACCESSORIES: Array[String] = [
	"blade_dance_ring",
	"pierce_charm",
	"pulse_amulet",
	"beastlord_fang",
	"apothecary_vial",
]

const PASSIVE_BY_ID: Dictionary = {
	"bloodpact_plate": "eq_bloodpact_plate",
	"flurry_light_mail": "eq_flurry_mail",
	"bulwark_role_plate": "eq_bulwark_role",
	"cover_aegis_cloak": "eq_cover_aegis",
	"hexweave_robe": "eq_hexweave_robe",
	"blade_dance_ring": "eq_blade_dance_ring",
	"pierce_charm": "eq_pierce_charm",
	"pulse_amulet": "eq_pulse_amulet",
	"beastlord_fang": "eq_beastlord_fang",
	"apothecary_vial": "eq_apothecary_vial",
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


func test_build_passive_helpers() -> void:
	assert_eq(CombatPassives.pierce_secondary_damage_mult(-1), 1.0)
	assert_eq(CombatPassives.heal_power_mult_for_member(-1), 1.0)
	assert_false(CombatPassives.heal_applies_guard_for_member(-1))
	assert_eq(CombatPassives.hexweave_incoming_mult_for_member(-1, 5), 1.0)
	assert_eq(CombatPassives.cover_ally_incoming_mult_for(0, -1), 1.0)
	var hex_def: Dictionary = CombatPassives.get_def("eq_hexweave_robe")
	assert_eq(float(hex_def.get("incoming_per_enemy_debuff", 0.0)), 0.03)
	var pierce_def: Dictionary = CombatPassives.get_def("eq_pierce_charm")
	assert_eq(float(pierce_def.get("pierce_secondary_damage_mult", 1.0)), 1.35)


func test_roll_one_returns_unowned() -> void:
	GameState.armor_inventory.clear()
	GameState.accessory_inventory.clear()
	for m: Resource in GameState.party_members:
		if m == null:
			continue
		m.equipped_armor = null
		m.equipped_accessory = null
	var rolled: Dictionary = _BuildLegendaryLoot.roll_one()
	assert_false(rolled.is_empty())
	assert_true(str(rolled.get("category", "")) in ["armor", "accessory"])
	assert_false(str(rolled.get("id", "")).is_empty())


func test_boss_loot_grants_build_extra() -> void:
	GameState.stage_progress.erase("mourngate_1_5")
	GameState.armor_inventory.clear()
	GameState.accessory_inventory.clear()
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NORMAL
	var dc: Node = _DungeonController.new()
	add_child_autofree(dc)
	dc.start_stage("mourngate_1_5")
	var bonus: Dictionary = dc.apply_boss_legendary_loot(dc.current_stage_data)
	assert_eq(str(bonus["armor_id"]), "serdion_ward_plate")
	assert_eq(str(bonus["accessory_id"]), "mourngate_royal_seal")
	assert_false(str(bonus.get("build_id", "")).is_empty(), "ビルドLが追加付与される")
	assert_true(str(bonus.get("build_category", "")) in ["armor", "accessory"])
	var total: int = GameState.armor_inventory.size() + GameState.accessory_inventory.size()
	assert_eq(total, 3, "Biome固定2＋ビルド1")


func test_detail_text_for_build_armor() -> void:
	var armor_inst: Resource = load("res://scripts/domain/ArmorInstance.gd").new()
	armor_inst.armor_id = "cover_aegis_cloak"
	var text: String = EquipmentItemDetailHelper.equipment_legendary_effect_text(armor_inst, "armor")
	assert_false(text.is_empty())
	assert_true(text.contains("傷つ") or text.contains("被ダメ"))
