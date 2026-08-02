extends GutTest

## 一時停止戦闘ログシートのノード階層契約。
## SheetContent は SheetScroll 配下にあり、SheetVBox 直下指定は null になる。


func test_sheet_content_lives_under_scroll() -> void:
	var sheet := PanelContainer.new()
	sheet.name = "PauseBattleLogSheet"
	add_child_autofree(sheet)
	var root := VBoxContainer.new()
	root.name = "SheetVBox"
	sheet.add_child(root)
	var scroll := ScrollContainer.new()
	scroll.name = "SheetScroll"
	root.add_child(scroll)
	var content := VBoxContainer.new()
	content.name = "SheetContent"
	scroll.add_child(content)

	assert_null(
		sheet.get_node_or_null("SheetVBox/SheetContent"),
		"直下パスは Scroll 越しなので null"
	)
	assert_not_null(
		sheet.get_node_or_null("SheetVBox/SheetScroll/SheetContent"),
		"Scroll 経由パスは存在する"
	)
	assert_eq(
		sheet.find_child("SheetContent", true, false),
		content,
		"find_child で SheetContent を取得できる"
	)
