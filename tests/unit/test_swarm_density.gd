extends GutTest
## 群れ人数連動ステ＋ソロ速度／回避（P3-BAL-SWARM-DENSITY-001）。


func test_density_table() -> void:
	assert_almost_eq(BalanceConfig.swarm_density_hp_mult(1), 1.35, 0.001)
	assert_almost_eq(BalanceConfig.swarm_density_atk_mult(1), 1.25, 0.001)
	assert_almost_eq(BalanceConfig.swarm_density_spd_mult(1), 1.50, 0.001)
	assert_almost_eq(BalanceConfig.SOLO_EVASION_MULT, 0.5, 0.001)
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
	## 護衛付きエリート等は呼び出し側が false を渡す想定。
	var rat: Resource = DataRegistry.get_enemy_data("crown_eater_rat")
	var cc: CombatController = CombatController.new()
	add_child_autofree(cc)
	cc.start_combat_group([rat], 1, false)
	assert_false(cc.is_swarm_density_solo())
	assert_eq(cc.swarm_density_count, 0)


func test_elite_solo_applies_density_when_flagged() -> void:
	## DungeonScene は ELITE かつ group.size()==1 のとき true を渡す。
	var moth: Resource = DataRegistry.get_enemy_data("clock_moth")
	assert_not_null(moth)
	var cc: CombatController = CombatController.new()
	add_child_autofree(cc)
	cc.start_combat_group([moth], 1, true)
	assert_true(cc.is_swarm_density_solo())
	assert_almost_eq(
		cc.get_enemy_initiative_score_at(0),
		float(moth.attack_speed) * BalanceConfig.SWARM_DENSITY_SOLO_SPD,
		0.001
	)


func test_solo_halves_evasion_roll() -> void:
	## 基礎回避 → ソロ倍率後。中間ロールなら非ソロ回避／ソロ命中。
	GameState.seed_all_starters_unlocked()
	var member: Resource = GameState.party_members[0]
	var saved_armor: Resource = member.equipped_armor
	var saved_acc: Resource = member.equipped_accessory
	var armor: Resource = preload("res://scripts/domain/ArmorInstance.gd").new()
	armor.armor_id = "leather_armor"
	armor.evasion_rate = 0.40
	member.equipped_armor = armor
	member.equipped_accessory = null
	var base_rate: float = DamageCalculator.member_evasion_rate(0)
	assert_gte(base_rate, 0.40)
	var solo_rate: float = base_rate * BalanceConfig.SOLO_EVASION_MULT
	var roll_mid: float = (solo_rate + base_rate) * 0.5
	assert_true(DamageCalculator.roll_member_evasion(0, _FixedRng.new(roll_mid), 1.0))
	assert_false(
		DamageCalculator.roll_member_evasion(0, _FixedRng.new(roll_mid), BalanceConfig.SOLO_EVASION_MULT)
	)
	var rat: Resource = DataRegistry.get_enemy_data("crown_eater_rat")
	var solo: CombatController = CombatController.new()
	add_child_autofree(solo)
	solo.start_combat_group([rat], 1, true)
	assert_true(solo.is_swarm_density_solo())
	var pair: CombatController = CombatController.new()
	add_child_autofree(pair)
	pair.start_combat_group([rat, rat], 1, true)
	assert_false(pair.is_swarm_density_solo())
	## enemy_damage_to_member はソロ時 SOLO_EVASION_MULT を渡す（上の roll と同値）。
	member.equipped_armor = saved_armor
	member.equipped_accessory = saved_acc


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


class _FixedRng extends RefCounted:
	var _v: float = 0.0

	func _init(v: float = 0.0) -> void:
		_v = v

	func randf() -> float:
		return _v
