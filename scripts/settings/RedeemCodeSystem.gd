class_name RedeemCodeSystem
extends RefCounted

## 特典コード受取（P3-UX-REDEEM-001）。セーブごと1回。セーブ必須。


static func try_redeem(raw_code: String, reload_from_disk: bool = false) -> Dictionary:
	var key: String = RedeemCodeCatalog.normalize(raw_code)
	if key.is_empty():
		return _fail("empty", "コードを入力してください")
	if not SaveManager.has_save():
		return _fail("no_save", "セーブデータがありません。ゲーム開始後に入力してください")
	if reload_from_disk:
		SaveManager.load_game()
	var entry: Dictionary = RedeemCodeCatalog.find(raw_code)
	if entry.is_empty():
		return _fail("invalid", "コードが正しくありません")
	var code_id: String = str(entry.get("id", key))
	if GameState.is_redeem_code_claimed(code_id):
		return _fail("already", "このコードは受取済みです")
	var gold: int = maxi(0, int(entry.get("gold", 0)))
	var tokens: int = maxi(0, int(entry.get("gacha_token", 0)))
	var tickets: Dictionary = entry.get("tickets", {}) if entry.get("tickets", {}) is Dictionary else {}
	if gold > 0:
		GameState.gold += gold
	if tokens > 0:
		GameState.gacha_token += tokens
	for tid in tickets.keys():
		TicketInventory.add(str(tid), int(tickets[tid]))
	GameState.mark_redeem_code_claimed(code_id)
	SaveManager.save_game()
	return {
		"ok": true,
		"code_id": code_id,
		"display_name": str(entry.get("display_name", "特典")),
		"summary": _format_summary(gold, tokens, tickets),
		"message": "%sを受け取りました" % str(entry.get("display_name", "特典")),
	}


static func _format_summary(gold: int, tokens: int, tickets: Dictionary) -> String:
	var parts: PackedStringArray = PackedStringArray()
	if gold > 0:
		parts.append("ゴールド ×%d" % gold)
	if tokens > 0:
		parts.append("%s ×%d" % [CurrencyHelper.DISPLAY_NAME, tokens])
	for tid in tickets.keys():
		var qty: int = int(tickets[tid])
		if qty <= 0:
			continue
		parts.append("%s ×%d" % [TicketSystem.display_name(str(tid)), qty])
	if parts.is_empty():
		return "特典を受け取りました"
	return "\n".join(parts)


static func _fail(reason: String, message: String) -> Dictionary:
	return {"ok": false, "reason": reason, "message": message}
