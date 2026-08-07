class_name SurveyCompleteRewards
extends RefCounted

## ダンジョン SURVEY 100%（完全調査）景品（P3-SURVEY-COMPLETE-001）。
## 100%到達ごとに付与し、ゲージを 0% へ戻す（案Aサイクル）。
## アッシュ／インクは未所持時のみ（2周目以降は出さない）。
## 2026-08-07: チケット確定廃止。魔晶石×10。招待状／封蔵は抽選のみ。

const _SurveyConfig := preload("res://scripts/survey/SurveyConfig.gd")
const _TicketInventory := preload("res://scripts/tickets/TicketInventory.gd")
const _PetSystem := preload("res://scripts/pets/PetSystem.gd")

## 限界突破券抽選（確定付与しない）
const P_LB_STAR2: float = 0.05
const P_LB_STAR3: float = 0.05
const P_LB_STAR4: float = 0.01
## 招待状チケット抽選（確定付与しない）
const P_GACHA_MOURNGATE: float = 0.30
const P_GACHA_WHISPERWOOD: float = 0.40
const P_GACHA_MISTFEN: float = 0.25
const P_GACHA_BLACKSHORE: float = 0.35
const P_GACHA_FROSTRIDGE: float = 0.40
## 封蔵開封券（招待券と混ぜる／P3-GACHA-EQ-SEAL-TICKET-001）
const P_SEAL_MOURNGATE: float = 0.30
const P_SEAL_WHISPERWOOD: float = 0.40
const P_SEAL_MISTFEN: float = 0.25
const P_SEAL_BLACKSHORE: float = 0.50
const P_SEAL_FROSTRIDGE: float = 0.50

## dungeon_id → 確定報酬定義。
## gold / token / materials{id:qty} / tickets{id:qty} / pet_id
## lb_rolls / seal_rolls / gacha_rolls: Array[{id, p}] — 独立抽選
const TABLE: Dictionary = {
	"mourngate": {
		"gold": 200,
		"token": 100,
		"gacha_rolls": [{"id": "ticket_gacha_free", "p": P_GACHA_MOURNGATE}],
		"seal_rolls": [{"id": "ticket_seal_free", "p": P_SEAL_MOURNGATE}],
	},
	"whisperwood": {
		"gold": 350,
		"token": 150,
		"materials": {"base_ore": 5, "relic_shard": 2},
		"pet_id": "pet_ash",
		"gacha_rolls": [{"id": "ticket_gacha_free", "p": P_GACHA_WHISPERWOOD}],
		"seal_rolls": [{"id": "ticket_seal_free", "p": P_SEAL_WHISPERWOOD}],
	},
	"mistfen": {
		"gold": 500,
		"token": 200,
		"materials": {"base_ore": 8, "relic_shard": 4},
		"lb_rolls": [{"id": "ticket_lb_star2", "p": P_LB_STAR2}],
		"gacha_rolls": [{"id": "ticket_gacha_free", "p": P_GACHA_MISTFEN}],
		"seal_rolls": [{"id": "ticket_seal_free", "p": P_SEAL_MISTFEN}],
	},
	"blackshore": {
		"gold": 650,
		"token": 250,
		"materials": {"base_ore": 10, "relic_shard": 5},
		"pet_id": "pet_ink",
		"lb_rolls": [
			{"id": "ticket_lb_star3", "p": P_LB_STAR3},
			{"id": "ticket_lb_star4", "p": P_LB_STAR4},
		],
		"gacha_rolls": [{"id": "ticket_gacha_free", "p": P_GACHA_BLACKSHORE}],
		"seal_rolls": [{"id": "ticket_seal_free", "p": P_SEAL_BLACKSHORE}],
	},
	"frostridge": {
		"gold": 800,
		"token": 300,
		"lb_rolls": [
			{"id": "ticket_lb_star3", "p": P_LB_STAR3},
			{"id": "ticket_lb_star4", "p": P_LB_STAR4},
		],
		"gacha_rolls": [{"id": "ticket_gacha_free", "p": P_GACHA_FROSTRIDGE}],
		"seal_rolls": [{"id": "ticket_seal_free", "p": P_SEAL_FROSTRIDGE}],
	},
}


static func has_table(dungeon_id: String) -> bool:
	return TABLE.has(dungeon_id)


## 一度でも完全調査を達成したか（セーブ互換・UI用。繰り返し景品の阻害には使わない）。
static func is_claimed(dungeon_id: String) -> bool:
	return bool(GameState.hub_survey_complete_claimed.get(dungeon_id, false))


static func mark_claimed(dungeon_id: String) -> void:
	GameState.hub_survey_complete_claimed[dungeon_id] = true


## UI 用: 確定景品の表示エントリ（抽選は chance_note 付き）。所持済みペットは出さない。
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
	if not pet_id.is_empty() and not _PetSystem.owns_pet(pet_id):
		out.append({"kind": "pet", "id": pet_id, "qty": 1, "label": pet_id})
	var lb_rolls: Variant = d.get("lb_rolls", [])
	if lb_rolls is Array:
		for roll_v in lb_rolls as Array:
			if not (roll_v is Dictionary):
				continue
			var roll: Dictionary = roll_v
			var tid: String = str(roll.get("id", ""))
			var p: float = float(roll.get("p", 0.0))
			if tid.is_empty() or p <= 0.0:
				continue
			out.append({
				"kind": "ticket",
				"id": tid,
				"qty": 1,
				"label": tid,
				"chance_note": _pct_label(p),
			})
	var seal_rolls: Variant = d.get("seal_rolls", [])
	if seal_rolls is Array:
		for roll_v2 in seal_rolls as Array:
			if not (roll_v2 is Dictionary):
				continue
			var sroll: Dictionary = roll_v2
			var sid: String = str(sroll.get("id", ""))
			var sp: float = float(sroll.get("p", 0.0))
			if sid.is_empty() or sp <= 0.0:
				continue
			out.append({
				"kind": "ticket",
				"id": sid,
				"qty": 1,
				"label": sid,
				"chance_note": _pct_label(sp),
			})
	var gacha_rolls: Variant = d.get("gacha_rolls", [])
	if gacha_rolls is Array:
		for roll_v3 in gacha_rolls as Array:
			if not (roll_v3 is Dictionary):
				continue
			var groll: Dictionary = roll_v3
			var gid: String = str(groll.get("id", ""))
			var gp: float = float(groll.get("p", 0.0))
			if gid.is_empty() or gp <= 0.0:
				continue
			out.append({
				"kind": "ticket",
				"id": gid,
				"qty": 1,
				"label": gid,
				"chance_note": _pct_label(gp),
			})
	return out


static func _pct_label(p: float) -> String:
	var pct: float = p * 100.0
	if is_equal_approx(pct, roundf(pct)):
		return "%d%%" % int(round(pct))
	return "%.1f%%" % pct


## UI 表示名（個数付き）。
static func preview_display_name(entry: Dictionary) -> String:
	var kind: String = str(entry.get("kind", ""))
	var qty: int = int(entry.get("qty", 1))
	match kind:
		"gold":
			return "ゴールド ×%d" % qty
		"token":
			return "魔晶石 ×%d" % qty
		"material":
			var mid: String = str(entry.get("id", ""))
			var mname: String = DataRegistry.get_material_name(mid)
			if mname.is_empty():
				mname = mid
			return "%s ×%d" % [mname, qty]
		"ticket":
			var tid: String = str(entry.get("id", ""))
			var tname: String = TicketSystem.display_name(tid)
			if tname.is_empty():
				tname = str(entry.get("label", tid))
			return "%s ×%d" % [tname, qty]
		"pet":
			var pet_id: String = str(entry.get("id", ""))
			var pet_data: Resource = _PetSystem.get_pet_data(pet_id)
			var pname: String = str(pet_data.display_name) if pet_data != null else pet_id
			return pname
		_:
			return str(entry.get("label", kind))


## 確率表示（空なら確定）。
static func preview_chance_label(entry: Dictionary) -> String:
	var note: String = str(entry.get("chance_note", "")).strip_edges()
	if note.is_empty():
		return "確定"
	return note


## アイコン行の重複排除キー。
static func preview_dedupe_key(entry: Dictionary) -> String:
	var kind: String = str(entry.get("kind", ""))
	match kind:
		"gold", "token":
			return kind
		"material", "ticket", "pet":
			return "%s:%s" % [kind, str(entry.get("id", ""))]
		_:
			return "%s:%s" % [kind, str(entry.get("label", ""))]


## 100%到達時: 景品付与 → ゲージ 0% リセット。繰り返し可。ペットは未所持時のみ。
static func try_claim(dungeon_id: String, notify: bool = true) -> Dictionary:
	if dungeon_id.is_empty() or not has_table(dungeon_id):
		return {"ok": false, "reason": "no_table"}
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
	## 限界突破券（独立抽選・外れ補償なし）
	var lb_rolls: Variant = def.get("lb_rolls", [])
	var lb_hits: PackedStringArray = PackedStringArray()
	if lb_rolls is Array:
		for roll_v in lb_rolls as Array:
			if not (roll_v is Dictionary):
				continue
			var roll: Dictionary = roll_v
			var tid: String = str(roll.get("id", ""))
			var p: float = float(roll.get("p", 0.0))
			if tid.is_empty() or p <= 0.0:
				continue
			if randf() < p:
				_TicketInventory.add(tid, 1)
				ticket_out[tid] = int(ticket_out.get(tid, 0)) + 1
				lb_hits.append(tid)
	## 封蔵開封券（独立抽選）
	var seal_rolls: Variant = def.get("seal_rolls", [])
	if seal_rolls is Array:
		for roll_v2 in seal_rolls as Array:
			if not (roll_v2 is Dictionary):
				continue
			var sroll: Dictionary = roll_v2
			var sid: String = str(sroll.get("id", ""))
			var sp: float = float(sroll.get("p", 0.0))
			if sid.is_empty() or sp <= 0.0:
				continue
			if randf() < sp:
				_TicketInventory.add(sid, 1)
				ticket_out[sid] = int(ticket_out.get(sid, 0)) + 1
	## 招待状チケット（独立抽選）
	var gacha_rolls: Variant = def.get("gacha_rolls", [])
	var gacha_hit: bool = false
	if gacha_rolls is Array:
		for roll_v3 in gacha_rolls as Array:
			if not (roll_v3 is Dictionary):
				continue
			var groll: Dictionary = roll_v3
			var gid: String = str(groll.get("id", ""))
			var gp: float = float(groll.get("p", 0.0))
			if gid.is_empty() or gp <= 0.0:
				continue
			if randf() < gp:
				_TicketInventory.add(gid, 1)
				ticket_out[gid] = int(ticket_out.get(gid, 0)) + 1
				gacha_hit = true
	if gacha_rolls is Array and not (gacha_rolls as Array).is_empty():
		granted["lottery"] = "gacha" if gacha_hit else "miss"
	## LB 結果は別キー。lottery（招待券など）を上書きしない。
	if not lb_hits.is_empty():
		granted["lb_hits"] = lb_hits.duplicate()
		if str(granted.get("lottery", "")).is_empty():
			granted["lottery"] = "lb:" + ",".join(lb_hits)
	granted["tickets"] = ticket_out
	## ペットは未所持時のみ解放・通知（2周目以降は出さない）
	var pet_id: String = str(def.get("pet_id", ""))
	if not pet_id.is_empty() and not _PetSystem.owns_pet(pet_id):
		if _PetSystem.unlock_pet(pet_id, false):
			granted["pet_id"] = pet_id
	mark_claimed(dungeon_id)
	## 案A: 付与後に通常調査（0%）へ戻す
	GameState.hub_survey_progress[dungeon_id] = 0.0
	if notify:
		_queue_notice(dungeon_id, granted)
	return granted


## ロード時: 100%で止まっているセーブを清算（付与＋0%）。既に claimed なら付与せずリセットのみ。
static func sync_all_pending(notify: bool = false) -> void:
	const _SurveySystem := preload("res://scripts/survey/SurveySystem.gd")
	for dungeon_id_v in TABLE.keys():
		var dungeon_id: String = str(dungeon_id_v)
		if _SurveySystem.get_survey_percent(dungeon_id) + 0.001 < _SurveyConfig.SURVEY_COMPLETE_PERCENT:
			continue
		if is_claimed(dungeon_id):
			GameState.hub_survey_progress[dungeon_id] = 0.0
		else:
			try_claim(dungeon_id, notify)


## 付与結果 → ポップ用エントリ（実際に付与されたもののみ。抽選外れは出ない）。
static func granted_entries(granted: Dictionary) -> Array:
	var out: Array = []
	var gold: int = int(granted.get("gold", 0))
	if gold > 0:
		out.append({"kind": "gold", "qty": gold, "label": "ゴールド"})
	var token: int = int(granted.get("token", 0))
	if token > 0:
		out.append({"kind": "token", "qty": token, "label": "魔晶石"})
	var mats: Variant = granted.get("materials", {})
	if mats is Dictionary:
		for mid in mats.keys():
			var qty: int = int(mats[mid])
			if qty <= 0:
				continue
			var mname: String = DataRegistry.get_material_name(str(mid))
			if mname.is_empty():
				mname = str(mid)
			out.append({"kind": "material", "id": str(mid), "qty": qty, "label": mname})
	var tickets: Variant = granted.get("tickets", {})
	if tickets is Dictionary:
		for tid in tickets.keys():
			var tqty: int = int(tickets[tid])
			if tqty <= 0:
				continue
			var td: Resource = DataRegistry.get_ticket_data(str(tid))
			var tname: String = str(td.display_name) if td != null else str(tid)
			out.append({"kind": "ticket", "id": str(tid), "qty": tqty, "label": tname})
	var pet_id: String = str(granted.get("pet_id", "")).strip_edges()
	if not pet_id.is_empty():
		var pet: Resource = _PetSystem.get_pet_data(pet_id)
		var pname: String = str(pet.display_name) if pet != null else pet_id
		out.append({"kind": "pet", "id": pet_id, "qty": 1, "label": pname})
	return out


## 付与結果の表示用内訳（テキストフォールバック）。
static func format_granted_detail(granted: Dictionary) -> String:
	var parts: PackedStringArray = []
	for entry_v in granted_entries(granted):
		if not (entry_v is Dictionary):
			continue
		var entry: Dictionary = entry_v
		var kind: String = str(entry.get("kind", ""))
		var qty: int = int(entry.get("qty", 0))
		var label: String = str(entry.get("label", ""))
		match kind:
			"gold":
				parts.append("Gold %d" % qty)
			"token":
				parts.append("魔晶石 %d" % qty)
			"pet":
				parts.append(label)
			_:
				parts.append("%s ×%d" % [label, qty])
	return "、".join(parts) if not parts.is_empty() else "報酬"


## デバッグ／プレビュー用: 確定景品だけのサンプル付与辞書（抽選は含めない）。
static func sample_guaranteed_granted(dungeon_id: String) -> Dictionary:
	var def: Variant = TABLE.get(dungeon_id, {})
	if not (def is Dictionary):
		return {}
	var d: Dictionary = def as Dictionary
	var out: Dictionary = {}
	var gold: int = int(d.get("gold", 0))
	if gold > 0:
		out["gold"] = gold
	var token: int = int(d.get("token", 0))
	if token > 0:
		out["token"] = token
	var mats: Variant = d.get("materials", {})
	if mats is Dictionary and not (mats as Dictionary).is_empty():
		out["materials"] = (mats as Dictionary).duplicate(true)
	var tickets: Variant = d.get("tickets", {})
	if tickets is Dictionary and not (tickets as Dictionary).is_empty():
		out["tickets"] = (tickets as Dictionary).duplicate(true)
	var pet_id: String = str(d.get("pet_id", ""))
	if not pet_id.is_empty() and not _PetSystem.owns_pet(pet_id):
		out["pet_id"] = pet_id
	return out


static func _queue_notice(dungeon_id: String, granted: Dictionary) -> void:
	var data: Resource = DataRegistry.get_dungeon_data(dungeon_id)
	var name_str: String = dungeon_id
	if data != null and "display_name" in data and str(data.display_name) != "":
		name_str = str(data.display_name)
	var detail: String = format_granted_detail(granted)
	var rewards: Array = granted_entries(granted)
	const _ContentUnlockNotice := preload("res://scripts/ui/ContentUnlockNotice.gd")
	_ContentUnlockNotice._queue_entry(
		"survey_complete",
		dungeon_id,
		name_str,
		-1,
		detail,
		rewards
	)
