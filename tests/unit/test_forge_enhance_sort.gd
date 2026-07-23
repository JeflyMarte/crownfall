extends GutTest

## 鍛冶・強化左一覧の並び（装備中優先／ステ高い順）。

const _Helper = preload("res://scripts/blacksmith/BlacksmithUiHelper.gd")
const _Enh = preload("res://scripts/equipment/EquipmentEnhancer.gd")


func _make_weapon(weapon_id: String, rolled_attack: int, enhance_level: int = 0) -> Resource:
	var w: Resource = load("res://scripts/domain/WeaponInstance.gd").new()
	w.weapon_id = weapon_id
	w.rolled_attack = rolled_attack
	w.enhance_level = enhance_level
	w.is_appraised = true
	w.equip_level = 1
	return w


func test_enhance_list_stat_score_prefers_higher_attack() -> void:
	var low: Resource = _make_weapon("iron_sword", 20)
	var high: Resource = _make_weapon("iron_sword", 80)
	assert_gt(_Helper.enhance_list_stat_score(high), _Helper.enhance_list_stat_score(low))


func test_enhance_list_sort_equipped_before_unequipped() -> void:
	var unequipped_strong: Resource = _make_weapon("iron_sword", 200)
	var equipped_weak: Resource = _make_weapon("iron_sword", 10)
	assert_true(
		_Helper.enhance_list_sort_before(equipped_weak, unequipped_strong, true, false),
		"装備中が未装備より先"
	)
	assert_false(
		_Helper.enhance_list_sort_before(unequipped_strong, equipped_weak, false, true)
	)


func test_enhance_list_sort_unequipped_by_stat_desc() -> void:
	var low: Resource = _make_weapon("iron_sword", 20)
	var high: Resource = _make_weapon("iron_sword", 90)
	assert_true(_Helper.enhance_list_sort_before(high, low, false, false))
	var items: Array = [low, high]
	items.sort_custom(func(a: Resource, b: Resource) -> bool:
		return _Helper.enhance_list_sort_before(a, b, false, false)
	)
	assert_eq(_Enh.get_effective_attack(items[0]), _Enh.get_effective_attack(high))
