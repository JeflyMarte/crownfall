extends Node

const _DungeonTierConfig = preload("res://scripts/dungeon/DungeonTierConfig.gd")
const _WeaponStatResolver = preload("res://scripts/equipment/WeaponStatResolver.gd")
const _ArmorStatResolver = preload("res://scripts/equipment/ArmorStatResolver.gd")
const _AccessoryStatResolver = preload("res://scripts/equipment/AccessoryStatResolver.gd")
const _CommanderLifetime = preload("res://scripts/commander/CommanderLifetime.gd")
const _CommanderProfile = preload("res://scripts/commander/CommanderProfile.gd")

const SAVE_PATH: String = "user://save_data.json"

## セーブスキーマバージョン。構造変更時にインクリメントし、
## `_migrate_save_data` に v(n)→v(n+1) の段階マイグレーションを追加する。
## v0 = バージョンフィールド無しの旧セーブ（レガシー party/equipment/job/dungeon id を含む）
## v1 = save_version フィールド導入（2026-07-02）
const SAVE_VERSION: int = 5

func save_game() -> void:
	var data: Dictionary = {
		"save_version": SAVE_VERSION,
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
		"combat_presets": GameState.combat_presets.duplicate(true),
		"owned_relics": GameState.owned_relics.duplicate(),
		"daily_mission_state": GameState.daily_mission_state.duplicate(true),
		"current_dungeon_tier": GameState.current_dungeon_tier,
		"dungeon_tier_cleared": GameState.dungeon_tier_cleared.duplicate(true),
		"current_stage_id": GameState.current_stage_id,
		"stage_progress": GameState.stage_progress.duplicate(true),
		"commander": GameState.commander.duplicate(true),
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
	_apply_save_data(_migrate_save_data(result))
	DailyMissionSystem.ensure_refreshed()
	EventSystem.ensure_active()

## 段階マイグレーション。v0（バージョン無し）の互換吸収は _apply_save_data 内の
## 既存レガシー処理（party キー / equipment / _migrate_job_id / _migrate_dungeon_id）が担う。
## 以後の構造変更は「if version < N: 変換」を本関数へ追記する。
func _migrate_save_data(data: Dictionary) -> Dictionary:
	var version: int = int(data.get("save_version", 0))
	if version > SAVE_VERSION:
		push_warning("SaveManager: save_version %d is newer than supported %d — loading best-effort" % [version, SAVE_VERSION])
	if version < 2:
		data = _migrate_save_v1_to_v2(data)
	if version < 3:
		data = _migrate_save_v2_to_v3(data)
	if version < 4:
		data = _migrate_save_v3_to_v4(data)
	if version < 5:
		data = _migrate_save_v4_to_v5(data)
	data["save_version"] = SAVE_VERSION
	return data

func _migrate_save_v4_to_v5(data: Dictionary) -> Dictionary:
	if not data.has("commander") or not data["commander"] is Dictionary:
		data["commander"] = _CommanderLifetime.default_commander_dict()
	return data

func _migrate_save_v3_to_v4(data: Dictionary) -> Dictionary:
	if data.has("owned_relics") and data["owned_relics"] is Array:
		var relics: Array = []
		for rid in data["owned_relics"]:
			var norm: String = CombatPassives.migrate_relic_passive_id(str(rid))
			if not norm.is_empty() and norm not in relics:
				relics.append(norm)
		data["owned_relics"] = relics
	var roster_key: String = ""
	if data.has("roster") and data["roster"] is Array:
		roster_key = "roster"
	elif data.has("party") and data["party"] is Array:
		roster_key = "party"
	if not roster_key.is_empty():
		var roster: Array = []
		for entry in data[roster_key]:
			if not entry is Dictionary:
				continue
			var e: Dictionary = (entry as Dictionary).duplicate(true)
			var relic_from_field: String = CombatPassives.migrate_relic_passive_id(str(e.get("relic_id", "")))
			var passives: Array = e.get("equipped_passives", [])
			if not passives is Array:
				passives = []
			var char_passives: Array = []
			var relic_id: String = ""
			for raw_pid in passives:
				var pid: String = str(raw_pid)
				if pid.is_empty():
					continue
				var migrated: String = CombatPassives.migrate_relic_passive_id(pid)
				if CombatPassives.is_relic_passive(migrated):
					if relic_id.is_empty():
						relic_id = migrated
					continue
				char_passives.append(migrated if not migrated.is_empty() else pid)
			if not relic_from_field.is_empty() and relic_id.is_empty():
				relic_id = relic_from_field
			var merged: Array = char_passives.duplicate()
			if not relic_id.is_empty():
				merged.append(relic_id)
			e["equipped_passives"] = merged
			e.erase("relic_id")
			roster.append(e)
		data[roster_key] = roster
	if data.has("combat_presets") and data["combat_presets"] is Array:
		var presets: Array = []
		for preset in data["combat_presets"]:
			if not preset is Dictionary:
				continue
			var p: Dictionary = (preset as Dictionary).duplicate(true)
			if p.has("settings") and p["settings"] is Dictionary:
				var settings: Dictionary = (p["settings"] as Dictionary).duplicate(true)
				for mid in settings.keys():
					var s = settings[mid]
					if not s is Dictionary:
						continue
					var sd: Dictionary = (s as Dictionary).duplicate(true)
					var relic_raw: String = str(sd.get("relic_passive_id", sd.get("relic_id", "")))
					if not relic_raw.is_empty():
						sd["relic_passive_id"] = CombatPassives.migrate_relic_passive_id(relic_raw)
					sd.erase("relic_id")
					settings[mid] = sd
				p["settings"] = settings
			presets.append(p)
		data["combat_presets"] = presets
	return data

func _migrate_save_v2_to_v3(data: Dictionary) -> Dictionary:
	if not data.has("stage_progress") or not data["stage_progress"] is Dictionary:
		return data
	var stage_progress: Dictionary = (data["stage_progress"] as Dictionary).duplicate(true)
	for stage_id in stage_progress.keys():
		var prog: Dictionary = stage_progress[stage_id]
		if not prog is Dictionary:
			continue
		if bool(prog.get("cleared", false)) and not prog.has("tiers"):
			prog["tiers"] = {str(_DungeonTierConfig.TIER_NORMAL): true}
			stage_progress[stage_id] = prog
	data["stage_progress"] = stage_progress
	return data

func _migrate_save_v1_to_v2(data: Dictionary) -> Dictionary:
	var stage_progress: Dictionary = {}
	if data.has("dungeon_progress") and data["dungeon_progress"] is Dictionary:
		for dungeon_id in data["dungeon_progress"]:
			var prog: Dictionary = data["dungeon_progress"][dungeon_id]
			if not bool(prog.get("cleared", false)):
				continue
			var final_stage: Resource = DataRegistry.get_stage_by_chapter(str(dungeon_id), 5)
			if final_stage != null:
				stage_progress[str(final_stage.id)] = {"cleared": true}
	if not stage_progress.is_empty():
		data["stage_progress"] = stage_progress
	return data

func _serialize_enemy_codex() -> Dictionary:
	var out: Dictionary = {}
	for enemy_id in GameState.enemy_codex:
		var entry: Dictionary = GameState.enemy_codex[enemy_id]
		out[enemy_id] = {
			"seen": bool(entry.get("seen", false)),
			"kills": int(entry.get("kills", 0)),
			"phases_seen": (entry.get("phases_seen", []) as Array).duplicate(),
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
		"rarity": adv.rarity,
		"is_evolved": adv.is_evolved,
		"base_stats": _serialize_stats(adv.base_stats),
		"equipped_weapon": weapon_instance_id,
		"equipped_armor": armor_instance_id,
		"equipped_accessory": accessory_instance_id,
		"equipped_skills": adv.equipped_skill_ids.duplicate(),
		"equipped_passives": adv.equipped_passive_ids.duplicate(),
		"passive_slots_customized": adv.passive_slots_customized,
		"tactics_id": adv.tactics_id,
		"tactics_custom_enabled": adv.tactics_custom_enabled,
		"tactics_custom_target": adv.tactics_custom_target,
		"tactics_custom_plan": _serialize_gambit_plan(adv.tactics_custom_plan),
		"formation_row": adv.formation_row,
		"formation_slot": adv.formation_slot,
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

func _serialize_gambit_plan(plan: Array) -> Array:
	var out: Array = []
	for entry in CombatGambit.normalize_plan(plan):
		if not entry is Dictionary:
			continue
		var row: Dictionary = {
			"slot": str(entry.get("slot", "")),
			"condition": str(entry.get("condition", "always")),
		}
		if entry.has("value"):
			row["value"] = entry.get("value")
		out.append(row)
	return out

func _deserialize_gambit_plan(plan_data: Array) -> Array:
	var raw: Array = []
	for entry in plan_data:
		if entry is Dictionary:
			raw.append((entry as Dictionary).duplicate(true))
	return CombatGambit.normalize_plan(raw)

func _serialize_inventory() -> Array:
	var out: Array = []
	for item in GameState.inventory:
		out.append({
			"instance_id": item.instance_id,
			"weapon_id": item.weapon_id,
			"is_appraised": item.is_appraised,
			"rolled_attack": item.rolled_attack,
			"element": str(item.element) if "element" in item else "",
			"element_power": int(item.element_power) if "element_power" in item else -1,
			"bane_class": str(item.bane_class) if "bane_class" in item else "",
			"bane_multiplier": float(item.bane_multiplier) if "bane_multiplier" in item else 0.0,
			"attack_speed": item.attack_speed,
			"critical_rate": item.critical_rate,
			"critical_damage": float(item.critical_damage) if "critical_damage" in item else 0.0,
			"on_hit_status_id": str(item.on_hit_status_id) if "on_hit_status_id" in item else "",
			"on_hit_status_chance": float(item.on_hit_status_chance) if "on_hit_status_chance" in item else 0.0,
			"knockback": item.knockback,
			"stagger_power": item.stagger_power,
			"attack_range": item.attack_range,
			"weight": item.weight,
			"prefix_ids": _serialize_affix_ids(item.prefix_ids),
			"suffix_ids": _serialize_affix_ids(item.suffix_ids),
			"enhance_level": int(item.enhance_level),
			"equip_level": EquipmentEnhancer.get_equip_level(item),
			"equip_exp": EquipmentEnhancer.get_equip_exp(item),
			"rolled_bonus_stats": _serialize_affix_ids(
				item.rolled_bonus_stats if "rolled_bonus_stats" in item else []
			),
			"perfect_roll_count": int(item.perfect_roll_count) if "perfect_roll_count" in item else 0,
		})
	return out

func _apply_save_data(data: Dictionary) -> void:
	if data.has("gold"):
		GameState.gold = int(data["gold"])
	if data.has("dungeon_progress") and data["dungeon_progress"] is Dictionary:
		GameState.dungeon_progress = data["dungeon_progress"]
	if data.has("current_dungeon_id"):
		GameState.current_dungeon_id = _migrate_dungeon_id(str(data["current_dungeon_id"]))
	if data.has("current_dungeon_tier"):
		GameState.current_dungeon_tier = _DungeonTierConfig.clamp_tier(int(data["current_dungeon_tier"]))
	if data.has("dungeon_tier_cleared") and data["dungeon_tier_cleared"] is Dictionary:
		GameState.dungeon_tier_cleared = (data["dungeon_tier_cleared"] as Dictionary).duplicate(true)
	if data.has("current_stage_id"):
		GameState.current_stage_id = str(data["current_stage_id"])
	if data.has("stage_progress") and data["stage_progress"] is Dictionary:
		GameState.stage_progress = (data["stage_progress"] as Dictionary).duplicate(true)
	GameState.sync_progress_from_stages()
	GameState.sanitize_current_stage_id()
	if data.has("discovery_registry") and data["discovery_registry"] is Dictionary:
		GameState.discovery_registry = data["discovery_registry"]
		GameState.sanitize_discovery_registry()
	if data.has("material_inventory") and data["material_inventory"] is Dictionary:
		GameState.material_inventory = data["material_inventory"].duplicate()
		GameState.sanitize_material_inventory()
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
				var phases_seen: Array = []
				if entry.get("phases_seen", []) is Array:
					for p in entry["phases_seen"]:
						phases_seen.append(int(p))
				codex[str(enemy_id)] = {
					"seen": bool(entry.get("seen", false)),
					"kills": int(entry.get("kills", 0)),
					"phases_seen": phases_seen,
				}
		GameState.enemy_codex = codex
	if data.has("combat_presets") and data["combat_presets"] is Array:
		GameState.combat_presets = (data["combat_presets"] as Array).duplicate(true)
	if data.has("owned_relics") and data["owned_relics"] is Array:
		var relics: Array = []
		for rid in data["owned_relics"]:
			var norm: String = CombatRelics.normalize_id(str(rid))
			if not norm.is_empty() and norm not in relics:
				relics.append(norm)
		GameState.owned_relics = relics
	if data.has("daily_mission_state") and data["daily_mission_state"] is Dictionary:
		GameState.daily_mission_state = (data["daily_mission_state"] as Dictionary).duplicate(true)
	if data.has("commander") and data["commander"] is Dictionary:
		GameState.commander = (data["commander"] as Dictionary).duplicate(true)
	_CommanderProfile.ensure_commander()
	_migrate_legacy_global_equipment(data)

const _DUNGEON_MIGRATION: Dictionary = {
	"royal_ruins": Constants.MOURNGATE_DUNGEON_ID,
	"graveyard": Constants.MOURNGATE_DUNGEON_ID,
	"underground_factory": Constants.MOURNGATE_DUNGEON_ID,
}

func _valid_dungeon_ids() -> PackedStringArray:
	var ids: PackedStringArray = []
	for data: Resource in DataRegistry.get_all_dungeon_data():
		if data == null or not ("id" in data):
			continue
		var id: String = str(data.id)
		if id.is_empty() or id in ids:
			continue
		ids.append(id)
	if Constants.MOURNGATE_DUNGEON_ID not in ids:
		ids.append(Constants.MOURNGATE_DUNGEON_ID)
	return ids

func _migrate_dungeon_id(raw_id: String) -> String:
	if raw_id in _valid_dungeon_ids():
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
		adv.rarity = int(entry.get("rarity", Adventurer.DEFAULT_RARITY))
		adv.is_evolved = bool(entry.get("is_evolved", false))
		var saved_skills: Array = entry.get("equipped_skills", [])
		var skill_ids: Array[String] = []
		for sid in saved_skills:
			skill_ids.append(str(sid))
		adv.equipped_skill_ids = skill_ids
		var saved_passives: Array = entry.get("equipped_passives", [])
		var passive_ids: Array[String] = []
		for pid in saved_passives:
			passive_ids.append(str(pid))
		adv.equipped_passive_ids = passive_ids
		adv.passive_slots_customized = bool(entry.get("passive_slots_customized", not passive_ids.is_empty()))
		adv.tactics_id = str(entry.get("tactics_id", ""))
		adv.tactics_custom_enabled = bool(entry.get("tactics_custom_enabled", false))
		adv.tactics_custom_target = str(entry.get("tactics_custom_target", ""))
		adv.tactics_custom_plan = _deserialize_gambit_plan(entry.get("tactics_custom_plan", []))
		adv.relic_id = str(entry.get("relic_id", ""))
		adv.formation_row = int(entry.get("formation_row", 0))
		if entry.has("formation_slot"):
			adv.formation_slot = clampi(int(entry["formation_slot"]), 0, 3)
		else:
			adv.formation_slot = -1
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
	GameState.normalize_roster_rarity()
	GameState.normalize_all_equipped_skills()
	GameState.normalize_all_equipped_passives()
	_sync_gacha_roster_metadata()
	_restore_active_party(data)
	GameState.omit_gacha_helpers_from_roster()

func _sync_gacha_roster_metadata() -> void:
	for adv in GameState.roster:
		var adv_id: String = str(adv.id)
		if not adv_id.begins_with("gacha_"):
			continue
		var helper_id: String = adv_id.trim_prefix("gacha_")
		var helper: Resource = DataRegistry.get_gacha_helper_data(helper_id)
		if helper == null:
			continue
		if not str(helper.display_name).is_empty():
			adv.display_name = str(helper.display_name)
		adv.rarity = GachaRarityConfig.clamp_rarity(int(helper.rarity))
		var base_hp: int = CombatController.BASE_MEMBER_HP
		GachaRarityConfig.apply_base_stats_to_adventurer(adv, adv.rarity, base_hp)

func _restore_active_party(data: Dictionary) -> void:
	var active: Array = []
	if data.has("active_party_ids") and data["active_party_ids"] is Array:
		for raw_id in data["active_party_ids"]:
			if active.size() >= GameState.ACTIVE_PARTY_SIZE:
				break
			var m: Resource = GameState.find_roster_member_by_id(str(raw_id))
			if m != null and not active.has(m):
				active.append(m)
	if active.is_empty():
		var limit: int = mini(GameState.ACTIVE_PARTY_SIZE, GameState.roster.size())
		for i in limit:
			active.append(GameState.roster[i])
	if not GameState.set_active_party(active):
		var fallback: Array = []
		var fb_limit: int = mini(GameState.ACTIVE_PARTY_SIZE, GameState.roster.size())
		for i in fb_limit:
			fallback.append(GameState.roster[i])
		GameState.set_active_party(fallback)

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
		if entry.has("element"):
			item.element = str(entry.get("element", ""))
			item.element_power = int(entry.get("element_power", -1))
			item.bane_class = str(entry.get("bane_class", ""))
			item.bane_multiplier = float(entry.get("bane_multiplier", 0.0))
			item.critical_damage = float(entry.get("critical_damage", 0.0))
			if entry.has("on_hit_status_id"):
				item.on_hit_status_id = str(entry.get("on_hit_status_id", ""))
			if entry.has("on_hit_status_chance"):
				item.on_hit_status_chance = float(entry.get("on_hit_status_chance", 0.0))
		else:
			_WeaponStatResolver.backfill_from_master(item)
		item.attack_speed = float(entry.get("attack_speed", 0.0))
		item.critical_rate = float(entry.get("critical_rate", 0.0))
		item.knockback = float(entry.get("knockback", 0.0))
		item.stagger_power = float(entry.get("stagger_power", entry.get("stun_power", 0.0)))
		item.attack_range = float(entry.get("attack_range", 1.0))
		item.weight = float(entry.get("weight", 1.0))
		item.prefix_ids = _deserialize_affix_ids(entry.get("prefix_ids", []))
		item.suffix_ids = _deserialize_affix_ids(entry.get("suffix_ids", []))
		item.enhance_level = int(entry.get("enhance_level", 0))
		item.equip_level = int(entry.get("equip_level", 1))
		item.equip_exp = int(entry.get("equip_exp", 0))
		if entry.has("rolled_bonus_stats"):
			item.rolled_bonus_stats = _deserialize_affix_ids(entry.get("rolled_bonus_stats", []))
		if entry.has("perfect_roll_count"):
			item.perfect_roll_count = int(entry.get("perfect_roll_count", 0))
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
			"resist_elements": item.resist_elements.duplicate() if "resist_elements" in item else [],
			"resist_multiplier": float(item.resist_multiplier) if "resist_multiplier" in item else 0.0,
			"exp_gain_rate": float(item.exp_gain_rate) if "exp_gain_rate" in item else 0.0,
			"gold_gain_rate": float(item.gold_gain_rate) if "gold_gain_rate" in item else 0.0,
			"rare_drop_rate": float(item.rare_drop_rate) if "rare_drop_rate" in item else 0.0,
			"evasion_rate": float(item.evasion_rate) if "evasion_rate" in item else 0.0,
			"status_immunities": item.status_immunities.duplicate() if "status_immunities" in item else [],
			"resistance": item.resistance,
			"weight": item.weight,
			"rarity": item.rarity,
			"is_appraised": item.is_appraised,
			"prefix_ids": _serialize_affix_ids(item.prefix_ids),
			"suffix_ids": _serialize_affix_ids(item.suffix_ids),
			"equip_level": EquipmentEnhancer.get_equip_level(item),
			"equip_exp": EquipmentEnhancer.get_equip_exp(item),
			"rolled_bonus_stats": _serialize_affix_ids(
				item.rolled_bonus_stats if "rolled_bonus_stats" in item else []
			),
			"perfect_roll_count": int(item.perfect_roll_count) if "perfect_roll_count" in item else 0,
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
		if entry.has("resist_elements"):
			item.resist_elements = _deserialize_affix_ids(entry.get("resist_elements", []))
		if entry.has("resist_multiplier"):
			item.resist_multiplier = float(entry.get("resist_multiplier", 0.0))
		if entry.has("exp_gain_rate"):
			item.exp_gain_rate = float(entry.get("exp_gain_rate", 0.0))
		if entry.has("gold_gain_rate"):
			item.gold_gain_rate = float(entry.get("gold_gain_rate", 0.0))
		if entry.has("rare_drop_rate"):
			item.rare_drop_rate = float(entry.get("rare_drop_rate", 0.0))
		if entry.has("evasion_rate"):
			item.evasion_rate = float(entry.get("evasion_rate", 0.0))
		if entry.has("status_immunities"):
			item.status_immunities = _deserialize_affix_ids(entry.get("status_immunities", []))
		if not entry.has("resist_elements"):
			_ArmorStatResolver.backfill_from_master(item)
		item.resistance = float(entry.get("resistance", 0.0))
		item.weight = float(entry.get("weight", 1.0))
		item.rarity = int(entry.get("rarity", 0))
		item.is_appraised = bool(entry.get("is_appraised", false))
		item.prefix_ids = _deserialize_affix_ids(entry.get("prefix_ids", []))
		item.suffix_ids = _deserialize_affix_ids(entry.get("suffix_ids", []))
		item.equip_level = int(entry.get("equip_level", 1))
		item.equip_exp = int(entry.get("equip_exp", 0))
		if entry.has("rolled_bonus_stats"):
			item.rolled_bonus_stats = _deserialize_affix_ids(entry.get("rolled_bonus_stats", []))
		if entry.has("perfect_roll_count"):
			item.perfect_roll_count = int(entry.get("perfect_roll_count", 0))
		items.append(item)
	return items

func _serialize_accessory_inventory() -> Array:
	var out: Array = []
	for item in GameState.accessory_inventory:
		out.append({
			"instance_id": item.instance_id,
			"accessory_id": item.accessory_id,
			"hp_bonus": int(item.hp_bonus) if "hp_bonus" in item else 0,
			"attack_bonus": int(item.attack_bonus) if "attack_bonus" in item else 0,
			"defense_bonus": int(item.defense_bonus) if "defense_bonus" in item else 0,
			"crit_rate_bonus": float(item.crit_rate_bonus) if "crit_rate_bonus" in item else 0.0,
			"evasion_rate": float(item.evasion_rate) if "evasion_rate" in item else 0.0,
			"exp_gain_rate": float(item.exp_gain_rate) if "exp_gain_rate" in item else 0.0,
			"gold_gain_rate": float(item.gold_gain_rate) if "gold_gain_rate" in item else 0.0,
			"rare_drop_rate": float(item.rare_drop_rate) if "rare_drop_rate" in item else 0.0,
			"is_appraised": item.is_appraised,
			"prefix_ids": _serialize_affix_ids(item.prefix_ids),
			"suffix_ids": _serialize_affix_ids(item.suffix_ids),
			"equip_level": EquipmentEnhancer.get_equip_level(item),
			"equip_exp": EquipmentEnhancer.get_equip_exp(item),
			"rolled_bonus_stats": _serialize_affix_ids(
				item.rolled_bonus_stats if "rolled_bonus_stats" in item else []
			),
			"perfect_roll_count": int(item.perfect_roll_count) if "perfect_roll_count" in item else 0,
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
		if entry.has("hp_bonus"):
			item.hp_bonus = int(entry.get("hp_bonus", 0))
			item.attack_bonus = int(entry.get("attack_bonus", 0))
			item.defense_bonus = int(entry.get("defense_bonus", 0))
			item.crit_rate_bonus = float(entry.get("crit_rate_bonus", 0.0))
			item.evasion_rate = float(entry.get("evasion_rate", 0.0))
			item.exp_gain_rate = float(entry.get("exp_gain_rate", 0.0))
			item.gold_gain_rate = float(entry.get("gold_gain_rate", 0.0))
			item.rare_drop_rate = float(entry.get("rare_drop_rate", 0.0))
		else:
			_AccessoryStatResolver.backfill_from_master(item)
		item.is_appraised = bool(entry.get("is_appraised", false))
		item.prefix_ids = _deserialize_affix_ids(entry.get("prefix_ids", []))
		item.suffix_ids = _deserialize_affix_ids(entry.get("suffix_ids", []))
		item.equip_level = int(entry.get("equip_level", 1))
		item.equip_exp = int(entry.get("equip_exp", 0))
		if entry.has("rolled_bonus_stats"):
			item.rolled_bonus_stats = _deserialize_affix_ids(entry.get("rolled_bonus_stats", []))
		if entry.has("perfect_roll_count"):
			item.perfect_roll_count = int(entry.get("perfect_roll_count", 0))
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
