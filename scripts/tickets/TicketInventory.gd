class_name TicketInventory
extends RefCounted

## GameState.ticket_inventory 操作。


static func get_qty(ticket_id: String) -> int:
	if ticket_id.is_empty():
		return 0
	return maxi(0, int(GameState.ticket_inventory.get(ticket_id, 0)))


static func add(ticket_id: String, amount: int) -> void:
	if ticket_id.is_empty() or amount <= 0:
		return
	if DataRegistry.get_ticket_data(ticket_id) == null:
		push_warning("TicketInventory.add: unknown ticket_id=%s" % ticket_id)
		return
	GameState.ticket_inventory[ticket_id] = get_qty(ticket_id) + amount


static func consume(ticket_id: String, amount: int = 1) -> bool:
	if ticket_id.is_empty() or amount <= 0:
		return false
	var have: int = get_qty(ticket_id)
	if have < amount:
		return false
	var next: int = have - amount
	if next <= 0:
		GameState.ticket_inventory.erase(ticket_id)
	else:
		GameState.ticket_inventory[ticket_id] = next
	return true


static func sanitize() -> void:
	var cleaned: Dictionary = {}
	for tid in GameState.ticket_inventory.keys():
		var id_str: String = str(tid)
		if DataRegistry.get_ticket_data(id_str) == null:
			continue
		var qty: int = int(GameState.ticket_inventory[tid])
		if qty > 0:
			cleaned[id_str] = qty
	GameState.ticket_inventory = cleaned


static func grant_debug_stock(each: int = 10) -> void:
	for tid in TicketIds.ALL:
		add(tid, each)
