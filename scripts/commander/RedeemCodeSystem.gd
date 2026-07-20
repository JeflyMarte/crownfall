class_name RedeemCodeSystem
extends RefCounted

## 調査許可コード入力（P3-CODE-REDEEM-001）。
## 成功時は配布ボックスへ投入し、セーブ単位で1回限り。

const _CommanderGiftBox := preload("res://scripts/commander/CommanderGiftBox.gd")
const _CommanderProfile := preload("res://scripts/commander/CommanderProfile.gd")
const _RedeemCodeCatalog := preload("res://scripts/commander/RedeemCodeCatalog.gd")


static func normalize(raw: String) -> String:
	var s: String = raw.strip_edges().to_upper()
	s = s.replace(" ", "").replace("-", "").replace("_", "")
	return s


static func ensure_storage() -> void:
	_CommanderProfile.ensure_commander()
	if not GameState.commander.has("redeemed_codes") or not GameState.commander["redeemed_codes"] is Array:
		GameState.commander["redeemed_codes"] = []


static func is_redeemed(normalized: String) -> bool:
	ensure_storage()
	if normalized.is_empty():
		return false
	for raw: Variant in GameState.commander["redeemed_codes"]:
		if str(raw) == normalized:
			return true
	return false


## 結果: { ok, reason?, gift_id?, title?, summary? }
## reason: empty / invalid / used / enqueue_failed
static func redeem(raw_code: String) -> Dictionary:
	var normalized: String = normalize(raw_code)
	if normalized.is_empty():
		return {"ok": false, "reason": "empty"}
	if not _RedeemCodeCatalog.has_code(normalized):
		return {"ok": false, "reason": "invalid"}
	if is_redeemed(normalized):
		return {"ok": false, "reason": "used"}
	var payload: Dictionary = _RedeemCodeCatalog.payload_for(normalized)
	if payload.is_empty():
		return {"ok": false, "reason": "invalid"}
	payload["source"] = "redeem:%s" % normalized
	var gift_id: String = _CommanderGiftBox.enqueue(payload)
	if gift_id.is_empty():
		return {"ok": false, "reason": "enqueue_failed"}
	_mark_redeemed(normalized)
	return {
		"ok": true,
		"gift_id": gift_id,
		"title": str(payload.get("title", "")),
		"summary": _CommanderGiftBox.reward_summary(payload),
	}


static func _mark_redeemed(normalized: String) -> void:
	ensure_storage()
	var used: Array = GameState.commander["redeemed_codes"]
	used.append(normalized)
	GameState.commander["redeemed_codes"] = used
