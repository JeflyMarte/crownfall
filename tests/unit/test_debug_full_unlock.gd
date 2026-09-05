extends GutTest

## タイトル「デバッグ」フル所持プリセット＋本編と分離したセーブスロット。

const _DebugFullUnlock = preload("res://scripts/debug/DebugFullUnlock.gd")
const SAVE_PATH_NORMAL: String = "user://save_data.json"
const SAVE_PATH_DEBUG: String = "user://save_data_debug.json"


func before_each() -> void:
	SaveManager.use_normal_slot()
	if FileAccess.file_exists(SAVE_PATH_NORMAL):
		DirAccess.remove_absolute(SAVE_PATH_NORMAL)
	if FileAccess.file_exists(SAVE_PATH_DEBUG):
		DirAccess.remove_absolute(SAVE_PATH_DEBUG)
	GameState.reset_for_new_game()


func after_each() -> void:
	SaveManager.use_normal_slot()
	if FileAccess.file_exists(SAVE_PATH_NORMAL):
		DirAccess.remove_absolute(SAVE_PATH_NORMAL)
	if FileAccess.file_exists(SAVE_PATH_DEBUG):
		DirAccess.remove_absolute(SAVE_PATH_DEBUG)
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
	assert_eq(GameState.armor_inventory.size(), DataRegistry.get_all_armor_data().size())
	assert_eq(GameState.accessory_inventory.size(), DataRegistry.get_all_accessory_data().size())
	## 生産は入手解放制。デバッグではクラフト可能レシピが並ぶこと。
	assert_gt(CraftHelper.list_unlocked_crafts().size(), 0)
	assert_true(CraftHelper.is_unlocked("weapon", "iron_sword"))
	assert_false(CraftHelper.get_craftable_recipes().is_empty())
	assert_true(GameState.is_dungeon_unlocked("whisperwood"), "デバッグ時はβ外メインも解放")
	assert_eq(TicketInventory.get_qty(TicketIds.GACHA_FREE), Constants.DEBUG_TICKET_GRANT_EACH)
	assert_eq(TicketInventory.get_qty(TicketIds.LB_STAR3), Constants.DEBUG_TICKET_GRANT_EACH)
	assert_eq(TicketInventory.get_qty(TicketIds.LB_STAR4), Constants.DEBUG_TICKET_GRANT_EACH)
	var mythic_w: bool = false
	for item in GameState.inventory:
		if str(item.weapon_id) == "burial_crown_greatsword":
			mythic_w = true
			break
	assert_true(mythic_w, "神話武器が所持に含まれる")
	for hid: String in ["helper_q", "helper_r", "helper_s"]:
		assert_gte(int(GameState.owned_helpers.get(hid, 0)), 1, "機巧士 %s 所持" % hid)
		assert_not_null(GameState.find_roster_member_by_id("gacha_" + hid), "機巧士 %s ロスター" % hid)


func test_debug_full_unlock_max_levels_and_codex() -> void:
	_DebugFullUnlock.apply()
	for member in GameState.roster:
		assert_eq(int(member.level), LevelSystem.MAX_LEVEL, str(member.id))
	for item in GameState.inventory:
		assert_eq(
			int(item.equip_level),
			EquipmentEnhancer.EQUIP_MAX_LEVEL,
			str(item.weapon_id)
		)
	for member in GameState.roster:
		if member == null or member.equipped_weapon == null:
			continue
		assert_eq(
			int(member.equipped_weapon.equip_level),
			EquipmentEnhancer.EQUIP_MAX_LEVEL,
			str(member.id)
		)
	const _CommanderProfile = preload("res://scripts/commander/CommanderProfile.gd")
	assert_eq(_CommanderProfile.current_rank(), "S+%d" % _DebugFullUnlock.DEBUG_COMMANDER_S_PLUS)
	assert_eq(
		int(GameState.commander.get("permit_points_earned", 0)),
		_DebugFullUnlock.DEBUG_COMMANDER_S_PLUS
	)
	var enemies: Array = DataRegistry.get_all_enemy_data()
	assert_gt(enemies.size(), 0)
	for data in enemies:
		var eid: String = str(data.id)
		assert_eq(GameState.get_enemy_stage(eid), 5, eid)
	assert_true(CatalogHelper.is_discovered("weapon", "burial_crown_greatsword"))
	assert_true(CatalogHelper.is_discovered("dungeon", "mistfen"))
	assert_gt(GameState.armor_inventory.size(), 0)
	var armors: Array = DataRegistry.get_all_armor_data()
	assert_gt(armors.size(), 0)
	assert_true(CatalogHelper.is_discovered("armor", str(armors[0].armor_id)))
	## debug_full_unlock フラグだけで図鑑開示が立つ
	GameState.discovery_registry.clear()
	GameState.enemy_codex.clear()
	assert_true(CatalogHelper.is_discovered("dungeon", "mistfen"))
	assert_eq(GameState.get_enemy_stage("serdion"), 5)


func test_debug_save_uses_separate_slot_without_touching_normal() -> void:
	## 本編セーブを先に残す
	SaveManager.use_normal_slot()
	GameState.reset_for_new_game()
	GameState.gold = 12345
	GameState.debug_full_unlock = false
	SaveManager.save_game()
	assert_true(SaveManager.has_normal_save())
	assert_false(SaveManager.has_debug_save())

	## デバッグ開始＝別ファイルへ
	SaveManager.use_debug_slot()
	_DebugFullUnlock.apply()
	SaveManager.save_game()
	assert_true(SaveManager.has_debug_save())
	assert_true(SaveManager.has_normal_save(), "本編セーブは残る")

	## 本編を読み直すとデバッグ値が混入しない
	SaveManager.use_normal_slot()
	GameState.reset_for_new_game()
	SaveManager.load_game()
	assert_eq(GameState.gold, 12345)
	assert_false(GameState.debug_full_unlock)

	## デバッグを読み直すとフル所持
	SaveManager.use_debug_slot()
	GameState.reset_for_new_game()
	SaveManager.load_game()
	assert_true(GameState.debug_full_unlock)
	assert_eq(GameState.gold, _DebugFullUnlock.DEBUG_GOLD)


func test_debug_save_roundtrip_keeps_flag() -> void:
	SaveManager.use_debug_slot()
	_DebugFullUnlock.apply()
	SaveManager.save_game()
	GameState.reset_for_new_game()
	assert_false(GameState.debug_full_unlock)
	assert_true(SaveManager.load_game())
	assert_true(GameState.debug_full_unlock)
	assert_eq(GameState.gold, _DebugFullUnlock.DEBUG_GOLD)
	assert_true(GameState.is_dungeon_unlocked("whisperwood"))
	assert_eq(GameState.armor_inventory.size(), DataRegistry.get_all_armor_data().size())
	assert_eq(int(GameState.roster[0].level), LevelSystem.MAX_LEVEL)


func test_debug_continue_preserves_mutated_state() -> void:
	## タイトル「デバッグ」は既存スロットを load（毎回 apply で消さない）。
	SaveManager.use_debug_slot()
	_DebugFullUnlock.apply()
	GameState.gold = 42
	SaveManager.save_game()
	GameState.reset_for_new_game()
	assert_true(SaveManager.has_debug_save())
	assert_true(SaveManager.load_game())
	assert_eq(GameState.gold, 42)
	assert_true(GameState.debug_full_unlock)
