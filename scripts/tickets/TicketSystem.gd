class_name TicketSystem
extends RefCounted

## チケット効果の適用（無料ガチャ・レア別限界突破）。

const _GachaLimitBreak = preload("res://scripts/gacha/GachaLimitBreak.gd")
const _GachaRarityConfig = preload("res://scripts/gacha/GachaRarityConfig.gd")


static func free_gacha_qty() -> int:
	return TicketInventory.get_qty(TicketIds.GACHA_FREE)


static func can_use_free_gacha() -> bool:
	return free_gacha_qty() > 0


static func try_consume_free_gacha() -> bool:
	return TicketInventory.consume(TicketIds.GACHA_FREE, 1)


static func refund_free_gacha() -> void:
	TicketInventory.add(TicketIds.GACHA_FREE, 1)


static func ticket_id_for_limit_break_rarity(rarity: int) -> String:
	match _GachaRarityConfig.clamp_rarity(rarity):
		3:
			return TicketIds.LB_STAR3
		4:
			return TicketIds.LB_STAR4
		_:
			return ""


static func helper_id_from_member(member: Resource) -> String:
	if member == null:
		return ""
	var mid: String = str(member.id)
	if mid.begins_with("gacha_"):
		return mid.trim_prefix("gacha_")
	return ""


static func can_limit_break_helper(helper_id: String) -> Dictionary:
	if helper_id.is_empty():
		return {"ok": false, "reason": "no_helper"}
	if not GameState.owned_helpers.has(helper_id):
		return {"ok": false, "reason": "not_owned"}
	var helper: Resource = DataRegistry.get_gacha_helper_data(helper_id)
	if helper == null:
		return {"ok": false, "reason": "unknown_helper"}
	var rarity: int = _GachaRarityConfig.clamp_rarity(int(helper.rarity))
	var ticket_id: String = ticket_id_for_limit_break_rarity(rarity)
	if ticket_id.is_empty():
		return {"ok": false, "reason": "no_ticket_for_rarity", "rarity": rarity}
	if TicketInventory.get_qty(ticket_id) <= 0:
		return {"ok": false, "reason": "no_ticket", "ticket_id": ticket_id, "rarity": rarity}
	var count: int = int(GameState.owned_helpers[helper_id])
	var bt: int = _GachaLimitBreak.breakthrough_from_owned_count(count)
	if bt >= _GachaLimitBreak.MAX_BREAKTHROUGH:
		return {"ok": false, "reason": "max_breakthrough", "ticket_id": ticket_id, "rarity": rarity}
	return {
		"ok": true,
		"ticket_id": ticket_id,
		"rarity": rarity,
		"breakthrough": bt,
		"owned_count": count,
	}


static func can_limit_break_member(member: Resource) -> Dictionary:
	return can_limit_break_helper(helper_id_from_member(member))


static func apply_limit_break_helper(helper_id: String) -> Dictionary:
	var check: Dictionary = can_limit_break_helper(helper_id)
	if not bool(check.get("ok", false)):
		return check
	var ticket_id: String = str(check.get("ticket_id", ""))
	if not TicketInventory.consume(ticket_id, 1):
		return {"ok": false, "reason": "consume_failed", "ticket_id": ticket_id}
	var prev: int = int(GameState.owned_helpers.get(helper_id, 1))
	var next: int = prev + 1
	GameState.owned_helpers[helper_id] = next
	var bt: int = _GachaLimitBreak.breakthrough_from_owned_count(next)
	return {
		"ok": true,
		"helper_id": helper_id,
		"ticket_id": ticket_id,
		"breakthrough": bt,
		"owned_count": next,
	}


static func apply_limit_break_member(member: Resource) -> Dictionary:
	return apply_limit_break_helper(helper_id_from_member(member))


static func display_name(ticket_id: String) -> String:
	var data: Resource = DataRegistry.get_ticket_data(ticket_id)
	if data != null and not str(data.display_name).is_empty():
		return str(data.display_name)
	return ticket_id
