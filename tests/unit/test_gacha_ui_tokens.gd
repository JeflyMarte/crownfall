extends GutTest

## 召喚所 UI polish（GachaUiTokens）— headless 検証。

func test_gacha_ui_asset_paths_exist() -> void:
	for key in [
		GachaUiTokens.BG,
		GachaUiTokens.ORNAMENT_DIAMOND,
		GachaUiTokens.ICO_BACK,
		GachaUiTokens.SECTION_RULE,
		GachaUiTokens.TAB_ACTIVE,
		GachaUiTokens.TAB_INACTIVE,
		GachaUiTokens.BANNER_FRAME,
		GachaUiTokens.PITY_BAR_BG,
		GachaUiTokens.PITY_BAR_FILL,
		GachaUiTokens.BTN_1PULL,
		GachaUiTokens.BTN_10PULL_DISABLED,
		GachaUiTokens.RIBBON_SR,
		GachaUiTokens.LINEUP_CELL,
		GachaUiTokens.PANEL_DARK,
		GachaUiTokens.BTN_DETAIL,
		GachaUiTokens.ICO_TOKEN,
		GachaUiTokens.REVEAL_FRAME,
	]:
		assert_true(ResourceLoader.exists(key), "missing gacha chrome: %s" % key)

func test_tab_styles_use_texture() -> void:
	var active: StyleBox = GachaUiTokens.tab_active_style()
	var inactive: StyleBox = GachaUiTokens.tab_inactive_style()
	assert_true(active is StyleBoxTexture)
	assert_true(inactive is StyleBoxTexture)
	assert_not_null((active as StyleBoxTexture).texture)
	assert_not_null((inactive as StyleBoxTexture).texture)

func test_pity_helpers() -> void:
	assert_almost_eq(GachaUiTokens.pity_ratio(15, 30), 0.5, 0.001)
	assert_eq(GachaUiTokens.pity_caption(15, 30), "天井まで 15 / 30 連（未所持確定）")

func test_decorate_title_uses_screen_title() -> void:
	var lbl := Label.new()
	lbl.text = GachaUiTokens.SCREEN_TITLE
	GachaUiTokens.decorate_title(lbl)
	assert_true(lbl.text.begins_with(UiTypography.TITLE_ORNAMENT_LEFT.strip_edges()))
	assert_true(lbl.text.ends_with(UiTypography.TITLE_ORNAMENT_RIGHT.strip_edges()))

func test_active_tab_index_is_normal() -> void:
	assert_eq(GachaUiTokens.ACTIVE_TAB_INDEX, 2)
	assert_eq(GachaUiTokens.TAB_LABELS[GachaUiTokens.ACTIVE_TAB_INDEX], "ノーマル")

func test_ten_pull_ribbon_text() -> void:
	assert_eq(GachaUiTokens.TEN_PULL_RIBBON_TEXT, "★3以上1体確定")
