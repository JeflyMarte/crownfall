class_name AbyssMilestoneRewards
extends RefCounted

## 深層マイルストーン報酬（P3-DG-ABYSS-001-B）。案R＋66F=R1。

const _AbyssDungeonConfig := preload("res://scripts/dungeon/AbyssDungeonConfig.gd")
const _AbyssLegendaryWeapons := preload("res://scripts/dungeon/AbyssLegendaryWeapons.gd")
const _TicketInventory := preload("res://scripts/tickets/TicketInventory.gd")

const MILESTONE_FLOORS: Array[int] = [33, 66, 99]
const ENDLESS_BAG_START: int = 100
const ENDLESS_BAG_STEP: int = 10

## floor → { "first": {...}, "repeat": {...} }
## materials: { id: qty }, tokens: int, tickets: { id: qty }, abyss_legendary: bool
## P3-BAL-ECO-001: 深層魔晶石を通常クリア帯より厚く（初回100/200/300）
const REWARDS: Dictionary = {
	33: {
		"first": {
			"tokens": 100,
			"materials": {"epic_ore": 5, "elite_relic_shard": 2},
		},
		"repeat": {
			"materials": {"epic_ore": 2},
		},
	},
	66: {
		"first": {
			"tokens": 200,
			"materials": {"epic_ore": 8, "elite_relic_shard": 3},
			"tickets": {"ticket_lb_star3": 1},
		},
		"repeat": {
			"tokens": 25,
			"materials": {"epic_ore": 3},
		},
	},
	99: {
		"first": {
			"tokens": 300,
			"materials": {"elite_relic_shard": 5},
			"abyss_legendary": true,
		},
		"repeat": {
			"tokens": 50,
			"materials": {"elite_relic_shard": 3},
		},
	},
}

const ENDLESS_BAG: Dictionary = {
	"materials": {"epic_ore": 1},
}


static func try_claim_for_floor(dungeon_id: String, floor_1based: int) -> Array[Dictionary]:
	var granted: Array[Dictionary] = []
	if not _AbyssDungeonConfig.is_abyss_dungeon_id(dungeon_id) or floor_1based <= 0:
		return granted
	for ms: int in MILESTONE_FLOORS:
		if floor_1based == ms:
			var pack: Dictionary = _claim_milestone(dungeon_id, ms)
			if not pack.is_empty():
				granted.append(pack)
	if (
		floor_1based >= ENDLESS_BAG_START
		and floor_1based % ENDLESS_BAG_STEP == 0
	):
		var bag: Dictionary = _claim_endless_bag(dungeon_id, floor_1based)
		if not bag.is_empty():
			granted.append(bag)
	return granted


static func _claim_milestone(dungeon_id: String, floor: int) -> Dictionary:
	var table: Dictionary = REWARDS.get(floor, {})
	if table.is_empty():
		return {}
	var first_done: bool = _is_first_claimed(dungeon_id, floor)
	var kind: String = "repeat" if first_done else "first"
	var reward: Dictionary = table.get(kind, {})
	if reward.is_empty():
		return {}
	_apply_reward(reward, dungeon_id)
	if not first_done:
		_mark_first_claimed(dungeon_id, floor)
	var summary: Dictionary = reward.duplicate(true)
	summary["floor"] = floor
	summary["kind"] = kind
	summary["label"] = _label_for(floor, kind)
	_append_run_notice(str(summary["label"]))
	return summary


static func _claim_endless_bag(dungeon_id: String, floor: int) -> Dictionary:
	var key: String = "bag_%d" % floor
	if _is_bag_claimed(dungeon_id, key):
		return {}
	_apply_reward(ENDLESS_BAG, dungeon_id)
	_mark_bag_claimed(dungeon_id, key)
	var summary: Dictionary = ENDLESS_BAG.duplicate(true)
	summary["floor"] = floor
	summary["kind"] = "bag"
	summary["label"] = "深層 F%d 踏破袋" % floor
	_append_run_notice(str(summary["label"]))
	return summary


static func _apply_reward(reward: Dictionary, dungeon_id: String = "") -> void:
	var tokens: int = int(reward.get("tokens", 0))
	if tokens > 0:
		## 実付与は Result の bank（last_run_token_reward）。二重加算しない。
		GameState.last_run_token_reward += tokens
	var mats: Variant = reward.get("materials", {})
	if mats is Dictionary:
		for mat_id in mats.keys():
			GameState.add_material(str(mat_id), int(mats[mat_id]))
	var tickets: Variant = reward.get("tickets", {})
	if tickets is Dictionary:
		for tid in tickets.keys():
			_TicketInventory.add(str(tid), int(tickets[tid]))
	if bool(reward.get("abyss_legendary", false)) and not dungeon_id.is_empty():
		var granted: Resource = _AbyssLegendaryWeapons.grant_for_abyss(dungeon_id)
		var wname: String = _AbyssLegendaryWeapons.display_name_for_abyss(dungeon_id)
		if granted != null and not wname.is_empty():
			_append_run_notice("深層限定レジェンド獲得：%s" % wname)
		elif not wname.is_empty():
			_append_run_notice("深層限定レジェンド：%s（付与失敗）" % wname)
		else:
			_append_run_notice("深層限定レジェンド（未対応 Biome）")


static func _label_for(floor: int, kind: String) -> String:
	var tag: String = "初回" if kind == "first" else "再到達"
	return "深層マイルストーン F%d（%s）" % [floor, tag]


static func _append_run_notice(line: String) -> void:
	if line.is_empty():
		return
	if not (GameState.last_run_abyss_notices is Array):
		GameState.last_run_abyss_notices = []
	GameState.last_run_abyss_notices.append(line)


static func _progress(dungeon_id: String) -> Dictionary:
	return GameState.dungeon_progress.get(dungeon_id, {})


static func _save_progress(dungeon_id: String, progress: Dictionary) -> void:
	GameState.dungeon_progress[dungeon_id] = progress


static func _ms_root(progress: Dictionary) -> Dictionary:
	var root: Variant = progress.get("abyss_milestones", {})
	if not root is Dictionary:
		return {"first": {}, "bags": {}}
	var d: Dictionary = (root as Dictionary).duplicate(true)
	if not d.has("first") or not d["first"] is Dictionary:
		d["first"] = {}
	if not d.has("bags") or not d["bags"] is Dictionary:
		d["bags"] = {}
	return d


static func _is_first_claimed(dungeon_id: String, floor: int) -> bool:
	var progress: Dictionary = _progress(dungeon_id)
	var root: Dictionary = _ms_root(progress)
	return bool((root["first"] as Dictionary).get(str(floor), false))


static func _mark_first_claimed(dungeon_id: String, floor: int) -> void:
	var progress: Dictionary = _progress(dungeon_id)
	var root: Dictionary = _ms_root(progress)
	var first: Dictionary = root["first"]
	first[str(floor)] = true
	root["first"] = first
	progress["abyss_milestones"] = root
	_save_progress(dungeon_id, progress)


static func _is_bag_claimed(dungeon_id: String, key: String) -> bool:
	var progress: Dictionary = _progress(dungeon_id)
	var root: Dictionary = _ms_root(progress)
	return bool((root["bags"] as Dictionary).get(key, false))


static func _mark_bag_claimed(dungeon_id: String, key: String) -> void:
	var progress: Dictionary = _progress(dungeon_id)
	var root: Dictionary = _ms_root(progress)
	var bags: Dictionary = root["bags"]
	bags[key] = true
	root["bags"] = bags
	progress["abyss_milestones"] = root
	_save_progress(dungeon_id, progress)
