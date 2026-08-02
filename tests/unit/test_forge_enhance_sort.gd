extends GutTest

## 鍛冶・強化左一覧の並び（装備中優先／総合力順）。

const _Helper = preload("res://scripts/blacksmith/BlacksmithUiHelper.gd")
const _Power = preload("res://scripts/equipment/EquipmentPower.gd")


func _make_weapon(weapon_id: String, rolled_attack: int, enhance_level: int = 0) -> Resource:
	var w: Resource = load("res://scripts/domain/WeaponInstance.gd").new()
	w.weapon_id = weapon_id
	w.rolled_attack = rolled_attack
	w.enhance_level = enhance_level
	w.is_appraised = true
	w.equip_level = 1
	w.attack_speed = 1.0
	w.critical_rate = 0.0
	## マイグレーションをスキップするため空でない mods を置く。
	w.random_mods = [{"kind": "attack_up", "value": 0, "label": "t"}]
	return w


func test_enhance_list_sort_equipped_before_unequipped() -> void:
	var unequipped_strong: Resource = _make_weapon("iron_sword", 200)
	var equipped_weak: Resource = _make_weapon("iron_sword", 10)
	assert_true(
		_Helper.enhance_list_sort_before(equipped_weak, unequipped_strong, true, false, "weapon"),
		"装備中が未装備より先"
	)
	assert_false(
		_Helper.enhance_list_sort_before(unequipped_strong, equipped_weak, false, true, "weapon")
	)


func test_enhance_list_sort_by_power_desc() -> void:
	var weak: Resource = _make_weapon("iron_sword", 40)
	var strong: Resource = _make_weapon("iron_sword", 200)
	assert_gt(_Power.score(strong, "weapon"), _Power.score(weak, "weapon"))
	assert_true(_Helper.enhance_list_sort_before(strong, weak, false, false, "weapon"))
	var items: Array = [weak, strong]
	items.sort_custom(func(a: Resource, b: Resource) -> bool:
		return _Helper.enhance_list_sort_before(a, b, false, false, "weapon")
	)
	assert_eq(int(items[0].rolled_attack), 200)
