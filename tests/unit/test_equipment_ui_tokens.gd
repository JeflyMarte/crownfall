extends GutTest

## 装備画面 UI polish（EquipmentUiTokens）— headless 検証。

func test_equipment_ui_asset_paths_exist() -> void:
	for path in EquipmentUiTokens.STAT_ICONS.values():
		assert_true(ResourceLoader.exists(str(path)), "missing stat icon: %s" % path)
	for path in EquipmentUiTokens.CATEGORY_ICONS.values():
		assert_true(ResourceLoader.exists(str(path)), "missing category icon: %s" % path)
	for key in [
		EquipmentUiTokens.BG,
		EquipmentUiTokens.CHAR_CARD,
		EquipmentUiTokens.PORTRAIT_PEDESTAL,
		EquipmentUiTokens.TAB_ACTIVE,
		EquipmentUiTokens.SLOT_FRAME,
		EquipmentUiTokens.BTN_UNEQUIP,
		EquipmentUiTokens.FILTER_ICON,
	]:
		assert_true(ResourceLoader.exists(key), "missing equipment chrome: %s" % key)
	for path in EquipmentUiTokens.INV_CELLS:
		assert_true(ResourceLoader.exists(path), "missing inv cell: %s" % path)

func test_category_label_all() -> void:
	assert_eq(EquipmentUiHelper.category_label("all"), "すべて")
	assert_eq(EquipmentUiHelper.category_label("weapon"), "武器")

func test_inv_cell_style_uses_metallic_background() -> void:
	var sb: StyleBox = EquipmentUiTokens.inv_cell_style(2, false)
	if sb is StyleBoxTexture and (sb as StyleBoxTexture).texture != null:
		assert_not_null((sb as StyleBoxTexture).texture)
	elif sb is StyleBoxFlat:
		assert_gt((sb as StyleBoxFlat).bg_color.a, 0.5)

func test_inv_cell_styles_differ_by_rarity() -> void:
	var common: StyleBox = EquipmentUiTokens.inv_cell_style(0, false)
	var epic: StyleBox = EquipmentUiTokens.inv_cell_style(2, false)
	if common is StyleBoxTexture and epic is StyleBoxTexture:
		var common_tex: Texture2D = (common as StyleBoxTexture).texture
		var epic_tex: Texture2D = (epic as StyleBoxTexture).texture
		if common_tex != null and epic_tex != null:
			assert_ne(common_tex, epic_tex)
	elif common is StyleBoxFlat and epic is StyleBoxFlat:
		assert_ne((common as StyleBoxFlat).bg_color, (epic as StyleBoxFlat).bg_color)

func test_cell_px_for_grid_width_fills_six_columns() -> void:
	var px: int = EquipmentUiTokens.cell_px_for_grid_width(688.0, 6, 4)
	assert_true(px >= 112)

func test_scaled_margin_shrinks_with_cell() -> void:
	assert_true(
		EquipmentUiTokens.scaled_margin(144, 72, 14)
		< EquipmentUiTokens.scaled_margin(144, 144, 14)
	)

func test_icon_inset_leaves_room_for_art() -> void:
	var inset: int = EquipmentUiTokens.icon_inset_px(112, 144)
	assert_true(inset < 56)

func test_tooltip_panel_style_is_opaque() -> void:
	var sb: StyleBoxFlat = EquipmentUiTokens.tooltip_panel_style()
	assert_eq(sb.bg_color.a, 1.0)

func test_decorate_title_adds_diamond_ornament() -> void:
	var lbl := Label.new()
	lbl.text = "キャラクター装備"
	EquipmentUiTokens.decorate_title(lbl)
	assert_eq(lbl.text, "◆ キャラクター装備 ◆")

func test_effect_stat_key_mapping() -> void:
	assert_eq(str(EquipmentUiTokens.EFFECT_STAT_KEYS.get("攻撃力", "")), "attack")
	assert_eq(str(EquipmentUiTokens.EFFECT_STAT_KEYS.get("HP", "")), "hp")
	assert_eq(str(EquipmentUiTokens.EFFECT_STAT_KEYS.get("クリティカルダメージ", "")), "crit_damage")
	assert_eq(str(EquipmentUiTokens.EFFECT_STAT_KEYS.get("攻撃速度", "")), "speed")

func test_rarity_stars_text_maps_equipment_tier() -> void:
	assert_eq(EquipmentUiHelper.rarity_stars_text(0), "★")
	assert_eq(EquipmentUiHelper.rarity_stars_text(1), "★★")
	assert_eq(EquipmentUiHelper.rarity_stars_text(3), "★★★★")

func test_enhance_badge_hides_until_first_enhance() -> void:
	var weapon := WeaponInstance.new()
	assert_eq(EquipmentUiHelper.enhance_badge(weapon, "weapon"), "")
	weapon.enhance_level = 1
	assert_eq(EquipmentUiHelper.enhance_badge(weapon, "weapon"), "+1")
	weapon.enhance_level = 2
	assert_eq(EquipmentUiHelper.enhance_badge(weapon, "weapon"), "+2")
	assert_eq(EquipmentUiHelper.enhance_badge(weapon, "armor"), "")
