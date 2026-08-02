extends GutTest

## 降臨セット装備（P3-DG-EVENT-SET-001）

const _Evt = preload("res://scripts/dungeon/EventExclusiveRewards.gd")
const _Sets = preload("res://scripts/equipment/EquipmentSetBonuses.gd")
const _Abyss = preload("res://scripts/dungeon/AbyssLegendaryWeapons.gd")
const _DungeonTierConfig = preload("res://scripts/dungeon/DungeonTierConfig.gd")


func before_each() -> void:
	GameState.reset_for_new_game()
	GameState.seed_all_starters_unlocked()


func test_set_resources_and_rarity() -> void:
	assert_not_null(DataRegistry.get_weapon_data("chronos_toki_sword"))
	assert_not_null(DataRegistry.get_armor_data("chronos_toki_armor"))
	assert_not_null(DataRegistry.get_accessory_data("chronos_toki_orb"))
	assert_not_null(DataRegistry.get_weapon_data("valgard_antique_blade"))
	assert_not_null(DataRegistry.get_armor_data("valgard_antique_armor"))
	assert_not_null(DataRegistry.get_accessory_data("valgard_antique_amulet"))
	assert_eq(int(DataRegistry.get_weapon_data("chronos_toki_sword").rarity), Enums.Rarity.SET)
	assert_eq(int(DataRegistry.get_armor_data("valgard_antique_armor").rarity), Enums.Rarity.SET)
	assert_eq(CodexContentHelper.rarity_label(Enums.Rarity.SET), "エンシェントレア")


func test_old_exclusives_removed() -> void:
	assert_false(ResourceLoader.exists("res://resources/weapons/chronos_ringblade.tres"))
	assert_false(ResourceLoader.exists("res://resources/weapons/valgard_rampart_maul.tres"))
	assert_false(ResourceLoader.exists("res://resources/accessories/chronos_gear_brooch.tres"))
	assert_false(ResourceLoader.exists("res://resources/accessories/valgard_ward_seal.tres"))
	assert_false(CombatPassives.is_relic_passive("relic_chronos_fragment"))
	assert_false(CombatPassives.is_relic_passive("relic_valgard_gear"))


func test_first_clear_grants_three_pieces() -> void:
	var granted: Dictionary = _Evt.apply_boss_loot("chronos_mausoleum", _DungeonTierConfig.TIER_NORMAL)
	assert_false(str(granted.get("weapon_id", "")).is_empty())
	assert_eq(str(granted.get("armor_id", "")), "chronos_toki_armor")
	assert_eq(str(granted.get("accessory_id", "")), "chronos_toki_orb")
	assert_true(str(granted.get("relic_id", "")).is_empty())
	assert_eq(_Sets.set_id_of_weapon(str(granted.get("weapon_id", ""))), _Sets.SET_CHRONOS_TOKI)

	var granted_v: Dictionary = _Evt.apply_boss_loot("valgard_boundary", _DungeonTierConfig.TIER_NORMAL)
	assert_false(str(granted_v.get("weapon_id", "")).is_empty())
	assert_eq(str(granted_v.get("armor_id", "")), "valgard_antique_armor")
	assert_eq(str(granted_v.get("accessory_id", "")), "valgard_antique_amulet")


func test_set_activation_requires_three_pieces() -> void:
	assert_gt(GameState.party_members.size(), 0)
	var member: Resource = GameState.party_members[0]
	assert_true(_Evt._grant_weapon("chronos_toki_sword"))
	member.equipped_weapon = GameState.inventory[GameState.inventory.size() - 1]
	assert_eq(_Sets.active_set_id_for_member(member), "")
	assert_true(_Sets.passive_ui_def_for_member(member).is_empty())
	assert_true(_Evt._grant_armor("chronos_toki_armor"))
	member.equipped_armor = GameState.armor_inventory[GameState.armor_inventory.size() - 1]
	assert_eq(_Sets.active_set_id_for_member(member), "")
	assert_true(_Sets.passive_ui_def_for_member(member).is_empty())
	assert_true(_Evt._grant_accessory("chronos_toki_orb"))
	member.equipped_accessory = GameState.accessory_inventory[GameState.accessory_inventory.size() - 1]
	assert_eq(_Sets.active_set_id_for_member(member), _Sets.SET_CHRONOS_TOKI)
	assert_eq(_Sets.speed_mult(0), 1.15)
	assert_eq(_Sets.skill_cd_mult(0), 0.85)
	assert_eq(_Sets.outgoing_mult(0), 1.0)
	var ui_def: Dictionary = _Sets.passive_ui_def_for_member(member)
	assert_false(ui_def.is_empty())
	assert_eq(str(ui_def.get("display_name", "")), "クロノスの加護")
	assert_eq(str(ui_def.get("source_name", "")), "エンシェントセット")


func test_valgard_set_bonus_values() -> void:
	assert_eq(float(_Sets.BONUS[_Sets.SET_VALGARD_ANTIQUE].get("hp_mult", 0.0)), 1.12)
	assert_eq(float(_Sets.BONUS[_Sets.SET_VALGARD_ANTIQUE].get("outgoing_mult", 0.0)), 1.12)
	assert_eq(float(_Sets.BONUS[_Sets.SET_VALGARD_ANTIQUE].get("incoming_mult", 0.0)), 0.89)


func test_pool_exclusion_and_icons() -> void:
	assert_true(_Evt.is_event_exclusive_weapon("chronos_toki_sword"))
	assert_true(_Evt.is_event_exclusive_armor("chronos_toki_armor"))
	assert_true(_Evt.is_event_exclusive_accessory("valgard_antique_amulet"))
	assert_false(_Abyss.is_abyss_legendary_id("chronos_toki_sword"))
	var chronos: Resource = DataRegistry.get_dungeon_data("chronos_mausoleum")
	var valgard: Resource = DataRegistry.get_dungeon_data("valgard_boundary")
	assert_false("chronos_toki_sword" in chronos.weapon_pool)
	assert_false("chronos_toki_orb" in chronos.accessory_pool)
	assert_false("valgard_antique_blade" in valgard.weapon_pool)
	assert_false(str(IconPaths.ICON_MAP.get("weapon:chronos_toki_sword", "")).is_empty())
	assert_false(str(IconPaths.ICON_MAP.get("armor:valgard_antique_armor", "")).is_empty())
	assert_false(str(IconPaths.ICON_MAP.get("accessory:chronos_toki_orb", "")).is_empty())
