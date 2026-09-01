extends GutTest
## P3-EQ-INV-CAP-001 / 002 — 装備袋 武+防+飾 合計上限と装備者キャッシュ。


func before_each() -> void:
	GameState.inventory.clear()
	GameState.armor_inventory.clear()
	GameState.accessory_inventory.clear()
	GameState.mark_equipped_item_owner_cache_dirty()


func test_cap_constant_is_1000() -> void:
	assert_eq(Constants.MAX_EQUIPMENT_INVENTORY, 1000)


func test_count_label_format() -> void:
	assert_eq(GameState.equipment_inventory_count_label(), "0/1000件")
	var w: Resource = WeaponInstance.new()
	w.instance_id = "cap_w_1"
	w.weapon_id = "iron_sword"
	w.is_appraised = true
	assert_true(GameState.try_add_weapon_instance(w))
	assert_eq(GameState.equipment_inventory_count(), 1)
	assert_eq(GameState.equipment_inventory_count_label(), "1/1000件")


func test_blocks_at_cap() -> void:
	for i in Constants.MAX_EQUIPMENT_INVENTORY:
		var w: Resource = WeaponInstance.new()
		w.instance_id = "cap_fill_%d" % i
		w.weapon_id = "iron_sword"
		w.is_appraised = true
		assert_true(GameState.try_add_weapon_instance(w), "fill %d" % i)
	assert_eq(GameState.equipment_inventory_count(), Constants.MAX_EQUIPMENT_INVENTORY)
	assert_false(GameState.can_add_equipment())
	var extra: Resource = WeaponInstance.new()
	extra.instance_id = "cap_extra"
	extra.weapon_id = "iron_sword"
	extra.is_appraised = true
	assert_false(GameState.try_add_weapon_instance(extra))
	assert_eq(GameState.inventory.size(), Constants.MAX_EQUIPMENT_INVENTORY)


func test_ignore_cap_for_debug_path() -> void:
	for i in Constants.MAX_EQUIPMENT_INVENTORY:
		var w: Resource = WeaponInstance.new()
		w.instance_id = "cap_dbg_%d" % i
		w.weapon_id = "iron_sword"
		assert_true(GameState.try_add_weapon_instance(w))
	var over: Resource = WeaponInstance.new()
	over.instance_id = "cap_over"
	over.weapon_id = "iron_sword"
	assert_true(GameState.try_add_weapon_instance(over, true))
	assert_eq(GameState.equipment_inventory_count(), Constants.MAX_EQUIPMENT_INVENTORY + 1)


func test_equipped_owner_cache_after_controller_equip() -> void:
	if GameState.party_members.is_empty():
		GameState.seed_all_starters_unlocked()
	var member: Resource = GameState.party_members[0]
	var w: Resource = WeaponInstance.new()
	w.instance_id = "cache_w_1"
	w.weapon_id = "iron_sword"
	w.is_appraised = true
	GameState.try_add_weapon_instance(w)
	var ctrl: Node = load("res://scripts/equipment/EquipmentController.gd").new()
	add_child_autofree(ctrl)
	ctrl.equip_weapon_for_member(w, member)
	assert_eq(member.equipped_weapon, w)
	assert_eq(GameState.find_item_equipped_owner(w), member)


func test_gacha_pull_blocked_when_full() -> void:
	var GachaEquipSystem = load("res://scripts/gacha/GachaEquipSystem.gd")
	for i in Constants.MAX_EQUIPMENT_INVENTORY:
		var w: Resource = WeaponInstance.new()
		w.instance_id = "cap_gacha_%d" % i
		w.weapon_id = "iron_sword"
		GameState.try_add_weapon_instance(w)
	GameState.gacha_token = 9999
	var before_token: int = GameState.gacha_token
	var result: Dictionary = GachaEquipSystem.pull(false)
	assert_false(bool(result.get("ok", true)))
	assert_eq(str(result.get("reason", "")), "inventory_full")


func test_spawn_weapon_fails_when_inventory_full() -> void:
	var _DungeonController := load("res://scripts/dungeon/DungeonController.gd")
	for i in Constants.MAX_EQUIPMENT_INVENTORY:
		var w: Resource = WeaponInstance.new()
		w.instance_id = "cap_spawn_%d" % i
		w.weapon_id = "iron_sword"
		w.is_appraised = true
		assert_true(GameState.try_add_weapon_instance(w))
	var dc: Node = _DungeonController.new()
	add_child_autofree(dc)
	dc.start_dungeon("mourngate")
	assert_false(dc._spawn_weapon("iron_sword"))
	assert_eq(dc.last_weapon_dropped, "")
