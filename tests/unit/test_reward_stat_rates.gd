extends GutTest
## P3-EQ-STAT-002 — luck 廃止・報酬率3分割のコード移行。

const _AffixStatCalculator = preload("res://scripts/equipment/AffixStatCalculator.gd")
const _DungeonController = preload("res://scripts/dungeon/DungeonController.gd")
const _AccessoryInstance = preload("res://scripts/domain/AccessoryInstance.gd")

var _saved_accessory: Resource = null


func before_each() -> void:
	var member: Resource = GameState.party_members[0]
	_saved_accessory = member.equipped_accessory
	member.equipped_accessory = null


func after_each() -> void:
	var member: Resource = GameState.party_members[0]
	member.equipped_accessory = _saved_accessory


func test_affix_gold_gain() -> void:
	var member: Resource = GameState.party_members[0]
	var acc: Resource = _AccessoryInstance.new()
	acc.accessory_id = "silver_ring"
	acc.is_appraised = true
	var prefixes: Array[String] = []
	prefixes.append("fortune")
	acc.prefix_ids = prefixes
	member.equipped_accessory = acc
	assert_eq(_AffixStatCalculator.apply_gold_bonus(100), 110)


func test_affix_exp_gain_stacks() -> void:
	var member: Resource = GameState.party_members[0]
	var acc: Resource = _AccessoryInstance.new()
	acc.accessory_id = "silver_ring"
	acc.is_appraised = true
	var prefixes: Array[String] = []
	prefixes.append("scholarly")
	acc.prefix_ids = prefixes
	member.equipped_accessory = acc
	assert_eq(_AffixStatCalculator.apply_exp_bonus(100), 110)


func test_accessory_base_and_affix_rare_drop() -> void:
	var member: Resource = GameState.party_members[0]
	var acc: Resource = _AccessoryInstance.new()
	acc.accessory_id = "spore_charm"
	acc.is_appraised = true
	acc.rare_drop_rate = 0.02
	var prefixes: Array[String] = []
	prefixes.append("treasure_hunter")
	acc.prefix_ids = prefixes
	member.equipped_accessory = acc
	var common_w: int = _AffixStatCalculator.apply_rarity_drop_weight(40, Enums.Rarity.COMMON)
	var epic_w: int = _AffixStatCalculator.apply_rarity_drop_weight(5, Enums.Rarity.EPIC)
	assert_eq(common_w, 40, "COMMON は tier0 で補正なし")
	assert_eq(epic_w, 6, "ベース0.02+Affix0.05 で EPIC 重み底上げ")


func test_accumulate_rewards_applies_exp_bonus() -> void:
	var member: Resource = GameState.party_members[0]
	var acc: Resource = _AccessoryInstance.new()
	acc.accessory_id = "silver_ring"
	acc.is_appraised = true
	var prefixes: Array[String] = []
	prefixes.append("scholarly")
	acc.prefix_ids = prefixes
	member.equipped_accessory = acc
	var dc: Node = _DungeonController.new()
	add_child_autofree(dc)
	dc.run_exp_reward = 0
	dc.accumulate_rewards(100, 0)
	assert_eq(dc.run_exp_reward, 110)
