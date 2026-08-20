extends GutTest

## P3-UX-EQUIP-LOCK-001: ロックは即メモリ反映。フルセーブは debounce（フリーズ対策）。

const _WeaponInstance := preload("res://scripts/domain/WeaponInstance.gd")


func before_each() -> void:
	GameState.reset_for_new_game()


func _make_weapon() -> Resource:
	var w: Resource = _WeaponInstance.new()
	w.weapon_id = "iron_sword"
	w.is_appraised = true
	w.equip_level = 1
	w.is_locked = false
	GameState.inventory.append(w)
	return w


func test_catalog_lock_toggles_without_immediate_save() -> void:
	var packed: PackedScene = load("res://scenes/equipment/EquipmentCatalogScene.tscn")
	assert_not_null(packed)
	var scene: Node = packed.instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	var item: Resource = _make_weapon()
	assert_false(EquipmentEnhancer.is_item_locked(item))
	## セーブ無しでトグルだけ先に反映されること。
	scene._toggle_catalog_item_lock(item, "weapon", null)
	assert_true(EquipmentEnhancer.is_item_locked(item))
	assert_true(bool(scene._lock_save_pending), "save should be pending, not inline")
	scene._toggle_catalog_item_lock(item, "weapon", null)
	assert_false(EquipmentEnhancer.is_item_locked(item))
	assert_true(bool(scene._lock_save_pending))


func test_catalog_lock_flush_writes_save() -> void:
	var packed: PackedScene = load("res://scenes/equipment/EquipmentCatalogScene.tscn")
	assert_not_null(packed)
	var scene: Node = packed.instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	var item: Resource = _make_weapon()
	scene._toggle_catalog_item_lock(item, "weapon", null)
	assert_true(EquipmentEnhancer.is_item_locked(item))
	scene._flush_lock_save()
	assert_false(bool(scene._lock_save_pending))
	assert_true(SaveManager.has_save())
	## 再ロードしてもロックが残る。
	GameState.reset_for_new_game()
	assert_true(SaveManager.load_game())
	assert_eq(GameState.inventory.size(), 1)
	assert_true(EquipmentEnhancer.is_item_locked(GameState.inventory[0]))


func test_long_press_lock_clears_pointer_state() -> void:
	## release 欠落でも次のセル操作が死なないこと。
	var packed: PackedScene = load("res://scenes/equipment/EquipmentCatalogScene.tscn")
	assert_not_null(packed)
	var scene: Node = packed.instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	var item: Resource = _make_weapon()
	var btn := Button.new()
	scene.add_child(btn)
	scene._begin_cell_press(item, "weapon", "", btn)
	assert_true(bool(scene._cell_pointer_down))
	scene._on_cell_long_press_timeout()
	assert_false(bool(scene._cell_pointer_down), "press state cleared after lock")
	assert_true(EquipmentEnhancer.is_item_locked(item))
