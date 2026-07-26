extends GutTest

## 鍛冶・強化左一覧の並び（装備中優先／レアリティ順）。

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


func test_enhance_list_sort_equipped_before_unequipped() -> void:
	var unequipped_rare: Resource = _make_weapon("lighthouse_greatsword", 200)
	var equipped_common: Resource = _make_weapon("iron_sword", 10)
	assert_true(
		_Helper.enhance_list_sort_before(equipped_common, unequipped_rare, true, false),
		"装備中が未装備より先"
	)
	assert_false(
		_Helper.enhance_list_sort_before(unequipped_rare, equipped_common, false, true)
	)


func test_enhance_list_sort_unequipped_by_rarity_desc() -> void:
	var common: Resource = _make_weapon("iron_sword", 90)
	var rare: Resource = _make_weapon("lighthouse_greatsword", 20)
	assert_gt(_Enh.item_rarity(rare), _Enh.item_rarity(common))
	assert_true(_Helper.enhance_list_sort_before(rare, common, false, false))
	var items: Array = [common, rare]
	items.sort_custom(func(a: Resource, b: Resource) -> bool:
		return _Helper.enhance_list_sort_before(a, b, false, false)
	)
	assert_eq(str(items[0].weapon_id), "lighthouse_greatsword")
