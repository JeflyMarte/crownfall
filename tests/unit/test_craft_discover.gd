extends GutTest
## P3-CRAFT-DISCOVER-001 — 入手解放・レア別コスト・除外。


func test_unlock_on_obtain_enables_craft() -> void:
	GameState.reset_for_new_game()
	GameState.unlocked_craft_outputs.clear()
	var craft_before: Resource = CraftHelper.build_craft_data("weapon", "iron_sword")
	assert_not_null(craft_before)
	assert_false(CraftHelper.is_unlocked("weapon", "iron_sword"))
	assert_false(CraftHelper.is_craft_unlocked(craft_before))
	var inst: Resource = WeaponInstance.new()
	inst.instance_id = "t_craft_1"
	inst.weapon_id = "iron_sword"
	GameState.note_equipment_obtained(inst)
	assert_true(CraftHelper.is_unlocked("weapon", "iron_sword"))
	var craft: Resource = CraftHelper.build_craft_data("weapon", "iron_sword")
	assert_true(CraftHelper.is_craft_unlocked(craft))


func test_mythic_not_craftable() -> void:
	assert_false(CraftHelper.is_craftable_master("weapon", "burial_crown_greatsword"))
	assert_false(CraftHelper.try_unlock("weapon", "burial_crown_greatsword"))


func test_legendary_costs_heavier_than_epic() -> void:
	var epic: Dictionary = CraftHelper.costs_for_rarity(Enums.Rarity.EPIC)
	var leg: Dictionary = CraftHelper.costs_for_rarity(Enums.Rarity.LEGENDARY)
	assert_gt(int(leg.get("gold_cost", 0)), int(epic.get("gold_cost", 0)))
	var leg_mats: Dictionary = leg.get("required_materials", {})
	assert_gte(int(leg_mats.get("elite_relic_shard", 0)), 2)


func test_list_unlocked_only_shows_obtained() -> void:
	GameState.reset_for_new_game()
	GameState.unlocked_craft_outputs.clear()
	assert_eq(CraftHelper.list_unlocked_crafts("weapon").size(), 0)
	assert_true(CraftHelper.try_unlock("weapon", "hunting_bow"))
	var list: Array = CraftHelper.list_unlocked_crafts("weapon")
	assert_eq(list.size(), 1)
	assert_eq(str(list[0].output_id), "hunting_bow")


func test_silver_ring_uses_rarity_costs() -> void:
	var data: Resource = DataRegistry.get_accessory_data("silver_ring")
	assert_not_null(data)
	var craft: Resource = CraftHelper.build_craft_data("accessory", "silver_ring")
	assert_not_null(craft)
	assert_eq(int(craft.gold_cost), int(CraftHelper.GOLD_BY_RARITY.get(int(data.rarity), 40)))


func test_run_records_only_new_craft_unlocks() -> void:
	GameState.reset_for_new_game()
	GameState.unlocked_craft_outputs.clear()
	GameState.clear_last_run_craft_unlocks()
	var inst: Resource = WeaponInstance.new()
	inst.instance_id = "t_craft_run_1"
	inst.weapon_id = "iron_sword"
	assert_true(CraftHelper.note_equipment_obtained(inst))
	assert_eq(GameState.last_run_craft_unlocks.size(), 1)
	assert_eq(str(GameState.last_run_craft_unlocks[0].get("output_id", "")), "iron_sword")
	## 再入手は解放済みなのでラン記録に増えない。
	var inst2: Resource = WeaponInstance.new()
	inst2.instance_id = "t_craft_run_2"
	inst2.weapon_id = "iron_sword"
	assert_false(CraftHelper.note_equipment_obtained(inst2))
	assert_eq(GameState.last_run_craft_unlocks.size(), 1)
	## セーブ同期（record_run=false）はラン記録しない。
	GameState.clear_last_run_craft_unlocks()
	var bow: Resource = WeaponInstance.new()
	bow.instance_id = "t_craft_run_3"
	bow.weapon_id = "hunting_bow"
	assert_true(CraftHelper.note_equipment_obtained(bow, false))
	assert_true(CraftHelper.is_unlocked("weapon", "hunting_bow"))
	assert_eq(GameState.last_run_craft_unlocks.size(), 0)
	## 潜行開始でラン記録をクリア。
	GameState.record_last_run_craft_unlock("weapon", "iron_sword", "鉄の剣")
	assert_eq(GameState.last_run_craft_unlocks.size(), 1)
	GameState.begin_run_material_tracking()
	assert_eq(GameState.last_run_craft_unlocks.size(), 0)
