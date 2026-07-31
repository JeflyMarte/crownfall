extends GutTest
## 装備総合力（非表示）とおすすめ比較の SSOT。


const _Power = preload("res://scripts/equipment/EquipmentPower.gd")
const _Helper = preload("res://scripts/equipment/EquipmentRecommendHelper.gd")


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


func _make_armor(armor_id: String, enhance: int, hp: int = 0) -> Resource:
	var inst: Resource = ArmorInstance.new()
	inst.instance_id = "pow_a_%s_%d" % [armor_id, randi() % 100000]
	inst.armor_id = armor_id
	inst.enhance_level = enhance
	inst.is_appraised = true
	inst.hp_bonus = hp
	inst.rolled_defense = 10
	inst.random_mods = [{"kind": "defense_up", "value": 0, "label": "t"}]
	return inst


func test_higher_atk_weapon_scores_higher() -> void:
	var weak: Resource = _make_weapon("iron_sword", 0, 40)
	var strong: Resource = _make_weapon("iron_sword", 0, 200)
	assert_gt(_Power.score(strong, "weapon"), _Power.score(weak, "weapon"))
	assert_gt(_Power.score(weak, "weapon"), 0.0)


func test_enhance_raises_weapon_score() -> void:
	var base: Resource = _make_weapon("iron_sword", 0)
	var enhanced: Resource = _make_weapon("iron_sword", 5)
	assert_gt(_Power.score(enhanced, "weapon"), _Power.score(base, "weapon"))


func test_armor_score_uses_hp_def() -> void:
	var weak: Resource = _make_armor("leather_armor", 0, 0)
	var strong: Resource = _make_armor("leather_armor", 5, 40)
	assert_gt(_Power.score(strong, "armor"), _Power.score(weak, "armor"))


func test_recommend_picks_higher_power() -> void:
	## 総合力が高い方を選ぶ（強化差で順位が付く）。
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
