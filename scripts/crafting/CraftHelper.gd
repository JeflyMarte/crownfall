class_name CraftHelper
extends RefCounted

## 生産レシピ SSOT（P3-CRAFT-DISCOVER-001）。
## - 解放: 装備を一度入手したら永続解放
## - 対象: N〜LEGENDARY（MYTHIC / SET / イベント専売は除外）
## - ★は重いコスト（L1）

const _MythicLoot := preload("res://scripts/equipment/MythicLoot.gd")
const _EventExclusiveRewards := preload("res://scripts/dungeon/EventExclusiveRewards.gd")
const _EquipmentSetBonuses := preload("res://scripts/equipment/EquipmentSetBonuses.gd")
const _EquipmentEnhancer := preload("res://scripts/equipment/EquipmentEnhancer.gd")

## レア別コスト（P3-BAL-CRAFT-GOLD-C-001: 序盤は微増、★は激重）。
const GOLD_BY_RARITY: Dictionary = {
	Enums.Rarity.COMMON: 120,
	Enums.Rarity.RARE: 280,
	Enums.Rarity.EPIC: 600,
	Enums.Rarity.LEGENDARY: 4000,
}
const MATERIALS_BY_RARITY: Dictionary = {
	Enums.Rarity.COMMON: {"relic_shard": 1, "base_ore": 1},
	Enums.Rarity.RARE: {"relic_shard": 2, "ancient_bone": 1},
	Enums.Rarity.EPIC: {"relic_shard": 2, "ancient_bone": 1, "epic_ore": 1},
	Enums.Rarity.LEGENDARY: {
		"relic_shard": 3,
		"epic_ore": 2,
		"elite_relic_shard": 2,
	},
}


static func craft_key(output_type: String, output_id: String) -> String:
	return "%s:%s" % [output_type, output_id]


static func parse_craft_key(key: String) -> Dictionary:
	var parts: PackedStringArray = key.split(":", false, 1)
	if parts.size() != 2:
		return {}
	return {"output_type": str(parts[0]), "output_id": str(parts[1])}


static func is_craftable_master(output_type: String, output_id: String) -> bool:
	if output_id.is_empty():
		return false
	if _MythicLoot.is_mythic_id(output_id):
		return false
	if _EventExclusiveRewards.is_event_exclusive_equip(output_id):
		return false
	if _EquipmentSetBonuses.is_set_piece_id(output_id):
		return false
	## 灰冠の九（封蔵）／深層専用／影狩死告は鍛冶生産の別枠（入手解放しない）。
	if (
		output_id.begins_with("kaiwan_")
		or output_id.begins_with("abyss_")
		or output_id.begins_with("deathreap_")
	):
		return false
	var data: Resource = _master_data(output_type, output_id)
	if data == null:
		return false
	var rarity: int = int(data.rarity) if "rarity" in data else Enums.Rarity.COMMON
	## SET(5) / MYTHIC(4) 以上は除外。LEGENDARY(3) まで可。
	if rarity >= Enums.Rarity.MYTHIC:
		return false
	if rarity > Enums.Rarity.LEGENDARY:
		return false
	return true


static func _master_data(output_type: String, output_id: String) -> Resource:
	match output_type:
		"weapon":
			return DataRegistry.get_weapon_data(output_id)
		"armor":
			return DataRegistry.get_armor_data(output_id)
		"accessory":
			return DataRegistry.get_accessory_data(output_id)
		_:
			return null


static func master_rarity(output_type: String, output_id: String) -> int:
	var data: Resource = _master_data(output_type, output_id)
	if data == null or not ("rarity" in data):
		return Enums.Rarity.COMMON
	return clampi(int(data.rarity), Enums.Rarity.COMMON, Enums.Rarity.LEGENDARY)


static func is_unlocked(output_type: String, output_id: String) -> bool:
	if output_type.is_empty() or output_id.is_empty():
		return false
	return bool(GameState.unlocked_craft_outputs.get(craft_key(output_type, output_id), false))


static func try_unlock(output_type: String, output_id: String) -> bool:
	if not is_craftable_master(output_type, output_id):
		return false
	var key: String = craft_key(output_type, output_id)
	if bool(GameState.unlocked_craft_outputs.get(key, false)):
		return false
	GameState.unlocked_craft_outputs[key] = true
	return true


## 装備入手時フック。初回解放なら true。
## record_run=true のとき Result 用 `last_run_craft_unlocks` にも積む（セーブ同期は false）。
static func note_equipment_obtained(instance: Resource, record_run: bool = true) -> bool:
	if instance == null:
		return false
	var cat: String = _EquipmentEnhancer.item_category(instance)
	var mid: String = _EquipmentEnhancer._item_master_id(instance)
	if cat.is_empty() or mid.is_empty():
		return false
	## 指揮官マイページ等の発見率用（トーストは EventBus→DungeonScene）。
	DiscoveryRegistry.register(cat, mid)
	if not try_unlock(cat, mid):
		return false
	if record_run:
		var label: String = mid
		var data: Resource = _master_data(cat, mid)
		if data != null and "display_name" in data:
			label = str(data.display_name)
		GameState.record_last_run_craft_unlock(cat, mid, label)
	return true


## 所持インベントリ／装備中から解放を同期（旧セーブ移行用）。
static func sync_unlocks_from_owned() -> void:
	var bags: Array = [
		GameState.inventory,
		GameState.armor_inventory,
		GameState.accessory_inventory,
	]
	for bag: Variant in bags:
		if not (bag is Array):
			continue
		for raw: Variant in bag:
			if raw is Resource:
				note_equipment_obtained(raw as Resource, false)
	for member: Variant in GameState.party_members:
		if member == null or not (member is Resource):
			continue
		var m: Resource = member as Resource
		if "equipped_weapon" in m and m.equipped_weapon != null:
			note_equipment_obtained(m.equipped_weapon, false)
		if "equipped_armor" in m and m.equipped_armor != null:
			note_equipment_obtained(m.equipped_armor, false)
		if "equipped_accessory" in m and m.equipped_accessory != null:
			note_equipment_obtained(m.equipped_accessory, false)
	for member2: Variant in GameState.roster:
		if member2 == null or not (member2 is Resource):
			continue
		var m2: Resource = member2 as Resource
		if "equipped_weapon" in m2 and m2.equipped_weapon != null:
			note_equipment_obtained(m2.equipped_weapon, false)
		if "equipped_armor" in m2 and m2.equipped_armor != null:
			note_equipment_obtained(m2.equipped_armor, false)
		if "equipped_accessory" in m2 and m2.equipped_accessory != null:
			note_equipment_obtained(m2.equipped_accessory, false)


static func costs_for_rarity(rarity: int) -> Dictionary:
	var r: int = clampi(rarity, Enums.Rarity.COMMON, Enums.Rarity.LEGENDARY)
	var gold: int = int(GOLD_BY_RARITY.get(r, 40))
	var mats: Dictionary = (MATERIALS_BY_RARITY.get(r, {"relic_shard": 1}) as Dictionary).duplicate()
	return {"gold_cost": gold, "required_materials": mats}


static func build_craft_data(output_type: String, output_id: String) -> Resource:
	if not is_craftable_master(output_type, output_id):
		return null
	var data: Resource = _master_data(output_type, output_id)
	if data == null:
		return null
	var rarity: int = master_rarity(output_type, output_id)
	var costs: Dictionary = costs_for_rarity(rarity)
	var craft: Resource = CraftData.new()
	craft.id = "craft_%s_%s" % [output_type, output_id]
	var base_name: String = str(data.display_name) if "display_name" in data else output_id
	craft.display_name = "%sの作成" % base_name
	craft.output_type = output_type
	craft.output_id = output_id
	craft.gold_cost = int(costs.get("gold_cost", 40))
	craft.required_materials = costs.get("required_materials", {})
	craft.unlock_condition = "obtained"
	return craft


static func list_unlocked_crafts(category: String = "") -> Array:
	var out: Array = []
	for key: Variant in GameState.unlocked_craft_outputs.keys():
		if not bool(GameState.unlocked_craft_outputs.get(key, false)):
			continue
		var parsed: Dictionary = parse_craft_key(str(key))
		if parsed.is_empty():
			continue
		var otype: String = str(parsed.get("output_type", ""))
		var oid: String = str(parsed.get("output_id", ""))
		if not category.is_empty() and otype != category:
			continue
		if not is_craftable_master(otype, oid):
			continue
		var craft: Resource = build_craft_data(otype, oid)
		if craft != null:
			out.append(craft)
	out.sort_custom(func(a: Resource, b: Resource) -> bool:
		var ra: int = master_rarity(str(a.output_type), str(a.output_id))
		var rb: int = master_rarity(str(b.output_type), str(b.output_id))
		if ra != rb:
			return ra < rb
		return str(a.display_name) < str(b.display_name)
	)
	return out


static func craft_output_exists(craft: Resource) -> bool:
	if craft == null:
		return false
	match craft.output_type:
		"armor":
			return DataRegistry.get_armor_data(craft.output_id) != null
		"accessory":
			return DataRegistry.get_accessory_data(craft.output_id) != null
		"weapon":
			return DataRegistry.get_weapon_data(craft.output_id) != null
		_:
			return false


static func has_enough_materials(required: Dictionary) -> bool:
	return first_missing_material_id(required).is_empty()


## 不足している素材 id（先頭1件）。足りていれば空。
static func first_missing_material_id(required: Dictionary) -> String:
	if required.is_empty():
		return ""
	for mat_id in required:
		var need: int = int(required[mat_id])
		if need <= 0:
			continue
		if GameState.get_material_quantity(str(mat_id)) < need:
			return str(mat_id)
	return ""


## 例: 「基礎鉱が足りません」。特定できないとき汎用文。
static func material_shortage_message(required: Dictionary) -> String:
	var mid: String = first_missing_material_id(required)
	if mid.is_empty():
		return "素材が足りません"
	var mat_name: String = DataRegistry.get_material_name(mid)
	if mat_name.is_empty():
		mat_name = mid
	return "%sが足りません" % mat_name


## 生産ボタン押下可（解放・袋容量など）。Gold／素材不足は別途テロップ。
static func can_attempt_craft(craft: Resource) -> bool:
	if craft == null:
		return false
	if not is_craft_unlocked(craft):
		return false
	if craft.output_type != "armor" and craft.output_type != "accessory" and craft.output_type != "weapon":
		return false
	if craft.output_id.is_empty() or not craft_output_exists(craft):
		return false
	return true


## Gold／素材不足の表示文。足りていれば空。
static func craft_shortage_message(craft: Resource, gold: int = -1) -> String:
	if craft == null:
		return ""
	var available_gold: int = GameState.gold if gold < 0 else gold
	if available_gold < int(craft.gold_cost):
		return "ゴールドが足りません"
	if not has_enough_materials(craft.required_materials):
		return material_shortage_message(craft.required_materials)
	return ""


static func is_craft_unlocked(craft: Resource) -> bool:
	return craft_lock_reason(craft).is_empty()


static func craft_lock_reason(craft: Resource) -> String:
	if craft == null:
		return "レシピが不正です"
	var otype: String = str(craft.output_type)
	var oid: String = str(craft.output_id)
	if not is_craftable_master(otype, oid):
		return "生産できない装備です"
	if not is_unlocked(otype, oid):
		return "未入手のため生産不可"
	## 旧 stage_cleared 互換（動的レシピは obtained）。
	var cond: String = str(craft.unlock_condition).strip_edges()
	if cond.begins_with("stage_cleared:"):
		var stage_id: String = cond.trim_prefix("stage_cleared:").strip_edges()
		if not stage_id.is_empty() and not GameState.is_stage_cleared(stage_id):
			var stage: Resource = DataRegistry.get_stage_data(stage_id)
			var stage_name: String = (
				str(stage.display_name) if stage != null and "display_name" in stage else stage_id
			)
			return "%s クリアで解放" % stage_name
	## デバッグ全所持は袋上限を超える前提。生産可否は ignore_cap 相当で判定。
	if not GameState.can_add_equipment(1, GameState.debug_full_unlock):
		return "装備袋がいっぱいです（%s）" % GameState.equipment_inventory_count_label()
	return ""


static func can_craft(craft: Resource, gold: int = -1) -> bool:
	if craft == null:
		return false
	if not is_craft_unlocked(craft):
		return false
	if craft.output_type != "armor" and craft.output_type != "accessory" and craft.output_type != "weapon":
		return false
	if craft.output_id.is_empty() or not craft_output_exists(craft):
		return false
	if not GameState.can_add_equipment(1, GameState.debug_full_unlock):
		return false
	var available_gold: int = GameState.gold if gold < 0 else gold
	if available_gold < int(craft.gold_cost):
		return false
	return has_enough_materials(craft.required_materials)


static func get_craftable_recipes(gold: int = -1) -> Array:
	var out: Array = []
	for craft in list_unlocked_crafts():
		if can_craft(craft, gold):
			out.append(craft)
	out.sort_custom(func(a: Resource, b: Resource) -> bool:
		return str(a.display_name) < str(b.display_name)
	)
	return out
