extends GutTest

const _MaterialUiTokens = preload("res://scripts/equipment/MaterialUiTokens.gd")
const _EquipmentEnhancer = preload("res://scripts/equipment/EquipmentEnhancer.gd")

func test_material_rarity_ssot_values() -> void:
	assert_eq(_EquipmentEnhancer.material_rarity("relic_shard"), Enums.Rarity.COMMON)
	assert_eq(_EquipmentEnhancer.material_rarity("ancient_bone"), Enums.Rarity.RARE)
	assert_eq(_EquipmentEnhancer.material_rarity("elite_relic_shard"), Enums.Rarity.EPIC)

func test_cell_styles_differ_by_rarity() -> void:
	var common: StyleBox = _MaterialUiTokens.cell_style(0, false, 64)
	var epic: StyleBox = _MaterialUiTokens.cell_style(2, false, 64)
	assert_not_null(common)
	assert_not_null(epic)
	if common is StyleBoxTexture and epic is StyleBoxTexture:
		assert_ne(
			(common as StyleBoxTexture).texture,
			(epic as StyleBoxTexture).texture,
			"N vs SR cell textures should differ"
		)

func test_forge_display_names_have_no_rare_prefix() -> void:
	for name in _EquipmentEnhancer.forge_material_display_names():
		assert_false(str(name).begins_with("【希少】"), "prefix removed: %s" % name)

func test_make_icon_cell_has_panel_child() -> void:
	var cell: PanelContainer = _MaterialUiTokens.make_icon_cell("relic_shard", 48, true)
	assert_not_null(cell)
	assert_gte(cell.get_child_count(), 1)
