extends GutTest
## 図鑑登録トースト表示名。

const _DiscoveryRegistry = preload("res://scripts/discovery/DiscoveryRegistry.gd")
const _CatalogHelper = preload("res://scripts/codex/CatalogHelper.gd")
const _DungeonController = preload("res://scripts/dungeon/DungeonController.gd")


func test_lore_display_label_uses_japanese_title() -> void:
	var title: String = _CatalogHelper.get_lore_title("ancient_record")
	assert_false(title.is_empty())
	assert_eq(
		_DiscoveryRegistry.get_display_label("lore", "ancient_record"),
		title
	)
	assert_ne(_DiscoveryRegistry.get_display_label("lore", "ancient_record"), "ancient_record")


func test_event_display_name_uses_outcome_label() -> void:
	assert_eq(
		_DungeonController.get_event_display_name("faded_inscription"),
		"風化した記録"
	)


func test_unknown_internal_id_falls_back_to_unknown_label() -> void:
	assert_eq(_DiscoveryRegistry.get_display_label("lore", "missing_lore_id"), "不明")
	assert_eq(
		_DiscoveryRegistry.format_new_discovery("lore", "ancient_record"),
		"【新規発見】碑文 / %s" % _CatalogHelper.get_lore_title("ancient_record")
	)


func test_register_many_enemies_dedupes_and_skips_known() -> void:
	GameState.discovery_registry.clear()
	var first: Array[String] = _DiscoveryRegistry.register_many(
		"enemy", ["sepia_hound", "rune_roach", "sepia_hound"]
	)
	assert_eq(first.size(), 2)
	assert_true(first.has("sepia_hound"))
	assert_true(first.has("rune_roach"))
	assert_true(_DiscoveryRegistry.is_discovered("enemy", "sepia_hound"))
	assert_true(_DiscoveryRegistry.is_discovered("enemy", "rune_roach"))
	var second: Array[String] = _DiscoveryRegistry.register_many(
		"enemy", ["sepia_hound", "crystal_hedgehog"]
	)
	assert_eq(second.size(), 1)
	assert_eq(second[0], "crystal_hedgehog")


func test_armor_and_accessory_are_discoverable() -> void:
	GameState.discovery_registry.clear()
	assert_true(_DiscoveryRegistry.register("armor", "leather_armor"))
	assert_true(_DiscoveryRegistry.register("accessory", "silver_ring"))
	assert_eq(_DiscoveryRegistry.get_category_label("armor"), "防具")
	assert_eq(_DiscoveryRegistry.get_category_label("accessory"), "装飾")
	assert_ne(_DiscoveryRegistry.get_display_label("armor", "leather_armor"), "不明")
	assert_ne(_DiscoveryRegistry.get_display_label("accessory", "silver_ring"), "不明")
