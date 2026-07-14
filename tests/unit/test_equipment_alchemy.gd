extends GutTest

## P3-FORGE-ALCHEMY-001 — 装備錬成

const _WeaponStatResolver = preload("res://scripts/equipment/WeaponStatResolver.gd")


func before_each() -> void:
	GameState.inventory.clear()
	GameState.armor_inventory.clear()
	GameState.accessory_inventory.clear()
	GameState.gold = 1000
	# party_members は他テストと共有するため消さない。無いときだけ補完。
	if GameState.party_members.is_empty() or GameState.roster.is_empty():
		GameState.seed_all_starters_unlocked()


func after_all() -> void:
	if GameState.party_members.is_empty() or GameState.roster.is_empty():
		GameState.seed_all_starters_unlocked()


func _make_weapon(level: int, rarity_hint_id: String = "iron_sword") -> Resource:
	var cls = load("res://scripts/domain/WeaponInstance.gd")
	var item: Resource = cls.new()
	item.instance_id = "w_%d_%d" % [level, randi()]
	item.weapon_id = rarity_hint_id
	item.is_appraised = true
	item.equip_level = level
	item.equip_exp = 0
	item.enhance_level = 0
	var data: Resource = DataRegistry.get_weapon_data(rarity_hint_id)
	if data != null:
		_WeaponStatResolver.apply_drop_stats(item, data)
	GameState.inventory.append(item)
	return item


func test_alchemy_gain_is_half_fodder_level_min_1() -> void:
	assert_eq(EquipmentEnhancer.alchemy_level_gain(_make_weapon(1)), 1)
	assert_eq(EquipmentEnhancer.alchemy_level_gain(_make_weapon(10)), 5)
	assert_eq(EquipmentEnhancer.alchemy_level_gain(_make_weapon(11)), 5)


func test_perform_alchemy_raises_base_and_removes_fodder() -> void:
	var base: Resource = _make_weapon(12)
	var fodder: Resource = _make_weapon(10)
	var result: Dictionary = EquipmentEnhancer.perform_alchemy(base, fodder)
	assert_true(bool(result.get("ok", false)), str(result))
	assert_eq(int(base.equip_level), 17)
	assert_eq(GameState.inventory.size(), 1)
	assert_true(base in GameState.inventory)
	assert_false(fodder in GameState.inventory)
	assert_eq(GameState.gold, 1000 - 100)


func test_alchemy_rejects_different_categories() -> void:
	var weapon: Resource = _make_weapon(5)
	var armor_cls = load("res://scripts/domain/ArmorInstance.gd")
	var armor: Resource = armor_cls.new()
	armor.instance_id = "a1"
	armor.armor_id = "leather_armor"
	armor.is_appraised = true
	armor.equip_level = 5
	GameState.armor_inventory.append(armor)
	var check: Dictionary = EquipmentEnhancer.can_alchemy(weapon, armor)
	assert_false(bool(check.get("ok", false)))


func test_alchemy_caps_at_99() -> void:
	var base: Resource = _make_weapon(97)
	var fodder: Resource = _make_weapon(20)
	var result: Dictionary = EquipmentEnhancer.perform_alchemy(base, fodder)
	assert_true(bool(result.get("ok", false)))
	assert_eq(int(base.equip_level), 99)
	assert_eq(int(result.get("gain", 0)), 2)
	assert_eq(GameState.gold, 1000 - 40)


func test_clamp_equip_level_to_member() -> void:
	var item: Resource = _make_weapon(20)
	var member := Adventurer.new()
	member.level = 8
	EquipmentEnhancer.clamp_equip_level_to_member(item, member)
	assert_eq(int(item.equip_level), 8)
