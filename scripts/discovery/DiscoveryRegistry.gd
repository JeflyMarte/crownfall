class_name DiscoveryRegistry
extends RefCounted

const CATEGORIES: Array[String] = ["room", "enemy", "event", "lore", "material", "dungeon", "weapon"]

static func _key(category: String, entry_id: String) -> String:
	return "%s:%s" % [category, entry_id]

static func register(category: String, entry_id: String) -> bool:
	if entry_id.is_empty() or category not in CATEGORIES:
		return false
	var key: String = _key(category, entry_id)
	if GameState.discovery_registry.has(key):
		return false
	GameState.discovery_registry[key] = true
	return true

static func is_discovered(category: String, entry_id: String) -> bool:
	return GameState.discovery_registry.has(_key(category, entry_id))

static func format_new_discovery(category: String, entry_id: String) -> String:
	return "【新規発見】%s / %s" % [category, entry_id]

static func room_type_to_id(room_type: int) -> String:
	match room_type:
		Enums.RoomType.HEAL:     return "heal"
		Enums.RoomType.TREASURE: return "treasure"
		Enums.RoomType.MERCHANT: return "merchant"
		Enums.RoomType.EVENT:    return "event"
		Enums.RoomType.ELITE:    return "elite"
	return ""

static func is_special_room(room_type: int) -> bool:
	return not room_type_to_id(room_type).is_empty()

static func count_by_category(category: String) -> int:
	var prefix: String = category + ":"
	var n: int = 0
	for key in GameState.discovery_registry:
		if (key as String).begins_with(prefix):
			n += 1
	return n
