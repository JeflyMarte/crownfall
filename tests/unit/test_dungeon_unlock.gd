extends GutTest

## P3-D157 — ダンジョン解放条件（メイン直列解放）のテスト。

var _saved_progress: Dictionary = {}

func before_each() -> void:
	_saved_progress = GameState.dungeon_progress
	GameState.dungeon_progress = {}

func after_each() -> void:
	GameState.dungeon_progress = _saved_progress

func test_first_main_always_unlocked() -> void:
	assert_true(GameState.is_dungeon_unlocked("mourngate"), "難易度1は常時解放")
	if Constants.SUB_DUNGEONS_PLAYABLE:
		assert_true(GameState.is_dungeon_unlocked("astoria_ruins"), "①寄り道は常時解放")
	else:
		assert_false(GameState.is_dungeon_unlocked("astoria_ruins"), "P3-DG-OMIT-001: 寄り道はオミット")

func test_side_routes_unlock_after_prior_main() -> void:
	if not Constants.SUB_DUNGEONS_PLAYABLE:
		assert_false(GameState.is_dungeon_unlocked("green_hollow"), "P3-DG-OMIT-001")
		GameState.mark_dungeon_cleared("mourngate")
		assert_false(GameState.is_dungeon_unlocked("green_hollow"), "P3-DG-OMIT-001")
		return
	assert_false(GameState.is_dungeon_unlocked("green_hollow"), "①未クリアでは②寄り道ロック")
	GameState.mark_dungeon_cleared("mourngate")
	assert_true(GameState.is_dungeon_unlocked("green_hollow"), "①クリアで②寄り道解放")
	assert_false(GameState.is_dungeon_unlocked("westbay_flats"), "③未クリアでは④寄り道ロック")
	GameState.mark_dungeon_cleared("mistfen")
	assert_true(GameState.is_dungeon_unlocked("westbay_flats"), "③クリアで④寄り道解放")
	assert_false(GameState.is_dungeon_unlocked("frostwall_path"), "④未クリアでは⑤寄り道ロック")
	GameState.mark_dungeon_cleared("blackshore")
	assert_true(GameState.is_dungeon_unlocked("frostwall_path"), "④クリアで⑤寄り道解放")

func test_second_main_locked_until_first_cleared() -> void:
	assert_false(GameState.is_dungeon_unlocked("whisperwood"), "①未クリアでは②ロック")
	GameState.mark_dungeon_cleared("mourngate")
	if Constants.BETA_MOURNGATE_ONLY:
		assert_false(GameState.is_dungeon_unlocked("whisperwood"), "βは①クリア後も②ロック")
	else:
		assert_true(GameState.is_dungeon_unlocked("whisperwood"), "①クリアで②解放")

func test_third_main_requires_second_not_first() -> void:
	GameState.mark_dungeon_cleared("mourngate")
	assert_false(GameState.is_dungeon_unlocked("mistfen"), "②未クリアでは③ロック")
	GameState.mark_dungeon_cleared("whisperwood")
	if Constants.BETA_MOURNGATE_ONLY:
		assert_false(GameState.is_dungeon_unlocked("mistfen"), "βは③もロック")
	else:
		assert_true(GameState.is_dungeon_unlocked("mistfen"), "②クリアで③解放")

func test_beta_mourngate_only_keeps_later_mains_locked() -> void:
	if not Constants.BETA_MOURNGATE_ONLY:
		pass_test("BETA_MOURNGATE_ONLY off")
		return
	assert_true(GameState.is_dungeon_unlocked("mourngate"))
	GameState.mark_dungeon_cleared("mourngate")
	GameState.mark_dungeon_cleared("whisperwood")
	GameState.mark_dungeon_cleared("mistfen")
	for dungeon_id in ["whisperwood", "mistfen", "blackshore", "frostridge"]:
		assert_false(GameState.is_dungeon_unlocked(dungeon_id), "β封鎖: " + dungeon_id)

func test_unknown_dungeon_locked() -> void:
	assert_false(GameState.is_dungeon_unlocked("no_such_dungeon"), "未知IDは false")

func test_apex_dungeons_unlock_after_main() -> void:
	if not Constants.SUB_DUNGEONS_PLAYABLE:
		GameState.mark_dungeon_cleared("mourngate")
		assert_false(GameState.is_dungeon_unlocked("mourngate_deep"), "P3-DG-OMIT-001")
		return
	assert_false(GameState.is_dungeon_unlocked("mourngate_deep"), "①未クリアでは征討ロック")
	GameState.mark_dungeon_cleared("mourngate")
	assert_true(GameState.is_dungeon_unlocked("mourngate_deep"), "①クリアでモーンゲート深層解放")
	assert_false(GameState.is_dungeon_unlocked("north_reach"), "⑤未クリアではノースリーチロック")
	GameState.mark_dungeon_cleared("frostridge")
	assert_true(GameState.is_dungeon_unlocked("north_reach"), "⑤クリアでノースリーチ解放")
