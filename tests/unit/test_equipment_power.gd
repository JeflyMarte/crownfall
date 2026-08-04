extends GutTest
## 装備総合力（非表示）とおすすめ比較の SSOT（主ステ寄り・案A）。


const _Power = preload("res://scripts/equipment/EquipmentPower.gd")
const _Helper = preload("res://scripts/equipment/EquipmentRecommendHelper.gd")
const _Enh = preload("res://scripts/equipment/EquipmentEnhancer.gd")


func before_each() -> void:
	GameState.seed_all_starters_unlocked()
	GameState.inventory = []
	GameState.armor_inventory = []
	GameState.accessory_inventory = []
	for raw: Variant in GameState.party_members:
		if raw == null:
			continue
		var m: Resource = raw as Resource
		m.equipped_weapon = null
		m.equipped_armor = null
		m.equipped_accessory = null


func _swordsman_index() -> int:
	for i in GameState.party_members.size():
		var m: Resource = GameState.party_members[i]
		if m != null and str(m.job_id) == "swordsman":
			return i
	fail_test("no swordsman")
	return 0


func _make_weapon(weapon_id: String, enhance: int, rolled_attack: int = -1) -> Resource:
	var inst: Resource = WeaponInstance.new()
	inst.instance_id = "pow_w_%s_%d" % [weapon_id, randi() % 100000]
	inst.weapon_id = weapon_id
	inst.enhance_level = enhance
	inst.is_appraised = true
	inst.attack_speed = 1.0
	inst.critical_rate = 0.0
	## マイグレーションをスキップするため空でない mods を置く。
	inst.random_mods = [{"kind": "attack_up", "value": 0, "label": "t"}]
	if rolled_attack >= 0:
		inst.rolled_attack = rolled_attack
	else:
		var data: Resource = DataRegistry.get_weapon_data(weapon_id)
		inst.rolled_attack = int(data.base_attack) if data != null else 0
	return inst


func _make_armor(armor_id: String, enhance: int, hp: int = 0, defense: int = 10) -> Resource:
	var inst: Resource = ArmorInstance.new()
	inst.instance_id = "pow_a_%s_%d" % [armor_id, randi() % 100000]
	inst.armor_id = armor_id
	inst.enhance_level = enhance
	inst.is_appraised = true
	inst.hp_bonus = hp
	inst.rolled_defense = defense
	inst.random_mods = [{"kind": "defense_up", "value": 0, "label": "t"}]
	return inst


func test_higher_atk_weapon_scores_higher() -> void:
	var weak: Resource = _make_weapon("iron_sword", 0, 40)
	var strong: Resource = _make_weapon("iron_sword", 0, 200)
	assert_gt(_Power.score(strong, "weapon"), _Power.score(weak, "weapon"))
	assert_gt(_Power.score(weak, "weapon"), 0.0)


func test_weapon_score_is_effective_attack_not_speed_mult() -> void:
	## 速度・会心で実効攻撃を逆転させない。
	var data: Resource = DataRegistry.get_weapon_data("iron_sword")
	assert_not_null(data)
	var solid: Resource = _make_weapon("iron_sword", 0, int(data.base_attack))
	solid.equip_level = 20
	solid.attack_speed = 0.8
	solid.critical_rate = 0.05
	solid.random_mods = [{"kind": "attack_up", "value": 40, "label": "t", "min_v": 1, "max_v": 40}]
	var glassy: Resource = _make_weapon("iron_sword", 0, int(data.base_attack))
	glassy.equip_level = 5
	glassy.attack_speed = 1.5
	glassy.critical_rate = 0.4
	glassy.critical_damage = 2.0
	glassy.random_mods = [{"kind": "attack_up", "value": 5, "label": "t", "min_v": 1, "max_v": 5}]
	assert_gt(_Power.score(solid, "weapon"), _Power.score(glassy, "weapon"))
	## 主ステ＝実効攻撃。レア加点は別途加算。
	assert_eq(
		_Power.score(solid, "weapon"),
		float(_Enh.get_effective_attack(solid)) + float(_Enh.item_rarity(solid)) * _Power.RARITY_TIER_BONUS
	)


func test_epic_higher_level_outranks_common_with_attack_roll() -> void:
	## オーナー報告: N Lv4 が E Lv9 より優先されるのはおかしい。
	## 同帯剣で COMMON＋攻撃ロールでも EPIC 高Lv を下回ること。
	var common: Resource = _make_weapon("verdant_cleaver", 0, 120)
	common.equip_level = 4
	common.random_mods = [{
		"kind": "attack_up", "value": 22, "label": "t", "min_v": 1, "max_v": 22, "perfect": true,
	}]
	var epic: Resource = _make_weapon("frost_blade", 0, 96)
	epic.equip_level = 9
	epic.random_mods = [{
		"kind": "attack_speed", "value": 0.1, "label": "t", "min_v": 0.01, "max_v": 0.2,
	}]
	assert_eq(_Enh.item_rarity(common), Enums.Rarity.COMMON)
	assert_eq(_Enh.item_rarity(epic), Enums.Rarity.EPIC)
	assert_gt(_Power.score(epic, "weapon"), _Power.score(common, "weapon"))
	var idx: int = _swordsman_index()
	var member: Resource = GameState.party_members[idx]
	GameState.inventory = [common, epic]
	assert_eq(_Helper.pick_best_unequipped(member).get("weapon"), epic)


func test_late_common_can_still_beat_early_epic_on_raw_power() -> void:
	## 終盤 COMMON の高ベースは、序盤 EPIC より強くてよい（レア加点だけでは覆さない）。
	var late_common: Resource = _make_weapon("ridge_cleaver", 0, 352)
	late_common.equip_level = 4
	late_common.random_mods = [{"kind": "attack_up", "value": 0, "label": "t"}]
	var early_epic: Resource = _make_weapon("frost_blade", 0, 96)
	early_epic.equip_level = 9
	early_epic.random_mods = [{"kind": "attack_up", "value": 0, "label": "t"}]
	assert_gt(_Power.score(late_common, "weapon"), _Power.score(early_epic, "weapon"))


func test_enhance_raises_weapon_score() -> void:
	var base: Resource = _make_weapon("iron_sword", 0)
	var enhanced: Resource = _make_weapon("iron_sword", 5)
	assert_gt(_Power.score(enhanced, "weapon"), _Power.score(base, "weapon"))


func test_armor_defense_outranks_hp_roll_alone() -> void:
	## HPロール付き低Lvが、高防御高Lvを逆転しない（HP×0.25）。
	var hp_roll: Resource = _make_armor("leather_armor", 0, 80, 40)
	hp_roll.equip_level = 3
	var def_focus: Resource = _make_armor("leather_armor", 0, 0, 120)
	def_focus.equip_level = 15
	def_focus.random_mods = [{"kind": "defense_up", "value": 40, "label": "t", "min_v": 1, "max_v": 40}]
	assert_gt(_Power.score(def_focus, "armor"), _Power.score(hp_roll, "armor"))


func test_armor_score_uses_weighted_hp_and_def() -> void:
	var weak: Resource = _make_armor("leather_armor", 0, 0)
	var strong: Resource = _make_armor("leather_armor", 5, 40)
	assert_gt(_Power.score(strong, "armor"), _Power.score(weak, "armor"))


func test_recommend_picks_higher_power() -> void:
	var idx: int = _swordsman_index()
	var member: Resource = GameState.party_members[idx]
	var weak: Resource = _make_weapon("iron_sword", 0)
	var strong: Resource = _make_weapon("iron_sword", 5)
	assert_gt(
		_Power.score(strong, "weapon", member),
		_Power.score(weak, "weapon", member)
	)
	GameState.inventory = [weak, strong]
	var picks: Dictionary = _Helper.pick_best_unequipped(member)
	assert_eq(picks.get("weapon"), strong)
	_Helper.apply_for_member(idx)
	assert_eq(member.equipped_weapon, strong)


func test_job_preferred_weapon_gets_boost() -> void:
	var idx: int = _swordsman_index()
	var member: Resource = GameState.party_members[idx]
	var sword: Resource = _make_weapon("iron_sword", 0)
	var with_job: float = _Power.score(sword, "weapon", member)
	var bare: float = _Power.score(sword, "weapon", null)
	assert_gt(with_job, bare)


func test_accessory_score_does_not_double_count_field_mods() -> void:
	## フィールド反映済み mods を sum_kind で再加算しない（P3-FIX-EQ-META-AUDIT-A-001）。
	var acc: Resource = AccessoryInstance.new()
	acc.instance_id = "pow_acc_dbl"
	acc.accessory_id = "silver_ring"
	acc.is_appraised = true
	acc.enhance_level = 0
	acc.equip_level = 1
	acc.attack_bonus = 20
	acc.hp_bonus = 0
	acc.defense_bonus = 0
	acc.crit_rate_bonus = 0.0
	acc.random_mods = [{
		"kind": "attack_up",
		"value": 20,
		"label": "攻撃力アップ",
	}]
	var data: Resource = DataRegistry.get_accessory_data("silver_ring")
	assert_not_null(data)
	var atk: float = float(_Enh.effective_accessory_int_bonus(acc, "attack_bonus", data))
	assert_gt(atk, 0.0)
	var expected: float = atk + float(_Enh.item_rarity(acc)) * _Power.RARITY_TIER_BONUS
	assert_eq(_Power.score(acc, "accessory"), expected)
	assert_lt(_Power.score(acc, "accessory"), atk * 2.0 + float(_Enh.item_rarity(acc)) * _Power.RARITY_TIER_BONUS)


func test_tiebreak_prefers_higher_equip_level_when_score_tied() -> void:
	## 主スコア＋レア加点が同点なら装備Lvの高い方（レア・炉研ぎ同一）。
	var idx: int = _swordsman_index()
	var member: Resource = GameState.party_members[idx]
	var low_lv: Resource = _make_armor("leather_armor", 0, 0, 0)
	low_lv.equip_level = 2
	var high_lv: Resource = _make_armor("leather_armor", 0, 0, 0)
	high_lv.equip_level = 18
	assert_almost_eq(_Power.score(low_lv, "armor"), _Power.score(high_lv, "armor"), 0.0001)
	GameState.armor_inventory = [low_lv, high_lv]
	assert_eq(_Helper.pick_best_unequipped(member).get("armor"), high_lv)
