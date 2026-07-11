extends GutTest
## P3-MAT-SUPPLY-001 — ボス高品質欠片確定 / ELITE 付与修正。

const _DungeonController = preload("res://scripts/dungeon/DungeonController.gd")
const _DungeonTierConfig = preload("res://scripts/dungeon/DungeonTierConfig.gd")

func before_each() -> void:
	GameState.material_inventory.clear()
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NORMAL

func test_boss_material_loot_grants_one_on_normal() -> void:
	var dc: Node = _DungeonController.new()
	add_child_autofree(dc)
	var bonus: Dictionary = dc.apply_boss_material_loot()
	assert_eq(str(bonus.get("material_id", "")), "elite_relic_shard")
	assert_eq(int(bonus.get("amount", 0)), 1)
	assert_eq(GameState.get_material_quantity("elite_relic_shard"), 1)

func test_boss_material_loot_grants_two_on_hard() -> void:
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_HARD
	var dc: Node = _DungeonController.new()
	add_child_autofree(dc)
	var bonus: Dictionary = dc.apply_boss_material_loot()
	assert_eq(int(bonus.get("amount", 0)), 2)
	assert_eq(GameState.get_material_quantity("elite_relic_shard"), 2)

func test_elite_bonus_material_actually_added_when_forced() -> void:
	# 素材優先で確率30%。seed を回して少なくとも1回付与されることを確認。
	GameState.set_exploration_policy("material")
	var granted: bool = false
	for _i in range(80):
		GameState.material_inventory.clear()
		var dc: Node = _DungeonController.new()
		add_child_autofree(dc)
		# 防具/装飾の抽選を避けるため armor/accessory chance は触らず、material のみ見る
		var bonus: Dictionary = dc.apply_elite_bonus_loot()
		if not str(bonus.get("material_id", "")).is_empty():
			assert_eq(str(bonus["material_id"]), "elite_relic_shard")
			assert_eq(GameState.get_material_quantity("elite_relic_shard"), 1)
			granted = true
			break
	assert_true(granted, "ELITE material_chance で付与が一度も起きない")
	GameState.set_exploration_policy("")
