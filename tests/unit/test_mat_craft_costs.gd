extends GutTest
## P3-MAT-CRAFT-001 — レシピ差は必要数と Gold。

func test_craft_recipes_have_distinct_costs() -> void:
	var by_id: Dictionary = {}
	for craft in DataRegistry.get_all_craft_data():
		by_id[str(craft.id)] = craft
	assert_true(by_id.has("craft_apprentice_staff"))
	assert_true(by_id.has("craft_silver_ring"))
	assert_eq(int(by_id["craft_apprentice_staff"].gold_cost), 30)
	assert_eq(int(by_id["craft_hunting_bow"].gold_cost), 40)
	assert_eq(int(by_id["craft_leather_armor"].gold_cost), 50)
	assert_eq(int(by_id["craft_iron_sword"].gold_cost), 55)
	assert_eq(int(by_id["craft_bone_armor"].gold_cost), 70)
	assert_eq(int(by_id["craft_silver_ring"].gold_cost), 120)
	# 銀指輪のみ elite 必須
	assert_eq(int(by_id["craft_silver_ring"].required_materials.get("elite_relic_shard", 0)), 1)
	assert_eq(int(by_id["craft_iron_sword"].required_materials.get("elite_relic_shard", 0)), 0)
	# 骨鎧は骨寄り、鉄剣は欠片寄り
	assert_eq(int(by_id["craft_bone_armor"].required_materials.get("ancient_bone", 0)), 3)
	assert_eq(int(by_id["craft_iron_sword"].required_materials.get("relic_shard", 0)), 3)
