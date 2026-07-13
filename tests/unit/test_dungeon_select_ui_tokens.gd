extends GutTest

const _DungeonSelectUiTokens = preload("res://scripts/dungeon/DungeonSelectUiTokens.gd")

func test_dungeon_select_ui_asset_paths_exist() -> void:
	for key in [
		_DungeonSelectUiTokens.BTN_DEPART,
		_DungeonSelectUiTokens.BTN_DEPART_DISABLED,
		_DungeonSelectUiTokens.BTN_SELECT,
		_DungeonSelectUiTokens.BTN_SELECT_DISABLED,
		_DungeonSelectUiTokens.BTN_CONFIRM_YES,
		_DungeonSelectUiTokens.BTN_CONFIRM_YES_DISABLED,
		_DungeonSelectUiTokens.BTN_CONFIRM_NO,
		_DungeonSelectUiTokens.BTN_CONFIRM_NO_DISABLED,
		_DungeonSelectUiTokens.ICO_BACK,
	]:
		assert_true(ResourceLoader.exists(key), "missing dungeon select chrome: %s" % key)

func test_depart_button_styles_use_texture() -> void:
	var styles: Dictionary = _DungeonSelectUiTokens.depart_button_styles()
	for key in ["normal", "disabled"]:
		var sb: StyleBox = styles[key]
		assert_true(sb is StyleBoxTexture, key)
		assert_not_null((sb as StyleBoxTexture).texture, key)

func test_select_button_styles_use_texture() -> void:
	var styles: Dictionary = _DungeonSelectUiTokens.select_button_styles()
	for key in ["normal", "disabled"]:
		var sb: StyleBox = styles[key]
		assert_true(sb is StyleBoxTexture, key)
		assert_not_null((sb as StyleBoxTexture).texture, key)
