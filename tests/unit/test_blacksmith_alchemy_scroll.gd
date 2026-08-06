extends GutTest

## 錬成左リストが長いとき LeftScroll で下まで届くこと（Lv低装備がクリップされない）。

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

	var left_scroll: ScrollContainer = scene.find_child("LeftScroll", true, false) as ScrollContainer
	var left_list: VBoxContainer = scene.find_child("LeftList", true, false) as VBoxContainer
	var body_scroll: ScrollContainer = scene.find_child("BodyScroll", true, false) as ScrollContainer
	assert_not_null(left_scroll)
	assert_not_null(left_list)
	assert_gt(left_list.get_child_count(), 5)

	## 下帯オミット時は外枠 BodyScroll が左一覧のドラッグを奪わない。
	if body_scroll != null:
		assert_eq(
			body_scroll.vertical_scroll_mode,
			ScrollContainer.SCROLL_MODE_DISABLED,
			"BodyScroll must be disabled while craftable strip is hidden"
		)

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
	assert_gt(left_scroll.scroll_vertical, 0, "forcing scroll_vertical should move past top")
