extends GutTest
## P3-MONET-IAP-001-B — ショップ overlay が生成できること。

const _ShopOverlay := preload("res://scripts/ui/ShopOverlay.gd")


func test_shop_overlay_builds_and_lists_packs() -> void:
	var shop: CanvasLayer = _ShopOverlay.new() as CanvasLayer
	add_child_autofree(shop)
	shop.call("open")
	assert_true(shop.visible)
	var buys: int = _count_buy_buttons(shop)
	assert_eq(buys, 6, "パック6種の購入ボタン")
	shop.call("close")
	assert_false(shop.visible)


func test_present_is_blocked_while_omitted() -> void:
	assert_false(Constants.are_iap_purchases_playable())
	var host := Control.new()
	add_child_autofree(host)
	var shop: CanvasLayer = _ShopOverlay.present(host)
	assert_null(shop)


func _count_buy_buttons(n: Node) -> int:
	var count: int = 0
	if n is Button and (n as Button).text == "購入":
		count += 1
	for child in n.get_children():
		count += _count_buy_buttons(child)
	return count
