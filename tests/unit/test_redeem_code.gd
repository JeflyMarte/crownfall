extends GutTest
## 調査許可コード → 配布ボックス（P3-CODE-REDEEM-001）。

const _CommanderGiftBox = preload("res://scripts/commander/CommanderGiftBox.gd")
const _CommanderDefaults = preload("res://scripts/commander/CommanderDefaults.gd")
const _RedeemCodeSystem = preload("res://scripts/commander/RedeemCodeSystem.gd")
const _GachaLimitBreak = preload("res://scripts/gacha/GachaLimitBreak.gd")


func before_each() -> void:
	GameState.reset_for_new_game()
	GameState.gold = 100
	GameState.gacha_token = 0
	GameState.material_inventory = {}
	GameState.ticket_inventory = {}
	GameState.owned_helpers = {}
	GameState.commander = _CommanderDefaults.default_commander_dict()


func test_normalize_strips_separators() -> void:
	assert_eq(_RedeemCodeSystem.normalize(" crown-beta "), "CROWNBETA")
	assert_eq(_RedeemCodeSystem.normalize("CROWN_ALLY"), "CROWNALLY")


func test_redeem_beta_enqueues_gift_once() -> void:
	var result: Dictionary = _RedeemCodeSystem.redeem("CROWN-BETA")
	assert_true(result.get("ok", false))
	assert_eq(_CommanderGiftBox.pending_count(), 1)
	var again: Dictionary = _RedeemCodeSystem.redeem("CROWNBETA")
	assert_false(again.get("ok", false))
	assert_eq(str(again.get("reason", "")), "used")
	assert_eq(_CommanderGiftBox.pending_count(), 1)


func test_redeem_invalid_and_empty() -> void:
	assert_eq(str(_RedeemCodeSystem.redeem("").get("reason", "")), "empty")
	assert_eq(str(_RedeemCodeSystem.redeem("NOPE").get("reason", "")), "invalid")


func test_claim_helper_and_tickets_from_gift() -> void:
	var gift_id: String = _CommanderGiftBox.enqueue({
		"title": "助っ人＋券",
		"helpers": ["helper_a"],
		"tickets": {TicketIds.GACHA_FREE: 2},
		"gold": 50,
	})
	assert_false(gift_id.is_empty())
	var result: Dictionary = _CommanderGiftBox.claim(gift_id)
	assert_true(result.get("ok", false))
	assert_eq(GameState.gold, 150)
	assert_eq(TicketInventory.get_qty(TicketIds.GACHA_FREE), 2)
	assert_true(GameState.owned_helpers.has("helper_a"))
	assert_eq(int(GameState.owned_helpers["helper_a"]), 1)
	var found: bool = false
	for member in GameState.roster:
		if member != null and str(member.id) == "gacha_helper_a":
			found = true
			break
	assert_true(found, "roster should include gacha_helper_a")


func test_duplicate_helper_increments_breakthrough() -> void:
	GameState.owned_helpers["helper_a"] = 1
	var gift_id: String = _CommanderGiftBox.enqueue({
		"title": "重複助っ人",
		"helpers": ["helper_a"],
	})
	var result: Dictionary = _CommanderGiftBox.claim(gift_id)
	assert_true(result.get("ok", false))
	assert_eq(int(GameState.owned_helpers["helper_a"]), 2)
	assert_eq(_GachaLimitBreak.breakthrough_for_helper_id("helper_a"), 1)


func test_redeem_ally_then_claim() -> void:
	var redeem: Dictionary = _RedeemCodeSystem.redeem("CROWNALLY")
	assert_true(redeem.get("ok", false))
	var claim_all: Dictionary = _CommanderGiftBox.claim_all()
	assert_true(claim_all.get("ok", false))
	assert_true(GameState.owned_helpers.has("helper_a"))
