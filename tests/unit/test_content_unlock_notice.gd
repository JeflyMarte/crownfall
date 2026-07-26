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
