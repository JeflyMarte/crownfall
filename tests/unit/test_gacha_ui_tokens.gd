extends GutTest

## 招待状 UI polish（GachaUiTokens）— headless 検証。

func test_gacha_ui_asset_paths_exist() -> void:
	for key in [
		GachaUiTokens.BG,
		GachaUiTokens.BANNER_BG,
		GachaUiTokens.BANNER_TITLE,
		GachaUiTokens.BANNER_CATCHCOPY_ART,
		GachaUiTokens.FEATURED_BEAM,
		GachaUiTokens.FEATURED_MOTE,
		GachaUiTokens.ORNAMENT_DIAMOND,
		GachaUiTokens.ICO_BACK,
		GachaUiTokens.SECTION_RULE,
		GachaUiTokens.BANNER_FRAME,
		GachaUiTokens.BTN_1PULL,
		GachaUiTokens.BTN_1PULL_DISABLED,
		GachaUiTokens.LINEUP_CELL,
		GachaUiTokens.PANEL_DARK,
		GachaUiTokens.BTN_DETAIL,
		GachaUiTokens.ICO_TOKEN,
		GachaUiTokens.REVEAL_FRAME,
	]:
		assert_true(ResourceLoader.exists(key), "missing gacha chrome: %s" % key)

func test_pull_styles_use_texture() -> void:
	var enabled: StyleBox = GachaUiTokens.pull_1_style()
	assert_true(enabled is StyleBoxTexture)
	assert_not_null((enabled as StyleBoxTexture).texture)

func test_decorate_title_uses_screen_title() -> void:
	var lbl := Label.new()
	lbl.text = GachaUiTokens.SCREEN_TITLE
	GachaUiTokens.decorate_title(lbl)
	assert_true(lbl.text.begins_with(UiTypography.TITLE_ORNAMENT_LEFT.strip_edges()))
	assert_true(lbl.text.ends_with(UiTypography.TITLE_ORNAMENT_RIGHT.strip_edges()))

func test_banner_copy_constants() -> void:
	assert_eq(GachaUiTokens.SCREEN_TITLE, "ギルドへの招待状")
	assert_eq(GachaUiTokens.LINEUP_SECTION_TITLE, "招きの候補")
	assert_eq(GachaUiTokens.BANNER_CATCHCOPY, "各地の探索者へ、ギルドからの招き")
