extends GutTest

## おすすめ装備 — 未装備かつ装備可能な最強を装備。

const _Helper := preload("res://scripts/equipment/EquipmentRecommendHelper.gd")


func before_each() -> void:
	GameState.seed_all_starters_unlocked()
	GameState.inventory = []
	GameState.armor_inventory = []
	GameState.accessory_inventory = []
	for m: Resource in GameState.party_members:
		if m == null:
			continue
		m.equipped_weapon = null
		m.equipped_armor = null
		m.equipped_accessory = null


func _swordsman_index() -> int:
	for i in GameState.party_members.size():
		var m: Resource = GameState.party_members[i]
		if m != null and str(m.job_id) == "swordsman":
			return i
	return 0


func _make_weapon(weapon_id: String, enhance: int) -> Resource:
	var inst: Resource = WeaponInstance.new()
	inst.instance_id = "rec_w_%s_%d" % [weapon_id, randi() % 100000]
	inst.weapon_id = weapon_id
	inst.is_appraised = true
	inst.enhance_level = enhance
	inst.attack_speed = 1.0
	inst.critical_rate = 0.0
	## マイグレーションをスキップするため空でない mods を置く。
	inst.random_mods = [{"kind": "attack_up", "value": 0, "label": "t"}]
	return inst


func _make_armor(armor_id: String, enhance: int, hp: int = 0) -> Resource:
	var inst: Resource = ArmorInstance.new()
	inst.instance_id = "rec_a_%s_%d" % [armor_id, randi() % 100000]
	inst.armor_id = armor_id
	inst.is_appraised = true
	inst.enhance_level = enhance
	inst.hp_bonus = hp
	inst.random_mods = [{"kind": "defense_up", "value": 0, "label": "t"}]
	return inst


func test_picks_strongest_unequipped_weapon() -> void:
	var idx: int = _swordsman_index()
	var member: Resource = GameState.party_members[idx]
	var weak: Resource = _make_weapon("iron_sword", 0)
	var strong: Resource = _make_weapon("iron_sword", 5)
	var mid: Resource = _make_weapon("iron_sword", 2)
	GameState.inventory = [weak, strong, mid]
	var picks: Dictionary = _Helper.pick_best_unequipped(member)
	assert_eq(picks.get("weapon"), strong)
	var result: Dictionary = _Helper.apply_for_member(idx)
	assert_true(bool(result.get("changed", false)), str(result))
	assert_eq(member.equipped_weapon, strong)


func test_skips_equipped_by_others() -> void:
	var idx: int = _swordsman_index()
	var member: Resource = GameState.party_members[idx]
	var other_idx: int = (idx + 1) % GameState.party_members.size()
	var other: Resource = GameState.party_members[other_idx]
	var owned_strong: Resource = _make_weapon("iron_sword", 5)
	var free_weak: Resource = _make_weapon("iron_sword", 1)
	GameState.inventory = [owned_strong, free_weak]
	other.equipped_weapon = owned_strong
	var picks: Dictionary = _Helper.pick_best_unequipped(member)
	assert_eq(picks.get("weapon"), free_weak, "他人装備は候補外")
	_Helper.apply_for_member(idx)
	assert_eq(member.equipped_weapon, free_weak)
	assert_eq(other.equipped_weapon, owned_strong, "他人の装備は奪わない")


func test_skips_job_incompatible_weapon() -> void:
	var idx: int = _swordsman_index()
	var member: Resource = GameState.party_members[idx]
	## 剣士は弓不可（preferred 外）。
	var bow: Resource = _make_weapon("hunting_bow", 5)
	var sword: Resource = _make_weapon("iron_sword", 1)
	GameState.inventory = [bow, sword]
	var picks: Dictionary = _Helper.pick_best_unequipped(member)
	assert_eq(picks.get("weapon"), sword)


func test_keeps_current_if_already_best() -> void:
	var idx: int = _swordsman_index()
	var member: Resource = GameState.party_members[idx]
	var current: Resource = _make_weapon("iron_sword", 5)
	var weaker: Resource = _make_weapon("iron_sword", 0)
	GameState.inventory = [current, weaker]
	member.equipped_weapon = current
	var result: Dictionary = _Helper.apply_for_member(idx)
	assert_false(bool(result.get("changed", true)), str(result))
	assert_eq(member.equipped_weapon, current)


func test_equips_stronger_armor() -> void:
	var idx: int = _swordsman_index()
	var member: Resource = GameState.party_members[idx]
	var weak: Resource = _make_armor("leather_armor", 0, 0)
	var strong: Resource = _make_armor("leather_armor", 5, 40)
	GameState.armor_inventory = [weak, strong]
	_Helper.apply_for_member(idx)
	assert_eq(member.equipped_armor, strong)
