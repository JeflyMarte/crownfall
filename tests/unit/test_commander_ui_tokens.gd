extends GutTest

const _CommanderUiTokens = preload("res://scripts/commander/CommanderUiTokens.gd")

## 隊長台帳 UI chrome（CommanderUiTokens）— headless 検証。

func test_commander_ui_asset_paths_exist() -> void:
	for key in [
		_CommanderUiTokens.BG,
		_CommanderUiTokens.ORNAMENT_DIAMOND,
		_CommanderUiTokens.ICO_BACK,
		_CommanderUiTokens.SECTION_RULE,
		_CommanderUiTokens.BTN_RENAME,
		_CommanderUiTokens.BTN_RENAME_DISABLED,
		_CommanderUiTokens.BTN_CLAIM_ALL,
		_CommanderUiTokens.BTN_CLAIM,
		_CommanderUiTokens.BTN_FORGE,
		_CommanderUiTokens.BTN_CODEX,
		_CommanderUiTokens.BTN_CLEAR_TITLE,
		_CommanderUiTokens.BTN_CLEAR_TITLE_DISABLED,
		_CommanderUiTokens.BTN_DAILY_CLAIM,
		_CommanderUiTokens.BTN_DAILY_DONE,
		_CommanderUiTokens.BTN_DAILY_MOVE,
	]:
		assert_true(ResourceLoader.exists(key), "missing commander chrome: %s" % key)

func test_commander_button_styles_use_texture() -> void:
	for styles in [
		_CommanderUiTokens.rename_button_styles(),
		_CommanderUiTokens.claim_all_button_styles(),
		_CommanderUiTokens.claim_button_styles(),
		_CommanderUiTokens.forge_shortcut_button_styles(),
		_CommanderUiTokens.codex_shortcut_button_styles(),
		_CommanderUiTokens.clear_title_button_styles(),
		_CommanderUiTokens.daily_button_styles("claim"),
	]:
		for key in ["normal", "disabled"]:
			var sb: StyleBox = styles[key]
			assert_true(sb is StyleBoxTexture, key)
			assert_not_null((sb as StyleBoxTexture).texture, key)
