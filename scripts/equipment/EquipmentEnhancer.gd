class_name EquipmentEnhancer
extends RefCounted

const _EquipmentRollHelper = preload("res://scripts/equipment/EquipmentRollHelper.gd")
const _AccessoryStatResolver = preload("res://scripts/equipment/AccessoryStatResolver.gd")
const _WeaponStatResolver = preload("res://scripts/equipment/WeaponStatResolver.gd")
const _ElementResolver = preload("res://scripts/combat/ElementResolver.gd")

## 鍛冶屋「炉研ぎ」— 武器のみ +1〜+5（P3-D152）。
## 装備レベル成長 — P3-EQ-LVL-001。

const MAX_FORGE_LEVEL: int = 5
const EQUIP_MAX_LEVEL: int = 99
const EQUIP_GROWTH_RATE: float = 0.04
const EQUIP_LEGENDARY_GROWTH_MULT: float = 1.25
const EQUIP_EXP_BASE: int = 10
const EQUIP_EXP_PER_LEVEL: int = 5

const GOLD_BY_NEXT_LEVEL: Dictionary = {
	1: 30,
	2: 50,
	3: 80,
	4: 120,
	5: 180,
}

const MATERIALS_BY_NEXT_LEVEL: Array[Dictionary] = [
	{},
	{"relic_shard": 1},
	{"relic_shard": 2},
	{"relic_shard": 2, "ancient_bone": 1},
	{"relic_shard": 3, "elite_relic_shard": 1},
	{"relic_shard": 3, "elite_relic_shard": 2},
]

## 炉研ぎ消費素材＝戦闘ドロップの唯一対象（P3-D067 改）。
const ENHANCEMENT_MATERIAL_IDS: Array[String] = [
	"relic_shard",
	"ancient_bone",
	"elite_relic_shard",
]
const COMBAT_DROP_MATERIAL_IDS: Array[String] = ["relic_shard", "ancient_bone"]
const EVENT_DROP_MATERIAL_IDS: Array[String] = ["relic_shard", "ancient_bone"]

static func is_enhancement_material(material_id: String) -> bool:
	return material_id in ENHANCEMENT_MATERIAL_IDS

## 図鑑 S5「採取素材」表示用（敵別ではなく炉研ぎ共通3種。P3-MAT-CODEx-001）。
static func forge_material_display_names() -> PackedStringArray:
	var parts: PackedStringArray = []
	for mat_id in ENHANCEMENT_MATERIAL_IDS:
		var mat_data: Resource = DataRegistry.get_material_data(str(mat_id))
		var mat_name: String = str(mat_id) if mat_data == null else str(mat_data.display_name)
		if mat_data != null and int(mat_data.rarity) >= 1:
			mat_name = "【希少】" + mat_name
		parts.append(mat_name)
	return parts

static func pick_combat_drop_material() -> String:
	if COMBAT_DROP_MATERIAL_IDS.is_empty():
		return "relic_shard"
	return COMBAT_DROP_MATERIAL_IDS[0] if randf() < 0.72 else COMBAT_DROP_MATERIAL_IDS[1]

static func pick_event_drop_material() -> String:
	if EVENT_DROP_MATERIAL_IDS.is_empty():
		return "relic_shard"
	return EVENT_DROP_MATERIAL_IDS[randi() % EVENT_DROP_MATERIAL_IDS.size()]

static func get_enhance_level(weapon: Resource) -> int:
	if weapon == null:
		return 0
	if not ("enhance_level" in weapon):
		return 0
	return clampi(int(weapon.enhance_level), 0, MAX_FORGE_LEVEL)

static func get_effective_attack(weapon: Resource) -> int:
	if weapon == null:
		return 0
	var scaled: int = scale_equip_stat(
		int(weapon.rolled_attack),
		get_equip_level(weapon),
		weapon_rarity(weapon)
	)
	return scaled + get_enhance_level(weapon)

static func get_display_name(weapon: Resource) -> String:
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
	return name + _EquipmentRollHelper.perfect_roll_suffix(weapon)

static func get_gold_cost(next_level: int) -> int:
	return int(GOLD_BY_NEXT_LEVEL.get(next_level, 0))

static func get_material_cost(next_level: int) -> Dictionary:
	if next_level < 1 or next_level > MAX_FORGE_LEVEL:
		return {}
	var raw: Dictionary = MATERIALS_BY_NEXT_LEVEL[next_level]
	return raw.duplicate()

static func can_enhance(weapon: Resource) -> Dictionary:
	var fail := func(reason: String) -> Dictionary:
		return {"ok": false, "reason": reason}
	if weapon == null or str(weapon.weapon_id).is_empty():
		return fail.call("武器が選択されていません")
	if not bool(weapon.is_appraised):
		return fail.call("未鑑定の武器は炉研ぎできません")
	var current: int = get_enhance_level(weapon)
	if current >= MAX_FORGE_LEVEL:
		return fail.call("炉研ぎ上限に達しています")
	var next_level: int = current + 1
	var gold_cost: int = get_gold_cost(next_level)
	var materials: Dictionary = get_material_cost(next_level)
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

static func enhance_weapon(weapon: Resource) -> Dictionary:
	var check: Dictionary = can_enhance(weapon)
	if not bool(check.get("ok", false)):
		return check
	var gold_cost: int = int(check.get("gold_cost", 0))
	var materials: Dictionary = check.get("materials", {})
	GameState.gold -= gold_cost
	GameState.consume_materials(materials)
	weapon.enhance_level = int(check.get("next_level", get_enhance_level(weapon) + 1))
	return {
		"ok": true,
		"reason": "",
		"next_level": weapon.enhance_level,
		"display_name": get_display_name(weapon),
		"effective_attack": get_effective_attack(weapon),
	}

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
	return scale_equip_stat(int(armor.rolled_defense), get_equip_level(armor), armor_rarity(armor))

static func effective_armor_hp(armor: Resource) -> int:
	if armor == null:
		return 0
	return scale_equip_stat(int(armor.hp_bonus), get_equip_level(armor), armor_rarity(armor))

static func effective_accessory_int_bonus(accessory: Resource, field: String, data: Resource) -> int:
	if accessory == null:
		return 0
	var raw: int = _AccessoryStatResolver.resolve_int_stat(accessory, field, data)
	if raw <= 0:
		return 0
	var rarity: int = int(data.rarity) if data != null else accessory_rarity(accessory)
	return scale_equip_stat(raw, get_equip_level(accessory), rarity)

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
	var lv: int = get_equip_level(item)
	if lv <= 1:
		return ""
	return " Lv.%d" % lv
