class_name DiscoveryRegistry
extends RefCounted

const CATEGORIES: Array[String] = [
	"room", "enemy", "event", "lore", "material", "dungeon",
	"weapon", "armor", "accessory",
]
const _DungeonController = preload("res://scripts/dungeon/DungeonController.gd")

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


## 複数 ID を登録し、今回新規だった ID だけ返す（重複はスキップ）。
static func register_many(category: String, entry_ids: Array) -> Array[String]:
	var newly: Array[String] = []
	var seen_batch: Dictionary = {}
	for raw in entry_ids:
		var entry_id: String = str(raw)
		if entry_id.is_empty() or seen_batch.has(entry_id):
			continue
		seen_batch[entry_id] = true
		if register(category, entry_id):
			newly.append(entry_id)
	return newly

static func is_discovered(category: String, entry_id: String) -> bool:
	return GameState.discovery_registry.has(_key(category, entry_id))

static func format_new_discovery(category: String, entry_id: String) -> String:
	return "【新規発見】%s / %s" % [
		get_category_label(category),
		get_display_label(category, entry_id),
	]

static func get_category_label(category: String) -> String:
	match category:
		"enemy": return "モンスター"
		"weapon": return "武器"
		"armor": return "防具"
		"accessory": return "装飾"
		"dungeon": return "ダンジョン"
		"material": return "素材"
		"room": return "部屋"
		"event": return "イベント"
		"lore": return "碑文"
		_: return category

static func get_display_label(category: String, entry_id: String) -> String:
	match category:
		"enemy":
			var data: Resource = DataRegistry.get_enemy_data(entry_id)
			if data != null and not data.display_name.is_empty():
				return data.display_name
		"weapon":
			var weapon: Resource = DataRegistry.get_weapon_data(entry_id)
			if weapon != null and not weapon.display_name.is_empty():
				return weapon.display_name
		"armor":
			var armor: Resource = DataRegistry.get_armor_data(entry_id)
			if armor != null and not armor.display_name.is_empty():
				return armor.display_name
		"accessory":
			var accessory: Resource = DataRegistry.get_accessory_data(entry_id)
			if accessory != null and not accessory.display_name.is_empty():
				return accessory.display_name
		"dungeon":
			var dungeon: Resource = DataRegistry.get_dungeon_data(entry_id)
			if dungeon != null and not dungeon.display_name.is_empty():
				return dungeon.display_name
		"material":
			var material: Resource = DataRegistry.get_material_data(entry_id)
			if material != null and not material.display_name.is_empty():
				return material.display_name
		"lore":
			var lore_title: String = CatalogHelper.get_lore_title(entry_id)
			if not lore_title.is_empty():
				return lore_title
		"event":
			var event_label: String = _DungeonController.get_event_display_name(entry_id)
			if not event_label.is_empty():
				return event_label
		"room":
			match entry_id:
				"heal": return "回復の部屋"
				"treasure": return "宝箱の部屋"
				"merchant": return "商人の部屋"
				"event": return "イベントの部屋"
				"elite": return "エリートの部屋"
				"trap": return "罠の部屋"
				_: return _display_fallback(entry_id)
		_: pass
	return _display_fallback(entry_id)

static func _display_fallback(entry_id: String) -> String:
	if entry_id.is_empty():
		return "不明"
	# 未解決の snake_case 内部 ID はプレイヤー向け UI に出さない。
	if entry_id.find("_") >= 0:
		return "不明"
	return entry_id

static func room_type_to_id(room_type: int) -> String:
	match room_type:
		Enums.RoomType.HEAL:     return "heal"
		Enums.RoomType.TREASURE: return "treasure"
		Enums.RoomType.MERCHANT: return "merchant"
		Enums.RoomType.EVENT:    return "event"
		Enums.RoomType.ELITE:    return "elite"
		Enums.RoomType.TRAP:     return "trap"
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
