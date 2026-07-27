extends GutTest

## ContentUnlockNotice: 章クリア後の次解放解決。

const _ContentUnlockNotice := preload("res://scripts/ui/ContentUnlockNotice.gd")
const _DungeonTierConfig := preload("res://scripts/dungeon/DungeonTierConfig.gd")


func test_next_unlock_after_mourngate_is_whisperwood() -> void:
	var notice: Dictionary = _ContentUnlockNotice.next_unlock_after_main_clear(
		"mourngate", _DungeonTierConfig.TIER_NORMAL
	)
	assert_eq(str(notice.get("kind", "")), "dungeon")
	assert_eq(str(notice.get("id", "")), "whisperwood")
	assert_true(str(notice.get("display_name", "")).find("ウィスパー") >= 0)


func test_next_unlock_after_frostridge_is_hard_mourngate() -> void:
	var notice: Dictionary = _ContentUnlockNotice.next_unlock_after_main_clear(
		"frostridge", _DungeonTierConfig.TIER_NORMAL
	)
	assert_eq(str(notice.get("kind", "")), "dungeon_tier")
	assert_eq(str(notice.get("id", "")), "mourngate")
	assert_eq(int(notice.get("tier", -1)), _DungeonTierConfig.TIER_HARD)
	assert_true(str(notice.get("display_name", "")).begins_with("ハード・"))


func test_next_unlock_after_hard_frostridge_is_nightmare_mourngate() -> void:
	var notice: Dictionary = _ContentUnlockNotice.next_unlock_after_main_clear(
		"frostridge", _DungeonTierConfig.TIER_HARD
	)
	assert_eq(str(notice.get("kind", "")), "dungeon_tier")
	assert_eq(str(notice.get("id", "")), "mourngate")
	assert_eq(int(notice.get("tier", -1)), _DungeonTierConfig.TIER_NIGHTMARE)
	assert_true(str(notice.get("display_name", "")).begins_with("ナイトメア・"))


func test_next_unlock_after_mistfen_is_blackshore() -> void:
	var notice: Dictionary = _ContentUnlockNotice.next_unlock_after_main_clear(
		"mistfen", _DungeonTierConfig.TIER_NORMAL
	)
	assert_eq(str(notice.get("id", "")), "blackshore")


func test_show_pending_skips_hub_deferred_survey_complete() -> void:
	## 結果／選択画面は survey_complete を消費せず、他解放だけ出す。
	GameState.pending_content_unlock_notices = [
		{
			"kind": "survey_complete",
			"id": "mourngate",
			"display_name": "王都地下モーンゲート",
			"detail": "テスト景品",
		},
		{
			"kind": "dungeon",
			"id": "whisperwood",
			"display_name": "ウィスパーウッド",
		},
	]
	var host := Control.new()
	host.name = "UnlockHost"
	add_child_autofree(host)
	var overlay: CanvasLayer = _ContentUnlockNotice.show_pending_on_except_hub_deferred(host)
	assert_not_null(overlay, "dungeon 解放は結果側でも表示する")
	assert_eq(GameState.pending_content_unlock_notices.size(), 1)
	var left: Dictionary = GameState.pending_content_unlock_notices[0]
	assert_eq(str(left.get("kind", "")), "survey_complete")
	assert_eq(str(left.get("id", "")), "mourngate")
	GameState.pending_content_unlock_notices.clear()


func test_show_pending_except_hub_deferred_keeps_only_survey() -> void:
	GameState.pending_content_unlock_notices = [
		{
			"kind": "survey_complete",
			"id": "whisperwood",
			"display_name": "ウィスパーウッド",
		},
	]
	var host := Control.new()
	add_child_autofree(host)
	var overlay: CanvasLayer = _ContentUnlockNotice.show_pending_on_except_hub_deferred(host)
	assert_null(overlay, "完全調査だけなら結果側では出さない")
	assert_eq(GameState.pending_content_unlock_notices.size(), 1)
	assert_eq(str(GameState.pending_content_unlock_notices[0].get("kind", "")), "survey_complete")
	GameState.pending_content_unlock_notices.clear()
