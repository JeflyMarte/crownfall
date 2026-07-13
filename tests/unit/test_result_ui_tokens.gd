extends GutTest

const _ResultUiTokens = preload("res://scripts/result/ResultUiTokens.gd")

func test_result_ui_asset_paths_exist() -> void:
	for key in [
		_ResultUiTokens.BTN_NEXT,
		_ResultUiTokens.BTN_NEXT_DISABLED,
		_ResultUiTokens.BTN_RETRY,
		_ResultUiTokens.BTN_RETRY_DISABLED,
		_ResultUiTokens.BTN_HOME,
		_ResultUiTokens.BTN_HOME_DISABLED,
	]:
		assert_true(ResourceLoader.exists(key), "missing result chrome: %s" % key)

func test_footer_button_styles_use_texture() -> void:
	for styles in [
		_ResultUiTokens.next_button_styles(),
		_ResultUiTokens.retry_button_styles(),
		_ResultUiTokens.home_button_styles(),
	]:
		for key in ["normal", "disabled"]:
			var sb: StyleBox = styles[key]
			assert_true(sb is StyleBoxTexture, key)
			assert_not_null((sb as StyleBoxTexture).texture, key)
