extends GutTest
## P3-FIX-COMBAT-AUDIT-G-001 — 詠唱 off-by-one／パッシブ撃破打ち切り／ペット発火境界。

const _EnemyData = preload("res://scripts/data/EnemyData.gd")
const _Adventurer = preload("res://scripts/domain/Adventurer.gd")
const _PetSystem = preload("res://scripts/pets/PetSystem.gd")


func after_each() -> void:
	GameState.party_members = []
	GameState.active_pet = null


func test_cast_time_one_resolves_on_next_advance() -> void:
	## P3-D112-1: ceil(cast_time)=1 → 開始後の次の自分番で ready。
	var member: Resource = _Adventurer.new()
	member.id = "caster"
	member.job_id = "mage"
	GameState.party_members = [member]
	var enemy: Resource = _EnemyData.new()
	enemy.id = "cast_probe"
	enemy.max_hp = 50
	enemy.attack = 5
	var cc := CombatController.new()
	add_child_autofree(cc)
	cc.start_combat(enemy, 1)
	cc.begin_party_cast(0, "ultimate_strike", 0, 1)
	assert_eq(cc.advance_pending_cast("party", 0), "ready")
	cc.begin_enemy_cast(0, "boss_decree_wave", 1)
	assert_eq(cc.advance_pending_cast("enemy", 0), "ready")


func test_cast_time_two_chants_once_then_ready() -> void:
	var member: Resource = _Adventurer.new()
	member.id = "long_caster"
	member.job_id = "mage"
	GameState.party_members = [member]
	var enemy: Resource = _EnemyData.new()
	enemy.id = "cast2"
	enemy.max_hp = 50
	enemy.attack = 5
	var cc := CombatController.new()
	add_child_autofree(cc)
	cc.start_combat(enemy, 1)
	cc.begin_party_cast(0, "ultimate_strike", 0, 2)
	assert_eq(cc.advance_pending_cast("party", 0), "chant")
	assert_eq(cc.advance_pending_cast("party", 0), "ready")


func test_combat_start_loop_covers_pet_index() -> void:
	GameState.party_members = [_Adventurer.new()]
	GameState.party_members[0].id = "h0"
	GameState.party_members[0].job_id = "swordsman"
	GameState.active_pet = _PetSystem.create_pet_adventurer(_PetSystem.STARTER_PET_ID)
	var enemy: Resource = _EnemyData.new()
	enemy.id = "pet_start"
	enemy.max_hp = 40
	enemy.attack = 5
	var cc := CombatController.new()
	add_child_autofree(cc)
	cc.start_combat(enemy, 1)
	assert_gt(cc.party_combat_hp.size(), GameState.party_members.size())
	var pet_idx: int = GameState.party_members.size()
	assert_true(GameState.is_pet_combatant(pet_idx))
	assert_true(cc.is_member_alive(pet_idx))
