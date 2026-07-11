extends GutTest

## 鍛冶屋 UI polish（ForgeUiTokens / BlacksmithUiHelper）— headless 検証。

func test_forge_ui_asset_paths_exist() -> void:
	for path in ForgeUiTokens.STAT_ICONS.values():
		assert_true(ResourceLoader.exists(str(path)), "missing stat icon: %s" % path)
	for path in ForgeUiTokens.CATEGORY_ICONS.values():
		assert_true(ResourceLoader.exists(str(path)), "missing category icon: %s" % path)
	for key in [
		ForgeUiTokens.ORNAMENT_DIAMOND,
		ForgeUiTokens.ICO_BACK,
		ForgeUiTokens.ANVIL_PANEL,
		ForgeUiTokens.HERO_GLOW,
		ForgeUiTokens.HERO_ITEM_BG,
		ForgeUiTokens.TAB_ACTIVE,
		ForgeUiTokens.LIST_CARD_NORMAL,
		ForgeUiTokens.LIST_CARD_SELECTED,
		ForgeUiTokens.ITEM_CELL_NORMAL,
		ForgeUiTokens.ITEM_CELL_SELECTED,
		ForgeUiTokens.CRAFT_CHIP_NORMAL,
		ForgeUiTokens.CRAFT_CHIP_SELECTED,
		ForgeUiTokens.MATERIAL_CELL,
		ForgeUiTokens.BTN_PRODUCE,
	]:
		assert_true(ResourceLoader.exists(key), "missing forge chrome: %s" % key)
	for path in ForgeUiTokens.ITEM_CELLS_RARITY:
		assert_true(ResourceLoader.exists(path), "missing rarity cell: %s" % path)

func test_item_cell_style_uses_texture() -> void:
	var sb: StyleBox = ForgeUiTokens.item_cell_style(2, false)
	assert_true(sb is StyleBoxTexture)
	assert_not_null((sb as StyleBoxTexture).texture)

func test_list_card_normal_style_uses_texture() -> void:
	var sb: StyleBox = ForgeUiTokens.list_card_normal_style()
	assert_true(sb is StyleBoxTexture)
	assert_not_null((sb as StyleBoxTexture).texture)

func test_rarity_box_uses_texture_when_assets_present() -> void:
	var sb: StyleBox = BlacksmithUiHelper.rarity_box(1, false)
	assert_true(sb is StyleBoxTexture)
	assert_not_null((sb as StyleBoxTexture).texture)

func test_craft_stat_entries_weapon_includes_atk() -> void:
	var craft: Resource = DataRegistry.get_craft_data("craft_iron_sword")
	assert_not_null(craft)
	var entries: Array = BlacksmithUiHelper.craft_stat_entries(craft)
	assert_gt(entries.size(), 0)
	assert_eq(str(entries[0].get("key", "")), "atk")
	assert_eq(str(entries[0].get("label", "")), "攻撃力")

func test_craft_stat_entries_armor_includes_def() -> void:
	var craft: Resource = DataRegistry.get_craft_data("craft_leather_armor")
	assert_not_null(craft)
	var entries: Array = BlacksmithUiHelper.craft_stat_entries(craft)
	assert_gt(entries.size(), 0)
	assert_eq(str(entries[0].get("key", "")), "def")

func test_output_subtitle_weapon_has_type_label() -> void:
	var craft: Resource = DataRegistry.get_craft_data("craft_iron_sword")
	assert_not_null(craft)
	var sub: String = BlacksmithUiHelper.output_subtitle(craft)
	assert_true(sub.begins_with("装備種別:"))

func test_list_card_selected_style_uses_texture_when_available() -> void:
	var sb: StyleBox = ForgeUiTokens.list_card_selected_style()
	assert_true(sb is StyleBoxTexture)
	assert_not_null((sb as StyleBoxTexture).texture)

func test_material_chip_style_uses_normal_inv_frame() -> void:
	var sb: StyleBox = BlacksmithUiHelper.material_chip_style(true, 64)
	assert_true(sb is StyleBoxTexture)
	assert_not_null((sb as StyleBoxTexture).texture)

func test_rarity_name_color_follows_rarity() -> void:
	var common: Color = BlacksmithUiHelper.rarity_name_color(0)
	var rare: Color = BlacksmithUiHelper.rarity_name_color(1)
	assert_ne(common, rare)

func test_decorate_title_adds_diamond_ornament() -> void:
	var lbl := Label.new()
	lbl.text = "鍛冶屋"
	ForgeUiTokens.decorate_title(lbl)
	assert_eq(lbl.text, "◆ 鍛冶屋 ◆")
