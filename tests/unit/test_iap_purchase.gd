extends GutTest
## P3-MONET-IAP-001 — 魔晶石 IAP カタログ・付与・二重防止。

const _IapCatalog := preload("res://scripts/iap/IapCatalog.gd")

var _saved_token: int = 0
var _saved_txns: Dictionary = {}


func before_each() -> void:
	_saved_token = GameState.gacha_token
	_saved_txns = GameState.iap_fulfilled_txns.duplicate()
	GameState.gacha_token = 0
	GameState.iap_fulfilled_txns = {}
	PurchaseManager.disable_mock_for_tests()
	PurchaseManager.set_persist_grants_for_tests(false)


func after_each() -> void:
	PurchaseManager.disable_mock_for_tests()
	PurchaseManager.set_persist_grants_for_tests(true)
	GameState.gacha_token = _saved_token
	GameState.iap_fulfilled_txns = _saved_txns


func test_catalog_has_six_packs_matching_decision() -> void:
	assert_eq(_IapCatalog.all_products().size(), 6)
	assert_eq(_IapCatalog.tokens_for(_IapCatalog.PRODUCT_S), 80)
	assert_eq(_IapCatalog.tokens_for(_IapCatalog.PRODUCT_M), 500)
	assert_eq(_IapCatalog.tokens_for(_IapCatalog.PRODUCT_L), 1100)
	assert_eq(_IapCatalog.tokens_for(_IapCatalog.PRODUCT_XL), 2400)
	assert_eq(_IapCatalog.tokens_for(_IapCatalog.PRODUCT_XXL), 5200)
	assert_eq(_IapCatalog.tokens_for(_IapCatalog.PRODUCT_MAX), 11200)
	assert_eq(_IapCatalog.price_jpy_for(_IapCatalog.PRODUCT_M), 610)


func test_fulfill_adds_tokens_once_per_txn() -> void:
	var first: Dictionary = PurchaseManager.fulfill(_IapCatalog.PRODUCT_M, "txn_a")
	assert_true(bool(first.get("ok", false)))
	assert_false(bool(first.get("duplicate", false)))
	assert_eq(GameState.gacha_token, 500)
	var second: Dictionary = PurchaseManager.fulfill(_IapCatalog.PRODUCT_M, "txn_a")
	assert_true(bool(second.get("ok", false)))
	assert_true(bool(second.get("duplicate", false)))
	assert_eq(GameState.gacha_token, 500, "同一 transaction は二重付与しない")


func test_fulfill_rejects_unknown_product() -> void:
	var result: Dictionary = PurchaseManager.fulfill("iap.unknown", "txn_b")
	assert_false(bool(result.get("ok", false)))
	assert_eq(GameState.gacha_token, 0)


func test_purchases_are_omitted() -> void:
	assert_false(Constants.are_iap_purchases_playable())
	PurchaseManager.enable_mock_for_tests()
	var started: Dictionary = PurchaseManager.purchase(_IapCatalog.PRODUCT_S)
	assert_false(bool(started.get("ok", false)))
	assert_eq(str(started.get("reason", "")), "omitted")
	assert_eq(GameState.gacha_token, 0)


func test_store_event_error_does_not_grant() -> void:
	PurchaseManager.handle_store_event_for_tests({
		"type": "purchase",
		"result": "error",
		"product_id": _IapCatalog.PRODUCT_M,
	})
	assert_eq(GameState.gacha_token, 0)
