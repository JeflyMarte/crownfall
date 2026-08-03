extends GutTest
## P3-FIX-COMBAT-AUDIT-D-001 — 敵詠唱スロット／ペット境界／列AoE。

const _PetSystem = preload("res://scripts/pets/PetSystem.gd")


func after_each() -> void:
	GameState.party_members = []
	GameState.active_pet = null


func test_column_aoe_empty_row_falls_back_intentionally() -> void:
	## P3-D106d-2: 空列は反対列へ。配線バグではなく仕様。
	GameState.party_members = [
		_human("h0", GameState.FORMATION_FRONT),
		_human("h1", GameState.FORMATION_BACK),
	]
	var alive := func(i: int) -> bool: return true
	var front: Dictionary = CombatFormation.resolve_column_members_with_fallback(
		CombatFormation.TARGET_PARTY_FRONT, 2, alive
	)
	assert_eq((front["indices"] as Array).size(), 1)
	assert_eq(int((front["indices"] as Array)[0]), 0)
	assert_false(bool(front.get("fallback", true)))

	## 前列全滅扱いで後列のみ → front 指定は fallback で後列へ
	var only_back_alive := func(i: int) -> bool: return i == 1
	var fb: Dictionary = CombatFormation.resolve_column_members_with_fallback(
		CombatFormation.TARGET_PARTY_FRONT, 2, only_back_alive
	)
	assert_true(bool(fb.get("fallback", false)))
	assert_eq(int((fb["indices"] as Array)[0]), 1)


func test_pet_is_always_front_row_in_column_sets() -> void:
	GameState.party_members = [_human("h0", GameState.FORMATION_BACK)]
	GameState.active_pet = _PetSystem.create_pet_adventurer(_PetSystem.STARTER_PET_ID)
	assert_false(GameState.is_member_back_row(1), "pet combatant index is always front")
	var alive := func(i: int) -> bool: return true
	var front: Dictionary = CombatFormation.resolve_column_members_with_fallback(
		CombatFormation.TARGET_PARTY_FRONT, 2, alive
	)
	var idxs: Array = front["indices"] as Array
	assert_true(1 in idxs, "pet included in party_front")
	var back: Dictionary = CombatFormation.resolve_column_members_with_fallback(
		CombatFormation.TARGET_PARTY_BACK, 2, alive
	)
	assert_false(1 in (back["indices"] as Array), "pet not in party_back unless fallback")


func test_heal_party_includes_pet_combatant_slot() -> void:
	## 部屋回復と同型: party_combat_hp にペットを含む。
	GameState.party_members = [_human("h0", GameState.FORMATION_FRONT)]
	GameState.active_pet = _PetSystem.create_pet_adventurer(_PetSystem.STARTER_PET_ID)
	var cc := CombatController.new()
	add_child_autofree(cc)
	cc.party_combat_hp = [50, 40]
	cc.party_max_hp = [100, 100]
	assert_eq(cc.party_combat_hp.size(), 2)
	cc.heal_party(10)
	assert_eq(cc.party_combat_hp[0], 60)
	assert_eq(cc.party_combat_hp[1], 50)


func test_threat_shares_sum_to_one_for_multi_target() -> void:
	var shares: Dictionary = CombatFormation.threat_damage_shares(
		[0, 1, 2],
		func(i: int) -> float: return float((i + 1) * 10)
	)
	var sum: float = 0.0
	for k in shares.keys():
		sum += float(shares[k])
	assert_almost_eq(sum, 1.0, 0.001)


func _human(id: String, row: int) -> Resource:
	var adv: Resource = load("res://scripts/domain/Adventurer.gd").new()
	adv.id = id
	adv.job_id = "swordsman"
	adv.formation_row = row
	return adv
