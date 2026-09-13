extends GutTest

## VirtualInventoryGrid: フィルタ切替でセルが古いまま残らないこと


func test_set_entries_force_rebuilds_cells() -> void:
	var grid = VirtualInventoryGrid.new()
	var scroll := ScrollContainer.new()
	scroll.size = Vector2(400, 200)
	add_child_autofree(scroll)
	var host := Control.new()
	scroll.add_child(host)
	var made: Array = []
	grid.bind(
		scroll,
		host,
		VirtualInventoryGrid.BindMode.INNER_SCROLL,
		func(entry: Dictionary, _i: int) -> Control:
			var b := Button.new()
			b.text = str(entry.get("id", ""))
			made.append(b.text)
			return b
	)
	grid.cell_size = Vector2(64, 64)
	grid.columns = 2
	grid.set_entries([{"id": "a"}, {"id": "b"}], "")
	await get_tree().process_frame
	assert_eq(made, ["a", "b"])
	made.clear()
	grid.set_entries([{"id": "c"}, {"id": "d"}], "")
	await get_tree().process_frame
	assert_eq(made, ["c", "d"], "force refresh must remake cells")
	var labels: PackedStringArray = []
	for child in host.get_children():
		if child is Button:
			labels.append((child as Button).text)
	assert_true("c" in labels)
	assert_true("d" in labels)
	assert_false("a" in labels)
