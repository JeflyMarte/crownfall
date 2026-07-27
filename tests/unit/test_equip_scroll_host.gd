extends GutTest

## P3-UX-EQUIP-SCROLL-002: 所持ホストは非 Scroll、外 TabEquip のみスクロール。


func test_equipment_inventory_host_is_not_scroll_container() -> void:
	var packed: PackedScene = load("res://scenes/equipment/EquipmentScene.tscn")
	assert_not_null(packed)
	var scene: Node = packed.instantiate()
	add_child_autofree(scene)
	var host: Node = scene.get_node_or_null(
		"VBoxContainer/TabContainer/TabEquip/EquipContent/InventoryScroll"
	)
	assert_not_null(host)
	assert_false(host is ScrollContainer, "内側所持は ScrollContainer にしない")
	assert_true(host is MarginContainer or host is Control)
	var tab: Node = scene.get_node_or_null("VBoxContainer/TabContainer/TabEquip")
	assert_true(tab is ScrollContainer, "外 TabEquip がスクロール本体")
