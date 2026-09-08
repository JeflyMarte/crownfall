extends GutTest

## 装備袋が大きいときにキャラ画面のタップが固まらないこと（1.0.5 実機報告の回帰防止）。
## 比較のたびに表示名／レア度を引き直すと所持1000で 9 秒超（実機は数十秒の無反応）だった。

const _WeaponInstance := preload("res://scripts/domain/WeaponInstance.gd")

## デスクトップ headless の実測は 30ms 未満。CI のばらつきを見て広めに取る。
const SLOT_TAP_BUDGET_MS: float = 1000.0


func before_each() -> void:
	GameState.reset_for_new_game()
	GameState.seed_all_starters_unlocked()


func _weapon_ids() -> Array:
	var ids: Array = []
	var dir := DirAccess.open("res://resources/weapons")
	if dir == null:
		return ["iron_sword"]
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			ids.append(file_name.get_basename())
		file_name = dir.get_next()
	dir.list_dir_end()
	return ids


func _fill_bag(count: int) -> void:
	var ids: Array = _weapon_ids()
	for i in range(count):
		var item: Resource = _WeaponInstance.new()
		item.weapon_id = str(ids[i % ids.size()])
		item.instance_id = "sortperf_%d" % i
		item.equip_level = 1 + (i % 40)
		item.is_appraised = true
		GameState.inventory.append(item)


func _entries_from_bag() -> Array:
	var entries: Array = []
	for item in GameState.inventory:
		entries.append({"item": item, "category": "weapon"})
	return entries


func test_slot_tap_stays_responsive_with_full_bag() -> void:
	_fill_bag(Constants.MAX_EQUIPMENT_INVENTORY)
	var packed: PackedScene = load("res://scenes/equipment/EquipmentScene.tscn")
	var scene: Control = packed.instantiate() as Control
	add_child_autofree(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	var started: int = Time.get_ticks_usec()
	scene.call("_on_slot_pressed", "weapon")
	var elapsed_ms: float = float(Time.get_ticks_usec() - started) / 1000.0
	assert_lt(
		elapsed_ms,
		SLOT_TAP_BUDGET_MS,
		"武器スロットのタップが %.1f ms かかっている（袋 %d 件）" % [
			elapsed_ms, Constants.MAX_EQUIPMENT_INVENTORY
		]
	)


func test_member_cycle_rebuild_stays_responsive_with_full_bag() -> void:
	_fill_bag(Constants.MAX_EQUIPMENT_INVENTORY)
	var packed: PackedScene = load("res://scenes/equipment/EquipmentScene.tscn")
	var scene: Control = packed.instantiate() as Control
	add_child_autofree(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	var started: int = Time.get_ticks_usec()
	scene.call("_cycle_member", 1)
	scene.call("_flush_member_cycle_inventory_rebuild")
	var elapsed_ms: float = float(Time.get_ticks_usec() - started) / 1000.0
	assert_lt(elapsed_ms, SLOT_TAP_BUDGET_MS, "キャラ切替が %.1f ms かかっている" % elapsed_ms)


func test_rarity_sort_keeps_rarity_desc_then_name_asc() -> void:
	_fill_bag(60)
	var entries: Array = _entries_from_bag()
	var sorted: Array = EquipmentUiHelper.sort_inventory_entries(entries, "rarity")
	assert_eq(sorted.size(), entries.size(), "件数が変わらない")

	var prev_rarity: int = 999
	var prev_name: String = ""
	for entry in sorted:
		var item: Resource = entry.get("item")
		var data: Resource = DataRegistry.get_weapon_data(str(item.weapon_id))
		var rarity: int = int(data.rarity) if data != null else 0
		var display_name: String = EquipmentEnhancer.get_display_name(item)
		if rarity == prev_rarity:
			assert_true(prev_name <= display_name, "同レア度内は名前昇順")
		else:
			assert_true(rarity < prev_rarity, "レア度は降順")
		prev_rarity = rarity
		prev_name = display_name


func test_name_sort_is_pure_name_ascending() -> void:
	_fill_bag(60)
	var sorted: Array = EquipmentUiHelper.sort_inventory_entries(_entries_from_bag(), "name")
	var prev_name: String = ""
	for entry in sorted:
		var display_name: String = EquipmentEnhancer.get_display_name(entry.get("item"))
		assert_true(prev_name <= display_name, "名前昇順")
		prev_name = display_name


func test_confirm_is_control_overlay_not_window_dialog() -> void:
	## Window 系ダイアログは実機で入力を食ってフリーズする既往（known-pitfalls）。
	var packed: PackedScene = load("res://scenes/equipment/EquipmentScene.tscn")
	var scene: Control = packed.instantiate() as Control
	add_child_autofree(scene)
	await get_tree().process_frame
	await get_tree().process_frame

	var overlay: Control = scene.find_child("ConfirmOverlay", true, false) as Control
	assert_not_null(overlay, "確認オーバーレイが Control で存在する")
	assert_false(overlay.visible, "既定では非表示")

	for child in scene.get_children():
		assert_false(
			child is AcceptDialog,
			"キャラ画面に Window ダイアログを置かない: %s" % child.name
		)
