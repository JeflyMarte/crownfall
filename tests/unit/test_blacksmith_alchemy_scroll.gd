extends GutTest

## 錬成左リストが長いとき LeftScroll で下まで届くこと（仮想リストでもスクロール可能）。

const _WeaponInstance := preload("res://scripts/domain/WeaponInstance.gd")


func before_each() -> void:
	GameState.reset_for_new_game()
	GameState.seed_all_starters_unlocked()


func _make_weapon(level: int) -> Resource:
	var item: Resource = _WeaponInstance.new()
	item.weapon_id = "iron_sword"
	item.instance_id = "scroll_probe_%d" % level
	item.equip_level = level
	item.is_appraised = true
	GameState.inventory.append(item)
	return item


func test_alchemy_left_list_scroll_reaches_low_level_items() -> void:
	for i in range(12):
		_make_weapon(12 - i)

	var packed: PackedScene = load("res://scenes/blacksmith/BlacksmithScene.tscn")
	var scene: Control = packed.instantiate() as Control
	add_child_autofree(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	scene.call("_set_mode", "alchemy")
	await get_tree().process_frame
	await get_tree().process_frame
	## 仮想リストの deferred refresh を待つ。
	await get_tree().process_frame

	var left_scroll: ScrollContainer = scene.find_child("LeftScroll", true, false) as ScrollContainer
	var left_list: VBoxContainer = scene.find_child("LeftList", true, false) as VBoxContainer
	var body_scroll: ScrollContainer = scene.find_child("BodyScroll", true, false) as ScrollContainer
	assert_not_null(left_scroll)
	assert_not_null(left_list)

	## 仮想化後は LeftList 直下は見出し＋ホスト程度。件数は VirtualInventoryGrid 側。
	var virtual_host: Control = scene.find_child("AlchemyVirtualHost", true, false) as Control
	assert_not_null(virtual_host, "alchemy left list should use AlchemyVirtualHost")
	var alchemy_virtual: Variant = scene.get("_alchemy_virtual")
	assert_not_null(alchemy_virtual)
	assert_gt(int(alchemy_virtual.entry_count()), 5, "virtual grid should hold many alchemy bases")
	assert_gt(
		float(alchemy_virtual.content_height()),
		left_scroll.size.y,
		"virtual content height should exceed LeftScroll viewport"
	)

	## 下帯オミット時は外枠 BodyScroll が左一覧のドラッグを奪わない。
	if body_scroll != null:
		assert_eq(
			body_scroll.vertical_scroll_mode,
			ScrollContainer.SCROLL_MODE_DISABLED,
			"BodyScroll must be disabled while craftable strip is hidden"
		)
		assert_eq(body_scroll.visible, false, "BodyScroll should be hidden while strip omitted")

	var main_split: HBoxContainer = scene.find_child("MainSplit", true, false) as HBoxContainer
	assert_not_null(main_split)
	## 下帯なし時は MainSplit を BodyScroll から外し、高さ拘束で LeftScroll を生かす。
	assert_eq(main_split.get_parent(), scene, "MainSplit must be direct child when strip omitted")

	var list_min_h: float = left_list.get_combined_minimum_size().y
	assert_gt(list_min_h, left_scroll.size.y, "list content should exceed LeftScroll viewport")
	assert_eq(left_list.clip_contents, false, "LeftList must not clip; LeftScroll clips")
	assert_eq(
		left_scroll.horizontal_scroll_mode,
		ScrollContainer.SCROLL_MODE_SHOW_NEVER
	)

	var bar: ScrollBar = left_scroll.get_v_scroll_bar()
	assert_not_null(bar)
	assert_gt(bar.max_value, bar.page, "LeftScroll must allow vertical scroll")

	left_scroll.scroll_vertical = int(bar.max_value)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_gt(left_scroll.scroll_vertical, 0, "forcing scroll_vertical should move past top")
	## 下端までスクロールしても仮想ホストに可視セルが残る。
	assert_gt(virtual_host.get_child_count(), 0, "virtual host should keep visible cells after scroll")
