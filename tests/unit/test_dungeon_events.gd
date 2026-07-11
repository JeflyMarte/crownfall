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

func test_event_pool_is_lore_only() -> void:
	var dc: Node = _make_controller("whisperwood")
	for ev: Dictionary in dc._get_event_pool():
		assert_eq(str(ev.get("outcome", {}).get("type", "")), "lore", str(ev.get("id", "")))

func test_whisperwood_pool_has_biome_lore_only() -> void:
	var ids: Array = _pool_ids(_make_controller("whisperwood"))
	assert_has(ids, "whisperwood_warden_carving", "②専用碑文が含まれる")
	assert_has(ids, "faded_inscription", "共通碑文が含まれる")
	assert_does_not_have(ids, "whisperwood_moss_spring", "回復イベントは除外")
	assert_does_not_have(ids, "fallen_altar", "回復イベントは除外")
	assert_does_not_have(ids, "mourngate_crystal_vein", "①専用は混ざらない")

func test_mistfen_pool_has_biome_lore_only() -> void:
	var ids: Array = _pool_ids(_make_controller("mistfen"))
	assert_has(ids, "mistfen_libris_seal", "③専用碑文が含まれる")
	assert_does_not_have(ids, "whisperwood_warden_carving", "②専用は混ざらない")

func test_astoria_ruins_pool_has_surface_lore_only() -> void:
	var ids: Array = _pool_ids(_make_controller("astoria_ruins"))
	assert_has(ids, "astoria_crown_bridge_rubble", "①寄り道専用碑文が含まれる")
	assert_does_not_have(ids, "astoria_bleeding_wall", "素材イベントは除外")
	assert_does_not_have(ids, "mourngate_crystal_vein", "Gold イベントは除外")

func test_side_route_lore_pools() -> void:
	var green_ids: Array = _pool_ids(_make_controller("green_hollow"))
	assert_has(green_ids, "whisperwood_warden_carving", "②帯の碑文を共用")
	assert_does_not_have(green_ids, "green_hollow_bog_fire", "非碑文イベントは除外")
	var west_ids: Array = _pool_ids(_make_controller("westbay_flats"))
	assert_has(west_ids, "blackshore_pharos_echo", "④帯の碑文を共用")
	assert_does_not_have(west_ids, "westbay_holy_spring", "回復イベントは除外")
	var frost_ids: Array = _pool_ids(_make_controller("frostwall_path"))
	assert_has(frost_ids, "frostridge_boundary_marker", "⑤帯の碑文を共用")
	assert_does_not_have(frost_ids, "frostwall_ice_shard", "素材イベントは除外")

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

func test_blackshore_main_has_biome_lore_only() -> void:
	var ids: Array = _pool_ids(_make_controller("blackshore"))
	assert_has(ids, "blackshore_pharos_echo", "④メイン専用碑文が含まれる")
	assert_does_not_have(ids, "blackshore_tidal_pool", "非碑文イベントは除外")

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

func test_pick_event_deduplicates_until_pool_exhausted() -> void:
	var dc: Node = _make_controller("whisperwood")
	var pool_size: int = dc._get_event_pool().size()
	var seen: Dictionary = {}
	for _i in pool_size:
		var ev: Dictionary = dc.pick_event()
		var eid: String = str(ev.get("id", ""))
		assert_false(seen.has(eid), "同一ラン内で event が重複: %s" % eid)
		seen[eid] = true
	var fallback: Dictionary = dc.pick_event()
	assert_false(fallback.is_empty(), "枯渇後フォールバックで抽選できる")

func test_mourngate_material_event_resolves_enhancement_id() -> void:
	var dc: Node = _make_controller("mourngate")
	var outcome: Dictionary = dc.resolve_event_outcome({
		"type": "material",
		"material_id": "relic_shard",
		"discovery_id": "relic_shard",
		"amount": 1,
	})
	var mat_id: String = str(outcome.get("material_id", ""))
	assert_has(EquipmentEnhancer.EVENT_DROP_MATERIAL_IDS, mat_id)
	assert_eq(str(outcome.get("label", "")), DataRegistry.get_material_name(mat_id))

func test_whisperwood_material_keeps_relic_shard() -> void:
	var dc: Node = _make_controller("whisperwood")
	var outcome: Dictionary = dc.resolve_event_outcome({
		"type": "material",
		"material_id": "relic_shard",
		"discovery_id": "relic_shard",
		"amount": 1,
		"label": "沼澱の試料",
	})
	assert_eq(str(outcome.get("material_id", "")), "relic_shard")
	assert_eq(str(outcome.get("label", "")), DataRegistry.get_material_name("relic_shard"))

func test_room_roll_only_allows_supported_non_combat_types() -> void:
	for trial_seed: int in [1, 7, 42, 99, 12345]:
		seed(trial_seed)
		var dc: Node = _make_controller("mourngate")
		dc.start_stage("mourngate_1_3")
		var allowed: Array[int] = [
			Enums.RoomType.COMBAT,
			Enums.RoomType.ELITE,
			Enums.RoomType.HEAL,
			Enums.RoomType.EVENT,
			Enums.RoomType.TREASURE,
			Enums.RoomType.TRAP,
		]
		for rt: int in dc.room_sequence:
			assert_true(rt in allowed, "seed=%d 未対応部屋: %d" % [trial_seed, rt])
