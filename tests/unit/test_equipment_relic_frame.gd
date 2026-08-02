extends GutTest
## レリック専用 InvCell フレーム（装備一覧／スロット）。


func test_relic_inv_cell_asset_exists() -> void:
	assert_true(
		ResourceLoader.exists("res://assets/ui/equipment_ui/UI_Equip_InvCell_RELIC.png"),
		"UI_Equip_InvCell_RELIC.png should exist"
	)


func test_relic_cell_style_uses_dedicated_texture() -> void:
	var sb: StyleBox = EquipmentUiTokens.relic_cell_style(false, EquipmentUiTokens.INV_CELL_DESIGN_PX)
	assert_not_null(sb)
	assert_true(sb is StyleBoxTexture, "relic_cell_style should be StyleBoxTexture")
	var tex_sb: StyleBoxTexture = sb as StyleBoxTexture
	assert_not_null(tex_sb.texture)
	## EPIC 紫枠への誤配線でないこと。
	var epic: StyleBox = EquipmentUiTokens.inv_cell_style(Enums.Rarity.EPIC)
	assert_true(epic is StyleBoxTexture)
	assert_ne(
		(tex_sb.texture as Texture2D),
		((epic as StyleBoxTexture).texture as Texture2D)
	)


func test_relic_inv_cell_fill_is_not_white() -> void:
	## 白マット下地のまま出さない（他レア InvCell と同じ暗い fill）。
	var tex: Texture2D = load("res://assets/ui/equipment_ui/UI_Equip_InvCell_RELIC.png") as Texture2D
	assert_not_null(tex)
	var img: Image = tex.get_image()
	assert_not_null(img)
	var c: Color = img.get_pixel(tex.get_width() / 2, tex.get_height() / 2)
	assert_lt(c.r, 0.55, "relic center should not be white fill")
	assert_lt(c.g, 0.55, "relic center should not be white fill")
	assert_lt(c.b, 0.55, "relic center should not be white fill")
