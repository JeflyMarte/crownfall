class_name EquipmentEnhancer
extends RefCounted

## 鍛冶屋「炉研ぎ」— 武器のみ +1〜+5（P3-D152）。

const MAX_LEVEL: int = 5

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

static func get_enhance_level(weapon: Resource) -> int:
	if weapon == null:
		return 0
	if not ("enhance_level" in weapon):
		return 0
	return clampi(int(weapon.enhance_level), 0, MAX_LEVEL)

static func get_effective_attack(weapon: Resource) -> int:
	if weapon == null:
		return 0
	return int(weapon.rolled_attack) + get_enhance_level(weapon)

static func get_display_name(weapon: Resource) -> String:
	if weapon == null or str(weapon.weapon_id).is_empty():
		return ""
	var base_name: String = DataRegistry.get_weapon_name(str(weapon.weapon_id))
	var level: int = get_enhance_level(weapon)
	if level <= 0:
		return base_name
	return "%s +%d" % [base_name, level]

static func get_gold_cost(next_level: int) -> int:
	return int(GOLD_BY_NEXT_LEVEL.get(next_level, 0))

static func get_material_cost(next_level: int) -> Dictionary:
	if next_level < 1 or next_level > MAX_LEVEL:
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
	if current >= MAX_LEVEL:
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
