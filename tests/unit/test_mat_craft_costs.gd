extends GutTest
## 動的生産コストの健全性（P3-CRAFT-DISCOVER-001）。旧固定6レシピ表は廃止。


func test_rarity_cost_table_is_monotonic() -> void:
	var prev_gold: int = 0
	for rarity: int in [
		Enums.Rarity.COMMON,
		Enums.Rarity.RARE,
		Enums.Rarity.EPIC,
		Enums.Rarity.LEGENDARY,
	]:
		var costs: Dictionary = CraftHelper.costs_for_rarity(rarity)
		var gold: int = int(costs.get("gold_cost", 0))
		assert_gt(gold, prev_gold)
		prev_gold = gold
		assert_false((costs.get("required_materials", {}) as Dictionary).is_empty())


func test_basic_weapons_are_craftable_masters() -> void:
	assert_true(CraftHelper.is_craftable_master("weapon", "iron_sword"))
	assert_true(CraftHelper.is_craftable_master("weapon", "hunting_bow"))
	assert_true(CraftHelper.is_craftable_master("weapon", "apprentice_staff"))
	assert_true(CraftHelper.is_craftable_master("armor", "leather_armor"))
	assert_true(CraftHelper.is_craftable_master("accessory", "silver_ring"))
