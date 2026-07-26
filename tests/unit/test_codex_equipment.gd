extends GutTest

## 図鑑: ダンジョンオミット＋装備品タブ（P3-CODEX-DG-OMIT / EQ-001）。

const _CodexScene := preload("res://scripts/codex/CodexScene.gd")


func test_codex_dungeon_playable_flag_default_off() -> void:
	assert_false(Constants.CODEX_DUNGEON_PLAYABLE, "図鑑ダンジョンタブはオミット")


func test_playable_categories_omit_dungeon_include_equipment() -> void:
	var cats: Array[String] = _CodexScene.playable_categories()
	assert_false(cats.has("dungeon"))
	assert_true(cats.has("equipment"))
	assert_false(cats.has("weapon"), "カテゴリキーは equipment")


func test_equipment_entries_cover_weapon_armor_accessory() -> void:
	var entries: Array = CatalogHelper.get_equipment_entries()
	assert_gt(entries.size(), 50, "装備品が十分な件数ある")
	var kinds: Dictionary = {}
	var discovered_n: int = 0
	for e: Dictionary in entries:
		assert_true(bool(e.get("discovered", false)), "装備品は常時開示（説明対象）")
		assert_false(str(e.get("description", "")).is_empty(), "説明文がある: %s" % e.get("id"))
		var kind: String = str(e.get("equip_kind", ""))
		kinds[kind] = true
		discovered_n += 1
		assert_true(str(e.get("list_label", "")).begins_with("【"), "種別プレフィックス")
	assert_true(kinds.has("weapon"), "武器を含む")
	assert_true(kinds.has("armor"), "防具を含む")
	assert_true(kinds.has("accessory"), "装飾を含む")
	assert_eq(discovered_n, entries.size())


func test_equipment_description_builders() -> void:
	const _Content := preload("res://scripts/codex/CodexContentHelper.gd")
	var weapon: Resource = DataRegistry.get_all_weapon_data()[0]
	var armor: Resource = DataRegistry.get_all_armor_data()[0]
	var acc: Resource = DataRegistry.get_all_accessory_data()[0]
	assert_false(_Content.build_weapon_description(weapon).is_empty())
	assert_true(_Content.build_armor_description(armor).contains("防具"))
	assert_true(_Content.build_accessory_description(acc).contains("装飾"))


func test_guide_world010_mentions_equipment_not_dungeon_tab() -> void:
	var desc: String = ""
	for entry: Dictionary in GuideCatalog.get_world_entries():
		if str(entry.get("id", "")) == "WORLD-G010":
			desc = str(entry.get("description", ""))
			break
	assert_false(desc.is_empty())
	assert_true(desc.contains("装備品"), "図鑑案内に装備品")
	assert_false(desc.contains("ダンジョンの概要"), "ダンジョン概要案内は撤去")
