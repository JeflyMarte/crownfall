extends GutTest
## P3-FIX-COMBAT-AUDIT-F-001 — 敵スキルCD個体別／死者状態／オトモレジェンド境界。

const _EnemyData = preload("res://scripts/data/EnemyData.gd")
const _Adventurer = preload("res://scripts/domain/Adventurer.gd")
const _PetSystem = preload("res://scripts/pets/PetSystem.gd")
const _SkillExecutor = preload("res://scripts/combat/SkillExecutor.gd")
const _SkillData = preload("res://scripts/data/SkillData.gd")


func after_each() -> void:
	GameState.party_members = []
	GameState.active_pet = null


func test_enemy_skill_cooldown_keys_are_per_slot() -> void:
	var skill: Resource = _SkillData.new()
	skill.id = "shared_swarm_skill"
	skill.cooldown = 5.0
	skill.effect_type = "buff"
	var exec: RefCounted = _SkillExecutor.new()
	var key0: String = "enemy:0:%s" % skill.id
	var key1: String = "enemy:1:%s" % skill.id
	assert_true(exec.can_cast(skill, key0))
	assert_true(exec.can_cast(skill, key1))
	var res: Dictionary = exec.execute_support_skill(skill, key0)
	assert_true(bool(res.get("executed", false)))
	assert_false(exec.can_cast(skill, key0), "slot 0 should be on cooldown")
	assert_true(exec.can_cast(skill, key1), "slot 1 must not share slot 0 cooldown")


func test_apply_status_rejects_dead_party_member() -> void:
	var a: Resource = _Adventurer.new()
	a.id = "alive"
	a.job_id = "swordsman"
	var b: Resource = _Adventurer.new()
	b.id = "dead"
	b.job_id = "mage"
	GameState.party_members = [a, b]
	var enemy: Resource = _EnemyData.new()
	enemy.id = "status_enemy"
	enemy.max_hp = 50
	enemy.attack = 10
	var cc := CombatController.new()
	add_child_autofree(cc)
	cc.start_combat(enemy, 1)
	cc.party_combat_hp[1] = 0
	assert_false(cc.is_member_alive(1))
	assert_false(cc.apply_status("party_1", "bleed", 1, 10))
	assert_eq(cc.get_member_status_stacks(1, "bleed"), 0)
	assert_true(cc.apply_status("party_0", "bleed", 1, 10))
	assert_eq(cc.get_member_status_stacks(0, "bleed"), 1)


func test_tick_all_statuses_skips_dead_party_members() -> void:
	var a: Resource = _Adventurer.new()
	a.id = "tick_alive"
	a.job_id = "swordsman"
	var b: Resource = _Adventurer.new()
	b.id = "tick_dead"
	b.job_id = "mage"
	GameState.party_members = [a, b]
	var enemy: Resource = _EnemyData.new()
	enemy.id = "tick_enemy"
	enemy.max_hp = 50
	enemy.attack = 10
	var cc := CombatController.new()
	add_child_autofree(cc)
	cc.start_combat(enemy, 1)
	## 付与後に倒す（apply は生存時のみ許可）。
	assert_true(cc.apply_status("party_1", "bleed", 1, 20))
	cc.party_combat_hp[1] = 0
	var results: Array[Dictionary] = cc.tick_all_statuses()
	for result: Dictionary in results:
		assert_false(str(result.get("unit_id", "")).begins_with("party_1"))


func test_party_status_unit_id_suffix_is_index() -> void:
	## "party_" は6文字。substr(7) だと index0 固定になる既往。
	assert_eq(int("party_0".substr(6)), 0)
	assert_eq(int("party_1".substr(6)), 1)
	assert_eq(int("party_10".substr(6)), 10)
	assert_eq(int("party_0".substr(7)), 0, "empty→0 trap")
	assert_ne(int("party_10".substr(7)), 10)


func test_pet_combat_index_is_beyond_party_members_size() -> void:
	## レジェンド走査は party_combat_hp（オトモ含む）を見る必要がある。
	GameState.party_members = [_Adventurer.new()]
	GameState.party_members[0].id = "human0"
	GameState.party_members[0].job_id = "swordsman"
	GameState.active_pet = _PetSystem.create_pet_adventurer(_PetSystem.STARTER_PET_ID)
	var enemy: Resource = _EnemyData.new()
	enemy.id = "pet_legend_enemy"
	enemy.max_hp = 40
	enemy.attack = 5
	var cc := CombatController.new()
	add_child_autofree(cc)
	cc.start_combat(enemy, 1)
	assert_gt(cc.party_combat_hp.size(), GameState.party_members.size())
	var pet_idx: int = GameState.party_members.size()
	assert_true(GameState.is_pet_combatant(pet_idx))
	assert_true(cc.is_member_alive(pet_idx))
	assert_true(cc.apply_status("party_%d" % pet_idx, "empower_pet", 1, 0))
	assert_eq(cc.get_member_status_stacks(pet_idx, "empower_pet"), 1)
