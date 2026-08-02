extends GutTest
## 群れ人数連動ステ＋ソロ速度（P3-BAL-SWARM-DENSITY-001）。


func test_density_table() -> void:
	assert_almost_eq(BalanceConfig.swarm_density_hp_mult(1), 1.35, 0.001)
	assert_almost_eq(BalanceConfig.swarm_density_atk_mult(1), 1.25, 0.001)
	assert_almost_eq(BalanceConfig.swarm_density_spd_mult(1), 1.30, 0.001)
	assert_almost_eq(BalanceConfig.swarm_density_hp_mult(2), 1.0, 0.001)
	assert_almost_eq(BalanceConfig.swarm_density_atk_mult(3), 0.85, 0.001)
	assert_almost_eq(BalanceConfig.swarm_density_hp_mult(4), 0.80, 0.001)


func test_solo_vs_pair_stats() -> void:
	var rat: Resource = DataRegistry.get_enemy_data("crown_eater_rat")
	assert_not_null(rat)
	var solo: CombatController = CombatController.new()
	add_child_autofree(solo)
	solo.start_combat_group([rat], 1, true)
	assert_true(solo.is_swarm_density_solo())
	var solo_hp: int = solo.get_enemy_max_hp_at(0)
	var solo_atk: int = solo.get_enemy_attack_at(0)
	var solo_spd: float = solo.get_enemy_initiative_score_at(0)
	var pair: CombatController = CombatController.new()
	add_child_autofree(pair)
	pair.start_combat_group([rat, rat], 1, true)
	assert_false(pair.is_swarm_density_solo())
	assert_gt(solo_hp, pair.get_enemy_max_hp_at(0))
	assert_gt(solo_atk, pair.get_enemy_attack_at(0))
	assert_gt(solo_spd, pair.get_enemy_initiative_score_at(0))


func test_elite_path_can_skip_density() -> void:
	var rat: Resource = DataRegistry.get_enemy_data("crown_eater_rat")
	var cc: CombatController = CombatController.new()
	add_child_autofree(cc)
	cc.start_combat_group([rat], 1, false)
	assert_false(cc.is_swarm_density_solo())
	assert_eq(cc.swarm_density_count, 0)


func test_summon_keeps_start_density() -> void:
	var rat: Resource = DataRegistry.get_enemy_data("crown_eater_rat")
	var cc: CombatController = CombatController.new()
	add_child_autofree(cc)
	cc.start_combat_group([rat], 1, true)
	var solo_hp: int = cc.get_enemy_max_hp_at(0)
	var added: int = cc.append_enemy_to_swarm(rat, 5)
	assert_eq(added, 1)
	## 召集後もソロ開始倍率のまま（2体基準に落とさない）。
	assert_eq(cc.get_enemy_max_hp_at(1), solo_hp)


func test_solo_kits_aoe() -> void:
	var frog_tongue: Resource = DataRegistry.get_skill_data("enemy_frog_tongue")
	assert_eq(str(frog_tongue.target_type), "party_front")
	var needle: Resource = DataRegistry.get_skill_data("enemy_spore_needle")
	assert_eq(str(needle.target_type), "all_party")
