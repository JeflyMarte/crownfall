extends GutTest
## P3-MAT-CRAFT-001 — レシピ差は必要数と Gold。

func test_craft_recipes_have_distinct_costs() -> void:
	var by_id: Dictionary = {}
	for craft in DataRegistry.get_all_craft_data():
		by_id[str(craft.id)] = craft
	assert_true(by_id.has("craft_apprentice_staff"))
	assert_true(by_id.has("craft_silver_ring"))
	assert_eq(int(by_id["craft_apprentice_staff"].gold_cost), 40)
	assert_eq(int(by_id["craft_apprentice_staff"].required_materials.get("ancient_bone", 0)), 1)
	assert_eq(int(by_id["craft_hunting_bow"].gold_cost), 40)
	assert_eq(int(by_id["craft_leather_armor"].gold_cost), 50)
	assert_eq(int(by_id["craft_iron_sword"].gold_cost), 55)
	assert_eq(int(by_id["craft_bone_armor"].gold_cost), 70)
	assert_eq(int(by_id["craft_silver_ring"].gold_cost), 120)
	# 銀指輪のみ elite 必須＋1-5クリア解放
	assert_eq(int(by_id["craft_silver_ring"].required_materials.get("elite_relic_shard", 0)), 1)
	assert_eq(str(by_id["craft_silver_ring"].unlock_condition), "stage_cleared:mourngate_1_5")
	assert_eq(int(by_id["craft_iron_sword"].required_materials.get("elite_relic_shard", 0)), 0)
	# 骨鎧は骨寄り、鉄剣は欠片寄り
	assert_eq(int(by_id["craft_bone_armor"].required_materials.get("ancient_bone", 0)), 3)
	assert_eq(int(by_id["craft_iron_sword"].required_materials.get("relic_shard", 0)), 3)


func test_silver_ring_locked_until_mourngate_1_5() -> void:
	GameState.reset_for_new_game()
	if Constants.STARTER_STORY_RECRUIT:
		assert_true(GameState.select_starting_adventurer("adventurer_0"))
	var ring: Resource = null
	for craft in DataRegistry.get_all_craft_data():
		if str(craft.id) == "craft_silver_ring":
			ring = craft
			break
	assert_not_null(ring)
	assert_false(CraftHelper.is_craft_unlocked(ring))
	assert_false(CraftHelper.can_craft(ring))
	GameState.mark_stage_cleared("mourngate_1_5", 0)
	assert_true(CraftHelper.is_craft_unlocked(ring))
