extends GutTest

## タイトル「デバッグ」フル所持プリセット。

const _DebugFullUnlock = preload("res://scripts/debug/DebugFullUnlock.gd")
const SAVE_PATH: String = "user://save_data.json"


func before_each() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	GameState.reset_for_new_game()


func after_each() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	GameState.reset_for_new_game()


func test_debug_full_unlock_grants_currency_roster_and_gear() -> void:
	_DebugFullUnlock.apply()
	assert_eq(GameState.gold, _DebugFullUnlock.DEBUG_GOLD)
	assert_eq(GameState.gacha_token, _DebugFullUnlock.DEBUG_GACHA_TOKEN)
	assert_true(GameState.debug_full_unlock)
	assert_false(GameState.needs_starter_pick())
	assert_eq(GameState.starter_unlocked_ids.size(), GameState.BASE_ROSTER_DEFS.size())
	assert_gte(GameState.roster.size(), GameState.BASE_ROSTER_DEFS.size())
	assert_gte(GameState.inventory.size(), DataRegistry.get_all_weapon_data().size())
	assert_gt(GameState.armor_inventory.size(), 0)
	assert_gt(GameState.accessory_inventory.size(), 0)
	assert_true(GameState.is_dungeon_unlocked("whisperwood"), "デバッグ時はβ外メインも解放")
	var mythic_w: bool = false
	for item in GameState.inventory:
		if str(item.weapon_id) == "burial_crown_greatsword":
			mythic_w = true
			break
	assert_true(mythic_w, "神話武器が所持に含まれる")


func test_debug_save_roundtrip_keeps_flag() -> void:
	_DebugFullUnlock.apply()
	SaveManager.save_game()
	GameState.reset_for_new_game()
	assert_false(GameState.debug_full_unlock)
	SaveManager.load_game()
	assert_true(GameState.debug_full_unlock)
	assert_eq(GameState.gold, _DebugFullUnlock.DEBUG_GOLD)
	assert_true(GameState.is_dungeon_unlocked("whisperwood"))
