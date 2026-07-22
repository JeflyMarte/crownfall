extends GutTest
## キャラ画面「装備中の効果」が武器ATK等を正しく含むこと。

const _EquipmentScene = preload("res://scripts/equipment/EquipmentScene.gd")
const _WeaponInstance = preload("res://scripts/domain/WeaponInstance.gd")
const _EquipmentEnhancer = preload("res://scripts/equipment/EquipmentEnhancer.gd")


func test_effect_bonuses_include_weapon_attack_and_crit() -> void:
	## Control シーンをツリーに入れずメソッドだけ検証（_ready 依存を避ける）。
	var scene: Object = _EquipmentScene.new()
	var member: Resource = GameState.party_members[0]
	assert_ne(member, null)
	var prev_weapon: Resource = member.equipped_weapon
	var weapon: Resource = _WeaponInstance.new()
	weapon.weapon_id = "iron_sword"
	weapon.rolled_attack = 40
	weapon.critical_rate = 0.12
	weapon.critical_damage = 1.5
	weapon.attack_speed = 1.0
	weapon.is_appraised = true
	weapon.equip_level = 1
	member.equipped_weapon = weapon
	var bonuses: Dictionary = scene._compute_equipment_effect_bonuses(member)
	var expect_atk: int = _EquipmentEnhancer.get_effective_attack(weapon)
	assert_eq(int(bonuses.get("attack", 0)), expect_atk, "武器ATKが効果欄に入る")
	assert_almost_eq(float(bonuses.get("crit_rate", 0.0)), 0.12, 0.0001)
	assert_almost_eq(float(bonuses.get("crit_damage", 0.0)), 0.5, 0.0001, "1.5倍 → +50%")
	member.equipped_weapon = null
	var empty: Dictionary = scene._compute_equipment_effect_bonuses(member)
	assert_eq(int(empty.get("attack", -1)), 0)
	assert_almost_eq(float(empty.get("crit_rate", -1.0)), 0.0, 0.0001)
	member.equipped_weapon = prev_weapon
	scene.free()
