extends Node

## ギルド日課ミッション（P3-DAILY / P3-DAILY-002）。
## プールから毎日3件を day_key シードで決定的抽選。5:00 JST リセット。

signal missions_updated

const _WeaponStatResolver = preload("res://scripts/equipment/WeaponStatResolver.gd")
const _ArmorStatResolver = preload("res://scripts/equipment/ArmorStatResolver.gd")
const _AccessoryStatResolver = preload("res://scripts/equipment/AccessoryStatResolver.gd")
const _MythicLoot = preload("res://scripts/equipment/MythicLoot.gd")
const _BuildLegendaryLoot = preload("res://scripts/equipment/BuildLegendaryLoot.gd")
const _AbyssLegendaryWeapons = preload("res://scripts/dungeon/AbyssLegendaryWeapons.gd")
const _EventExclusiveRewards = preload("res://scripts/dungeon/EventExclusiveRewards.gd")

const JST_OFFSET_SEC: int = 9 * 3600
const DAY_START_HOUR_JST: int = 5
const DAILY_PICK_COUNT: int = 3

## 日課装備レア重み N/R/E（P3-BAL-DAILY-REWARD-VARIETY-001）
const EQUIP_RARITY_WEIGHTS_NORMAL: Array[int] = [45, 35, 20]
const EQUIP_RARITY_WEIGHTS_EPIC_BIAS: Array[int] = [35, 35, 30]
const EQUIP_FALLBACK_GOLD: Array[int] = [80, 120, 180]
const EQUIP_CATEGORIES: Array[String] = ["weapon", "armor", "accessory"]

## 抽選プール（P3-DAILY-002-4 / P3-BAL-GACHA-001: 招待日課は除外）
const DAILY_POOL: Array[String] = [
	"daily_clear_run",
	"daily_kill_enemies",
	"daily_kill_elite",
	"daily_kill_boss",
	"daily_craft_item",
	"daily_enhance_item",
	"daily_alchemy_item",
	"daily_dismantle_item",
]
## データ残置・プール外（消費500に対し報酬20の逆インセンティブ解消）
const DAILY_POOL_OMITTED: Array[String] = [
	"daily_gacha_pull",
]

func ensure_refreshed() -> void:
	var day_key: String = _current_day_key()
	var state: Dictionary = GameState.daily_mission_state
	if str(state.get("day_key", "")) == day_key and _entries_valid(state.get("entries", [])):
		return
	_reset_for_day(day_key)

func report_progress(objective_type: String, param: String = "", amount: int = 1) -> void:
	if amount <= 0 or objective_type.is_empty():
		return
	ensure_refreshed()
	var changed: bool = false
	var entries: Array = GameState.daily_mission_state.get("entries", [])
	for raw in entries:
		if not raw is Dictionary:
			continue
		var entry: Dictionary = raw
		if bool(entry.get("claimed", false)):
			continue
		var mission: Resource = _get_mission_data(str(entry.get("mission_id", "")))
		if mission == null:
			continue
		if str(mission.objective_type) != objective_type:
			continue
		if not _param_matches(mission, param):
			continue
		var target: int = maxi(1, int(mission.target_count))
		var before: int = int(entry.get("progress", 0))
		entry["progress"] = mini(target, before + amount)
		if int(entry["progress"]) != before:
			changed = true
	if changed:
		missions_updated.emit()

func get_entries() -> Array[Dictionary]:
	ensure_refreshed()
	var out: Array[Dictionary] = []
	for raw in GameState.daily_mission_state.get("entries", []):
		if not raw is Dictionary:
			continue
		var entry: Dictionary = (raw as Dictionary).duplicate()
		var mission: Resource = _get_mission_data(str(entry.get("mission_id", "")))
		if mission == null:
			continue
		var target: int = maxi(1, int(mission.target_count))
		var progress: int = int(entry.get("progress", 0))
		entry["title"] = str(mission.title)
		entry["description"] = str(mission.description)
		entry["target_count"] = target
		entry["progress"] = progress
		entry["claimed"] = bool(entry.get("claimed", false))
		entry["complete"] = progress >= target
		entry["can_claim"] = entry["complete"] and not entry["claimed"]
		entry["reward_gold"] = int(mission.reward_gold)
		entry["reward_gacha_token"] = int(mission.reward_gacha_token)
		entry["reward_material_id"] = str(mission.reward_material_id)
		entry["reward_material_qty"] = int(mission.reward_material_qty)
		entry["reward_equip"] = bool(mission.get("reward_equip"))
		entry["objective_type"] = str(mission.objective_type)
		entry["genre_id"] = genre_id_for_mission(str(mission.id), str(mission.objective_type))
		out.append(entry)
	return out


## 日課ジャンル（行先頭アイコン用）。探索 / 鍛冶 / 招待。
const GENRE_ADVENTURE: String = "adventure"
const GENRE_FORGE: String = "forge"
const GENRE_GACHA: String = "gacha"


static func genre_id_for_mission(mission_id: String, objective_type: String = "") -> String:
	match mission_id:
		"daily_clear_run", "daily_kill_enemies", "daily_kill_elite", "daily_kill_boss":
			return GENRE_ADVENTURE
		"daily_craft_item", "daily_enhance_item", "daily_alchemy_item", "daily_dismantle_item":
			return GENRE_FORGE
		"daily_gacha_pull":
			return GENRE_GACHA
	match objective_type:
		"dungeon_clear", "kill_enemy", "kill_elite", "kill_boss":
			return GENRE_ADVENTURE
		"craft_item", "enhance_item", "alchemy_item", "dismantle_item":
			return GENRE_FORGE
		"gacha_pull":
			return GENRE_GACHA
	return GENRE_ADVENTURE


static func genre_icon_texture(genre_id: String) -> Texture2D:
	return IconPaths.get_icon_texture(genre_id, "daily")


func claim(index: int) -> Dictionary:
	ensure_refreshed()
	var entries: Array = GameState.daily_mission_state.get("entries", [])
	if index < 0 or index >= entries.size():
		return {"ok": false, "reason": "invalid_index"}
	var entry: Dictionary = entries[index]
	if bool(entry.get("claimed", false)):
		return {"ok": false, "reason": "already_claimed"}
	var mission: Resource = _get_mission_data(str(entry.get("mission_id", "")))
	if mission == null:
		return {"ok": false, "reason": "missing_mission"}
	var target: int = maxi(1, int(mission.target_count))
	if int(entry.get("progress", 0)) < target:
		return {"ok": false, "reason": "not_complete"}
	var granted: Dictionary = _apply_rewards(mission)
	entry["claimed"] = true
	missions_updated.emit()
	granted["ok"] = true
	return granted

func has_claimable() -> bool:
	for entry in get_entries():
		if bool(entry.get("can_claim", false)):
			return true
	return false

func reset_countdown_text() -> String:
	var now_utc: int = int(Time.get_unix_time_from_system())
	var jst_now: int = now_utc + JST_OFFSET_SEC
	var dt: Dictionary = Time.get_datetime_dict_from_unix_time(jst_now)
	var next_jst: int = jst_now
	if dt.hour >= DAY_START_HOUR_JST:
		next_jst += 86400
	var next_dt: Dictionary = Time.get_datetime_dict_from_unix_time(next_jst)
	var next_reset_jst: int = int(
		Time.get_unix_time_from_datetime_dict({
			"year": next_dt.year,
			"month": next_dt.month,
			"day": next_dt.day,
			"hour": DAY_START_HOUR_JST,
			"minute": 0,
			"second": 0,
		})
	) - JST_OFFSET_SEC
	var remain: int = maxi(0, next_reset_jst - now_utc)
	var hours: int = remain / 3600
	var mins: int = (remain % 3600) / 60
	return "%d:%02d" % [hours, mins]

func _reset_for_day(day_key: String) -> void:
	var picked: Array[String] = pick_missions_for_day(day_key)
	var entries: Array = []
	for mission_id in picked:
		entries.append({
			"mission_id": mission_id,
			"progress": 0,
			"claimed": false,
		})
	GameState.daily_mission_state = {"day_key": day_key, "entries": entries}
	missions_updated.emit()

## テスト／デバッグ用。day_key から決定的に3件を返す。
func pick_missions_for_day(day_key: String) -> Array[String]:
	var pool: Array[String] = DAILY_POOL.duplicate()
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed_from_day_key(day_key)
	for i in range(pool.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: String = pool[i]
		pool[i] = pool[j]
		pool[j] = tmp
	var out: Array[String] = []
	for i in mini(DAILY_PICK_COUNT, pool.size()):
		out.append(pool[i])
	return out

func current_day_key() -> String:
	return _current_day_key()


func _current_day_key() -> String:
	var jst_now: int = int(Time.get_unix_time_from_system()) + JST_OFFSET_SEC
	var dt: Dictionary = Time.get_datetime_dict_from_unix_time(jst_now)
	if int(dt.hour) < DAY_START_HOUR_JST:
		jst_now -= 86400
		dt = Time.get_datetime_dict_from_unix_time(jst_now)
	return "%04d-%02d-%02d" % [int(dt.year), int(dt.month), int(dt.day)]

func _seed_from_day_key(day_key: String) -> int:
	## 同じ日は同じ3件。hash() は実行間で変わることがあるので文字列から自前ハッシュ。
	var h: int = 2166136261
	for i in day_key.length():
		h = int((h ^ day_key.unicode_at(i)) * 16777619) & 0x7fffffff
	return h

func _entries_valid(entries: Variant) -> bool:
	if not entries is Array:
		return false
	var arr: Array = entries
	if arr.size() != DAILY_PICK_COUNT:
		return false
	for raw in arr:
		if not raw is Dictionary:
			return false
		var mid: String = str((raw as Dictionary).get("mission_id", ""))
		if mid.is_empty() or mid not in DAILY_POOL:
			return false
		if _get_mission_data(mid) == null:
			return false
	return true

func _get_mission_data(mission_id: String) -> Resource:
	if mission_id.is_empty():
		return null
	var path: String = Constants.RESOURCE_DAILY_MISSIONS_PATH + mission_id + ".tres"
	if not ResourceLoader.exists(path):
		return null
	return load(path)

func _param_matches(mission: Resource, param: String) -> bool:
	var required: String = str(mission.target_param)
	if required.is_empty():
		return true
	return required == param

func _apply_rewards(mission: Resource) -> Dictionary:
	var result: Dictionary = {
		"gold": 0,
		"gacha_token": 0,
		"material_id": "",
		"material_qty": 0,
		"equip_granted": false,
		"equip_category": "",
		"equip_id": "",
		"equip_fallback_gold": 0,
	}
	var gold: int = int(mission.reward_gold)
	if gold > 0:
		GameState.gold += gold
		result["gold"] = gold
	var tokens: int = int(mission.reward_gacha_token)
	if tokens > 0:
		GameState.gacha_token += tokens
		result["gacha_token"] = tokens
	var mat_id: String = str(mission.reward_material_id)
	var mat_qty: int = int(mission.reward_material_qty)
	if not mat_id.is_empty() and mat_qty > 0:
		GameState.add_material(mat_id, mat_qty)
		result["material_id"] = mat_id
		result["material_qty"] = mat_qty
	if bool(mission.get("reward_equip")):
		var epic_bias: bool = bool(mission.get("reward_equip_epic_bias"))
		var equip_result: Dictionary = _grant_random_equip(epic_bias)
		result["equip_granted"] = bool(equip_result.get("granted", false))
		result["equip_category"] = str(equip_result.get("category", ""))
		result["equip_id"] = str(equip_result.get("id", ""))
		var fallback: int = int(equip_result.get("fallback_gold", 0))
		if fallback > 0:
			GameState.gold += fallback
			result["gold"] = int(result["gold"]) + fallback
			result["equip_fallback_gold"] = fallback
	return result


func _grant_random_equip(epic_bias: bool) -> Dictionary:
	var rarity: int = _roll_equip_rarity(epic_bias)
	var category: String = EQUIP_CATEGORIES[randi() % EQUIP_CATEGORIES.size()]
	var item_id: String = _pick_equip_id(category, rarity)
	if item_id.is_empty():
		## 当該レアが空なら他レアを試し、それでも無ければ Gold。
		for try_rarity in [Enums.Rarity.COMMON, Enums.Rarity.RARE, Enums.Rarity.EPIC]:
			item_id = _pick_equip_id(category, try_rarity)
			if not item_id.is_empty():
				rarity = try_rarity
				break
	if item_id.is_empty():
		for alt_cat in EQUIP_CATEGORIES:
			if alt_cat == category:
				continue
			item_id = _pick_equip_id(alt_cat, rarity)
			if not item_id.is_empty():
				category = alt_cat
				break
	if item_id.is_empty() or not GameState.can_add_equipment(1):
		return {
			"granted": false,
			"category": category,
			"id": "",
			"fallback_gold": _fallback_gold_for_rarity(rarity),
		}
	if not _spawn_equip_instance(category, item_id):
		return {
			"granted": false,
			"category": category,
			"id": "",
			"fallback_gold": _fallback_gold_for_rarity(rarity),
		}
	return {"granted": true, "category": category, "id": item_id, "fallback_gold": 0}


func _roll_equip_rarity(epic_bias: bool) -> int:
	var weights: Array[int] = (
		EQUIP_RARITY_WEIGHTS_EPIC_BIAS if epic_bias else EQUIP_RARITY_WEIGHTS_NORMAL
	)
	var total: int = 0
	for w in weights:
		total += maxi(0, w)
	if total <= 0:
		return Enums.Rarity.COMMON
	var roll: int = randi() % total
	var acc: int = 0
	for i in weights.size():
		acc += maxi(0, weights[i])
		if roll < acc:
			return clampi(i, Enums.Rarity.COMMON, Enums.Rarity.EPIC)
	return Enums.Rarity.COMMON


func _fallback_gold_for_rarity(rarity: int) -> int:
	var idx: int = clampi(rarity, 0, EQUIP_FALLBACK_GOLD.size() - 1)
	return EQUIP_FALLBACK_GOLD[idx]


func _pick_equip_id(category: String, rarity: int) -> String:
	var pool: Array[String] = _equip_ids_for_rarity(category, rarity)
	if pool.is_empty():
		return ""
	return pool[randi() % pool.size()]


func _equip_ids_for_rarity(category: String, rarity: int) -> Array[String]:
	var out: Array[String] = []
	var all: Array = []
	match category:
		"weapon":
			all = DataRegistry.get_all_weapon_data()
		"armor":
			all = DataRegistry.get_all_armor_data()
		"accessory":
			all = DataRegistry.get_all_accessory_data()
		_:
			return out
	for data: Resource in all:
		if data == null:
			continue
		if int(data.rarity) != rarity:
			continue
		if rarity > Enums.Rarity.EPIC:
			continue
		var item_id: String = _equip_data_id(category, data)
		if item_id.is_empty():
			continue
		if not _is_daily_equip_eligible(category, item_id):
			continue
		out.append(item_id)
	return out


func _equip_data_id(category: String, data: Resource) -> String:
	match category:
		"weapon":
			return str(data.id)
		"armor":
			return str(data.armor_id)
		"accessory":
			return str(data.id)
	return ""


func _is_daily_equip_eligible(category: String, item_id: String) -> bool:
	if item_id.is_empty():
		return false
	if _MythicLoot.is_mythic_id(item_id):
		return false
	if item_id.begins_with("kaiwan_"):
		return false
	if item_id in _BuildLegendaryLoot.all_ids():
		return false
	if category == "weapon" and _AbyssLegendaryWeapons.is_abyss_legendary_id(item_id):
		return false
	if _EventExclusiveRewards.is_event_exclusive_equip(item_id):
		return false
	return true


func _spawn_equip_instance(category: String, item_id: String) -> bool:
	match category:
		"weapon":
			return _spawn_daily_weapon(item_id)
		"armor":
			return _spawn_daily_armor(item_id)
		"accessory":
			return _spawn_daily_accessory(item_id)
	return false


func _spawn_daily_weapon(weapon_id: String) -> bool:
	var weapon_data: Resource = DataRegistry.get_weapon_data(weapon_id)
	if weapon_data == null:
		return false
	var instance: Resource = WeaponInstance.new()
	instance.instance_id = "daily_%d_%d" % [Time.get_ticks_msec(), randi() % 100000]
	instance.weapon_id = weapon_id
	_WeaponStatResolver.apply_drop_stats(instance, weapon_data)
	EquipmentEnhancer.assign_drop_equip_level(instance, null, null, -1)
	instance.is_appraised = true
	if not GameState.try_add_weapon_instance(instance):
		return false
	GameState.note_equipment_obtained(instance)
	GameState.mark_equipment_new(instance)
	return true


func _spawn_daily_armor(armor_id: String) -> bool:
	var armor_data: Resource = DataRegistry.get_armor_data(armor_id)
	if armor_data == null:
		return false
	var instance: Resource = ArmorInstance.new()
	instance.instance_id = "daily_%d_%d" % [Time.get_ticks_msec() + 1, randi() % 100000]
	instance.armor_id = armor_id
	_ArmorStatResolver.apply_drop_stats(instance, armor_data)
	instance.rarity = armor_data.rarity
	EquipmentEnhancer.assign_drop_equip_level(instance, null, null, -1)
	instance.is_appraised = true
	if not GameState.try_add_armor_instance(instance):
		return false
	GameState.note_equipment_obtained(instance)
	GameState.mark_equipment_new(instance)
	return true


func _spawn_daily_accessory(accessory_id: String) -> bool:
	var accessory_data: Resource = DataRegistry.get_accessory_data(accessory_id)
	if accessory_data == null:
		return false
	var instance: Resource = AccessoryInstance.new()
	instance.instance_id = "daily_%d_%d" % [Time.get_ticks_msec() + 2, randi() % 100000]
	instance.accessory_id = accessory_id
	_AccessoryStatResolver.apply_drop_stats(instance, accessory_data)
	EquipmentEnhancer.assign_drop_equip_level(instance, null, null, -1)
	instance.is_appraised = true
	if not GameState.try_add_accessory_instance(instance):
		return false
	GameState.note_equipment_obtained(instance)
	GameState.mark_equipment_new(instance)
	return true
