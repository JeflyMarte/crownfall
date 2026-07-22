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
		ForgeUiTokens.BTN_PRODUCE_DISABLED,
		ForgeUiTokens.BTN_DISMANTLE,
		ForgeUiTokens.BTN_DISMANTLE_DISABLED,
		ForgeUiTokens.BTN_BULK_DISMANTLE,
		ForgeUiTokens.BTN_BULK_DISMANTLE_DISABLED,
		ForgeUiTokens.BTN_ENHANCE,
		ForgeUiTokens.BTN_ENHANCE_DISABLED,
		ForgeUiTokens.TITLE_COMPLETE,
		ForgeUiTokens.RESULT_PANEL,
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

func test_material_chip_style_uses_rarity_inv_frame() -> void:
	var common: StyleBox = BlacksmithUiHelper.material_chip_style(0, true, 64)
	var rare: StyleBox = BlacksmithUiHelper.material_chip_style(1, true, 64)
	assert_true(common is StyleBoxTexture)
	assert_true(rare is StyleBoxTexture)
	assert_not_null((common as StyleBoxTexture).texture)
	assert_not_null((rare as StyleBoxTexture).texture)

func test_material_chip_style_for_id() -> void:
	var sb: StyleBox = BlacksmithUiHelper.material_chip_style_for_id("elite_relic_shard", true, 64)
	assert_true(sb is StyleBoxTexture)
	assert_not_null((sb as StyleBoxTexture).texture)

func test_produce_button_styles_use_texture() -> void:
	var styles: Dictionary = ForgeUiTokens.produce_button_styles()
	for key in ["normal", "disabled"]:
		var sb: StyleBox = styles[key]
		assert_true(sb is StyleBoxTexture, key)
		assert_not_null((sb as StyleBoxTexture).texture, key)

	var common: Color = BlacksmithUiHelper.rarity_name_color(0)
	var rare: Color = BlacksmithUiHelper.rarity_name_color(1)
	assert_ne(common, rare)

func test_decorate_title_adds_diamond_ornament() -> void:
	var lbl := Label.new()
	lbl.text = "鍛冶屋"
	ForgeUiTokens.decorate_title(lbl)
	assert_eq(lbl.text, "◆ 鍛冶屋 ◆")

func test_forge_item_icon_inset_matches_equipment_policy() -> void:
	var cell_px: int = BlacksmithUiHelper.list_cell_px()
	var forge_inset: int = BlacksmithUiHelper.item_icon_inset_px(cell_px)
	var equip_inset: int = EquipmentUiTokens.icon_inset_px(
		cell_px, EquipmentUiTokens.INV_CELL_DESIGN_PX
	)
	assert_eq(forge_inset, equip_inset)
	assert_gte(cell_px, EquipmentUiTokens.INV_CELL_PX)
	assert_lt(BlacksmithUiHelper.list_icon_px(), cell_px)


func test_forge_list_icon_stays_inside_safe_fill() -> void:
	## 再発防止: 弓でも safe_fill を超えて左右にはみ出さない。
	var cell_px: int = BlacksmithUiHelper.list_icon_px()
	var inset: int = BlacksmithUiHelper.item_icon_inset_px(cell_px)
	var bow_shrunk: int = maxi(
		2, int(round(float(inset) * EquipmentUiTokens.BOW_ICON_INSET_SCALE))
	)
	## 旧バグ: 弓 inset 縮小だけだと side が枠クロムを超える。
	var unsafe_side: int = cell_px - bow_shrunk * 2
	var safe_side: int = BlacksmithUiHelper.forge_icon_side_px(cell_px, inset)
	assert_lte(float(safe_side), float(cell_px) * BlacksmithUiHelper.FORGE_ICON_SAFE_FILL + 0.001)
	assert_lt(safe_side, unsafe_side)

	var cell: Control = BlacksmithUiHelper.make_item_icon_cell(
		"hunting_bow", "weapon", 1, cell_px, false
	)
	assert_eq(cell.size_flags_horizontal, Control.SIZE_SHRINK_BEGIN)
	assert_eq(cell.size_flags_vertical, Control.SIZE_SHRINK_CENTER)
	assert_eq(cell.custom_minimum_size.x, float(cell_px))
	assert_true(cell.clip_contents)
	var icon: TextureRect = cell.find_child("ItemIcon", true, false) as TextureRect
	assert_not_null(icon)
	## FULL_RECT＋対称 inset。描画幅は cell - 2*inset。
	var draw_inset: float = icon.offset_left
	var icon_w: float = float(cell_px) - draw_inset * 2.0
	assert_lte(icon_w, float(cell_px) * BlacksmithUiHelper.FORGE_ICON_SAFE_FILL + 0.001)
	assert_lte(icon_w, float(safe_side) + 0.001)
	assert_gte(draw_inset, 0.0)
	cell.free()


func test_forge_list_row_keeps_icon_inside_scroll_width() -> void:
	## 長い装備名でも行最小幅が LeftScroll 想定幅を超えないこと。
	var scroll_w: float = 228.0
	var cell_px: int = BlacksmithUiHelper.list_icon_px()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.custom_minimum_size = Vector2(scroll_w, BlacksmithUiHelper.LIST_CARD_MIN_HEIGHT)
	var icon: Control = BlacksmithUiHelper.make_item_icon_cell(
		"verdia_longbow", "weapon", 2, cell_px, false
	)
	row.add_child(icon)
	var name_lbl := Label.new()
	name_lbl.text = "ヴェルディア長弓 Lv.1"
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_lbl.max_lines_visible = 1
	name_lbl.clip_text = true
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_lbl)
	add_child(row)
	await get_tree().process_frame
	assert_lte(icon.get_combined_minimum_size().x, float(cell_px) + 0.001)
	## 省略ありなら Label 最小幅は全文幅より小さくなる（行が scroll に収まる前提）。
	assert_lt(name_lbl.get_combined_minimum_size().x, 200.0)
	assert_lte(row.get_combined_minimum_size().x, scroll_w + 1.0)
	row.free()


func test_forge_icon_cell_is_not_panel_container() -> void:
	## PanelContainer+content_margin 押し合いの再発を防ぐ。
	var cell: Control = BlacksmithUiHelper.make_item_icon_cell(
		"apprentice_staff", "weapon", 0, BlacksmithUiHelper.list_icon_px(), false
	)
	assert_false(cell is PanelContainer)
	assert_eq(cell.name, "ForgeItemIconCell")
	cell.free()


func test_forge_list_icon_uses_flat_frame_at_list_size() -> void:
	## 小さいセルは InvCell 9-slice ではなく Flat 四辺枠（左欠け見え防止）。
	var cell: Control = BlacksmithUiHelper.make_item_icon_cell(
		"iron_sword", "weapon", 1, BlacksmithUiHelper.list_icon_px(), false
	)
	var sb: StyleBox = cell.get_theme_stylebox("normal")
	assert_true(sb is StyleBoxFlat)
	cell.free()
	var big: Control = BlacksmithUiHelper.make_item_icon_cell(
		"iron_sword", "weapon", 1, BlacksmithUiHelper.list_cell_px(), false
	)
	var big_sb: StyleBox = big.get_theme_stylebox("normal")
	assert_true(big_sb is StyleBoxTexture)
	big.free()

func test_bow_display_texture_is_cropped() -> void:
	var src: Texture2D = load("res://assets/ui/equipment/ICO_WPN_HuntingBow.png") as Texture2D
	assert_not_null(src)
	var shown: Texture2D = IconPaths.display_texture_for_weapon("hunting_bow", src)
	assert_true(shown is AtlasTexture)
	var atlas: AtlasTexture = shown as AtlasTexture
	assert_lt(atlas.region.size.x, float(src.get_width()))
	assert_lt(atlas.region.size.y, float(src.get_height()))
	# IconPaths.get_icon_texture 経由でも同じ扱いになること
	var via_map: Texture2D = IconPaths.get_icon_texture("hunting_bow", "weapon")
	assert_true(via_map is AtlasTexture)
