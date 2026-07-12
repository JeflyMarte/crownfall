extends GutTest

## パーフェクトロール⭐️ — ステータス行表示。

const _EquipmentPerfectRollHelper = preload("res://scripts/equipment/EquipmentPerfectRollHelper.gd")
const _EquipmentDisplayNames = preload("res://scripts/equipment/EquipmentDisplayNames.gd")
const _EquipmentEnhancer = preload("res://scripts/equipment/EquipmentEnhancer.gd")
const _WeaponStatResolver = preload("res://scripts/equipment/WeaponStatResolver.gd")
const _EquipmentItemDetailHelper = preload("res://scripts/equipment/EquipmentItemDetailHelper.gd")
const _WeaponInstance = preload("res://scripts/domain/WeaponInstance.gd")
const _ArmorInstance = preload("res://scripts/domain/ArmorInstance.gd")

func test_display_name_has_no_perfect_stars() -> void:
	var armor: Resource = _ArmorInstance.new()
	armor.armor_id = "leather_armor"
	armor.perfect_roll_count = 3
	var name: String = _EquipmentDisplayNames.get_instance_name(armor, "armor")
	assert_false(name.contains("⭐️"))

func test_attack_stat_shows_star_when_roll_is_max() -> void:
	var weapon: Resource = _WeaponInstance.new()
	weapon.weapon_id = "iron_sword"
	var data: Resource = DataRegistry.get_weapon_data("iron_sword")
	assert_not_null(data)
	var rarity: int = int(data.rarity)
	var roll_max: int = int(
		_WeaponStatResolver.ATTACK_ROLL_MAX.get(rarity, _WeaponStatResolver.ATTACK_ROLL_MAX[Enums.Rarity.COMMON])
	)
	weapon.rolled_attack = int(data.base_attack) + roll_max
	var rows: Array = _EquipmentItemDetailHelper.stat_rows(weapon, "weapon")
	var attack_row: Dictionary = rows[0]
	assert_true(str(attack_row.get("value", "")).ends_with("⭐️"))

func test_non_rolled_stat_has_no_star() -> void:
	var weapon: Resource = _WeaponInstance.new()
	weapon.weapon_id = "iron_sword"
	var data: Resource = DataRegistry.get_weapon_data("iron_sword")
	weapon.rolled_attack = int(data.base_attack)
	var rows: Array = _EquipmentItemDetailHelper.stat_rows(weapon, "weapon")
	var attack_row: Dictionary = rows[0]
	assert_false(str(attack_row.get("value", "")).contains("⭐️"))
