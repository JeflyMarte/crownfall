extends GutTest

## 結果画面「入手装備」一覧（P3-UX-RESULT-DROP-LIST-001）。

const _DungeonController := preload("res://scripts/dungeon/DungeonController.gd")


func before_each() -> void:
	GameState.reset_for_new_game()
	GameState.seed_all_starters_unlocked()
	GameState.clear_last_run_equipment_drops()


func test_record_keeps_all_drops_in_order() -> void:
	var dc: Node = _DungeonController.new()
	add_child_autofree(dc)
	dc.start_dungeon("mourngate")
	GameState.begin_run_material_tracking()
	assert_eq(GameState.last_run_equipment_drops.size(), 0)
	dc._spawn_weapon("iron_sword")
	dc._spawn_armor("leather_armor")
	dc._spawn_accessory("silver_ring")
	assert_eq(GameState.last_run_equipment_drops.size(), 3)
	assert_eq(str(GameState.last_run_equipment_drops[0].get("category", "")), "weapon")
	assert_eq(str(GameState.last_run_equipment_drops[1].get("category", "")), "armor")
	assert_eq(str(GameState.last_run_equipment_drops[2].get("category", "")), "accessory")
	assert_eq(str(GameState.last_run_equipment_drops[0].get("item_id", "")), "iron_sword")


func test_begin_run_clears_previous_drop_list() -> void:
	GameState.last_run_equipment_drops = [
		{"category": "weapon", "instance_id": "x", "item_id": "iron_sword"},
	]
	GameState.begin_run_material_tracking()
	assert_eq(GameState.last_run_equipment_drops.size(), 0)


func test_multiple_same_category_are_kept() -> void:
	var dc: Node = _DungeonController.new()
	add_child_autofree(dc)
	dc.start_dungeon("mourngate")
	GameState.begin_run_material_tracking()
	dc._spawn_weapon("iron_sword")
	dc._spawn_weapon("rusted_blade")
	assert_eq(GameState.last_run_equipment_drops.size(), 2)
	assert_eq(str(GameState.last_run_equipment_drops[0].get("item_id", "")), "iron_sword")
	assert_eq(str(GameState.last_run_equipment_drops[1].get("item_id", "")), "rusted_blade")


func test_relic_drops_recorded_for_result() -> void:
	GameState.begin_run_material_tracking()
	assert_eq(GameState.last_run_relic_drops.size(), 0)
	GameState.record_last_run_relic_drop("relic_war_banner")
	GameState.record_last_run_relic_drop("relic_scout_lens")
	GameState.record_last_run_relic_drop("relic_war_banner") ## 重複は積まない
	assert_eq(GameState.last_run_relic_drops.size(), 2)
	assert_eq(str(GameState.last_run_relic_drops[0]), "relic_war_banner")
	assert_eq(str(GameState.last_run_relic_drops[1]), "relic_scout_lens")
	assert_eq(GameState.last_run_relic_dropped, "relic_scout_lens")
	GameState.begin_run_material_tracking()
	assert_eq(GameState.last_run_relic_drops.size(), 0)
	assert_eq(GameState.last_run_relic_dropped, "")
