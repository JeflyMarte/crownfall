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
	## Lv10素材 → +5 / 帯×1.0 → 300G（P3-BAL-FORGE-GOLD-HEAVY-001）
	assert_eq(GameState.gold, 1000 - 300)


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
	## Lv20素材 → 帯×1.0 → 2×60=120G（P3-BAL-FORGE-GOLD-HEAVY-001）
	assert_eq(GameState.gold, 1000 - 120)


func test_alchemy_gold_tier_mult() -> void:
	assert_eq(EquipmentEnhancer.alchemy_gold_cost(5, 10), 300)
	assert_eq(EquipmentEnhancer.alchemy_gold_cost(5, 21), 450)
	assert_eq(EquipmentEnhancer.alchemy_gold_cost(5, 51), 600)


func test_alchemy_allows_equipped_base_and_unequips_fodder() -> void:
	## P3-FORGE-ALCHEMY-001-5b: 装備中も錬成可。素材は外れて消滅。
	assert_gte(GameState.party_members.size(), 2, "need two party members")
	var member_a: Resource = GameState.party_members[0]
	var member_b: Resource = GameState.party_members[1]
	var base: Resource = _make_weapon(12)
	var fodder: Resource = _make_weapon(10)
	member_a.equipped_weapon = base
	member_b.equipped_weapon = fodder
	var check: Dictionary = EquipmentEnhancer.can_alchemy(base, fodder)
	assert_true(bool(check.get("ok", false)), "equipped base+fodder should be allowed: %s" % str(check))
	assert_true(EquipmentEnhancer.alchemy_needs_confirm(fodder))
	var result: Dictionary = EquipmentEnhancer.perform_alchemy(base, fodder)
	assert_true(bool(result.get("ok", false)), str(result))
	assert_eq(int(base.equip_level), 17)
	assert_eq(member_b.equipped_weapon, null, "fodder must be unequipped before remove")
	assert_false(fodder in GameState.inventory)
	assert_eq(member_a.equipped_weapon, base, "base stays equipped")


func test_equip_preserves_level_above_member() -> void:
	## 装着時に装備LvをキャラLvへ永続クリップしない（P3-EQ-LVL-001-4 は EXP 上限のみ）。
	var member := Adventurer.new()
	member.level = 19
	member.job_id = "swordsman"
	var low: Resource = _make_weapon(19)
	var high: Resource = _make_weapon(35)
	var ctrl: Node = load("res://scripts/equipment/EquipmentController.gd").new()
	add_child_autofree(ctrl)
	ctrl.equip_weapon_for_member(low, member)
	assert_eq(int(low.equip_level), 19)
	ctrl.equip_weapon_for_member(high, member)
	assert_eq(member.equipped_weapon, high)
	assert_eq(int(high.equip_level), 35, "高Lv武器を低Lvキャラに装備しても保存Lvは下がらない")
