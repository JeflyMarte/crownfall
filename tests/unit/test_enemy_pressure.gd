extends GutTest
## P3-BAL-ENEMY-PRESSURE-001 — 与ダメ+25%／味方DoT厚／回復封じ。

const _Adventurer = preload("res://scripts/domain/Adventurer.gd")


func after_each() -> void:
	GameState.party_members = []


func test_enemy_global_atk_pressure_mult() -> void:
	assert_almost_eq(BalanceConfig.ENEMY_GLOBAL_ATK_MULT, 1.625, 0.001)
	assert_almost_eq(BalanceConfig.ENEMY_DOT_ON_PARTY_MULT, 1.40, 0.001)


func test_heal_block_zeros_received_heal() -> void:
	var member: Resource = _Adventurer.new()
	member.id = "t"
	member.job_id = "vanguard"
	GameState.party_members = [member]
	var cc: CombatController = CombatController.new()
	add_child_autofree(cc)
	var rat: Resource = DataRegistry.get_enemy_data("crown_eater_rat")
	assert_not_null(rat)
	cc.start_combat_group([rat], 1)
	assert_true(cc.party_combat_hp.size() >= 1)
	cc.party_combat_hp[0] = maxi(1, int(cc.party_max_hp[0]) - 200)
	var before: int = int(cc.party_combat_hp[0])
	assert_true(cc.apply_status("party_0", "heal_block", 1, 0))
	var healed: int = cc.heal_member(0, 100)
	assert_eq(healed, 0)
	assert_eq(int(cc.party_combat_hp[0]), before)
	## 吸血経路（apply_received_mult=false）は通す
	var lifesteal: int = cc.heal_member(0, 50, false)
	assert_eq(lifesteal, 50)


func test_blood_leech_has_heal_block_skill() -> void:
	var data: Resource = DataRegistry.get_enemy_data("blood_leech")
	assert_not_null(data)
	assert_true(data.skill_ids.has("enemy_blood_wound"))
	assert_false(data.skill_ids.has("enemy_mire_mend"))
	var skill: Resource = DataRegistry.get_skill_data("enemy_blood_wound")
	assert_not_null(skill)
	assert_eq(str(skill.apply_status_id), "heal_block")
	assert_eq(str(skill.target_type), "party_back")


func test_party_dot_uses_enemy_dot_mult() -> void:
	var resolver: StatusResolver = StatusResolver.new()
	assert_true(resolver.apply_status("party_0", "bleed", 1, 1000))
	var ticks: Array = resolver.tick_unit("party_0")
	assert_gt(ticks.size(), 0)
	## bleed 20%×1000=200 → ×1.40=280
	assert_eq(int(ticks[0].get("damage", 0)), 280)
	## 敵側 DoT は倍率なし
	assert_true(resolver.apply_status("enemy_0", "bleed", 1, 1000))
	var enemy_ticks: Array = resolver.tick_unit("enemy_0")
	assert_eq(int(enemy_ticks[0].get("damage", 0)), 200)
