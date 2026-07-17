class_name EquipmentEnhancer
extends RefCounted

const _EquipmentRollHelper = preload("res://scripts/equipment/EquipmentRollHelper.gd")
const _AccessoryStatResolver = preload("res://scripts/equipment/AccessoryStatResolver.gd")
const _WeaponStatResolver = preload("res://scripts/equipment/WeaponStatResolver.gd")
const _ElementResolver = preload("res://scripts/combat/ElementResolver.gd")

## 鍛冶屋「炉研ぎ」— 武器・防具・装飾 +1〜+5（P3-D152 / P3-FORGE-002）。
## 装備レベル成長 — P3-EQ-LVL-001。分解 — P3-FORGE-003。

const COMMON_MATERIAL_ID: String = "relic_shard"
const BASE_ORE_ID: String = "base_ore"
const RARE_ORE_ID: String = "ancient_bone"
const EPIC_ORE_ID: String = "epic_ore"
const LEGEND_ORE_ID: String = "elite_relic_shard"

const MAX_FORGE_LEVEL: int = 5
const EQUIP_MAX_LEVEL: int = 99
const EQUIP_GROWTH_RATE: float = 0.04
const EQUIP_LEGENDARY_GROWTH_MULT: float = 1.25
const EQUIP_EXP_BASE: int = 10
const EQUIP_EXP_PER_LEVEL: int = 5
const DISMANTLE_CRAFT_RETURN_CAP: float = 0.6
## 錬成 — P3-FORGE-ALCHEMY-001
const ALCHEMY_LEVEL_FACTOR: float = 0.5
const ALCHEMY_GOLD_PER_GAIN: int = 20
const ALCHEMY_CONFIRM_ENHANCE_LEVEL: int = 3

const GOLD_BY_NEXT_LEVEL: Dictionary = {
	1: 30,
	2: 50,
	3: 80,
	4: 120,
	5: 180,
}

## 炉研ぎ消費素材＝戦闘ドロップの唯一対象（P3-MAT-004）。
const ENHANCEMENT_MATERIAL_IDS: Array[String] = [
	COMMON_MATERIAL_ID,
	BASE_ORE_ID,
	RARE_ORE_ID,
	EPIC_ORE_ID,
	LEGEND_ORE_ID,
]
const COMBAT_DROP_MATERIAL_IDS: Array[String] = [BASE_ORE_ID, COMMON_MATERIAL_ID]
const EVENT_DROP_MATERIAL_IDS: Array[String] = [BASE_ORE_ID, COMMON_MATERIAL_ID]

static func is_enhancement_material(material_id: String) -> bool:
	return material_id in ENHANCEMENT_MATERIAL_IDS

static func material_rarity(material_id: String) -> int:
	var mat_data: Resource = DataRegistry.get_material_data(material_id)
	if mat_data == null:
		return Enums.Rarity.COMMON
	return clampi(int(mat_data.rarity), Enums.Rarity.COMMON, Enums.Rarity.LEGENDARY)

## 図鑑 S5「採取素材」表示用（P3-MAT-004 / P3-MAT-CODEx-001 / P3-MAT-RARITY-001）。
static func forge_material_display_names() -> PackedStringArray:
	var parts: PackedStringArray = []
	for mat_id in ENHANCEMENT_MATERIAL_IDS:
		var mat_data: Resource = DataRegistry.get_material_data(str(mat_id))
		var mat_name: String = str(mat_id) if mat_data == null else str(mat_data.display_name)
		parts.append(mat_name)
	return parts

static func pick_combat_drop_material() -> String:
	if COMBAT_DROP_MATERIAL_IDS.is_empty():
		return BASE_ORE_ID
	return COMBAT_DROP_MATERIAL_IDS[0] if randf() < 0.65 else COMBAT_DROP_MATERIAL_IDS[1]

static func primary_ore_for_rarity(rarity: int) -> String:
	match clampi(rarity, Enums.Rarity.COMMON, Enums.Rarity.LEGENDARY):
		Enums.Rarity.RARE:
			return RARE_ORE_ID
		Enums.Rarity.EPIC:
			return EPIC_ORE_ID
		Enums.Rarity.LEGENDARY:
			return LEGEND_ORE_ID
		_:
			return BASE_ORE_ID

static func item_category(item: Resource) -> String:
	if item == null:
		return ""
	if "weapon_id" in item and not str(item.weapon_id).is_empty():
		return "weapon"
	if "armor_id" in item and not str(item.armor_id).is_empty():
		return "armor"
	if "accessory_id" in item and not str(item.accessory_id).is_empty():
		return "accessory"
	return ""

static func item_rarity(item: Resource) -> int:
	match item_category(item):
		"weapon":
			return weapon_rarity(item)
		"armor":
			return armor_rarity(item)
		"accessory":
			return accessory_rarity(item)
		_:
			return Enums.Rarity.COMMON

static func get_material_cost(next_level: int, item_rarity: int = Enums.Rarity.COMMON) -> Dictionary:
	if next_level < 1 or next_level > MAX_FORGE_LEVEL:
		return {}
	var rarity: int = clampi(item_rarity, Enums.Rarity.COMMON, Enums.Rarity.LEGENDARY)
	var primary_id: String = primary_ore_for_rarity(rarity)
	var costs: Dictionary = {}
	if rarity == Enums.Rarity.LEGENDARY and next_level >= 4:
		costs[COMMON_MATERIAL_ID] = 3
		costs[LEGEND_ORE_ID] = 2 if next_level == 4 else 3
		return costs
	var common_count: int = 1
	var primary_count: int = 1
	match next_level:
		1:
			common_count = 1
			primary_count = 1
		2:
			common_count = 1
			primary_count = 2
		3:
			common_count = 2
			primary_count = 2
		4:
			common_count = 3 if rarity == Enums.Rarity.COMMON else 2
			primary_count = 3 if rarity == Enums.Rarity.COMMON else 2
		5:
			common_count = 3 if rarity == Enums.Rarity.COMMON else 2
			primary_count = 4 if rarity == Enums.Rarity.COMMON else 2
	costs[COMMON_MATERIAL_ID] = common_count
	costs[primary_id] = primary_count
	if next_level >= 4:
		if rarity == Enums.Rarity.RARE:
			costs[EPIC_ORE_ID] = 1
		elif rarity == Enums.Rarity.EPIC:
			costs[LEGEND_ORE_ID] = 1
	return costs

static func get_enhance_level(item: Resource) -> int:
	if item == null or not ("enhance_level" in item):
		return 0
	return clampi(int(item.enhance_level), 0, MAX_FORGE_LEVEL)

static func get_effective_attack(weapon: Resource) -> int:
	if weapon == null:
		return 0
	var scaled: int = scale_equip_stat(
		int(weapon.rolled_attack),
		get_equip_level(weapon),
		weapon_rarity(weapon)
	)
	return scaled + get_enhance_level(weapon) * BalanceConfig.EQUIP_FORGE_FLAT_PER_LEVEL

static func pick_event_drop_material() -> String:
	if EVENT_DROP_MATERIAL_IDS.is_empty():
		return COMMON_MATERIAL_ID
	return EVENT_DROP_MATERIAL_IDS[randi() % EVENT_DROP_MATERIAL_IDS.size()]

static func get_display_name(item: Resource) -> String:
	var category: String = item_category(item)
	match category:
		"weapon":
			return get_weapon_display_name(item)
		"armor":
			return get_armor_display_name(item)
		"accessory":
			return get_accessory_display_name(item)
		_:
			return ""

static func get_weapon_display_name(weapon: Resource) -> String:
	if weapon == null or str(weapon.weapon_id).is_empty():
		return ""
	var base_name: String = DataRegistry.get_weapon_name(str(weapon.weapon_id))
	var prefix: String = _ElementResolver.get_weapon_prefix(_WeaponStatResolver.resolve_element(weapon))
	if not prefix.is_empty():
		base_name = prefix + base_name
	var level: int = get_enhance_level(weapon)
	var lv_tag: String = format_equip_level_tag(weapon)
	var name: String = base_name + lv_tag
	if level > 0:
		name = "%s +%d" % [name, level]
	return name

static func get_armor_display_name(armor: Resource) -> String:
	if armor == null or str(armor.armor_id).is_empty():
		return ""
	var base_name: String = DataRegistry.get_armor_name(str(armor.armor_id))
	var level: int = get_enhance_level(armor)
	var lv_tag: String = format_equip_level_tag(armor)
	var name: String = base_name + lv_tag
	if level > 0:
		name = "%s +%d" % [name, level]
	return name + _EquipmentRollHelper.perfect_roll_suffix(armor)

static func get_accessory_display_name(accessory: Resource) -> String:
	if accessory == null or str(accessory.accessory_id).is_empty():
		return ""
	var base_name: String = DataRegistry.get_accessory_name(str(accessory.accessory_id))
	var level: int = get_enhance_level(accessory)
	var lv_tag: String = format_equip_level_tag(accessory)
	var name: String = base_name + lv_tag
	if level > 0:
		name = "%s +%d" % [name, level]
	return name + _EquipmentRollHelper.perfect_roll_suffix(accessory)

static func get_gold_cost(next_level: int) -> int:
	return int(GOLD_BY_NEXT_LEVEL.get(next_level, 0))

static func can_enhance_item(item: Resource) -> Dictionary:
	var fail := func(reason: String) -> Dictionary:
		return {"ok": false, "reason": reason}
	if item == null or item_category(item).is_empty():
		return fail.call("装備が選択されていません")
	if not bool(item.is_appraised):
		return fail.call("未鑑定の装備は炉研ぎできません")
	var current: int = get_enhance_level(item)
	if current >= MAX_FORGE_LEVEL:
		return fail.call("炉研ぎ上限に達しています")
	var next_level: int = current + 1
	var rarity: int = item_rarity(item)
	var gold_cost: int = get_gold_cost(next_level)
	var materials: Dictionary = get_material_cost(next_level, rarity)
	if GameState.gold < gold_cost:
		return fail.call("ゴールドが足りません")
	if not CraftHelper.has_enough_materials(materials):
		return fail.call("素材が足りません")
	return {
		"ok": true,
		"reason": "",
		"next_level": next_level,
		"gold_cost": gold_cost,
		"materials": materials,
	}

static func can_enhance(weapon: Resource) -> Dictionary:
	return can_enhance_item(weapon)

static func enhance_item(item: Resource) -> Dictionary:
	var check: Dictionary = can_enhance_item(item)
	if not bool(check.get("ok", false)):
		return check
	var gold_cost: int = int(check.get("gold_cost", 0))
	var materials: Dictionary = check.get("materials", {})
	GameState.gold -= gold_cost
	GameState.consume_materials(materials)
	item.enhance_level = int(check.get("next_level", get_enhance_level(item) + 1))
	var result: Dictionary = {
		"ok": true,
		"reason": "",
		"next_level": item.enhance_level,
		"display_name": get_display_name(item),
		"category": item_category(item),
	}
	match item_category(item):
		"weapon":
			result["effective_attack"] = get_effective_attack(item)
		"armor":
			result["effective_defense"] = effective_armor_defense(item)
			result["effective_hp"] = effective_armor_hp(item)
		"accessory":
			result["effective_attack"] = effective_accessory_int_bonus(
				item, "attack_bonus", DataRegistry.get_accessory_data(str(item.accessory_id))
			)
	return result

static func enhance_weapon(weapon: Resource) -> Dictionary:
	return enhance_item(weapon)

static func clamp_equip_level(level: int) -> int:
	return clampi(level, 1, EQUIP_MAX_LEVEL)

static func equip_growth_rate_for_rarity(rarity: int) -> float:
	var rate: float = EQUIP_GROWTH_RATE
	if rarity >= Enums.Rarity.LEGENDARY:
		rate *= EQUIP_LEGENDARY_GROWTH_MULT
	return rate

static func scale_equip_stat(base: int, equip_level: int, rarity: int = 0) -> int:
	if base <= 0:
		return 0
	var lv: int = clamp_equip_level(equip_level)
	var rate: float = equip_growth_rate_for_rarity(rarity)
	return maxi(1, base + int(floor(float(base) * rate * float(lv - 1))))

static func scale_equip_float(base: float, equip_level: int, rarity: int = 0) -> float:
	if base <= 0.0:
		return 0.0
	var lv: int = clamp_equip_level(equip_level)
	var rate: float = equip_growth_rate_for_rarity(rarity)
	return base + base * rate * float(lv - 1)

static func resolve_drop_equip_level(stage: Resource, dungeon: Resource) -> int:
	var base_lv: int = 1
	if stage != null and int(stage.enemy_level) > 0:
		base_lv = int(stage.enemy_level)
	elif dungeon != null and int(dungeon.enemy_level) > 0:
		base_lv = int(dungeon.enemy_level)
	return clamp_equip_level(base_lv + randi_range(-1, 1))

static func equip_exp_to_next_level(level: int) -> int:
	return EQUIP_EXP_BASE + clamp_equip_level(level) * EQUIP_EXP_PER_LEVEL

static func get_equip_level(item: Resource) -> int:
	if item == null or not ("equip_level" in item):
		return 1
	return clamp_equip_level(int(item.equip_level))

static func get_equip_exp(item: Resource) -> int:
	if item == null or not ("equip_exp" in item):
		return 0
	return maxi(0, int(item.equip_exp))

static func equip_level_cap_for_member(member: Resource) -> int:
	if member == null:
		return EQUIP_MAX_LEVEL
	var member_level: int = 1
	if "level" in member:
		member_level = int(member.level)
	return clamp_equip_level(member_level)

static func add_equip_exp(item: Resource, amount: int, member: Resource) -> void:
	if item == null or amount <= 0 or not ("equip_exp" in item) or not ("equip_level" in item):
		return
	var cap: int = equip_level_cap_for_member(member)
	if get_equip_level(item) >= cap:
		return
	item.equip_exp = get_equip_exp(item) + amount
	while get_equip_level(item) < cap:
		var need: int = equip_exp_to_next_level(get_equip_level(item))
		if get_equip_exp(item) < need:
			break
		item.equip_exp = get_equip_exp(item) - need
		item.equip_level = get_equip_level(item) + 1

static func grant_party_combat_exp(enemy_level: int, members: Array) -> void:
	var gain: int = maxi(1, int(enemy_level) / 2)
	for member in members:
		if member == null:
			continue
		if member.equipped_weapon != null:
			add_equip_exp(member.equipped_weapon, gain, member)
		if member.equipped_armor != null:
			add_equip_exp(member.equipped_armor, gain, member)
		if member.equipped_accessory != null:
			add_equip_exp(member.equipped_accessory, gain, member)

static func weapon_rarity(weapon: Resource) -> int:
	if weapon == null or str(weapon.weapon_id).is_empty():
		return 0
	var data: Resource = DataRegistry.get_weapon_data(str(weapon.weapon_id))
	return int(data.rarity) if data != null else 0

static func armor_rarity(armor: Resource) -> int:
	if armor == null:
		return 0
	if "rarity" in armor and int(armor.rarity) > 0:
		return int(armor.rarity)
	if str(armor.armor_id).is_empty():
		return 0
	var data: Resource = DataRegistry.get_armor_data(str(armor.armor_id))
	return int(data.rarity) if data != null else 0

static func accessory_rarity(accessory: Resource) -> int:
	if accessory == null or str(accessory.accessory_id).is_empty():
		return 0
	var data: Resource = DataRegistry.get_accessory_data(str(accessory.accessory_id))
	return int(data.rarity) if data != null else 0

static func effective_armor_defense(armor: Resource) -> int:
	if armor == null:
		return 0
	return scale_equip_stat(int(armor.rolled_defense), get_equip_level(armor), armor_rarity(armor)) \
		+ get_enhance_level(armor) * BalanceConfig.EQUIP_FORGE_FLAT_PER_LEVEL

static func effective_armor_hp(armor: Resource) -> int:
	if armor == null:
		return 0
	return scale_equip_stat(int(armor.hp_bonus), get_equip_level(armor), armor_rarity(armor)) \
		+ get_enhance_level(armor) * BalanceConfig.EQUIP_FORGE_HP_PER_LEVEL

static func effective_accessory_int_bonus(accessory: Resource, field: String, data: Resource) -> int:
	if accessory == null:
		return 0
	var raw: int = _AccessoryStatResolver.resolve_int_stat(accessory, field, data)
	if raw <= 0:
		return 0
	var rarity: int = int(data.rarity) if data != null else accessory_rarity(accessory)
	return scale_equip_stat(raw, get_equip_level(accessory), rarity) \
		+ get_enhance_level(accessory) * BalanceConfig.EQUIP_FORGE_FLAT_PER_LEVEL

static func effective_accessory_float_bonus(accessory: Resource, field: String, data: Resource) -> float:
	if accessory == null:
		return 0.0
	var raw: float = _AccessoryStatResolver.resolve_float_stat(accessory, field, data)
	if raw <= 0.0:
		return 0.0
	var rarity: int = int(data.rarity) if data != null else accessory_rarity(accessory)
	return scale_equip_float(raw, get_equip_level(accessory), rarity)

static func assign_drop_equip_level(item: Resource, stage: Resource, dungeon: Resource) -> void:
	if item == null or not ("equip_level" in item):
		return
	item.equip_level = resolve_drop_equip_level(stage, dungeon)
	if "equip_exp" in item:
		item.equip_exp = 0

static func format_equip_level_tag(item: Resource) -> String:
	return " Lv.%d" % get_equip_level(item)


static func alchemy_level_gain(fodder: Resource) -> int:
	return maxi(1, int(floor(float(get_equip_level(fodder)) * ALCHEMY_LEVEL_FACTOR)))


static func alchemy_gold_cost(applied_gain: int) -> int:
	return maxi(0, applied_gain) * ALCHEMY_GOLD_PER_GAIN


static func alchemy_needs_confirm(fodder: Resource) -> bool:
	if fodder == null:
		return false
	if item_rarity(fodder) >= Enums.Rarity.EPIC:
		return true
	return get_enhance_level(fodder) >= ALCHEMY_CONFIRM_ENHANCE_LEVEL


static func clamp_equip_level_to_member(item: Resource, member: Resource) -> void:
	if item == null or member == null or not ("equip_level" in item):
		return
	var cap: int = equip_level_cap_for_member(member)
	if get_equip_level(item) > cap:
		item.equip_level = cap


static func alchemy_preview(base: Resource, fodder: Resource) -> Dictionary:
	var check: Dictionary = can_alchemy(base, fodder)
	if not bool(check.get("ok", false)):
		return check
	var from_lv: int = get_equip_level(base)
	var gain_raw: int = alchemy_level_gain(fodder)
	var to_lv: int = mini(EQUIP_MAX_LEVEL, from_lv + gain_raw)
	var applied: int = to_lv - from_lv
	var gold: int = alchemy_gold_cost(applied)
	return {
		"ok": true,
		"reason": "",
		"from_level": from_lv,
		"to_level": to_lv,
		"gain": applied,
		"gold_cost": gold,
		"needs_confirm": alchemy_needs_confirm(fodder),
	}


static func can_alchemy(base: Resource, fodder: Resource) -> Dictionary:
	var fail := func(reason: String) -> Dictionary:
		return {"ok": false, "reason": reason}
	if base == null or fodder == null:
		return fail.call("主材と素材を選んでください")
	if base == fodder:
		return fail.call("同じ装備を素材にはできません")
	var cat_base: String = item_category(base)
	var cat_fodder: String = item_category(fodder)
	if cat_base.is_empty() or cat_fodder.is_empty():
		return fail.call("装備が不正です")
	if cat_base != cat_fodder:
		return fail.call("同じ種類の装備同士のみ錬成できます")
	if item_rarity(fodder) >= Enums.Rarity.MYTHIC:
		return fail.call("神話装備は錬成素材にできません")
	if item_rarity(base) >= Enums.Rarity.MYTHIC:
		return fail.call("神話装備は錬成できません")
	if GameState.find_item_equipped_member_index(base) >= 0:
		return fail.call("主材が装備中です。外してから行ってください")
	if GameState.find_item_equipped_member_index(fodder) >= 0:
		return fail.call("素材が装備中です。外してから行ってください")
	var from_lv: int = get_equip_level(base)
	if from_lv >= EQUIP_MAX_LEVEL:
		return fail.call("主材は装備レベル上限です")
	var to_lv: int = mini(EQUIP_MAX_LEVEL, from_lv + alchemy_level_gain(fodder))
	var applied: int = to_lv - from_lv
	if applied <= 0:
		return fail.call("レベルが上がりません")
	var gold: int = alchemy_gold_cost(applied)
	if GameState.gold < gold:
		return fail.call("ゴールドが足りません")
	return {
		"ok": true,
		"reason": "",
		"from_level": from_lv,
		"to_level": to_lv,
		"gain": applied,
		"gold_cost": gold,
		"needs_confirm": alchemy_needs_confirm(fodder),
	}


static func perform_alchemy(base: Resource, fodder: Resource) -> Dictionary:
	var preview: Dictionary = alchemy_preview(base, fodder)
	if not bool(preview.get("ok", false)):
		return preview
	var gold: int = int(preview.get("gold_cost", 0))
	var to_lv: int = int(preview.get("to_level", get_equip_level(base)))
	if GameState.gold < gold:
		return {"ok": false, "reason": "ゴールドが足りません"}
	if not _remove_item_from_inventory(fodder):
		return {"ok": false, "reason": "素材を削除できませんでした"}
	GameState.gold -= gold
	base.equip_level = to_lv
	return {
		"ok": true,
		"reason": "",
		"from_level": int(preview.get("from_level", 1)),
		"to_level": to_lv,
		"gain": int(preview.get("gain", 0)),
		"gold_cost": gold,
	}


static func can_dismantle_item(item: Resource) -> Dictionary:
	var fail := func(reason: String) -> Dictionary:
		return {"ok": false, "reason": reason}
	if item == null or item_category(item).is_empty():
		return fail.call("装備が選択されていません")
	if not bool(item.is_appraised):
		return fail.call("未鑑定の装備は分解できません")
	if GameState.find_item_equipped_member_index(item) >= 0:
		return fail.call("装備中のアイテムは分解できません")
	return {"ok": true, "reason": ""}

static func _dismantle_base_yields(item: Resource) -> Dictionary:
	var rarity: int = item_rarity(item)
	var yields: Dictionary = {}
	match rarity:
		Enums.Rarity.RARE:
			yields[RARE_ORE_ID] = 1
			yields[COMMON_MATERIAL_ID] = 1
		Enums.Rarity.EPIC:
			yields[EPIC_ORE_ID] = 1
			yields[COMMON_MATERIAL_ID] = 2
		Enums.Rarity.LEGENDARY:
			yields[LEGEND_ORE_ID] = 1
			yields[COMMON_MATERIAL_ID] = 2
		_:
			yields[BASE_ORE_ID] = 2
			yields[COMMON_MATERIAL_ID] = 1
	return yields

static func _dismantle_enhance_bonus(item: Resource) -> Dictionary:
	var bonus: Dictionary = {}
	var enhance: int = get_enhance_level(item)
	if enhance <= 0:
		return bonus
	bonus[COMMON_MATERIAL_ID] = enhance
	var rarity: int = item_rarity(item)
	if enhance >= 4:
		bonus[primary_ore_for_rarity(rarity)] = bonus.get(primary_ore_for_rarity(rarity), 0) + 1
		if rarity == Enums.Rarity.RARE:
			bonus[EPIC_ORE_ID] = bonus.get(EPIC_ORE_ID, 0) + 1
		elif rarity == Enums.Rarity.EPIC:
			bonus[LEGEND_ORE_ID] = bonus.get(LEGEND_ORE_ID, 0) + 1
	return bonus

static func _merge_material_dict(target: Dictionary, add: Dictionary) -> Dictionary:
	for mat_id in add:
		target[mat_id] = int(target.get(mat_id, 0)) + int(add[mat_id])
	return target

static func _item_master_id(item: Resource) -> String:
	match item_category(item):
		"weapon":
			return str(item.weapon_id)
		"armor":
			return str(item.armor_id)
		"accessory":
			return str(item.accessory_id)
		_:
			return ""

static func _cap_dismantle_by_craft_return(item: Resource, yields: Dictionary) -> Dictionary:
	var category: String = item_category(item)
	var output_id: String = _item_master_id(item)
	if category.is_empty() or output_id.is_empty():
		return yields
	for craft in DataRegistry.get_all_craft_data():
		if str(craft.output_type) != category or str(craft.output_id) != output_id:
			continue
		var capped: Dictionary = {}
		for mat_id in yields:
			var recipe_qty: int = int(craft.required_materials.get(mat_id, 0))
			if recipe_qty <= 0:
				capped[mat_id] = int(yields[mat_id])
			else:
				var max_return: int = int(floor(float(recipe_qty) * DISMANTLE_CRAFT_RETURN_CAP))
				capped[mat_id] = mini(int(yields[mat_id]), max_return)
		return capped
	return yields

static func dismantle_preview(item: Resource) -> Dictionary:
	var check: Dictionary = can_dismantle_item(item)
	if not bool(check.get("ok", false)):
		return check
	var yields: Dictionary = _dismantle_base_yields(item)
	_merge_material_dict(yields, _dismantle_enhance_bonus(item))
	yields = _cap_dismantle_by_craft_return(item, yields)
	return {"ok": true, "reason": "", "materials": yields}

static func _remove_item_from_inventory(item: Resource) -> bool:
	var idx: int = -1
	match item_category(item):
		"weapon":
			idx = GameState.inventory.find(item)
			if idx >= 0:
				GameState.inventory.remove_at(idx)
				return true
		"armor":
			idx = GameState.armor_inventory.find(item)
			if idx >= 0:
				GameState.armor_inventory.remove_at(idx)
				return true
		"accessory":
			idx = GameState.accessory_inventory.find(item)
			if idx >= 0:
				GameState.accessory_inventory.remove_at(idx)
				return true
	return false

static func dismantle_item(item: Resource) -> Dictionary:
	var preview: Dictionary = dismantle_preview(item)
	if not bool(preview.get("ok", false)):
		return preview
	if not _remove_item_from_inventory(item):
		return {"ok": false, "reason": "インベントリから削除できませんでした"}
	var materials: Dictionary = preview.get("materials", {})
	for mat_id in materials:
		GameState.add_material(str(mat_id), int(materials[mat_id]))
	return {"ok": true, "reason": "", "materials": materials}

static func list_bulk_dismantle_candidates() -> Array:
	var out: Array = []
	for item in GameState.inventory:
		if _is_bulk_dismantle_candidate(item):
			out.append(item)
	for item in GameState.armor_inventory:
		if _is_bulk_dismantle_candidate(item):
			out.append(item)
	for item in GameState.accessory_inventory:
		if _is_bulk_dismantle_candidate(item):
			out.append(item)
	return out

static func _is_bulk_dismantle_candidate(item: Resource) -> bool:
	if not bool(can_dismantle_item(item).get("ok", false)):
		return false
	var rarity: int = item_rarity(item)
	return rarity == Enums.Rarity.COMMON or rarity == Enums.Rarity.RARE

static func dismantle_bulk_preview() -> Dictionary:
	var items: Array = list_bulk_dismantle_candidates()
	var total: Dictionary = {}
	for item in items:
		var preview: Dictionary = dismantle_preview(item)
		if bool(preview.get("ok", false)):
			_merge_material_dict(total, preview.get("materials", {}))
	return {"ok": true, "count": items.size(), "materials": total, "items": items}

static func dismantle_bulk_common_rare() -> Dictionary:
	var preview: Dictionary = dismantle_bulk_preview()
	var items: Array = preview.get("items", [])
	if items.is_empty():
		return {"ok": false, "reason": "分解対象がありません", "count": 0, "materials": {}}
	for item in items:
		if not _remove_item_from_inventory(item):
			continue
	for mat_id in preview.get("materials", {}):
		GameState.add_material(str(mat_id), int(preview["materials"][mat_id]))
	return {
		"ok": true,
		"reason": "",
		"count": items.size(),
		"materials": preview.get("materials", {}),
	}
