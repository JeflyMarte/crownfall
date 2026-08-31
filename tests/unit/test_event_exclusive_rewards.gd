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
	assert_not_null(DataRegistry.get_weapon_data("albark_namerefuse_sword"))
	assert_not_null(DataRegistry.get_weapon_data("albark_namerefuse_hammer"))
	assert_not_null(DataRegistry.get_armor_data("albark_namerefuse_armor"))
	assert_not_null(DataRegistry.get_accessory_data("albark_namerefuse_circlet"))
	assert_eq(int(DataRegistry.get_weapon_data("chronos_toki_sword").rarity), Enums.Rarity.SET)
	assert_eq(int(DataRegistry.get_armor_data("valgard_antique_armor").rarity), Enums.Rarity.SET)
	assert_eq(int(DataRegistry.get_weapon_data("albark_namerefuse_hammer").rarity), Enums.Rarity.SET)
	assert_not_null(DataRegistry.get_weapon_data("forge_slag_sword"))
	assert_not_null(DataRegistry.get_weapon_data("forge_slag_hammer"))
	assert_not_null(DataRegistry.get_armor_data("forge_slag_armor"))
	assert_not_null(DataRegistry.get_accessory_data("forge_slag_seal"))
	assert_eq(int(DataRegistry.get_weapon_data("forge_slag_hammer").rarity), Enums.Rarity.SET)
	assert_eq(CodexContentHelper.rarity_label(Enums.Rarity.SET), "エンシェントレア")


func test_old_exclusives_removed() -> void:
	assert_false(ResourceLoader.exists("res://resources/weapons/chronos_ringblade.tres"))
	assert_false(ResourceLoader.exists("res://resources/weapons/valgard_rampart_maul.tres"))
	assert_false(ResourceLoader.exists("res://resources/accessories/chronos_gear_brooch.tres"))
	assert_false(ResourceLoader.exists("res://resources/accessories/valgard_ward_seal.tres"))
	assert_false(CombatPassives.is_relic_passive("relic_chronos_fragment"))
	assert_false(CombatPassives.is_relic_passive("relic_valgard_gear"))


func test_boss_loot_grants_exactly_one_piece() -> void:
	var granted: Dictionary = _Evt.apply_boss_loot("chronos_mausoleum", _DungeonTierConfig.TIER_NORMAL)
	var pieces: int = 0
	if not str(granted.get("weapon_id", "")).is_empty():
		pieces += 1
		assert_eq(_Sets.set_id_of_weapon(str(granted.get("weapon_id", ""))), _Sets.SET_CHRONOS_TOKI)
	if not str(granted.get("armor_id", "")).is_empty():
		pieces += 1
		assert_eq(str(granted.get("armor_id", "")), "chronos_toki_armor")
	if not str(granted.get("accessory_id", "")).is_empty():
		pieces += 1
		assert_eq(str(granted.get("accessory_id", "")), "chronos_toki_orb")
	assert_eq(pieces, 1)
	assert_true(str(granted.get("relic_id", "")).is_empty())

	var granted_v: Dictionary = _Evt.apply_boss_loot("valgard_boundary", _DungeonTierConfig.TIER_NORMAL)
	var pieces_v: int = 0
	if not str(granted_v.get("weapon_id", "")).is_empty():
		pieces_v += 1
	if not str(granted_v.get("armor_id", "")).is_empty():
		pieces_v += 1
	if not str(granted_v.get("accessory_id", "")).is_empty():
		pieces_v += 1
	assert_eq(pieces_v, 1)


func test_reclear_grants_at_most_one_piece() -> void:
	GameState.mark_dungeon_tier_cleared("chronos_mausoleum", _DungeonTierConfig.TIER_NORMAL)
	var saw_drop := false
	var saw_miss := false
	for _i: int in 40:
		var granted: Dictionary = _Evt.apply_boss_loot("chronos_mausoleum", _DungeonTierConfig.TIER_NORMAL)
		var pieces: int = 0
		if not str(granted.get("weapon_id", "")).is_empty():
			pieces += 1
		if not str(granted.get("armor_id", "")).is_empty():
			pieces += 1
		if not str(granted.get("accessory_id", "")).is_empty():
			pieces += 1
		assert_lte(pieces, 1)
		if pieces == 1:
			saw_drop = true
		else:
			saw_miss = true
	assert_true(saw_drop, "reclear should sometimes drop one")
	assert_true(saw_miss, "reclear should sometimes drop none")


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


func test_namerefuse_set_activation_and_bonus() -> void:
	assert_eq(_Sets.set_id_for_dungeon("north_reach"), _Sets.SET_ALBARK_NAMEREFUSE)
	assert_eq(_Evt.source_label("north_reach"), "天望の塔")
	assert_eq(_Sets.all_piece_ids(_Sets.SET_ALBARK_NAMEREFUSE).size(), 7)
	assert_gt(GameState.party_members.size(), 0)
	var member: Resource = GameState.party_members[0]
	assert_true(_Evt._grant_weapon("albark_namerefuse_sword"))
	member.equipped_weapon = GameState.inventory[GameState.inventory.size() - 1]
	assert_true(_Evt._grant_armor("albark_namerefuse_armor"))
	member.equipped_armor = GameState.armor_inventory[GameState.armor_inventory.size() - 1]
	assert_true(_Evt._grant_accessory("albark_namerefuse_circlet"))
	member.equipped_accessory = GameState.accessory_inventory[GameState.accessory_inventory.size() - 1]
	assert_eq(_Sets.active_set_id_for_member(member), _Sets.SET_ALBARK_NAMEREFUSE)
	assert_eq(_Sets.status_chance_mult(0), 1.25)
	assert_eq(_Sets.enemy_buff_duration_mult(0), 0.75)
	assert_eq(_Sets.party_enemy_buff_duration_mult(), 0.75)
	## 3部位加護×1.25 × 単品武器×1.10 × 単品装飾×1.06（P3-EQ-ANCIENT-POWER-D-001）。
	assert_almost_eq(
		EvolutionTraits.effective_status_chance(0, 0.40),
		0.40 * 1.25 * 1.10 * 1.06,
		0.001
	)

	var ui_def: Dictionary = _Sets.passive_ui_def_for_member(member)
	assert_eq(str(ui_def.get("display_name", "")), "名拒みの加護")
	var granted: Dictionary = _Evt.apply_boss_loot("north_reach", _DungeonTierConfig.TIER_NORMAL)
	var pieces: int = 0
	if not str(granted.get("weapon_id", "")).is_empty():
		pieces += 1
		assert_eq(_Sets.set_id_of_weapon(str(granted.get("weapon_id", ""))), _Sets.SET_ALBARK_NAMEREFUSE)
	if not str(granted.get("armor_id", "")).is_empty():
		pieces += 1
	if not str(granted.get("accessory_id", "")).is_empty():
		pieces += 1
	assert_eq(pieces, 1)


func test_forge_slag_set_activation_and_bonus() -> void:
	assert_eq(_Sets.set_id_for_dungeon("red_forge_depths"), _Sets.SET_FORGE_SLAG)
	assert_eq(_Evt.source_label("red_forge_depths"), "星炉火口")
	assert_eq(_Sets.all_piece_ids(_Sets.SET_FORGE_SLAG).size(), 7)
	assert_gt(GameState.party_members.size(), 0)
	var member: Resource = GameState.party_members[0]
	assert_true(_Evt._grant_weapon("forge_slag_sword"))
	member.equipped_weapon = GameState.inventory[GameState.inventory.size() - 1]
	assert_true(_Evt._grant_armor("forge_slag_armor"))
	member.equipped_armor = GameState.armor_inventory[GameState.armor_inventory.size() - 1]
	assert_true(_Evt._grant_accessory("forge_slag_seal"))
	member.equipped_accessory = GameState.accessory_inventory[GameState.accessory_inventory.size() - 1]
	assert_eq(_Sets.active_set_id_for_member(member), _Sets.SET_FORGE_SLAG)
	assert_almost_eq(_Sets.ignite_duration_mult(0), 1.30, 0.001)
	assert_almost_eq(_Sets.party_ignite_duration_mult(), 1.30, 0.001)
	assert_almost_eq(_Sets.outgoing_vs_ignite_mult(0), 1.12, 0.001)
	var ui_def: Dictionary = _Sets.passive_ui_def_for_member(member)
	assert_eq(str(ui_def.get("display_name", "")), "星炉の加護")
	var granted: Dictionary = _Evt.apply_boss_loot("red_forge_depths", _DungeonTierConfig.TIER_NORMAL)
	var pieces: int = 0
	if not str(granted.get("weapon_id", "")).is_empty():
		pieces += 1
		assert_eq(_Sets.set_id_of_weapon(str(granted.get("weapon_id", ""))), _Sets.SET_FORGE_SLAG)
	if not str(granted.get("armor_id", "")).is_empty():
		pieces += 1
	if not str(granted.get("accessory_id", "")).is_empty():
		pieces += 1
	assert_eq(pieces, 1)


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
	assert_false(str(IconPaths.ICON_MAP.get("weapon:albark_namerefuse_hammer", "")).is_empty())
	assert_false(str(IconPaths.ICON_MAP.get("armor:albark_namerefuse_armor", "")).is_empty())
	assert_false(str(IconPaths.ICON_MAP.get("accessory:albark_namerefuse_circlet", "")).is_empty())
	assert_true(_Evt.is_event_exclusive_weapon("albark_namerefuse_hammer"))
	assert_true(_Evt.is_event_dungeon("north_reach"))
	assert_true(_Evt.is_event_dungeon("red_forge_depths"))
	assert_true(_Evt.is_event_exclusive_weapon("forge_slag_hammer"))
	## 専用ICO（流用禁止・バイト衝突防止）
	var namerefuse_icon_ids: Array[String] = [
		"weapon:albark_namerefuse_sword",
		"weapon:albark_namerefuse_dual",
		"weapon:albark_namerefuse_staff",
		"weapon:albark_namerefuse_bow",
		"weapon:albark_namerefuse_hammer",
		"armor:albark_namerefuse_armor",
		"accessory:albark_namerefuse_circlet",
	]
	var paths: Array[String] = []
	for key: String in namerefuse_icon_ids:
		var path: String = str(IconPaths.ICON_MAP.get(key, ""))
		assert_true(path.contains("AlbarkNamerefuse"), "dedicated path for %s" % key)
		assert_true(FileAccess.file_exists(path), path)
		assert_false(path in paths, "unique path %s" % path)
		paths.append(path)
		assert_gt(FileAccess.get_file_as_bytes(path).size(), 100)
	for i: int in range(paths.size()):
		var ba: PackedByteArray = FileAccess.get_file_as_bytes(paths[i])
		for j: int in range(i + 1, paths.size()):
			var bb: PackedByteArray = FileAccess.get_file_as_bytes(paths[j])
			assert_false(ba == bb, "unique bytes %s vs %s" % [paths[i], paths[j]])
	var forge_icon_ids: Array[String] = [
		"weapon:forge_slag_sword",
		"weapon:forge_slag_dual",
		"weapon:forge_slag_staff",
		"weapon:forge_slag_bow",
		"weapon:forge_slag_hammer",
		"armor:forge_slag_armor",
		"accessory:forge_slag_seal",
	]
	var forge_paths: Array[String] = []
	for key: String in forge_icon_ids:
		var path: String = str(IconPaths.ICON_MAP.get(key, ""))
		assert_true(path.contains("ForgeSlag"), "dedicated path for %s" % key)
		assert_true(FileAccess.file_exists(path), path)
		assert_false(path in forge_paths, "unique path %s" % path)
		forge_paths.append(path)
		assert_gt(FileAccess.get_file_as_bytes(path).size(), 100)
	for i: int in range(forge_paths.size()):
		var ba: PackedByteArray = FileAccess.get_file_as_bytes(forge_paths[i])
		for j: int in range(i + 1, forge_paths.size()):
			var bb: PackedByteArray = FileAccess.get_file_as_bytes(forge_paths[j])
			assert_false(ba == bb, "unique bytes %s vs %s" % [forge_paths[i], forge_paths[j]])
