extends GutTest
## P3-EQ-INV-CAP-001 — 装備袋 武+防+飾 合計上限。


func before_each() -> void:
	GameState.inventory.clear()
	GameState.armor_inventory.clear()
	GameState.accessory_inventory.clear()


func test_cap_constant_is_200() -> void:
	assert_eq(Constants.MAX_EQUIPMENT_INVENTORY, 200)


func test_count_label_format() -> void:
	assert_eq(GameState.equipment_inventory_count_label(), "0/200件")
	var w: Resource = WeaponInstance.new()
	w.instance_id = "cap_w_1"
	w.weapon_id = "iron_sword"
	w.is_appraised = true
	assert_true(GameState.try_add_weapon_instance(w))
	assert_eq(GameState.equipment_inventory_count(), 1)
	assert_eq(GameState.equipment_inventory_count_label(), "1/200件")


func test_blocks_at_cap() -> void:
	for i in Constants.MAX_EQUIPMENT_INVENTORY:
		var w: Resource = WeaponInstance.new()
		w.instance_id = "cap_fill_%d" % i
		w.weapon_id = "iron_sword"
		w.is_appraised = true
		assert_true(GameState.try_add_weapon_instance(w), "fill %d" % i)
	assert_eq(GameState.equipment_inventory_count(), 200)
	assert_false(GameState.can_add_equipment())
	var extra: Resource = WeaponInstance.new()
	extra.instance_id = "cap_extra"
	extra.weapon_id = "iron_sword"
	extra.is_appraised = true
	assert_false(GameState.try_add_weapon_instance(extra))
	assert_eq(GameState.inventory.size(), 200)


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
	assert_eq(GameState.equipment_inventory_count(), 201)


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
	assert_eq(GameState.gacha_token, before_token, "満杯時は魔晶石を消費しない")
