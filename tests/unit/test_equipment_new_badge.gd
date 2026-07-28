extends GutTest

## ドロップ装備の New 表示（次ダンジョン潜行まで）。

const _DungeonController := preload("res://scripts/dungeon/DungeonController.gd")
const _WeaponInstance := preload("res://scripts/domain/WeaponInstance.gd")


func before_each() -> void:
	SaveManager.use_normal_slot()
	GameState.reset_for_new_game()
	GameState.seed_all_starters_unlocked()
	GameState.new_equipment_instance_ids.clear()


func test_mark_and_clear_new_equipment() -> void:
	var inst: Resource = _WeaponInstance.new()
	inst.instance_id = "test_new_wpn_1"
	inst.weapon_id = "iron_sword"
	assert_false(GameState.is_equipment_new(inst))
	GameState.mark_equipment_new(inst)
	assert_true(GameState.is_equipment_new(inst))
	GameState.clear_new_equipment_marks()
	assert_false(GameState.is_equipment_new(inst))


func test_dungeon_spawn_marks_new_and_start_clears() -> void:
	var dc: Node = _DungeonController.new()
	add_child_autofree(dc)
	dc.start_dungeon("mourngate")
	assert_eq(GameState.new_equipment_instance_ids.size(), 0)
	dc._spawn_weapon("iron_sword")
	assert_gt(GameState.inventory.size(), 0)
	var dropped: Resource = GameState.inventory[GameState.inventory.size() - 1]
	assert_true(GameState.is_equipment_new(dropped), "ドロップ直後は New")
	## 次の潜行で消える。
	dc.start_dungeon("mourngate")
	assert_false(GameState.is_equipment_new(dropped))
	assert_eq(GameState.new_equipment_instance_ids.size(), 0)


func test_save_restores_new_equipment_marks() -> void:
	var inst: Resource = _WeaponInstance.new()
	inst.instance_id = "test_new_save_1"
	inst.weapon_id = "iron_sword"
	GameState.inventory.append(inst)
	GameState.mark_equipment_new(inst)
	SaveManager.save_game()
	GameState.new_equipment_instance_ids.clear()
	assert_false(GameState.is_equipment_new(inst))
	SaveManager.load_game()
	## load 後はシリアライズ済み inventory の instance を再解決する。
	var loaded: Resource = GameState.find_weapon_instance("test_new_save_1")
	assert_not_null(loaded)
	assert_true(GameState.is_equipment_new(loaded))
