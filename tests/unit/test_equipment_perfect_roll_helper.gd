extends GutTest

## パーフェクトロール⭐️ — ステータス行表示（P3-EQ-DIABLO-001: 固定行は⭐️無し、ランダム行に表示）。

const _EquipmentPerfectRollHelper = preload("res://scripts/equipment/EquipmentPerfectRollHelper.gd")
const _EquipmentDisplayNames = preload("res://scripts/equipment/EquipmentDisplayNames.gd")
const _EquipmentEnhancer = preload("res://scripts/equipment/EquipmentEnhancer.gd")
const _WeaponStatResolver = preload("res://scripts/equipment/WeaponStatResolver.gd")
const _EquipmentItemDetailHelper = preload("res://scripts/equipment/EquipmentItemDetailHelper.gd")
const _WeaponInstance = preload("res://scripts/domain/WeaponInstance.gd")
const _ArmorInstance = preload("res://scripts/domain/ArmorInstance.gd")
const _ERM = preload("res://scripts/equipment/EquipmentRandomMods.gd")

func test_display_name_has_no_perfect_stars() -> void:
	var armor: Resource = _ArmorInstance.new()
	armor.armor_id = "leather_armor"
	armor.perfect_roll_count = 3
	var name: String = _EquipmentDisplayNames.get_instance_name(armor, "armor")
	assert_false(name.contains("⭐️"))

func test_fixed_attack_row_has_no_star() -> void:
	var weapon: Resource = _WeaponInstance.new()
	weapon.weapon_id = "iron_sword"
	var data: Resource = DataRegistry.get_weapon_data("iron_sword")
	assert_not_null(data)
	weapon.rolled_attack = int(data.base_attack)
	weapon.random_mods = []
	var rows: Array = _EquipmentItemDetailHelper.stat_rows(weapon, "weapon")
	var attack_row: Dictionary = rows[0]
	assert_eq(str(attack_row.get("label", "")), "攻撃力")
	assert_false(str(attack_row.get("value", "")).contains("⭐️"))

func test_attack_up_mod_shows_star_and_range_when_perfect() -> void:
	var weapon: Resource = _WeaponInstance.new()
	weapon.weapon_id = "iron_sword"
	var data: Resource = DataRegistry.get_weapon_data("iron_sword")
	assert_not_null(data)
	var rarity: int = int(data.rarity)
	var roll_max: int = int(
		_WeaponStatResolver.ATTACK_ROLL_MAX.get(rarity, _WeaponStatResolver.ATTACK_ROLL_MAX[Enums.Rarity.COMMON])
	)
	weapon.rolled_attack = int(data.base_attack)
	weapon.random_mods = [{
		"id": _ERM.KIND_ATTACK_UP,
		"label": "攻撃力アップ",
		"kind": _ERM.KIND_ATTACK_UP,
		"value": roll_max,
		"min_v": 1,
		"max_v": roll_max,
		"perfect": true,
		"meta": {},
	}]
	var rows: Array = _EquipmentItemDetailHelper.stat_rows(weapon, "weapon")
	assert_gt(rows.size(), 1)
	var mod_line: String = str(rows[1].get("value", ""))
	assert_true(mod_line.contains("攻撃力アップ"), mod_line)
	assert_true(mod_line.contains("(%d〜%d)" % [1, roll_max]), mod_line)
	assert_true(mod_line.contains("⭐️"), mod_line)
	assert_eq(str(rows[0].get("value", "")), str(_EquipmentEnhancer.get_effective_attack(weapon)))


func test_crit_rate_mod_shows_range() -> void:
	var weapon: Resource = _WeaponInstance.new()
	weapon.weapon_id = "iron_sword"
	var data: Resource = DataRegistry.get_weapon_data("iron_sword")
	weapon.rolled_attack = int(data.base_attack)
	var rarity: int = int(data.rarity)
	var crit_max: float = float(
		_WeaponStatResolver.CRITICAL_RATE_ROLL_MAX.get(
			rarity, _WeaponStatResolver.CRITICAL_RATE_ROLL_MAX[Enums.Rarity.COMMON]
		)
	)
	var mid: float = 0.01 + crit_max * 0.5
	weapon.random_mods = [{
		"id": _ERM.KIND_CRIT_RATE,
		"label": "会心率",
		"kind": _ERM.KIND_CRIT_RATE,
		"value": mid,
		"min_v": 0.01,
		"max_v": crit_max,
		"perfect": false,
		"meta": {},
	}]
	var rows: Array = _EquipmentItemDetailHelper.stat_rows(weapon, "weapon")
	var crit_line: String = ""
	for row: Dictionary in rows:
		var val: String = str(row.get("value", ""))
		if val.contains("会心率"):
			crit_line = val
			break
	assert_false(crit_line.is_empty())
	assert_true(crit_line.contains("〜"), crit_line)
