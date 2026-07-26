class_name SurveyCompleteRewards
extends RefCounted

## ダンジョン SURVEY 100%（完全調査）一回限り景品（P3-SURVEY-COMPLETE-001 / 案A'′）。

const _SurveyConfig := preload("res://scripts/survey/SurveyConfig.gd")
const _TicketInventory := preload("res://scripts/tickets/TicketInventory.gd")
const _PetSystem := preload("res://scripts/pets/PetSystem.gd")

## ★4抽選（確定にしない）
const P_LB4_BLACKSHORE: float = 0.03
const P_LB4_FROSTRIDGE: float = 0.08
const P_GACHA_MISTFEN: float = 0.50

## dungeon_id → 確定報酬定義。
## gold / token / materials{id:qty} / tickets{id:qty} / pet_id / lottery(kind)
const TABLE: Dictionary = {
	"mourngate": {
		"gold": 500,
		"token": 30,
		"tickets": {"ticket_gacha_free": 1},
	},
	"whisperwood": {
		"gold": 800,
		"token": 50,
		"materials": {"base_ore": 8, "relic_shard": 4},
		"tickets": {"ticket_gacha_free": 1},
		"pet_id": "pet_ash",
	},
	"mistfen": {
		"gold": 1200,
		"token": 80,
		"materials": {"base_ore": 12, "relic_shard": 8},
		"tickets": {"ticket_lb_star2": 1},
		"lottery": "mistfen_gacha",
	},
	"blackshore": {
		"gold": 1500,
		"token": 100,
		"materials": {"base_ore": 15, "relic_shard": 10},
		"tickets": {"ticket_lb_star3": 1},
		"pet_id": "pet_ink",
		"lottery": "blackshore_lb4",
	},
	"frostridge": {
		"gold": 2000,
		"token": 150,
		"tickets": {"ticket_lb_star3": 1},
		"lottery": "frostridge_lb4",
	},
}


static func has_table(dungeon_id: String) -> bool:
	return TABLE.has(dungeon_id)


static func is_claimed(dungeon_id: String) -> bool:
	return bool(GameState.hub_survey_complete_claimed.get(dungeon_id, false))


static func mark_claimed(dungeon_id: String) -> void:
	GameState.hub_survey_complete_claimed[dungeon_id] = true


## UI 用: 確定景品の表示エントリ（抽選は「低確率★4」等の注記付き）。
static func preview_entries(dungeon_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var def: Variant = TABLE.get(dungeon_id, {})
	if not (def is Dictionary):
		return out
	var d: Dictionary = def as Dictionary
	var gold: int = int(d.get("gold", 0))
	if gold > 0:
		out.append({"kind": "gold", "qty": gold, "label": "ゴールド"})
	var token: int = int(d.get("token", 0))
	if token > 0:
		out.append({"kind": "token", "qty": token, "label": "魔晶石"})
	var mats: Variant = d.get("materials", {})
	if mats is Dictionary:
		for mid in mats.keys():
			out.append({"kind": "material", "id": str(mid), "qty": int(mats[mid]), "label": str(mid)})
	var tickets: Variant = d.get("tickets", {})
	if tickets is Dictionary:
		for tid in tickets.keys():
			out.append({"kind": "ticket", "id": str(tid), "qty": int(tickets[tid]), "label": str(tid)})
	var pet_id: String = str(d.get("pet_id", ""))
	if not pet_id.is_empty():
		out.append({"kind": "pet", "id": pet_id, "qty": 1, "label": pet_id})
	var lottery: String = str(d.get("lottery", ""))
	match lottery:
		"mistfen_gacha":
			out.append({
				"kind": "ticket",
				"id": TicketIds.GACHA_FREE,
				"qty": 1,
				"label": "ガチャチケット",
				"chance_note": "50%",
			})
		"blackshore_lb4":
			out.append({
				"kind": "ticket",
				"id": TicketIds.LB_STAR4,
				"qty": 1,
				"label": "★4限界突破券",
				"chance_note": "3%",
			})
		"frostridge_lb4":
			out.append({
				"kind": "ticket",
				"id": TicketIds.LB_STAR4,
				"qty": 1,
				"label": "★4限界突破券",
				"chance_note": "8%",
			})
	return out


## 100%到達時／ロード同期。未請求のみ付与。
static func try_claim(dungeon_id: String, notify: bool = true) -> Dictionary:
	if dungeon_id.is_empty() or not has_table(dungeon_id):
		return {"ok": false, "reason": "no_table"}
	if is_claimed(dungeon_id):
		return {"ok": false, "reason": "already_claimed"}
	const _SurveySystem := preload("res://scripts/survey/SurveySystem.gd")
	if _SurveySystem.get_survey_percent(dungeon_id) + 0.001 < _SurveyConfig.SURVEY_COMPLETE_PERCENT:
		return {"ok": false, "reason": "not_complete"}
	var def: Dictionary = (TABLE[dungeon_id] as Dictionary).duplicate(true)
	var granted: Dictionary = {
		"ok": true,
		"dungeon_id": dungeon_id,
		"gold": 0,
		"token": 0,
		"materials": {},
		"tickets": {},
		"pet_id": "",
		"lottery": "",
	}
	var gold: int = int(def.get("gold", 0))
	if gold > 0:
		GameState.gold += gold
		granted["gold"] = gold
	var token: int = int(def.get("token", 0))
	if token > 0:
		GameState.gacha_token += token
		granted["token"] = token
	var mats: Variant = def.get("materials", {})
	if mats is Dictionary:
		var mat_out: Dictionary = {}
		for mid in mats.keys():
			var qty: int = int(mats[mid])
			if qty <= 0:
				continue
			GameState.add_material(str(mid), qty)
			mat_out[str(mid)] = qty
		granted["materials"] = mat_out
	var tickets: Variant = def.get("tickets", {})
	var ticket_out: Dictionary = {}
	if tickets is Dictionary:
		for tid in tickets.keys():
			var qty: int = int(tickets[tid])
			if qty <= 0:
				continue
			_TicketInventory.add(str(tid), qty)
			ticket_out[str(tid)] = qty
	## 抽選
	var lottery: String = str(def.get("lottery", ""))
	match lottery:
		"mistfen_gacha":
			if randf() < P_GACHA_MISTFEN:
				_TicketInventory.add(TicketIds.GACHA_FREE, 1)
				ticket_out[TicketIds.GACHA_FREE] = int(ticket_out.get(TicketIds.GACHA_FREE, 0)) + 1
				granted["lottery"] = "gacha"
			else:
				granted["lottery"] = "miss"
		"blackshore_lb4":
			if randf() < P_LB4_BLACKSHORE:
				_TicketInventory.add(TicketIds.LB_STAR4, 1)
				ticket_out[TicketIds.LB_STAR4] = int(ticket_out.get(TicketIds.LB_STAR4, 0)) + 1
				granted["lottery"] = "lb4"
			else:
				GameState.gacha_token += 40
				granted["token"] = int(granted["token"]) + 40
				granted["lottery"] = "token_bonus"
		"frostridge_lb4":
			if randf() < P_LB4_FROSTRIDGE:
				_TicketInventory.add(TicketIds.LB_STAR4, 1)
				ticket_out[TicketIds.LB_STAR4] = int(ticket_out.get(TicketIds.LB_STAR4, 0)) + 1
				granted["lottery"] = "lb4"
			else:
				_TicketInventory.add(TicketIds.LB_STAR2, 1)
				ticket_out[TicketIds.LB_STAR2] = int(ticket_out.get(TicketIds.LB_STAR2, 0)) + 1
				granted["lottery"] = "lb2_consolation"
	granted["tickets"] = ticket_out
	## ペット解放は PetSystem.sync_unlocks_from_survey_progress が担当。
	var pet_id: String = str(def.get("pet_id", ""))
	if not pet_id.is_empty():
		granted["pet_id"] = pet_id
	mark_claimed(dungeon_id)
	if notify:
		_queue_notice(dungeon_id, granted)
	return granted


static func sync_all_pending(notify: bool = false) -> void:
	for dungeon_id_v in TABLE.keys():
		try_claim(str(dungeon_id_v), notify)


static func _queue_notice(dungeon_id: String, granted: Dictionary) -> void:
	var data: Resource = DataRegistry.get_dungeon_data(dungeon_id)
	var name_str: String = dungeon_id
	if data != null and "display_name" in data and str(data.display_name) != "":
		name_str = str(data.display_name)
	var parts: PackedStringArray = []
	if int(granted.get("gold", 0)) > 0:
		parts.append("Gold %d" % int(granted["gold"]))
	if int(granted.get("token", 0)) > 0:
		parts.append("魔晶石 %d" % int(granted["token"]))
	var mats: Variant = granted.get("materials", {})
	if mats is Dictionary:
		for mid in mats.keys():
			parts.append("%s ×%d" % [str(mid), int(mats[mid])])
	var tickets: Variant = granted.get("tickets", {})
	if tickets is Dictionary:
		for tid in tickets.keys():
			var td: Resource = DataRegistry.get_ticket_data(str(tid))
			var tname: String = str(td.display_name) if td != null else str(tid)
			parts.append("%s ×%d" % [tname, int(tickets[tid])])
	var pet_id: String = str(granted.get("pet_id", ""))
	if not pet_id.is_empty():
		var pet: Resource = _PetSystem.get_pet_data(pet_id)
		if pet != null:
			parts.append(str(pet.display_name))
	var detail: String = "、".join(parts) if not parts.is_empty() else "報酬"
	const _ContentUnlockNotice := preload("res://scripts/ui/ContentUnlockNotice.gd")
	_ContentUnlockNotice._queue_entry(
		"survey_complete",
		dungeon_id,
		"完全調査報酬（%s）: %s" % [name_str, detail]
	)
