extends GutTest
## P3-EQ-STAT-007 — レア度別ランダムステータス数・パーフェクトロール⭐️。

const _EquipmentRollHelper = preload("res://scripts/equipment/EquipmentRollHelper.gd")
const _EquipmentDisplayNames = preload("res://scripts/equipment/EquipmentDisplayNames.gd")
const _ArmorStatResolver = preload("res://scripts/equipment/ArmorStatResolver.gd")
const _ArmorInstance = preload("res://scripts/domain/ArmorInstance.gd")
const _ArmorData = preload("res://scripts/data/ArmorData.gd")

func test_random_stat_count_by_rarity() -> void:
	assert_eq(_EquipmentRollHelper.random_stat_count(Enums.Rarity.COMMON), 1)
	assert_eq(_EquipmentRollHelper.random_stat_count(Enums.Rarity.RARE), 2)
	assert_eq(_EquipmentRollHelper.random_stat_count(Enums.Rarity.EPIC), 3)
	assert_eq(_EquipmentRollHelper.random_stat_count(Enums.Rarity.LEGENDARY), 4)

func test_pick_random_stats_unique() -> void:
	var pool: Array[String] = ["a", "b", "c", "d", "e", "f"]
	var picked: Array[String] = _EquipmentRollHelper.pick_random_stats(pool, 3)
	assert_eq(picked.size(), 3)
	var seen: Dictionary = {}
	for id in picked:
		assert_false(seen.has(id))
		seen[id] = true

func test_armor_drop_assigns_rarity_stat_count() -> void:
	var data: Resource = _ArmorData.new()
	data.armor_id = "test_epic"
	data.base_defense = 8
	data.rarity = Enums.Rarity.EPIC
	var inst: Resource = _ArmorInstance.new()
	inst.armor_id = "test_epic"
	_ArmorStatResolver.apply_drop_stats(inst, data)
	assert_eq(inst.rolled_bonus_stats.size(), 3)

func test_perfect_roll_suffix_on_display_name() -> void:
	var inst: Resource = _ArmorInstance.new()
	inst.armor_id = "leather_armor"
	inst.perfect_roll_count = 3
	var name: String = _EquipmentDisplayNames.get_instance_name(inst, "armor")
	assert_true(name.ends_with("⭐️⭐️⭐️"))

func test_roll_int_bonus_perfect_at_max() -> void:
	var perfect_hits: int = 0
	for _i in 1000:
		var roll: Dictionary = _EquipmentRollHelper.roll_int_bonus(4)
		if bool(roll.get("perfect", false)):
			perfect_hits += 1
			assert_eq(int(roll.get("value", -1)), 4)
	assert_gt(perfect_hits, 0)
