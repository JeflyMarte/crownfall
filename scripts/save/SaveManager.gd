extends Node

const SAVE_PATH: String = "user://save_data.json"

func save_game() -> void:
	var data: Dictionary = {
		"gold": GameState.gold,
		"roster": _serialize_roster(),
		"active_party_ids": _serialize_active_party_ids(),
		"dungeon_progress": GameState.dungeon_progress,
		"current_dungeon_id": GameState.current_dungeon_id,
		"discovery_registry": GameState.discovery_registry,
		"material_inventory": GameState.material_inventory.duplicate(),
		"inventory": _serialize_inventory(),
		"armor_inventory": _serialize_armor_inventory(),
		"accessory_inventory": _serialize_accessory_inventory(),
		"enemy_codex": _serialize_enemy_codex(),
		"gacha_token": GameState.gacha_token,
		"gacha_pity": GameState.gacha_pity,
		"owned_helpers": GameState.owned_helpers.duplicate(),
	}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data))
	file.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var text: String = file.get_as_text()
	file.close()
	var result = JSON.parse_string(text)
	if not result is Dictionary:
		return
	_apply_save_data(result)

func _serialize_enemy_codex() -> Dictionary:
	var out: Dictionary = {}
	for enemy_id in GameState.enemy_codex:
		var entry: Dictionary = GameState.enemy_codex[enemy_id]
		out[enemy_id] = {
			"seen": bool(entry.get("seen", false)),
			"kills": int(entry.get("kills", 0)),
		}
	return out

func _serialize_roster() -> Array:
	var out: Array = []
	for member in GameState.roster:
		out.append(_serialize_adventurer(member))
	return out

func _serialize_active_party_ids() -> Array:
	var out: Array = []
	for member in GameState.party_members:
		if member != null:
			out.append(str(member.id))
	return out

func _serialize_adventurer(adv: Resource) -> Dictionary:
	var weapon_instance_id: String = ""
	var armor_instance_id: String = ""
	var accessory_instance_id: String = ""
	if adv.equipped_weapon != null:
		weapon_instance_id = adv.equipped_weapon.instance_id
	if adv.equipped_armor != null:
		armor_instance_id = adv.equipped_armor.instance_id
	if adv.equipped_accessory != null:
		accessory_instance_id = adv.equipped_accessory.instance_id
	return {
		"id": adv.id,
		"display_name": adv.display_name,
		"level": adv.level,
		"exp": adv.exp,
		"job_id": adv.job_id,
		"is_evolved": adv.is_evolved,
		"base_stats": _serialize_stats(adv.base_stats),
		"equipped_weapon": weapon_instance_id,
		"equipped_armor": armor_instance_id,
		"equipped_accessory": accessory_instance_id,
		"equipped_skills": adv.equipped_skill_ids.duplicate(),
	}

func _serialize_stats(stats: Resource) -> Dictionary:
	if stats == null:
		return {}
	return {
		"hp": stats.hp,
		"attack": stats.attack,
		"defense": stats.defense,
		"attack_speed": stats.attack_speed,
		"crit_rate": stats.crit_rate,
		"crit_damage": stats.crit_damage,
		"discovery": stats.discovery,
	}

func _serialize_inventory() -> Array:
	var out: Array = []
	for item in GameState.inventory:
		out.append({
			"instance_id": item.instance_id,
			"weapon_id": item.weapon_id,
			"is_appraised": item.is_appraised,
			"rolled_attack": item.rolled_attack,
			"attack_speed": item.attack_speed,
			"critical_rate": item.critical_rate,
			"knockback": item.knockback,
			"stagger_power": item.stagger_power,
			"attack_range": item.attack_range,
			"weight": item.weight,
			"prefix_ids": _serialize_affix_ids(item.prefix_ids),
			"suffix_ids": _serialize_affix_ids(item.suffix_ids),
		})
	return out

func _apply_save_data(data: Dictionary) -> void:
	if data.has("gold"):
		GameState.gold = int(data["gold"])
	if data.has("dungeon_progress") and data["dungeon_progress"] is Dictionary:
		GameState.dungeon_progress = data["dungeon_progress"]
	if data.has("current_dungeon_id"):
		GameState.current_dungeon_id = _migrate_dungeon_id(str(data["current_dungeon_id"]))
	if data.has("discovery_registry") and data["discovery_registry"] is Dictionary:
		GameState.discovery_registry = data["discovery_registry"]
	if data.has("material_inventory") and data["material_inventory"] is Dictionary:
		GameState.material_inventory = data["material_inventory"].duplicate()
	if data.has("inventory") and data["inventory"] is Array:
		GameState.inventory = _deserialize_inventory(data["inventory"])
	if data.has("armor_inventory") and data["armor_inventory"] is Array:
		GameState.armor_inventory = _deserialize_armor_inventory(data["armor_inventory"])
	if data.has("accessory_inventory") and data["accessory_inventory"] is Array:
		GameState.accessory_inventory = _deserialize_accessory_inventory(data["accessory_inventory"])
	_apply_roster_save(data)
	_apply_gacha_save(data)
	if data.has("enemy_codex") and data["enemy_codex"] is Dictionary:
		var codex: Dictionary = {}
		for enemy_id in data["enemy_codex"]:
			var entry = data["enemy_codex"][enemy_id]
			if entry is Dictionary:
				codex[str(enemy_id)] = {
					"seen": bool(entry.get("seen", false)),
					"kills": int(entry.get("kills", 0)),
				}
		GameState.enemy_codex = codex
	_migrate_legacy_global_equipment(data)

const _DUNGEON_MIGRATION: Dictionary = {
	"royal_ruins": Constants.MOURNGATE_DUNGEON_ID,
	"graveyard": Constants.MOURNGATE_DUNGEON_ID,
	"underground_factory": Constants.MOURNGATE_DUNGEON_ID,
}
const _VALID_DUNGEON_IDS: PackedStringArray = [Constants.MOURNGATE_DUNGEON_ID]

func _migrate_dungeon_id(raw_id: String) -> String:
	if raw_id in _VALID_DUNGEON_IDS:
		return raw_id
	var migrated: String = _DUNGEON_MIGRATION.get(raw_id, "")
	return migrated if not migrated.is_empty() else Constants.MOURNGATE_DUNGEON_ID

const _JOB_MIGRATION: Dictionary = {
	"warrior": "swordsman",
	"fighter": "swordsman",
	"scout": "ranger",
	"thief": "ranger",
	"rogue": "ranger",
	"guardian": "vanguard",
	"knight": "vanguard",
	"mage": "alchemist",
	"wizard": "alchemist",
}
const _VALID_JOB_IDS: PackedStringArray = ["swordsman", "ranger", "alchemist", "vanguard", "beast_tamer"]

func _migrate_job_id(raw_id: String) -> String:
	if raw_id in _VALID_JOB_IDS:
		return raw_id
	var migrated: String = _JOB_MIGRATION.get(raw_id, "")
	return migrated if not migrated.is_empty() else "swordsman"

func _deserialize_party(party_data: Array) -> Dictionary:
	var adventurer_class = load("res://scripts/domain/Adventurer.gd")
	var stats_class = load("res://scripts/domain/Stats.gd")
	if adventurer_class == null or stats_class == null:
		return {"members": [], "equipment_ids": []}
	var members: Array = []
	var equipment_ids: Array = []
	for entry in party_data:
		if not entry is Dictionary:
			continue
		var adv = adventurer_class.new()
		adv.id = entry.get("id", "")
		adv.display_name = entry.get("display_name", "")
		adv.level = int(entry.get("level", 1))
		adv.exp = int(entry.get("exp", 0))
		adv.job_id = _migrate_job_id(entry.get("job_id", ""))
		adv.is_evolved = bool(entry.get("is_evolved", false))
		var saved_skills: Array = entry.get("equipped_skills", [])
		var skill_ids: Array[String] = []
		for sid in saved_skills:
			skill_ids.append(str(sid))
		adv.equipped_skill_ids = skill_ids
		var stats = stats_class.new()
		var sd = entry.get("base_stats", {})
		if sd is Dictionary:
			stats.hp = int(sd.get("hp", 0))
			stats.attack = int(sd.get("attack", 0))
			stats.defense = int(sd.get("defense", 0))
			stats.attack_speed = float(sd.get("attack_speed", 0.0))
			stats.crit_rate = float(sd.get("crit_rate", 0.0))
			stats.crit_damage = float(sd.get("crit_damage", 0.0))
			stats.discovery = float(sd.get("discovery", 0.0))
		adv.base_stats = stats
		members.append(adv)
		equipment_ids.append({
			"weapon": str(entry.get("equipped_weapon", "")),
			"armor": str(entry.get("equipped_armor", "")),
			"accessory": str(entry.get("equipped_accessory", "")),
		})
	return {"members": members, "equipment_ids": equipment_ids}

# roster + アクティブ編成の復元（P3-D036b）。旧 "party" のみのセーブも互換復元する。
func _apply_roster_save(data: Dictionary) -> void:
	var roster_key: String = "roster" if data.has("roster") and data["roster"] is Array else ""
	if roster_key.is_empty() and data.has("party") and data["party"] is Array:
		roster_key = "party"
	if roster_key.is_empty():
		return
	var result: Dictionary = _deserialize_party(data[roster_key])
	var members: Array = result["members"]
	if members.is_empty():
		return
	GameState.roster = members
	_resolve_equipment_for(members, result["equipment_ids"])
	# 欠落基本職を補完（旧セーブ＝3名のみのケースで vanguard/beast_tamer を追加）
	GameState.ensure_base_roster_complete()
	# 旧セーブの基本職名/職IDを現行定義へ正規化（戦士/盗賊/魔術師 等の残存を解消）
	GameState.normalize_base_roster()
	_restore_active_party(data)

func _restore_active_party(data: Dictionary) -> void:
	var active: Array = []
	if data.has("active_party_ids") and data["active_party_ids"] is Array:
		for raw_id in data["active_party_ids"]:
			var m: Resource = GameState.find_roster_member_by_id(str(raw_id))
			if m != null and not active.has(m):
				active.append(m)
	if active.is_empty():
		var limit: int = mini(GameState.ACTIVE_PARTY_SIZE, GameState.roster.size())
		for i in limit:
			active.append(GameState.roster[i])
	GameState.party_members = active

func _apply_gacha_save(data: Dictionary) -> void:
	if data.has("gacha_token"):
		GameState.gacha_token = int(data["gacha_token"])
	if data.has("gacha_pity"):
		GameState.gacha_pity = int(data["gacha_pity"])
	if data.has("owned_helpers") and data["owned_helpers"] is Dictionary:
		var oh: Dictionary = {}
		for k in data["owned_helpers"]:
			oh[str(k)] = int(data["owned_helpers"][k])
		GameState.owned_helpers = oh

func _resolve_equipment_for(members: Array, equipment_ids: Array) -> void:
	for i in members.size():
		if i >= equipment_ids.size():
			continue
		var member: Resource = members[i]
		if member == null:
			continue
		var ids: Dictionary = equipment_ids[i]
		var weapon_id: String = str(ids.get("weapon", ""))
		if not weapon_id.is_empty():
			member.equipped_weapon = _find_weapon_instance(weapon_id)
		var armor_id: String = str(ids.get("armor", ""))
		if not armor_id.is_empty():
			member.equipped_armor = _find_armor_instance(armor_id)
		var accessory_id: String = str(ids.get("accessory", ""))
		if not accessory_id.is_empty():
			member.equipped_accessory = _find_accessory_instance(accessory_id)

func _migrate_legacy_global_equipment(data: Dictionary) -> void:
	if GameState.party_members.is_empty():
		return
	var member0: Resource = GameState.party_members[0]
	if member0 == null:
		return
	if data.has("equipment") and data["equipment"] is Dictionary:
		var eq_data: Dictionary = data["equipment"]
		if member0.equipped_weapon == null:
			var weapon_id: String = str(eq_data.get("weapon", ""))
			if not weapon_id.is_empty():
				member0.equipped_weapon = _find_weapon_instance(weapon_id)
	if data.has("equipped_armor") and data["equipped_armor"] is Dictionary:
		var armor_data: Dictionary = data["equipped_armor"]
		if member0.equipped_armor == null:
			var armor_id: String = str(armor_data.get("armor", ""))
			if not armor_id.is_empty():
				member0.equipped_armor = _find_armor_instance(armor_id)
	if data.has("equipped_accessory") and data["equipped_accessory"] is Dictionary:
		var accessory_data: Dictionary = data["equipped_accessory"]
		if member0.equipped_accessory == null:
			var accessory_id: String = str(accessory_data.get("accessory", ""))
			if not accessory_id.is_empty():
				member0.equipped_accessory = _find_accessory_instance(accessory_id)

func _find_weapon_instance(instance_id: String) -> Resource:
	if instance_id.is_empty():
		return null
	for item in GameState.inventory:
		if item.instance_id == instance_id:
			return item
	return null

func _find_armor_instance(instance_id: String) -> Resource:
	if instance_id.is_empty():
		return null
	for item in GameState.armor_inventory:
		if item.instance_id == instance_id:
			return item
	return null

func _find_accessory_instance(instance_id: String) -> Resource:
	if instance_id.is_empty():
		return null
	for item in GameState.accessory_inventory:
		if item.instance_id == instance_id:
			return item
	return null

func _deserialize_inventory(inv_data: Array) -> Array:
	var instance_class = load("res://scripts/domain/WeaponInstance.gd")
	if instance_class == null:
		return []
	var items: Array = []
	for entry in inv_data:
		if not entry is Dictionary:
			continue
		var item = instance_class.new()
		item.instance_id = entry.get("instance_id", "")
		item.weapon_id = entry.get("weapon_id", "")
		item.is_appraised = bool(entry.get("is_appraised", false))
		item.rolled_attack = int(entry.get("rolled_attack", 0))
		item.attack_speed = float(entry.get("attack_speed", 1.0))
		item.critical_rate = float(entry.get("critical_rate", 0.0))
		item.knockback = float(entry.get("knockback", 0.0))
		item.stagger_power = float(entry.get("stagger_power", entry.get("stun_power", 0.0)))
		item.attack_range = float(entry.get("attack_range", 1.0))
		item.weight = float(entry.get("weight", 1.0))
		item.prefix_ids = _deserialize_affix_ids(entry.get("prefix_ids", []))
		item.suffix_ids = _deserialize_affix_ids(entry.get("suffix_ids", []))
		items.append(item)
	return items

func _serialize_armor_inventory() -> Array:
	var out: Array = []
	for item in GameState.armor_inventory:
		out.append({
			"instance_id": item.instance_id,
			"armor_id": item.armor_id,
			"rolled_defense": item.rolled_defense,
			"hp_bonus": item.hp_bonus,
			"resistance": item.resistance,
			"weight": item.weight,
			"rarity": item.rarity,
			"is_appraised": item.is_appraised,
			"prefix_ids": _serialize_affix_ids(item.prefix_ids),
			"suffix_ids": _serialize_affix_ids(item.suffix_ids),
		})
	return out

func _deserialize_armor_inventory(inv_data: Array) -> Array:
	var instance_class = load("res://scripts/domain/ArmorInstance.gd")
	if instance_class == null:
		return []
	var items: Array = []
	for entry in inv_data:
		if not entry is Dictionary:
			continue
		var item = instance_class.new()
		item.instance_id = entry.get("instance_id", "")
		item.armor_id = entry.get("armor_id", "")
		item.rolled_defense = int(entry.get("rolled_defense", 0))
		item.hp_bonus = int(entry.get("hp_bonus", 0))
		item.resistance = float(entry.get("resistance", 0.0))
		item.weight = float(entry.get("weight", 1.0))
		item.rarity = int(entry.get("rarity", 0))
		item.is_appraised = bool(entry.get("is_appraised", false))
		item.prefix_ids = _deserialize_affix_ids(entry.get("prefix_ids", []))
		item.suffix_ids = _deserialize_affix_ids(entry.get("suffix_ids", []))
		items.append(item)
	return items

func _serialize_accessory_inventory() -> Array:
	var out: Array = []
	for item in GameState.accessory_inventory:
		out.append({
			"instance_id": item.instance_id,
			"accessory_id": item.accessory_id,
			"is_appraised": item.is_appraised,
			"prefix_ids": _serialize_affix_ids(item.prefix_ids),
			"suffix_ids": _serialize_affix_ids(item.suffix_ids),
		})
	return out

func _deserialize_accessory_inventory(inv_data: Array) -> Array:
	var instance_class = load("res://scripts/domain/AccessoryInstance.gd")
	if instance_class == null:
		return []
	var items: Array = []
	for entry in inv_data:
		if not entry is Dictionary:
			continue
		var item = instance_class.new()
		item.instance_id = entry.get("instance_id", "")
		item.accessory_id = entry.get("accessory_id", "")
		item.is_appraised = bool(entry.get("is_appraised", false))
		item.prefix_ids = _deserialize_affix_ids(entry.get("prefix_ids", []))
		item.suffix_ids = _deserialize_affix_ids(entry.get("suffix_ids", []))
		items.append(item)
	return items

func _serialize_affix_ids(ids: Array) -> Array:
	var out: Array = []
	for affix_id in ids:
		out.append(str(affix_id))
	return out

func _deserialize_affix_ids(data) -> Array[String]:
	var out: Array[String] = []
	if not data is Array:
		return out
	for affix_id in data:
		out.append(str(affix_id))
	return out
