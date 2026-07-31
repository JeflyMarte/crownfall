extends GutTest
## P3-FIX-COMBAT-AUDIT-E-001 — 敵クリティカル／ブロックフラグ／ボス weight 整合。

const _EnemyData = preload("res://scripts/data/EnemyData.gd")
const _Adventurer = preload("res://scripts/domain/Adventurer.gd")
const _WeaponInstance = preload("res://scripts/domain/WeaponInstance.gd")


func after_each() -> void:
	GameState.party_members = []
	GameState.active_pet = null


func test_enemy_critical_rate_applies_balance_multiplier() -> void:
	var member: Resource = _Adventurer.new()
	member.id = "crit_probe"
	member.job_id = "swordsman"
	GameState.party_members = [member]
	var enemy: Resource = _EnemyData.new()
	enemy.id = "crit_enemy"
	enemy.max_hp = 100
	enemy.attack = 100
	enemy.critical_rate = 1.0
	var cc := CombatController.new()
	add_child_autofree(cc)
	cc.start_combat(enemy, 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var hit: Dictionary = DamageCalculator.enemy_damage_to_member(cc, 0, 1.0, 100, 0, rng)
	assert_true(bool(hit.get("is_critical", false)))
	assert_false(bool(hit.get("missed", false)))
	## base は防御前。クリティカルで CRITICAL_MULTIPLIER 倍。
	assert_eq(int(hit.get("base", 0)), int(round(100.0 * BalanceConfig.CRITICAL_MULTIPLIER)))

	enemy.critical_rate = 0.0
	cc.start_combat(enemy, 1)
	rng.seed = 1
	var normal: Dictionary = DamageCalculator.enemy_damage_to_member(cc, 0, 1.0, 100, 0, rng)
	assert_false(bool(normal.get("is_critical", false)))
	assert_eq(int(normal.get("base", 0)), 100)


func test_incoming_block_sets_blocked_flag() -> void:
	var member: Resource = _Adventurer.new()
	member.id = "block_probe"
	member.job_id = "vanguard"
	var weapon: Resource = _WeaponInstance.new()
	weapon.weapon_id = "silvaria_oathblade"
	member.equipped_weapon = weapon
	GameState.party_members = [member]
	var enemy: Resource = _EnemyData.new()
	enemy.id = "block_enemy"
	enemy.max_hp = 100
	enemy.attack = 100
	enemy.critical_rate = 0.0
	var cc := CombatController.new()
	add_child_autofree(cc)
	cc.start_combat(enemy, 1)
	## block_chance=0.20 — 十分小さい seed で block を当てる
	var blocked_once: bool = false
	for seed_i: int in 200:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_i
		var result: Dictionary = DamageCalculator.enemy_damage_to_member(cc, 0, 1.0, 100, 0, rng)
		if bool(result.get("blocked", false)):
			blocked_once = true
			assert_false(bool(result.get("missed", false)))
			assert_gt(int(result.get("final", 0)), 0)
			break
	assert_true(blocked_once, "silvaria block should trigger within 200 seeds")


func test_boss_phase_skill_weights_subset_of_enemy_skill_ids() -> void:
	for boss_id: String in CombatBossPhases.boss_ids():
		var enemy: Resource = DataRegistry.get_enemy_data(boss_id)
		assert_not_null(enemy, boss_id)
		var skill_set: Dictionary = {}
		for sid in enemy.skill_ids:
			skill_set[str(sid)] = true
		for phase_i: int in range(CombatBossPhases.phase_count(boss_id)):
			var weights: Dictionary = CombatBossPhases.phase_def(boss_id, phase_i).get("skill_weight", {})
			for key: String in weights.keys():
				assert_true(
					skill_set.has(str(key)),
					"%s phase%d weight key '%s' missing from enemy.skill_ids" % [boss_id, phase_i, key]
				)
