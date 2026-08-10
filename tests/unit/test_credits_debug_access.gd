extends GutTest

## クレジット文面とデバッグ出荷ガード。

const _CreditsText = preload("res://scripts/settings/CreditsText.gd")
const _DebugAccess = preload("res://scripts/debug/DebugAccess.gd")
const _DebugFullUnlock = preload("res://scripts/debug/DebugFullUnlock.gd")


func test_credits_text_mentions_kenney_and_bgm() -> void:
	var body: String = _CreditsText.settings_body()
	assert_true(body.contains("Kenney"), "SE Kenney")
	assert_true(body.contains("BGM") or body.contains("オリジナル"), "BGM line")
	assert_true(body.contains("TomMusic") or body.contains("Fantasy"), "TomMusic pack")
	assert_false(body.contains("リポジトリ"), "プレイヤー向けにリポジトリ言及しない")
	assert_false(body.contains("ATTRIBUTION.md"), "プレイヤー向けに ATTRIBUTION パスを出さない")


func test_save_status_mentions_debug_only_when_debug_access() -> void:
	var _SettingsPrefs := preload("res://scripts/settings/SettingsPrefs.gd")
	var text: String = _SettingsPrefs.save_status_text()
	assert_true(text.begins_with("セーブ:"), "セーブ行")
	if _DebugAccess.is_allowed():
		assert_true(text.contains("本編"), "debug ビルドでは本編枠を表示")
	else:
		assert_false(text.contains("デバッグ"), "release ではデバッグ枠を出さない")
		assert_false(text.contains("本編"), "release では本編／デバッグ区別を出さない")


func test_debug_access_true_in_gut_debug_build() -> void:
	## GUT は debug バイナリ上で動く前提。release ガードの逆側を固定する。
	assert_true(_DebugAccess.is_allowed())


func test_debug_full_unlock_apply_sets_flag_when_allowed() -> void:
	if not _DebugAccess.is_allowed():
		pass_test("skipped outside debug builds")
		return
	_DebugFullUnlock.apply()
	assert_true(GameState.debug_full_unlock)
	GameState.reset_for_new_game()
	assert_false(GameState.debug_full_unlock)
