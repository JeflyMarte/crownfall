extends GutTest

## 編成 CHR 肖像が選択・巨大テクスチャでも原寸（~1254）へ逃げないこと。


func test_clamped_portrait_min_size_never_exceeds_hard_max() -> void:
	var tex := ImageTexture.create_from_image(Image.create(1254, 1254, false, Image.FORMAT_RGBA8))
	var host: Control = RosterUiHelper.make_clamped_portrait(tex, 9999, true)
	assert_lte(host.custom_minimum_size.x, RosterUiHelper.portrait_hard_max_px())
	assert_lte(host.custom_minimum_size.y, RosterUiHelper.portrait_hard_max_px())
	assert_eq(host.custom_minimum_size.x, float(RosterUiHelper.portrait_hard_max_px()))
	assert_true(host.clip_contents)
	assert_eq(host.size_flags_horizontal, Control.SIZE_SHRINK_CENTER)
	assert_eq(host.size_flags_vertical, Control.SIZE_SHRINK_CENTER)
	var art := host.get_node_or_null("PortraitArt") as TextureRect
	assert_not_null(art)
	assert_eq(art.expand_mode, TextureRect.EXPAND_IGNORE_SIZE)
	assert_eq(art.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	host.free()


func test_pick_and_card_styles_share_margins() -> void:
	var card: StyleBoxFlat = RosterUiHelper.card_panel_style(true, false) as StyleBoxFlat
	var pick: StyleBoxFlat = RosterUiHelper.pick_panel_style()
	assert_not_null(card)
	assert_eq(pick.content_margin_left, card.content_margin_left)
	assert_eq(pick.content_margin_top, card.content_margin_top)
	assert_eq(pick.content_margin_right, card.content_margin_right)
	assert_eq(pick.content_margin_bottom, card.content_margin_bottom)
	assert_eq(pick.get_border_width(SIDE_LEFT), card.get_border_width(SIDE_LEFT))
	assert_eq(pick.get_border_width(SIDE_TOP), card.get_border_width(SIDE_TOP))
