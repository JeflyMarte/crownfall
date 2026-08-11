extends GutTest

## P3-FORGE-ALCHEMY-001 — 装備錬成

const _WeaponStatResolver = preload("res://scripts/equipment/WeaponStatResolver.gd")


func before_each() -> void:
	GameState.inventory.clear()
	GameState.armor_inventory.clear()
	GameState.accessory_inventory.clear()
	GameState.gold = 10000
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


func test_alchemy_gain_is_quarter_fodder_level_min_1() -> void:
	## P3-BAL-ALCHEMY-GAIN-025-001: floor(素材Lv×0.25)、最低1
	assert_eq(EquipmentEnhancer.alchemy_level_gain(_make_weapon(1)), 1)
	assert_eq(EquipmentEnhancer.alchemy_level_gain(_make_weapon(10)), 2)
	assert_eq(EquipmentEnhancer.alchemy_level_gain(_make_weapon(11)), 2)
	assert_eq(EquipmentEnhancer.alchemy_level_gain(_make_weapon(40)), 10)


func test_perform_alchemy_raises_base_and_removes_fodder() -> void:
	var base: Resource = _make_weapon(12)
	var fodder: Resource = _make_weapon(10)
	var result: Dictionary = EquipmentEnhancer.perform_alchemy(base, fodder)
	assert_true(bool(result.get("ok", false)), str(result))
	assert_eq(int(base.equip_level), 14)
	assert_eq(GameState.inventory.size(), 1)
	assert_true(base in GameState.inventory)
	assert_false(fodder in GameState.inventory)
	## Lv10素材 → +2 / 素材帯×1.5 / 主材Lv12帯×1.5 / ◇×1 → 810G
	assert_eq(GameState.gold, 10000 - 810)


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
	## Lv20素材・主材97 → 素材帯×1.5・主材帯×3 → 2×180×1.5×3=1620G
	assert_eq(GameState.gold, 10000 - 1620)


func test_alchemy_gold_tier_mult() -> void:
	## 第4引数 base_level=1（帯×1.5）固定で素材帯だけ見る
	assert_eq(EquipmentEnhancer.alchemy_gold_cost(5, 10, Enums.Rarity.COMMON, 1), 2025)
	assert_eq(EquipmentEnhancer.alchemy_gold_cost(5, 21, Enums.Rarity.COMMON, 1), 2700)
	assert_eq(EquipmentEnhancer.alchemy_gold_cost(5, 51, Enums.Rarity.COMMON, 1), 4050)


func test_alchemy_gold_scales_with_base_level_tier() -> void:
	## 素材Lv10帯×1.5固定で主材帯を見る
	assert_eq(EquipmentEnhancer.alchemy_gold_cost(5, 10, Enums.Rarity.COMMON, 10), 2025)
	assert_eq(EquipmentEnhancer.alchemy_gold_cost(5, 10, Enums.Rarity.COMMON, 21), 2700)
	assert_eq(EquipmentEnhancer.alchemy_gold_cost(5, 10, Enums.Rarity.COMMON, 51), 4050)
	## Lv98★＋Lv99◇・実上昇1 → 1×180×3×3×3=4860
	assert_eq(
		EquipmentEnhancer.alchemy_gold_cost(1, 99, Enums.Rarity.LEGENDARY, 98),
		4860
	)


func test_alchemy_gold_scales_with_base_rarity() -> void:
	## 主材レアで炉研ぎと同倍率（主材帯は Lv1=×1.5）
	assert_eq(EquipmentEnhancer.alchemy_gold_cost(5, 10, Enums.Rarity.COMMON, 1), 2025)
	assert_eq(EquipmentEnhancer.alchemy_gold_cost(5, 10, Enums.Rarity.RARE, 1), 2532)
	assert_eq(EquipmentEnhancer.alchemy_gold_cost(5, 10, Enums.Rarity.EPIC, 1), 3240)
	assert_eq(EquipmentEnhancer.alchemy_gold_cost(5, 10, Enums.Rarity.LEGENDARY, 1), 6075)


func test_alchemy_allows_equipped_base_but_blocks_equipped_fodder() -> void:
	## 主材は装備中可。素材は装備中不可（一覧非表示と一致）。
	assert_gte(GameState.party_members.size(), 2, "need two party members")
	var member_a: Resource = GameState.party_members[0]
	var member_b: Resource = GameState.party_members[1]
	var base: Resource = _make_weapon(12)
	var fodder: Resource = _make_weapon(10)
	member_a.equipped_weapon = base
	member_b.equipped_weapon = fodder
	var check_equipped_fodder: Dictionary = EquipmentEnhancer.can_alchemy(base, fodder)
	assert_false(bool(check_equipped_fodder.get("ok", false)), "equipped fodder blocked")
	assert_true(str(check_equipped_fodder.get("reason", "")).contains("装備中"))
	member_b.equipped_weapon = null
	var check: Dictionary = EquipmentEnhancer.can_alchemy(base, fodder)
	assert_true(bool(check.get("ok", false)), "unequipped fodder ok: %s" % str(check))
	var result: Dictionary = EquipmentEnhancer.perform_alchemy(base, fodder)
	assert_true(bool(result.get("ok", false)), str(result))
	assert_eq(int(base.equip_level), 14)
	assert_false(fodder in GameState.inventory)
	assert_eq(member_a.equipped_weapon, base, "base stays equipped")


func test_locked_fodder_cannot_alchemy() -> void:
	## P3-UX-EQUIP-LOCK-001: ロック中は錬成素材不可。主材は可。
	var base: Resource = _make_weapon(12)
	var fodder: Resource = _make_weapon(10)
	assert_true(EquipmentEnhancer.set_item_locked(fodder, true))
	var check: Dictionary = EquipmentEnhancer.can_alchemy(base, fodder)
	assert_false(bool(check.get("ok", false)))
	assert_true(str(check.get("reason", "")).contains("ロック"))
	assert_true(EquipmentEnhancer.set_item_locked(base, true))
	assert_true(EquipmentEnhancer.set_item_locked(fodder, false))
	var check2: Dictionary = EquipmentEnhancer.can_alchemy(base, fodder)
	assert_true(bool(check2.get("ok", false)), "locked base may still be alchemy target: %s" % str(check2))


func test_locked_item_cannot_dismantle() -> void:
	var item: Resource = _make_weapon(8)
	assert_true(bool(EquipmentEnhancer.can_dismantle_item(item).get("ok", false)))
	assert_true(EquipmentEnhancer.set_item_locked(item, true))
	var check: Dictionary = EquipmentEnhancer.can_dismantle_item(item)
	assert_false(bool(check.get("ok", false)))
	assert_true(str(check.get("reason", "")).contains("ロック"))
	assert_false(EquipmentEnhancer.list_bulk_dismantle_candidates().has(item))


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
