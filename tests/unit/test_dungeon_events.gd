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

func test_astoria_ruins_pool_has_surface_events() -> void:
	var ids: Array = _pool_ids(_make_controller("astoria_ruins"))
	assert_has(ids, "mourngate_crystal_vein", "①帯イベントを共用")
	assert_has(ids, "astoria_bleeding_wall", "①寄り道専用イベントが含まれる")

func test_side_route_event_pools() -> void:
	var green_ids: Array = _pool_ids(_make_controller("green_hollow"))
	assert_has(green_ids, "green_hollow_bog_fire", "②寄り道専用")
	var west_ids: Array = _pool_ids(_make_controller("westbay_flats"))
	assert_has(west_ids, "blackshore_tidal_pool", "④帯イベントを共用")
	assert_has(west_ids, "westbay_holy_spring", "④寄り道専用")
	var frost_ids: Array = _pool_ids(_make_controller("frostwall_path"))
	assert_has(frost_ids, "frostridge_snow_shelter", "⑤帯イベントを共用")
	assert_has(frost_ids, "frostwall_ice_shard", "⑤寄り道専用")

func test_side_route_equipment_pools() -> void:
	for dungeon_id: String in [
		"astoria_ruins", "green_hollow", "westbay_flats", "frostwall_path",
	]:
		var data: Resource = DataRegistry.get_dungeon_data(dungeon_id)
		assert_not_null(data, dungeon_id)
		assert_eq(str(data.route_type), "side", dungeon_id)
		assert_gte(data.armor_pool.size(), 5, "%s 防具プール" % dungeon_id)
		assert_gte(data.accessory_pool.size(), 3, "%s 装飾プール" % dungeon_id)
		assert_gte(data.weapon_pool.size(), 8, "%s 武器プール" % dungeon_id)

func test_blackshore_main_has_biome_events() -> void:
	var ids: Array = _pool_ids(_make_controller("blackshore"))
	assert_has(ids, "blackshore_tidal_pool", "④メイン専用イベントが含まれる")

func test_new_lore_fragments_have_bodies() -> void:
	for lore_id: String in [
		"whisperwood_warden_carving", "whisperwood_canopy_whisper",
		"mistfen_libris_seal", "mistfen_drowned_ledger",
		"blackshore_pharos_echo", "blackshore_tide_chart",
		"frostridge_boundary_marker", "frostridge_blizzard_note",
	]:
		assert_false(
			CatalogHelper.get_lore_body(lore_id).is_empty(),
			"LF 本文が解析できる: %s" % lore_id
		)
