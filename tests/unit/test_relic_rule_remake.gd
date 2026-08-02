extends GutTest
## P3-BAL-RELIC-REMAKE-001 — 差し替え8種の定義・フック補助。


func _equip(relic_id: String) -> Resource:
	var member: Resource = load("res://scripts/domain/Adventurer.gd").new()
	member.id = "relic_remake"
	member.job_id = "swordsman"
	member.rarity = 1
	GameState.owned_relics = [relic_id]
	GameState.party_members = [member]
	GameState.set_member_relic(member, relic_id)
	return member


func after_each() -> void:
	GameState.party_members = []
	GameState.owned_relics = []


func test_eight_relic_display_names() -> void:
	assert_eq(CombatPassives.relic_display_name("relic_war_banner"), "指揮の軍旗")
	assert_eq(CombatPassives.relic_display_name("relic_aegis_shard"), "身代わりの鏡")
	assert_eq(CombatPassives.relic_display_name("relic_old_hourglass"), "連撃の歯車")
	assert_eq(CombatPassives.relic_display_name("relic_berserker_charm"), "生命の脈")
	assert_eq(CombatPassives.relic_display_name("relic_hunter_sigil"), "一騎の契")
	assert_eq(CombatPassives.relic_display_name("relic_reactive_aegis"), "吸血契約")
	assert_eq(CombatPassives.relic_display_name("relic_lament_ring"), "不死鳥の羽")
	assert_eq(CombatPassives.relic_display_name("relic_scout_lens"), "宝箱の羅針")


func test_death_save_heal_and_outgoing_penalty() -> void:
	_equip("relic_lament_ring")
	var cc: CombatController = CombatController.new()
	add_child_autofree(cc)
	cc.party_combat_hp = [10]
	cc.party_max_hp = [100]
	cc.clear_death_save_state()
	cc.apply_damage_to_member(0, 999)
	assert_gt(int(cc.party_combat_hp[0]), 1)
	assert_lte(int(cc.party_combat_hp[0]), 31)
	assert_almost_eq(cc.death_save_outgoing_mult_for(0), 0.75, 0.001)
	## 2回目の致死は耐えない
	cc.party_combat_hp[0] = 5
	cc.apply_damage_to_member(0, 999)
	assert_eq(int(cc.party_combat_hp[0]), 0)


func test_redirect_rear_hit_helper() -> void:
	var front: Resource = load("res://scripts/domain/Adventurer.gd").new()
	front.id = "front"
	front.job_id = "swordsman"
	var back: Resource = load("res://scripts/domain/Adventurer.gd").new()
	back.id = "back"
	back.job_id = "ranger"
	GameState.owned_relics = ["relic_aegis_shard"]
	GameState.party_members = [front, back]
	GameState.set_member_relic(front, "relic_aegis_shard")
	GameState.set_member_formation_slot(front, 0)
	GameState.set_member_formation_row(front, GameState.FORMATION_FRONT)
	GameState.set_member_formation_slot(back, 2)
	GameState.set_member_formation_row(back, GameState.FORMATION_BACK)
	assert_true(GameState.is_member_back_row(1))
	var cc: CombatController = CombatController.new()
	add_child_autofree(cc)
	cc.party_combat_hp = [50, 50]
	cc.party_max_hp = [50, 50]
	seed(1)
	var hit: int = 0
	var redirected: int = 0
	for _i: int in 40:
		var result: Dictionary = cc.try_redirect_rear_hit(1)
		hit += 1
		if bool(result.get("redirected", false)):
			redirected += 1
			assert_eq(int(result.get("target", -1)), 0)
	assert_gt(redirected, 0)
	assert_lt(redirected, hit)


func test_treasure_weight_add_from_party() -> void:
	_equip("relic_scout_lens")
	assert_eq(CombatPassives.party_treasure_room_weight_add(), 20)
