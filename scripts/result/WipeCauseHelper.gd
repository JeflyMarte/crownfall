class_name WipeCauseHelper
extends RefCounted

## 全滅リザルト用の敗因スナップショット（P3-UX-WIPE-CAUSE-001）。


static func build_snapshot(
	dungeon_controller: Node,
	combat_controller: Node,
	cause_kind: String = ""
) -> Dictionary:
	var snap: Dictionary = {
		"floor_text": "F1",
		"room_type": Enums.RoomType.COMBAT,
		"room_label": "戦闘",
		"cause_kind": "unknown",
		"enemy_id": "",
		"enemy_name": "",
	}
	if dungeon_controller != null and dungeon_controller.has_method("get_display_floor_text"):
		snap["floor_text"] = str(dungeon_controller.call("get_display_floor_text"))
	if dungeon_controller != null and "current_room_type" in dungeon_controller:
		var room_type: int = int(dungeon_controller.current_room_type)
		snap["room_type"] = room_type
		snap["room_label"] = _room_label(room_type)
	var kind: String = cause_kind.strip_edges()
	if kind.is_empty():
		if combat_controller != null and bool(combat_controller.get("is_in_combat")):
			kind = "combat"
		elif int(snap.get("room_type", Enums.RoomType.COMBAT)) == Enums.RoomType.TRAP:
			kind = "trap"
		else:
			kind = "unknown"
	snap["cause_kind"] = kind
	if kind == "trap":
		snap["room_label"] = "罠"
		return snap
	if combat_controller == null:
		return snap
	var enemy_data: Resource = null
	if combat_controller.has_method("get_enemy_data_at"):
		var slot: int = int(combat_controller.get("active_enemy_index"))
		if slot >= 0:
			enemy_data = combat_controller.call("get_enemy_data_at", slot) as Resource
	if enemy_data == null and "current_enemy_data" in combat_controller:
		enemy_data = combat_controller.current_enemy_data as Resource
	if enemy_data != null:
		snap["enemy_id"] = str(enemy_data.id)
		var ename: String = str(enemy_data.display_name)
		snap["enemy_name"] = ename if not ename.is_empty() else "敵"
	return snap


static func summary_line(snapshot: Dictionary) -> String:
	if snapshot.is_empty():
		return ""
	var floor_text: String = str(snapshot.get("floor_text", "F?"))
	var kind: String = str(snapshot.get("cause_kind", ""))
	match kind:
		"trap":
			return "%s・罠で全滅" % floor_text
		"combat", "unknown":
			var room_label: String = _combat_room_phrase(int(snapshot.get("room_type", Enums.RoomType.COMBAT)))
			return "%s・%sで全滅" % [floor_text, room_label]
		_:
			return "%s・探索中に全滅" % floor_text


static func detail_line(snapshot: Dictionary, combat_stats: Dictionary) -> String:
	if snapshot.is_empty():
		return ""
	var enemy_name: String = str(snapshot.get("enemy_name", ""))
	if not enemy_name.is_empty() and str(snapshot.get("cause_kind", "")) != "trap":
		return "主因: %s" % enemy_name
	return hint_line(combat_stats)


static func hint_line(combat_stats: Dictionary) -> String:
	if combat_stats.is_empty():
		return ""
	var total_taken: int = 0
	var total_heal: int = 0
	var max_taken: int = 0
	var max_member_id: String = ""
	for member_id: String in combat_stats.keys():
		var row: Dictionary = combat_stats[member_id]
		var taken: int = int(row.get("damage_taken", 0))
		total_taken += taken
		total_heal += int(row.get("heal_total", 0))
		if taken > max_taken:
			max_taken = taken
			max_member_id = member_id
	if total_taken <= 0:
		if total_heal <= 0:
			return "回復が追いつかなかった"
		return ""
	if max_taken >= int(round(float(total_taken) * 0.45)) and not max_member_id.is_empty():
		var name: String = _member_display_name(max_member_id)
		if not name.is_empty():
			return "%sへの集中攻撃が厳しかった" % name
	if total_heal < int(round(float(total_taken) * 0.08)):
		return "回復が追いつかなかった"
	return ""


static func _combat_room_phrase(room_type: int) -> String:
	match room_type:
		Enums.RoomType.ELITE:
			return "エリート戦"
		Enums.RoomType.BOSS:
			return "ボス戦"
		Enums.RoomType.TRAP:
			return "罠"
		Enums.RoomType.COMBAT:
			return "戦闘"
		_:
			return _room_label(room_type)


static func _room_label(room_type: int) -> String:
	match room_type:
		Enums.RoomType.START:
			return "開始"
		Enums.RoomType.COMBAT:
			return "戦闘"
		Enums.RoomType.EVENT:
			return "碑文"
		Enums.RoomType.TREASURE:
			return "宝箱"
		Enums.RoomType.ELITE:
			return "エリート"
		Enums.RoomType.TRAP:
			return "罠"
		Enums.RoomType.BOSS:
			return "ボス"
		Enums.RoomType.HEAL:
			return "回復"
		Enums.RoomType.EXIT:
			return "出口"
		_:
			return "探索"


static func _member_display_name(member_id: String) -> String:
	if member_id.is_empty():
		return ""
	for m: Resource in GameState.party_members:
		if m != null and str(m.id) == member_id:
			return str(m.display_name)
	if GameState.active_pet != null and str(GameState.active_pet.id) == member_id:
		return str(GameState.active_pet.display_name)
	return ""
