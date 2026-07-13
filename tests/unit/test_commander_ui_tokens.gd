extends GutTest

const _CommanderUiTokens = preload("res://scripts/commander/CommanderUiTokens.gd")

## 隊長台帳 UI chrome（背景・装飾）— headless 検証。

func test_commander_ui_asset_paths_exist() -> void:
	for key in [
		_CommanderUiTokens.BG,
		_CommanderUiTokens.ORNAMENT_DIAMOND,
		_CommanderUiTokens.ICO_BACK,
		_CommanderUiTokens.SECTION_RULE,
		_CommanderUiTokens.RANK_ICON_D,
		_CommanderUiTokens.RANK_ICON_C,
		_CommanderUiTokens.RANK_ICON_B,
		_CommanderUiTokens.RANK_ICON_A,
	]:
		assert_true(ResourceLoader.exists(key), "missing commander chrome: %s" % key)


func test_rank_icon_resolves_for_d_through_a() -> void:
	for code in ["D", "C", "B", "A"]:
		var tex: Texture2D = _CommanderUiTokens.rank_icon(code)
		assert_not_null(tex, "rank icon missing for %s" % code)
	# S は未配置時 null（文字フォールバック）
	if ResourceLoader.exists(_CommanderUiTokens.RANK_ICON_S):
		assert_not_null(_CommanderUiTokens.rank_icon("S"))
	else:
		assert_null(_CommanderUiTokens.rank_icon("S"))
