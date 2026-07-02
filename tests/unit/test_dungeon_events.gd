extends GutTest

## P3-EVT-001 — ダンジョン別イベントプールと LF 断章解析のテスト。

const DungeonControllerScript = preload("res://scripts/dungeon/DungeonController.gd")

func _make_controller(dungeon_id: String) -> Node:
	var dc: Node = DungeonControllerScript.new()
	if not dungeon_id.is_empty():
		dc.current_dungeon_data = DataRegistry.get_dungeon_data(dungeon_id)
	add_child_autofree(dc)
	return dc

func _pool_ids(dc: Node) -> Array:
	var ids: Array = []
	for ev in dc._get_event_pool():
		ids.append(str(ev.get("id", "")))
	return ids

func test_whisperwood_pool_has_biome_events() -> void:
	var ids: Array = _pool_ids(_make_controller("whisperwood"))
	assert_has(ids, "whisperwood_moss_spring", "②専用イベントが含まれる")
	assert_has(ids, "fallen_altar", "共通イベントも含まれる")
	assert_does_not_have(ids, "mourngate_crystal_vein", "①専用は混ざらない")

func test_mistfen_pool_has_biome_events() -> void:
	var ids: Array = _pool_ids(_make_controller("mistfen"))
	assert_has(ids, "mistfen_libris_seal", "③専用イベントが含まれる")
	assert_does_not_have(ids, "whisperwood_moss_spring", "②専用は混ざらない")

func test_new_lore_fragments_have_bodies() -> void:
	for lore_id: String in [
		"whisperwood_warden_carving", "whisperwood_canopy_whisper",
		"mistfen_libris_seal", "mistfen_drowned_ledger",
	]:
		assert_false(
			CatalogHelper.get_lore_body(lore_id).is_empty(),
			"LF 本文が解析できる: %s" % lore_id
		)
