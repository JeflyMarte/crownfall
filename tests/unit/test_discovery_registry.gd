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
