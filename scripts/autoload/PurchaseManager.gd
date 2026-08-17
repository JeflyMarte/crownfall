extends Node

## 魔晶石 IAP（P3-MONET-IAP-001）。iOS InAppStore シングルトンがあれば StoreKit。
## 付与は同一ウォレット `GameState.gacha_token`。transaction_id で二重付与を防ぐ。

const _IapCatalog := preload("res://scripts/iap/IapCatalog.gd")

signal purchase_finished(result: Dictionary)

var _store: Object = null
var _busy: bool = false
var _mock_enabled: bool = false
var _mock_seq: int = 0
var _pending_product_id: String = ""
var _localized_prices: Dictionary = {}
var _persist_grants: bool = true


func _ready() -> void:
	if not Constants.are_iap_purchases_playable():
		set_process(false)
		return
	if Engine.has_singleton("InAppStore"):
		_store = Engine.get_singleton("InAppStore")
		if _store.has_method("set_auto_finish_transaction"):
			_store.set_auto_finish_transaction(false)
		_request_product_info()
	set_process(_store != null)


func _process(_delta: float) -> void:
	_drain_store_events()


func is_store_available() -> bool:
	return _store != null or _mock_enabled


func is_busy() -> bool:
	return _busy


func localized_price_text(product_id: String) -> String:
	var cached: String = str(_localized_prices.get(product_id, ""))
	if not cached.is_empty():
		return cached
	return _IapCatalog.fallback_price_text(product_id)


func enable_mock_for_tests() -> void:
	_mock_enabled = true


func disable_mock_for_tests() -> void:
	_mock_enabled = false
	_busy = false
	_pending_product_id = ""
	_persist_grants = true


func set_persist_grants_for_tests(enabled: bool) -> void:
	_persist_grants = enabled


func purchase(product_id: String) -> Dictionary:
	if not Constants.are_iap_purchases_playable():
		return _fail("omitted", "現在は購入できません")
	if _busy:
		return _fail("busy", "購入処理中です")
	if _IapCatalog.by_id(product_id).is_empty():
		return _fail("unknown_product", "不明な商品です")
	if not is_store_available():
		return _fail("unavailable", "App Store（iOS）でのみ購入できます")
	_busy = true
	_pending_product_id = product_id
	if _mock_enabled:
		call_deferred("_flush_mock_success")
		return {"ok": true, "started": true, "product_id": product_id}
	if _store == null:
		_busy = false
		_pending_product_id = ""
		return _fail("unavailable", "App Store（iOS）でのみ購入できます")
	var err: Variant = _store.call("purchase", {"product_id": product_id})
	if int(err) != OK:
		_busy = false
		_pending_product_id = ""
		return _fail("store_error", "購入を開始できませんでした")
	return {"ok": true, "started": true, "product_id": product_id}


func fulfill(product_id: String, txn_id: String) -> Dictionary:
	var pid: String = product_id.strip_edges()
	var txn: String = txn_id.strip_edges()
	if pid.is_empty() or txn.is_empty():
		return _fail("bad_txn", "購入情報を確認できませんでした")
	if GameState.iap_fulfilled_txns.has(txn):
		return {
			"ok": true,
			"duplicate": true,
			"product_id": pid,
			"tokens": 0,
			"message": "受取済みです",
		}
	var tokens: int = _IapCatalog.tokens_for(pid)
	if tokens <= 0:
		return _fail("unknown_product", "不明な商品です")
	GameState.gacha_token += tokens
	GameState.iap_fulfilled_txns[txn] = true
	if _persist_grants:
		SaveManager.save_game()
	return {
		"ok": true,
		"duplicate": false,
		"product_id": pid,
		"tokens": tokens,
		"message": "%s ×%d を入手しました" % [CurrencyHelper.DISPLAY_NAME, tokens],
	}


func handle_store_event_for_tests(event: Dictionary) -> void:
	_handle_store_event(event)


func _flush_mock_success() -> void:
	_mock_seq += 1
	var pid: String = _pending_product_id
	_handle_store_event({
		"type": "purchase",
		"result": "ok",
		"product_id": pid,
		"transaction_id": "mock_%d" % _mock_seq,
	})


func _request_product_info() -> void:
	if _store == null or not _store.has_method("request_product_info"):
		return
	_store.call("request_product_info", {"product_ids": _IapCatalog.product_ids()})


func _drain_store_events() -> void:
	if _store == null or not _store.has_method("get_pending_event_count"):
		return
	while int(_store.call("get_pending_event_count")) > 0:
		var raw: Variant = _store.call("pop_pending_event")
		if raw is Dictionary:
			_handle_store_event(raw as Dictionary)


func _handle_store_event(event: Dictionary) -> void:
	var kind: String = str(event.get("type", ""))
	if kind == "product_info":
		_cache_product_info(event)
		return
	if kind != "purchase":
		return
	var result: String = str(event.get("result", ""))
	var product_id: String = str(event.get("product_id", _pending_product_id))
	if result != "ok":
		_busy = false
		_pending_product_id = ""
		var msg: String = "購入をキャンセルしました" if result == "cancelled" else "購入できませんでした"
		purchase_finished.emit(_fail(result if not result.is_empty() else "error", msg))
		return
	var txn: String = str(event.get("transaction_id", ""))
	if txn.is_empty():
		txn = "store_%s_%d" % [product_id, Time.get_unix_time_from_system()]
	var granted: Dictionary = fulfill(product_id, txn)
	_finish_store_transaction(product_id)
	_busy = false
	_pending_product_id = ""
	purchase_finished.emit(granted)


func _finish_store_transaction(product_id: String) -> void:
	if _store == null or not _store.has_method("finish_transaction"):
		return
	if product_id.is_empty():
		return
	_store.call("finish_transaction", product_id)


func _cache_product_info(event: Dictionary) -> void:
	if str(event.get("result", "")) != "ok":
		return
	var ids: Variant = event.get("ids", [])
	var prices: Variant = event.get("localized_prices", [])
	if not (ids is Array) or not (prices is Array):
		return
	var id_arr: Array = ids as Array
	var price_arr: Array = prices as Array
	var n: int = mini(id_arr.size(), price_arr.size())
	for i in n:
		var pid: String = str(id_arr[i])
		var price: String = str(price_arr[i])
		if not pid.is_empty() and not price.is_empty():
			_localized_prices[pid] = price


func _fail(reason: String, message: String) -> Dictionary:
	return {"ok": false, "reason": reason, "message": message, "tokens": 0}
