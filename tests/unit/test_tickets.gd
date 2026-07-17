extends GutTest

## P3-TICKET-001 — チケット基盤 / 無料ガチャ / レア別限界突破。

const SAVE_PATH: String = "user://save_data.json"


func before_each() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	GameState.reset_for_new_game()


func after_each() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	GameState.reset_for_new_game()


func test_ticket_resources_and_icons_exist() -> void:
	assert_eq(DataRegistry.get_all_ticket_data().size(), 3)
	for tid in TicketIds.ALL:
		assert_not_null(DataRegistry.get_ticket_data(tid), tid)
		assert_not_null(IconPaths.get_icon_texture(tid, "ticket"), tid)
	assert_false(Constants.TICKET_DISTRIBUTION_ENABLED)
	assert_true(TicketDistribution.active_grants_for(TicketDistribution.SOURCE_DAILY).is_empty())


func test_free_gacha_ticket_button_path() -> void:
	GameState.gacha_token = 0
	TicketInventory.add(TicketIds.GACHA_FREE, 1)
	assert_false(GachaSystem.can_pull(), "魔晶石0では通常招待不可")
	assert_true(GachaSystem.can_pull_with_ticket())
	var result: Dictionary = GachaSystem.pull(true)
	assert_true(bool(result.get("ok", false)), str(result))
	assert_true(bool(result.get("paid_with_ticket", false)))
	assert_eq(TicketInventory.get_qty(TicketIds.GACHA_FREE), 0)
	assert_eq(GameState.gacha_token, 0)


func test_token_pull_does_not_consume_ticket() -> void:
	GameState.gacha_token = 2
	TicketInventory.add(TicketIds.GACHA_FREE, 3)
	var result: Dictionary = GachaSystem.pull(false)
	assert_true(bool(result.get("ok", false)), str(result))
	assert_false(bool(result.get("paid_with_ticket", false)))
	assert_eq(GameState.gacha_token, 1)
	assert_eq(TicketInventory.get_qty(TicketIds.GACHA_FREE), 3)


func test_limit_break_star3_ticket() -> void:
	var helper: Resource = null
	for h in DataRegistry.get_all_gacha_helper_data():
		if h != null and int(h.rarity) == 3:
			helper = h
			break
	assert_not_null(helper, "★3 helper がプールにあること")
	var hid: String = str(helper.id)
	GameState.owned_helpers[hid] = 1
	TicketInventory.add(TicketIds.LB_STAR3, 1)
	var ok: Dictionary = TicketSystem.apply_limit_break_helper(hid)
	assert_true(bool(ok.get("ok", false)), str(ok))
	assert_eq(int(GameState.owned_helpers[hid]), 2)
	assert_eq(TicketInventory.get_qty(TicketIds.LB_STAR3), 0)


func test_limit_break_star4_ticket_and_max() -> void:
	var helper: Resource = null
	for h in DataRegistry.get_all_gacha_helper_data():
		if h != null and int(h.rarity) == 4:
			helper = h
			break
	assert_not_null(helper, "★4 helper がプールにあること")
	var hid: String = str(helper.id)
	GameState.owned_helpers[hid] = GachaLimitBreak.MAX_BREAKTHROUGH + 1
	TicketInventory.add(TicketIds.LB_STAR4, 1)
	var blocked: Dictionary = TicketSystem.can_limit_break_helper(hid)
	assert_false(bool(blocked.get("ok", true)))
	assert_eq(str(blocked.get("reason", "")), "max_breakthrough")
	GameState.owned_helpers[hid] = 1
	var ok: Dictionary = TicketSystem.apply_limit_break_helper(hid)
	assert_true(bool(ok.get("ok", false)), str(ok))
	assert_eq(TicketInventory.get_qty(TicketIds.LB_STAR4), 0)


func test_ticket_inventory_save_roundtrip() -> void:
	TicketInventory.grant_debug_stock(Constants.DEBUG_TICKET_GRANT_EACH)
	SaveManager.save_game()
	GameState.reset_for_new_game()
	assert_eq(TicketInventory.get_qty(TicketIds.GACHA_FREE), 0)
	SaveManager.load_game()
	assert_eq(TicketInventory.get_qty(TicketIds.GACHA_FREE), Constants.DEBUG_TICKET_GRANT_EACH)
	assert_eq(TicketInventory.get_qty(TicketIds.LB_STAR3), Constants.DEBUG_TICKET_GRANT_EACH)
	assert_eq(TicketInventory.get_qty(TicketIds.LB_STAR4), Constants.DEBUG_TICKET_GRANT_EACH)


func test_distribution_stop_data_present_but_inactive() -> void:
	assert_gte(TicketDistribution.GRANT_TABLE.size(), 3)
	assert_false(TicketDistribution.try_grant_from(TicketDistribution.SOURCE_DAILY))
	assert_eq(TicketInventory.get_qty(TicketIds.GACHA_FREE), 0)
