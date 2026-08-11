class_name WipeCauseHelper
extends RefCounted

## 全滅リザルト用の敗因スナップショット（P3-UX-WIPE-CAUSE-001 / 002）。

const _CombatWeather := preload("res://scripts/combat/CombatWeather.gd")
const _StatusEffectLinkHelper := preload("res://scripts/ui/StatusEffectLinkHelper.gd")

## 全滅時点でヒントに使える味方側の有害ステータス（優先順）。
const _HARMFUL_STATUS_IDS: Array[String] = [
	"poison",
	"bleed",
	"skill_silence",
	"silence",
	"curse",
	"major_curse",
	"stun",
	"fear",
	"vulnerable",
	"armor_break",
]


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
		"enemy_count": 0,
		"weather_id": "",
		"party_status_ids": [],
	}
	if dungeon_controller != null and dungeon_controller.has_method("get_display_floor_text"):
		snap["floor_text"] = str(dungeon_controller.call("get_display_floor_text"))
	if dungeon_controller != null and "current_room_type" in dungeon_controller:
		var room_type: int = int(dungeon_controller.current_room_type)
		snap["room_type"] = room_type
		snap["room_label"] = _room_label(room_type)
	var weather_id: String = str(GameState.current_weather)
	snap["weather_id"] = weather_id
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
	var enemy_count: int = 0
	if combat_controller.has_method("swarm_count"):
		enemy_count = int(combat_controller.call("swarm_count"))
	elif "swarm_data" in combat_controller:
		enemy_count = (combat_controller.swarm_data as Array).size()
	snap["enemy_count"] = enemy_count
	snap["party_status_ids"] = _collect_party_status_ids(combat_controller)
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


## 2〜3行目用。主因＋ヒント（最大2種を1行にまとめる）。
static func detail_lines(snapshot: Dictionary, combat_stats: Dictionary) -> PackedStringArray:
	var lines: PackedStringArray = []
	if snapshot.is_empty():
		return lines
	var primary: String = primary_detail_line(snapshot)
	if not primary.is_empty():
		lines.append(primary)
	var hints: PackedStringArray = collect_hints(snapshot, combat_stats, 2)
	if not hints.is_empty():
		lines.append("／".join(hints))
	elif primary.is_empty():
		## 主因もヒントもない場合は従来の単一ヒントへフォールバック
		var legacy: String = hint_line(combat_stats)
		if not legacy.is_empty():
			lines.append(legacy)
	return lines


static func detail_line(snapshot: Dictionary, combat_stats: Dictionary) -> String:
	return "\n".join(detail_lines(snapshot, combat_stats))


static func primary_detail_line(snapshot: Dictionary) -> String:
	if snapshot.is_empty():
		return ""
	if str(snapshot.get("cause_kind", "")) == "trap":
		return ""
	var enemy_name: String = str(snapshot.get("enemy_name", "")).strip_edges()
	if enemy_name.is_empty():
		return ""
	var enemy_count: int = int(snapshot.get("enemy_count", 0))
	if enemy_count >= 2:
		return "主因: %s（%d体）" % [enemy_name, enemy_count]
	return "主因: %s" % enemy_name


## ヒント候補を優先順で最大 max_count 件返す（攻略強制文は出さない）。
static func collect_hints(
	snapshot: Dictionary,
	combat_stats: Dictionary,
	max_count: int = 2
) -> PackedStringArray:
	var out: PackedStringArray = []
	if max_count <= 0:
		return out
	var focus: String = _hint_focus_fire(combat_stats)
	if not focus.is_empty():
		out.append(focus)
	if out.size() >= max_count:
		return out
	var heal: String = _hint_low_heal(combat_stats)
	if not heal.is_empty():
		out.append(heal)
	if out.size() >= max_count:
		return out
	var status_hint: String = _hint_party_status(snapshot)
	if not status_hint.is_empty():
		out.append(status_hint)
	if out.size() >= max_count:
		return out
	var weather_hint: String = _hint_weather(snapshot)
	if not weather_hint.is_empty():
		out.append(weather_hint)
	return out


static func hint_line(combat_stats: Dictionary) -> String:
	var focus: String = _hint_focus_fire(combat_stats)
	if not focus.is_empty():
		return focus
	return _hint_low_heal(combat_stats)


static func _hint_focus_fire(combat_stats: Dictionary) -> String:
	if combat_stats.is_empty():
		return ""
	var total_taken: int = 0
	var max_taken: int = 0
	var max_member_id: String = ""
	for member_id: String in combat_stats.keys():
		var row: Dictionary = combat_stats[member_id]
		var taken: int = int(row.get("damage_taken", 0))
		total_taken += taken
		if taken > max_taken:
			max_taken = taken
			max_member_id = member_id
	if total_taken <= 0:
		return ""
	if max_taken >= int(round(float(total_taken) * 0.45)) and not max_member_id.is_empty():
		var name: String = _member_display_name(max_member_id)
		if not name.is_empty():
			return "%sへの集中攻撃が厳しかった" % name
	return ""


static func _hint_low_heal(combat_stats: Dictionary) -> String:
	if combat_stats.is_empty():
		return ""
	var total_taken: int = 0
	var total_heal: int = 0
	for member_id: String in combat_stats.keys():
		var row: Dictionary = combat_stats[member_id]
		total_taken += int(row.get("damage_taken", 0))
		total_heal += int(row.get("heal_total", 0))
	if total_taken <= 0:
		if total_heal <= 0:
			return "回復が追いつかなかった"
		return ""
	if total_heal < int(round(float(total_taken) * 0.08)):
		return "回復が追いつかなかった"
	return ""


static func _hint_party_status(snapshot: Dictionary) -> String:
	var ids: Array = snapshot.get("party_status_ids", []) as Array
	if ids.is_empty():
		return ""
	var names: PackedStringArray = []
	for sid_v in ids:
		var sid: String = str(sid_v)
		if sid.is_empty():
			continue
		var dname: String = _StatusEffectLinkHelper.display_name_for(sid).strip_edges()
		if dname.is_empty():
			continue
		if names.has(dname):
			continue
		names.append(dname)
		if names.size() >= 2:
			break
	if names.is_empty():
		return ""
	return "%sが残っていた" % "・".join(names)


static func _hint_weather(snapshot: Dictionary) -> String:
	var weather_id: String = str(snapshot.get("weather_id", "")).strip_edges()
	if weather_id.is_empty():
		return ""
	var wlabel: String = _CombatWeather.label(weather_id)
	if wlabel.is_empty() or wlabel == "晴れ":
		return ""
	return "天候は%sだった" % wlabel


static func _collect_party_status_ids(combat_controller: Node) -> Array:
	var found: Array = []
	if combat_controller == null or not combat_controller.has_method("get_member_status_stacks"):
		return found
	var party_size: int = GameState.combatant_count()
	for i in range(party_size):
		for sid: String in _HARMFUL_STATUS_IDS:
			if found.has(sid):
				continue
			var stacks: int = int(combat_controller.call("get_member_status_stacks", i, sid))
			if stacks > 0:
				found.append(sid)
	return found


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
