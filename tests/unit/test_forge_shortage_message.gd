extends GutTest

## P3-UX-FORGE-SHORTAGE-TELOP-001 — 鍛冶不足文言。


func before_each() -> void:
	GameState.reset_for_new_game()


func test_material_shortage_names_first_missing() -> void:
	GameState.material_inventory.clear()
	var msg: String = CraftHelper.material_shortage_message({"base_ore": 3, "relic_shard": 1})
	assert_true(msg.ends_with("が足りません"), msg)
	var ore_name: String = DataRegistry.get_material_name("base_ore")
	assert_true(msg.begins_with(ore_name), msg)


func test_craft_shortage_prefers_gold_and_attemptable() -> void:
	assert_true(CraftHelper.try_unlock("weapon", "iron_sword") or CraftHelper.is_unlocked("weapon", "iron_sword"))
	var craft: Resource = CraftHelper.build_craft_data("weapon", "iron_sword")
	assert_not_null(craft)
	GameState.gold = 0
	GameState.material_inventory.clear()
	assert_eq(CraftHelper.craft_shortage_message(craft), "ゴールドが足りません")
	assert_true(CraftHelper.can_attempt_craft(craft))
	GameState.gold = 99999
	var mat_msg: String = CraftHelper.craft_shortage_message(craft)
	assert_true(mat_msg.ends_with("が足りません"), mat_msg)
	assert_ne(mat_msg, "ゴールドが足りません")


func test_enhance_attempt_allows_shortage() -> void:
	var w: Resource = WeaponInstance.new()
	w.instance_id = "t_shortage_w"
	w.weapon_id = "iron_sword"
	w.is_appraised = true
	w.enhance_level = 0
	w.equip_level = 1
	GameState.inventory.append(w)
	GameState.gold = 0
	assert_true(EquipmentEnhancer.can_attempt_enhance_item(w))
	var check: Dictionary = EquipmentEnhancer.can_enhance_item(w)
	assert_false(bool(check.get("ok", false)))
	assert_eq(str(check.get("reason", "")), "ゴールドが足りません")
