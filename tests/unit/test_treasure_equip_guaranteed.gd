extends GutTest
## P3-BAL-TREASURE-EQUIP-001 — 宝箱成功時は装備1点確定。


const _DungeonController = preload("res://scripts/dungeon/DungeonController.gd")
const _Treasure = preload("res://scripts/dungeon/TreasureRoomPresentation.gd")
const _Colors = preload("res://scripts/dungeon/NonCombatNarrativeColors.gd")


func before_each() -> void:
	GameState.inventory.clear()
	GameState.armor_inventory.clear()
	GameState.accessory_inventory.clear()
	GameState.current_dungeon_tier = 0


func test_generate_treasure_loot_always_grants_one_equip() -> void:
	var dc: Node = _DungeonController.new()
	add_child_autofree(dc)
	dc.current_dungeon_data = DataRegistry.get_dungeon_data("mourngate")
	dc.current_stage_data = DataRegistry.get_stage_data("mourngate_1_1")
	seed(42)
	for _i in 24:
		var before_w: int = GameState.inventory.size()
		var before_a: int = GameState.armor_inventory.size()
		var before_x: int = GameState.accessory_inventory.size()
		var loot: Dictionary = dc.generate_treasure_loot()
		assert_eq(int(loot.get("gold", 0)), BalanceConfig.treasure_gold(0))
		var cat: String = str(loot.get("equip_category", ""))
		assert_true(
			cat == "weapon" or cat == "armor" or cat == "accessory",
			"category=%s" % cat
		)
		var gained: int = (
			(GameState.inventory.size() - before_w)
			+ (GameState.armor_inventory.size() - before_a)
			+ (GameState.accessory_inventory.size() - before_x)
		)
		assert_eq(gained, 1, "exactly one equip per success")
		var filled: int = 0
		if not str(loot.get("weapon_id", "")).is_empty():
			filled += 1
		if not str(loot.get("armor_id", "")).is_empty():
			filled += 1
		if not str(loot.get("accessory_id", "")).is_empty():
			filled += 1
		assert_eq(filled, 1, "exactly one id field set")


func test_success_narrative_includes_armor() -> void:
	var bb: String = _Treasure.format_success_narrative_bbcode(
		"蓋が開いた", 120, "", "", "革の鎧"
	)
	assert_true(bb.contains(_Colors.HEX_ARMOR), "防具色")
	assert_true(bb.contains("革の鎧"), "防具名")
	var plain: String = _Treasure.format_success_narrative("開いた", 10, "", "", "骨の鎧")
	assert_true(plain.contains("防具: 骨の鎧"))
