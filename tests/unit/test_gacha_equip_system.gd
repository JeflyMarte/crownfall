extends GutTest
## P3-GACHA-EQ-SEAL-UI-001 — 封蔵の匣（灰冠装備ガチャ）。

const _GachaEquipSystem := preload("res://scripts/gacha/GachaEquipSystem.gd")


var _saved_token: int = 0
var _saved_inv: Array = []
var _saved_armor: Array = []
var _saved_acc: Array = []


func before_each() -> void:
	_saved_token = GameState.gacha_token
	_saved_inv = GameState.inventory.duplicate()
	_saved_armor = GameState.armor_inventory.duplicate()
	_saved_acc = GameState.accessory_inventory.duplicate()
	GameState.inventory.clear()
	GameState.armor_inventory.clear()
	GameState.accessory_inventory.clear()
	GameState.gacha_token = 0
	_GachaEquipSystem.reset_pools_for_tests()


func after_each() -> void:
	GameState.gacha_token = _saved_token
	GameState.inventory = _saved_inv
	GameState.armor_inventory = _saved_armor
	GameState.accessory_inventory = _saved_acc


func test_pool_has_27_kaiwan_entries() -> void:
	assert_eq(_GachaEquipSystem.POOL.size(), 27)
	var weapons: int = 0
	var armors: int = 0
	var accessories: int = 0
	for e: Dictionary in _GachaEquipSystem.POOL:
		match str(e.get("kind", "")):
			"weapon":
				weapons += 1
			"armor":
				armors += 1
			"accessory":
				accessories += 1
	assert_eq(weapons, 9)
	assert_eq(armors, 9)
	assert_eq(accessories, 9)


func test_pull_cost_is_300() -> void:
	assert_eq(_GachaEquipSystem.PULL_COST, 300)
	assert_eq(_GachaEquipSystem.pull_cost(), 300)


func test_rate_table_case_a() -> void:
	assert_almost_eq(_GachaEquipSystem.RATE_EPIC, 0.55, 0.001)
	assert_almost_eq(_GachaEquipSystem.RATE_LEGENDARY, 0.45, 0.001)
	assert_almost_eq(_GachaEquipSystem.RATE_L_KAIWAN, 0.60, 0.001)
	assert_almost_eq(_GachaEquipSystem.RATE_L_OTHER, 0.40, 0.001)
	assert_almost_eq(
		_GachaEquipSystem.RATE_EPIC + _GachaEquipSystem.RATE_LEGENDARY, 1.0, 0.001
	)


func test_can_pull_requires_token() -> void:
	GameState.gacha_token = 299
	assert_false(_GachaEquipSystem.can_pull())
	GameState.gacha_token = 300
	assert_true(_GachaEquipSystem.can_pull())


func test_pull_fails_without_token() -> void:
	GameState.gacha_token = 0
	var result: Dictionary = _GachaEquipSystem.pull()
	assert_false(bool(result.get("ok", true)))
	assert_eq(str(result.get("reason", "")), "no_token")


func test_pull_grants_equipment_and_spends_token() -> void:
	GameState.gacha_token = 600
	var before_w: int = GameState.inventory.size()
	var before_a: int = GameState.armor_inventory.size()
	var before_c: int = GameState.accessory_inventory.size()
	var result: Dictionary = _GachaEquipSystem.pull()
	assert_true(bool(result.get("ok", false)), str(result))
	assert_eq(GameState.gacha_token, 300)
	var rarity: int = int(result.get("rarity", -1))
	assert_true(
		rarity == Enums.Rarity.EPIC or rarity == Enums.Rarity.LEGENDARY,
		"rarity=%d" % rarity
	)
	var pool_tag: String = str(result.get("pool", ""))
	assert_true(pool_tag in ["epic", "kaiwan", "other_l"], pool_tag)
	var kind: String = str(result.get("kind", ""))
	assert_true(kind in ["weapon", "armor", "accessory"])
	assert_false(str(result.get("item_id", "")).is_empty())
	assert_false(str(result.get("display_name", "")).is_empty())
	assert_not_null(result.get("instance", null))
	var gained: int = (
		(GameState.inventory.size() - before_w)
		+ (GameState.armor_inventory.size() - before_a)
		+ (GameState.accessory_inventory.size() - before_c)
	)
	assert_eq(gained, 1)


func test_standard_pools_exclude_kaiwan_abyss_mythic() -> void:
	_GachaEquipSystem.ensure_pools()
	assert_gt(_GachaEquipSystem.epic_pool_count(), 0)
	assert_gt(_GachaEquipSystem.other_l_pool_count(), 0)
	for e: Dictionary in _GachaEquipSystem.entries_for_pool("epic"):
		var id_e: String = str(e.get("id", ""))
		assert_false(id_e.begins_with("kaiwan_"), id_e)
		assert_false(id_e.begins_with("abyss_"), id_e)
	for e2: Dictionary in _GachaEquipSystem.entries_for_pool("other_l"):
		var id_l: String = str(e2.get("id", ""))
		assert_false(id_l.begins_with("kaiwan_"), id_l)
		assert_false(id_l.begins_with("abyss_"), id_l)
		assert_ne(id_l, "burial_crown_greatsword")


func test_pool_resources_resolve() -> void:
	for e: Dictionary in _GachaEquipSystem.POOL:
		var kind: String = str(e.get("kind", ""))
		var item_id: String = str(e.get("id", ""))
		match kind:
			"weapon":
				assert_not_null(DataRegistry.get_weapon_data(item_id), item_id)
			"armor":
				assert_not_null(DataRegistry.get_armor_data(item_id), item_id)
			"accessory":
				assert_not_null(DataRegistry.get_accessory_data(item_id), item_id)
		var name_str: String = _GachaEquipSystem.display_name_for(kind, item_id)
		assert_ne(name_str, item_id)
		assert_false(name_str.is_empty())


func test_pull_with_seal_ticket() -> void:
	GameState.gacha_token = 0
	TicketInventory.add(TicketIds.SEAL_FREE, 1)
	assert_true(_GachaEquipSystem.can_pull_with_ticket())
	var result: Dictionary = _GachaEquipSystem.pull(true)
	assert_true(bool(result.get("ok", false)), str(result))
	assert_true(bool(result.get("paid_with_ticket", false)))
	assert_eq(TicketInventory.get_qty(TicketIds.SEAL_FREE), 0)
	assert_eq(GameState.gacha_token, 0)


func test_pull_ticket_fails_without_seal_ticket() -> void:
	GameState.gacha_token = 999
	var result: Dictionary = _GachaEquipSystem.pull(true)
	assert_false(bool(result.get("ok", true)))
	assert_eq(str(result.get("reason", "")), "no_ticket")
	assert_eq(GameState.gacha_token, 999)


func test_featured_entries_are_weapons() -> void:
	var featured: Array = _GachaEquipSystem.featured_entries()
	assert_eq(featured.size(), 9)
	for e: Dictionary in featured:
		assert_eq(str(e.get("kind", "")), "weapon")
