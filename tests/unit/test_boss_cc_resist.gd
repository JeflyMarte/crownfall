extends GutTest
## P3-BAL-BOSS-CC-RESIST-001 — ボス／EL CC耐性＋SKIP1回抽選。

const _EnemyData = preload("res://scripts/data/EnemyData.gd")
const _Adventurer = preload("res://scripts/domain/Adventurer.gd")
const _StatusResolver = preload("res://scripts/combat/StatusResolver.gd")


func after_each() -> void:
	GameState.party_members = []


func test_skip_uses_max_chance_once() -> void:
	var resolver = _StatusResolver.new()
	assert_true(resolver.apply_status("enemy_0", "fear", 1, 0))
	assert_true(resolver.apply_status("enemy_0", "chill", 1, 0))
	## 恐怖0.5＋冷却0.5 → 最大は0.5（合成75%ではない）
	assert_almost_eq(resolver.best_skip_action_chance("enemy_0"), 0.5, 0.001)


func test_balance_cc_constants() -> void:
	assert_almost_eq(BalanceConfig.CC_SKIP_MULT_BOSS, 0.5, 0.001)
	assert_almost_eq(BalanceConfig.CC_SKIP_MULT_ELITE, 0.75, 0.001)
	assert_eq(BalanceConfig.CC_STUN_DURATION_TICKS_BOSS, 1)


func test_boss_stun_shortened_and_not_guaranteed() -> void:
	var member: Resource = _Adventurer.new()
	member.id = "t"
	member.job_id = "vanguard"
	GameState.party_members = [member]
	var boss: Resource = _EnemyData.new()
	boss.id = "serdion"
	boss.enemy_type = Enums.EnemyType.BOSS
	boss.max_hp = 500
	boss.attack = 10
	var cc := CombatController.new()
	add_child_autofree(cc)
	cc.start_combat(boss, 1)
	assert_eq(cc.enemy_cc_tier_at(0), "boss")
	assert_almost_eq(cc.enemy_cc_skip_mult_at(0), 0.5, 0.001)
	assert_true(cc.apply_status_to_enemy_slot(0, "stun", 1, 0))
	var list: Array = cc.get_enemy_status_list_at(0)
	assert_eq(list.size(), 1)
	assert_eq(int(list[0].get("remaining_ticks", -1)), 1)
	## 実効 skip = 1.0 * 0.5 → 保証スキップではない
	assert_false(cc.peek_enemy_status_skip_at(0))


func test_elite_skip_mult() -> void:
	var member: Resource = _Adventurer.new()
	member.id = "t2"
	member.job_id = "swordsman"
	GameState.party_members = [member]
	var elite: Resource = _EnemyData.new()
	elite.id = "elite_probe"
	elite.enemy_type = Enums.EnemyType.ELITE
	elite.max_hp = 200
	elite.attack = 8
	var cc := CombatController.new()
	add_child_autofree(cc)
	cc.start_combat(elite, 1)
	assert_eq(cc.enemy_cc_tier_at(0), "elite")
	assert_almost_eq(cc.enemy_cc_skip_mult_at(0), 0.75, 0.001)
	assert_true(cc.apply_status_to_enemy_slot(0, "stun", 1, 0))
	var list: Array = cc.get_enemy_status_list_at(0)
	assert_eq(int(list[0].get("remaining_ticks", -1)), 2)
	assert_false(cc.peek_enemy_status_skip_at(0))


func test_normal_stun_still_guaranteed() -> void:
	var member: Resource = _Adventurer.new()
	member.id = "t3"
	member.job_id = "swordsman"
	GameState.party_members = [member]
	var normal: Resource = _EnemyData.new()
	normal.id = "fodder"
	normal.enemy_type = Enums.EnemyType.NORMAL
	normal.max_hp = 80
	normal.attack = 5
	var cc := CombatController.new()
	add_child_autofree(cc)
	cc.start_combat(normal, 1)
	assert_true(cc.apply_status_to_enemy_slot(0, "stun", 1, 0))
	assert_true(cc.peek_enemy_status_skip_at(0))
	var list: Array = cc.get_enemy_status_list_at(0)
	assert_eq(int(list[0].get("remaining_ticks", -1)), 2)
