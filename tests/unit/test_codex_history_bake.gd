extends GutTest

## 図鑑歴史／断片は bake JSON 経由で読む（docs/ 直読みは実機で空になる）。


func test_history_bake_file_exists() -> void:
	assert_true(
		FileAccess.file_exists("res://resources/codex/history_entries.json"),
		"history bake JSON が同梱されている"
	)


func test_fragment_bake_file_exists() -> void:
	assert_true(
		FileAccess.file_exists("res://resources/codex/fragment_entries.json"),
		"fragment bake JSON が同梱されている"
	)


func test_history_entries_load_from_bake() -> void:
	var entries: Array = CatalogHelper.get_history_entries()
	assert_eq(entries.size(), 50, "歴史は50件")
	var by_id: Dictionary = {}
	for e in entries:
		by_id[str(e.get("id", ""))] = e
	assert_true(by_id.has("HE-001"), "HE-001 がある")
	assert_eq(str(by_id["HE-001"].get("display_name", "")), "王国時代", "HE-001 タイトル")
	assert_true(bool(by_id["HE-001"].get("discovered", false)), "starter 開示")
	assert_false(str(by_id["HE-001"].get("description", "")).is_empty(), "Overview あり")
	assert_eq(str(by_id["HE-050"].get("display_name", "")), "赤鉄の工房と星炉の系譜", "HE-050 タイトル")


func test_lore_fragments_load_from_bake() -> void:
	var body: String = CatalogHelper.get_lore_body("ancient_record")
	assert_false(body.is_empty(), "ancient_record 本文が bake から取れる")
	var lore_entries: Array = CatalogHelper.get_lore_entries()
	assert_gte(lore_entries.size(), 30, "断片が複数ある")
