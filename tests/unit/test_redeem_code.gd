extends GutTest

## P3-UX-REDEEM-001 — 設定の特典コード受取。

const SAVE_PATH: String = "user://save_data.json"


func before_each() -> void:
	SaveManager.use_normal_slot()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	GameState.reset_for_new_game()
	GameState.gold = 100
	GameState.gacha_token = 5
	SaveManager.save_game()


func after_each() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	GameState.reset_for_new_game()


func test_normalize_strips_separators() -> void:
	assert_eq(RedeemCodeCatalog.normalize(" crownfall-beta "), "CROWNFALLBETA")
	assert_eq(RedeemCodeCatalog.normalize("CROWNFALL_BETA"), "CROWNFALLBETA")


func test_redeem_beta_code_grants_rewards_once() -> void:
	var before_gold: int = GameState.gold
	var before_token: int = GameState.gacha_token
	var before_ticket: int = TicketInventory.get_qty(TicketIds.GACHA_FREE)
	var ok: Dictionary = RedeemCodeSystem.try_redeem("CROWNFALL-BETA")
	assert_true(bool(ok.get("ok", false)), str(ok))
	assert_eq(GameState.gold, before_gold + 5000)
	assert_eq(GameState.gacha_token, before_token + 30)
	assert_eq(TicketInventory.get_qty(TicketIds.GACHA_FREE), before_ticket + 1)
	assert_true(GameState.is_redeem_code_claimed("crownfall_beta"))
	var again: Dictionary = RedeemCodeSystem.try_redeem("crownfall beta")
	assert_false(bool(again.get("ok", true)))
	assert_eq(str(again.get("reason", "")), "already")
	assert_eq(GameState.gold, before_gold + 5000)


func test_redeem_persists_across_reload() -> void:
	assert_true(bool(RedeemCodeSystem.try_redeem("CROWNFALLBETA").get("ok", false)))
	GameState.reset_for_new_game()
	SaveManager.load_game()
	assert_true(GameState.is_redeem_code_claimed("crownfall_beta"))
	var again: Dictionary = RedeemCodeSystem.try_redeem("CROWNFALL-BETA")
	assert_false(bool(again.get("ok", true)))
	assert_eq(str(again.get("reason", "")), "already")


func test_invalid_and_empty_codes() -> void:
	var empty: Dictionary = RedeemCodeSystem.try_redeem("   ")
	assert_false(bool(empty.get("ok", true)))
	assert_eq(str(empty.get("reason", "")), "empty")
	var bad: Dictionary = RedeemCodeSystem.try_redeem("NOT-A-REAL-CODE")
	assert_false(bool(bad.get("ok", true)))
	assert_eq(str(bad.get("reason", "")), "invalid")


func test_requires_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	var result: Dictionary = RedeemCodeSystem.try_redeem("CROWNFALL-BETA")
	assert_false(bool(result.get("ok", true)))
	assert_eq(str(result.get("reason", "")), "no_save")


func test_promo_codes_grant_tokens_and_tickets_no_gold() -> void:
	## 配布4種: Goldなし・魔晶石＋招待／封蔵。
	var cases: Array = [
		{"code": "THANKYOU-1K", "id": "thankyou_1k", "token": 100, "invite": 1, "seal": 0},
		{"code": "NOTE-CROWN", "id": "note_crown", "token": 200, "invite": 0, "seal": 1},
		{"code": "YOUTUBE-FALL", "id": "youtube_fall", "token": 100, "invite": 1, "seal": 1},
		{"code": "NINA-RECORD", "id": "nina_record", "token": 150, "invite": 1, "seal": 1},
	]
	for c: Variant in cases:
		var row: Dictionary = c as Dictionary
		GameState.reset_for_new_game()
		GameState.gold = 100
		GameState.gacha_token = 0
		SaveManager.save_game()
		var before_gold: int = GameState.gold
		var before_inv: int = TicketInventory.get_qty(TicketIds.GACHA_FREE)
		var before_seal: int = TicketInventory.get_qty(TicketIds.SEAL_FREE)
		var ok: Dictionary = RedeemCodeSystem.try_redeem(str(row["code"]))
		assert_true(bool(ok.get("ok", false)), "%s %s" % [str(row["code"]), str(ok)])
		assert_eq(GameState.gold, before_gold, str(row["code"]))
		assert_eq(GameState.gacha_token, int(row["token"]), str(row["code"]))
		assert_eq(
			TicketInventory.get_qty(TicketIds.GACHA_FREE),
			before_inv + int(row["invite"]),
			str(row["code"])
		)
		assert_eq(
			TicketInventory.get_qty(TicketIds.SEAL_FREE),
			before_seal + int(row["seal"]),
			str(row["code"])
		)
		assert_true(GameState.is_redeem_code_claimed(str(row["id"])))
