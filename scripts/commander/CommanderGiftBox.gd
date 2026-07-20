class_name CommanderGiftBox
extends RefCounted

const _CommanderProfile := preload("res://scripts/commander/CommanderProfile.gd")
const _CommanderLifetime := preload("res://scripts/commander/CommanderLifetime.gd")
const _GachaLimitBreak := preload("res://scripts/gacha/GachaLimitBreak.gd")

## 隊長台帳「配布ボックス」— 運営配布報酬の受取 SSOT。
## 配布物は `GameState.commander["gift_box"]` に格納し、セーブ v5 の commander 配下で永続化する。
##
## 運営配布（将来のサーバ連携・管理ツール）／調査許可コードは `enqueue()` で投入する。
## エントリ例:
##   {"title": "補填", "message": "...", "gold": 500, "gacha_token": 0,
##    "materials": {}, "tickets": {}, "helpers": ["helper_a"]}

const MAX_ENTRIES: int = 100


static func ensure_storage() -> void:
	_CommanderProfile.ensure_commander()
	if not GameState.commander.has("gift_box"):
		GameState.commander["gift_box"] = []
	elif not GameState.commander["gift_box"] is Array:
		GameState.commander["gift_box"] = []


static func pending_count() -> int:
	return get_pending_entries().size()


static func get_pending_entries() -> Array:
	ensure_storage()
	var out: Array = []
	for raw: Variant in GameState.commander["gift_box"]:
		if raw is Dictionary and not bool((raw as Dictionary).get("claimed", false)):
			out.append((raw as Dictionary).duplicate(true))
	return out


static func enqueue(payload: Dictionary) -> String:
	ensure_storage()
	var entry: Dictionary = _normalize_entry(payload)
	if entry.is_empty():
		return ""
	var box: Array = GameState.commander["gift_box"]
	box.append(entry)
	while box.size() > MAX_ENTRIES:
		box.pop_front()
	GameState.commander["gift_box"] = box
	return str(entry.get("id", ""))


static func claim(entry_id: String) -> Dictionary:
	ensure_storage()
	if entry_id.is_empty():
		return {"ok": false, "reason": "invalid_id"}
	var box: Array = GameState.commander["gift_box"]
	for i in box.size():
		if not box[i] is Dictionary:
			continue
		var entry: Dictionary = box[i]
		if str(entry.get("id", "")) != entry_id:
			continue
		if bool(entry.get("claimed", false)):
			return {"ok": false, "reason": "already_claimed"}
		var applied: Dictionary = _apply_rewards(entry)
		entry["claimed"] = true
		entry["claimed_at"] = int(Time.get_unix_time_from_system())
		box[i] = entry
		GameState.commander["gift_box"] = box
		return {"ok": true, "rewards": applied, "title": str(entry.get("title", ""))}
	return {"ok": false, "reason": "not_found"}


static func claim_all() -> Dictionary:
	var claimed: Array = []
	for entry: Dictionary in get_pending_entries():
		var result: Dictionary = claim(str(entry.get("id", "")))
		if bool(result.get("ok", false)):
			claimed.append(result)
	if claimed.is_empty():
		return {"ok": false, "reason": "empty", "count": 0}
	return {"ok": true, "count": claimed.size(), "claimed": claimed}


static func reward_summary(entry: Dictionary) -> String:
	var parts: PackedStringArray = []
	var gold: int = int(entry.get("gold", 0))
	if gold > 0:
		parts.append("ゴールド %s" % _format_int(gold))
	var tokens: int = int(entry.get("gacha_token", 0))
	if tokens > 0:
		parts.append("%s×%d" % [CurrencyHelper.DISPLAY_NAME, tokens])
	var materials: Variant = entry.get("materials", {})
	if materials is Dictionary:
		for mat_id: Variant in materials:
			var qty: int = int(materials[mat_id])
			if qty <= 0:
				continue
			parts.append("%s×%d" % [DataRegistry.get_material_name(str(mat_id)), qty])
	var tickets: Variant = entry.get("tickets", {})
	if tickets is Dictionary:
		for tid: Variant in tickets:
			var tqty: int = int(tickets[tid])
			if tqty <= 0:
				continue
			parts.append("%s×%d" % [_ticket_display_name(str(tid)), tqty])
	var helpers: Variant = entry.get("helpers", [])
	if helpers is Array:
		for hid_v: Variant in helpers:
			var hid: String = str(hid_v)
			if hid.is_empty():
				continue
			parts.append("助っ人 %s" % _helper_display_name(hid))
	if parts.is_empty():
		return "報酬なし"
	return " / ".join(parts)


static func _normalize_entry(payload: Dictionary) -> Dictionary:
	var title: String = str(payload.get("title", "")).strip_edges()
	if title.is_empty():
		title = "ギルド配布"
	var materials: Dictionary = {}
	var raw_mats: Variant = payload.get("materials", {})
	if raw_mats is Dictionary:
		for mat_id: Variant in raw_mats:
			var qty: int = int(raw_mats[mat_id])
			if qty > 0:
				materials[str(mat_id)] = qty
	var tickets: Dictionary = {}
	var raw_tickets: Variant = payload.get("tickets", {})
	if raw_tickets is Dictionary:
		for tid: Variant in raw_tickets:
			var tqty: int = int(raw_tickets[tid])
			if tqty > 0 and DataRegistry.get_ticket_data(str(tid)) != null:
				tickets[str(tid)] = tqty
	var helpers: Array = []
	var raw_helpers: Variant = payload.get("helpers", [])
	if raw_helpers is Array:
		for hid_v: Variant in raw_helpers:
			var hid: String = str(hid_v).strip_edges()
			if hid.is_empty():
				continue
			if DataRegistry.get_gacha_helper_data(hid) == null:
				continue
			if not helpers.has(hid):
				helpers.append(hid)
	var has_reward: bool = (
		int(payload.get("gold", 0)) > 0
		or int(payload.get("gacha_token", 0)) > 0
		or not materials.is_empty()
		or not tickets.is_empty()
		or not helpers.is_empty()
	)
	if not has_reward:
		## 空配布は投入しない（誤 enqueue 防止）。
		return {}
	return {
		"id": _make_id(),
		"title": title.substr(0, 32),
		"message": str(payload.get("message", "")).substr(0, 200),
		"gold": maxi(0, int(payload.get("gold", 0))),
		"gacha_token": maxi(0, int(payload.get("gacha_token", 0))),
		"materials": materials,
		"tickets": tickets,
		"helpers": helpers,
		"source": str(payload.get("source", "ops")),
		"created_at": int(payload.get("created_at", Time.get_unix_time_from_system())),
		"claimed": false,
		"claimed_at": 0,
	}


static func _apply_rewards(entry: Dictionary) -> Dictionary:
	var applied: Dictionary = {
		"gold": 0,
		"gacha_token": 0,
		"materials": {},
		"tickets": {},
		"helpers": [],
	}
	var gold: int = int(entry.get("gold", 0))
	if gold > 0:
		GameState.gold += gold
		applied["gold"] = gold
	var tokens: int = int(entry.get("gacha_token", 0))
	if tokens > 0:
		GameState.gacha_token += tokens
		applied["gacha_token"] = tokens
	var materials: Variant = entry.get("materials", {})
	if materials is Dictionary:
		var applied_mats: Dictionary = {}
		for mat_id: Variant in materials:
			var qty: int = int(materials[mat_id])
			if qty <= 0:
				continue
			GameState.add_material(str(mat_id), qty)
			applied_mats[str(mat_id)] = qty
		applied["materials"] = applied_mats
	var tickets: Variant = entry.get("tickets", {})
	if tickets is Dictionary:
		var applied_tickets: Dictionary = {}
		for tid: Variant in tickets:
			var tqty: int = int(tickets[tid])
			if tqty <= 0:
				continue
			TicketInventory.add(str(tid), tqty)
			applied_tickets[str(tid)] = tqty
		applied["tickets"] = applied_tickets
	var helpers: Variant = entry.get("helpers", [])
	if helpers is Array:
		var applied_helpers: Array = []
		for hid_v: Variant in helpers:
			var grant: Dictionary = _grant_helper(str(hid_v))
			if bool(grant.get("ok", false)):
				applied_helpers.append(grant)
		applied["helpers"] = applied_helpers
	return applied


## 助っ人付与。未所持→ロスター加入、所持済→限界突破カウント+1（ガチャと同型）。
static func _grant_helper(helper_id: String) -> Dictionary:
	if helper_id.is_empty():
		return {"ok": false, "reason": "empty"}
	var helper: Resource = DataRegistry.get_gacha_helper_data(helper_id)
	if helper == null:
		return {"ok": false, "reason": "unknown"}
	var is_new: bool = not GameState.owned_helpers.has(helper_id)
	if is_new:
		GameState.owned_helpers[helper_id] = 1
		var adv: Resource = GachaSystem.create_adventurer_from_helper(helper)
		## 配布は playable フラグに関わらずロスターへ入れる。
		if adv != null and not GameState.roster.has(adv):
			var already: bool = false
			var want_id: String = str(adv.id)
			for member in GameState.roster:
				if member != null and str(member.id) == want_id:
					already = true
					break
			if not already:
				GameState.roster.append(adv)
		GameState.normalize_roster_rarity()
		GameState.normalize_all_equipped_skills()
		GameState.normalize_all_equipped_passives()
		return {
			"ok": true,
			"helper_id": helper_id,
			"is_new": true,
			"display_name": str(helper.display_name),
			"breakthrough": 0,
		}
	var prev: int = int(GameState.owned_helpers[helper_id])
	var next: int = prev + 1
	GameState.owned_helpers[helper_id] = next
	var bt: int = _GachaLimitBreak.breakthrough_from_owned_count(next)
	return {
		"ok": true,
		"helper_id": helper_id,
		"is_new": false,
		"display_name": str(helper.display_name),
		"breakthrough": bt,
	}


static func _helper_display_name(helper_id: String) -> String:
	var helper: Resource = DataRegistry.get_gacha_helper_data(helper_id)
	if helper != null:
		return str(helper.display_name)
	return helper_id


static func _ticket_display_name(ticket_id: String) -> String:
	var data: Resource = DataRegistry.get_ticket_data(ticket_id)
	if data != null:
		return str(data.display_name)
	return ticket_id


static func _make_id() -> String:
	return "gift_%d_%d" % [int(Time.get_unix_time_from_system()), randi() % 100000]


static func _format_int(value: int) -> String:
	return _CommanderLifetime._format_int(value)
