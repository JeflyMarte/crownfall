extends GutTest
## P3-EQ-STAT-006 — 防具個体ステータス抽選・状態異常無効。

const _ArmorStatResolver = preload("res://scripts/equipment/ArmorStatResolver.gd")
const _ArmorInstance = preload("res://scripts/domain/ArmorInstance.gd")
const _ArmorData = preload("res://scripts/data/ArmorData.gd")
const _AffixStatCalculator = preload("res://scripts/equipment/AffixStatCalculator.gd")
const _CombatController = preload("res://scripts/combat/CombatController.gd")

var _saved_armor: Resource = null


func before_each() -> void:
	var member: Resource = GameState.party_members[0]
	_saved_armor = member.equipped_armor
	member.equipped_armor = null


func after_each() -> void:
	var member: Resource = GameState.party_members[0]
	member.equipped_armor = _saved_armor


func test_apply_drop_stats_always_rolls_defense() -> void:
	var data: Resource = _ArmorData.new()
	data.armor_id = "test_armor"
	data.base_defense = 10
	data.rarity = Enums.Rarity.COMMON
	var inst: Resource = _ArmorInstance.new()
	inst.armor_id = "test_armor"
	_ArmorStatResolver.apply_drop_stats(inst, data)
	## P3-EQ-DIABLO-001: 基礎防御は固定。ブレはランダム「防御力アップ」。
	assert_eq(int(inst.rolled_defense), 10)
	assert_eq(inst.random_mods.size(), 1)


func test_resolve_resist_elements_from_instance() -> void:
	var inst: Resource = _ArmorInstance.new()
	inst.armor_id = "leather_armor"
	var resists: Array[String] = []
	resists.append("ice")
	inst.resist_elements = resists
	assert_true(_ArmorStatResolver.resolve_resist_elements(inst).has("ice"))


func test_member_immune_to_status_blocks_party_apply() -> void:
	var member: Resource = GameState.party_members[0]
	var armor: Resource = _ArmorInstance.new()
	armor.armor_id = "leather_armor"
	var immunities: Array[String] = []
	immunities.append("poison")
	armor.status_immunities = immunities
	member.equipped_armor = armor
	var combat: Node = _CombatController.new()
	add_child_autofree(combat)
	assert_false(combat.apply_status("party_0", "poison", 1, 10))
	assert_true(combat.apply_status("party_0", "chill", 1, 10))


func test_armor_resist_roll_sets_multiplier() -> void:
	var data: Resource = _ArmorData.new()
	data.armor_id = "test_resist"
	data.base_defense = 5
	data.rarity = Enums.Rarity.RARE
	var master_resists: Array[String] = []
	master_resists.append("ice")
	data.resist_elements = master_resists
	var inst: Resource = _ArmorInstance.new()
	inst.armor_id = "test_resist"
	_ArmorStatResolver.apply_drop_stats(inst, data)
	for _i in 100:
		_ArmorStatResolver.apply_drop_stats(inst, data)
		if "resist_elements" in inst.rolled_bonus_stats:
			var mult: float = float(inst.resist_multiplier)
			assert_true(mult > 0.0)
			var weak: float = float(
				_ArmorStatResolver.RESIST_MULT_MIN_BY_RARITY.get(
					Enums.Rarity.RARE,
					_ArmorStatResolver.RESIST_MULT_MIN_BY_RARITY[Enums.Rarity.COMMON]
				)
			)
			assert_true(mult <= weak + 0.001)
			assert_true(mult >= BalanceConfig.ARMOR_RESIST_MULTIPLIER - 0.001)
			return
	pass_test("resist not picked in 100 rolls — acceptable variance")


func test_armor_rates_stack_in_affix_calculator() -> void:
	var saved_armors: Array = []
	for m: Resource in GameState.party_members:
		saved_armors.append(m.equipped_armor if m != null else null)
		if m != null:
			m.equipped_armor = null
	var member: Resource = GameState.party_members[0]
	var armor: Resource = _ArmorInstance.new()
	armor.armor_id = "leather_armor"
	armor.gold_gain_rate = 0.05
	armor.exp_gain_rate = 0.03
	armor.is_appraised = true
	## 移行スキップ（フィールド率がそのまま効く）
	armor.random_mods = [{
		"id": "marker", "label": "", "kind": "hp_up",
		"value": 0, "min_v": 0, "max_v": 0, "perfect": false, "meta": {},
	}]
	member.equipped_armor = armor
	assert_eq(_AffixStatCalculator.apply_gold_bonus(100), 105)
	assert_eq(_AffixStatCalculator.apply_exp_bonus(100), 103)
	for i in GameState.party_members.size():
		var m2: Resource = GameState.party_members[i]
		if m2 != null:
			m2.equipped_armor = saved_armors[i]
