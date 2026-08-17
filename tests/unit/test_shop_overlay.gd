extends GutTest
## P3-MONET-IAP-001-B — ショップ overlay が生成できること。


func test_shop_overlay_builds_and_lists_packs() -> void:
	var shop := ShopOverlay.new()
	add_child_autofree(shop)
	shop.open()
	assert_true(shop.visible)
	var buys: int = _count_buy_buttons(shop)
	assert_eq(buys, 6, "パック6種の購入ボタン")
	shop.close()
	assert_false(shop.visible)


func test_gacha_scene_instantiates_with_shop_entry() -> void:
	var packed: PackedScene = load("res://scenes/gacha/GachaScene.tscn") as PackedScene
	assert_not_null(packed)
	var scene: Node = packed.instantiate()
	add_child_autofree(scene)
	assert_not_null(scene)
	assert_true(scene.has_method("_open_shop"))


func _count_buy_buttons(n: Node) -> int:
	var count: int = 0
	if n is Button and (n as Button).text == "購入":
		count += 1
	for child in n.get_children():
		count += _count_buy_buttons(child)
	return count
