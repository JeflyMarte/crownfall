extends GutTest

## 召喚所 UI helper（GachaUiHelper）— headless 検証。

func test_sorted_helpers_non_empty() -> void:
	var helpers: Array = GachaUiHelper.sorted_helpers()
	assert_gt(helpers.size(), 0)

func test_catchcopy_normal_tab() -> void:
	assert_eq(
		GachaUiHelper.catchcopy_for_tab(GachaUiTokens.ACTIVE_TAB_INDEX),
		"王国の未来を担う新たな英雄たち"
	)

func test_pull_cost_amount() -> void:
	assert_eq(GachaUiHelper.pull_cost_amount(1), GachaSystem.PULL_COST)
	assert_eq(GachaUiHelper.pull_cost_amount(10), GachaSystem.PULL_COST * 10)

func test_banner_portrait_textures_caps_at_three() -> void:
	var textures: Array[Texture2D] = GachaUiHelper.banner_portrait_textures()
	assert_lte(textures.size(), GachaUiHelper.BANNER_PORTRAIT_MAX)

func test_make_lineup_row_has_name() -> void:
	var helpers: Array = GachaUiHelper.sorted_helpers()
	if helpers.is_empty():
		return
	var row: PanelContainer = GachaUiHelper.make_lineup_row(helpers[0])
	assert_not_null(row)
	assert_gt(row.get_child_count(), 0)
