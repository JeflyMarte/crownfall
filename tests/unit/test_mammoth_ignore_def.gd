extends GutTest
## 氷晶マンモス防御無視全体（P3-BAL-MAMMOTH-IGNORE-DEF-001）。

const _Adventurer = preload("res://scripts/domain/Adventurer.gd")
const _ArmorInstance = preload("res://scripts/domain/ArmorInstance.gd")
const _EnemyData = preload("res://scripts/data/EnemyData.gd")
const _Stats = preload("res://scripts/domain/Stats.gd")


func after_each() -> void:
	GameState.party_members = []
	GameState.active_pet = null


func test_crystal_trampling_skill() -> void:
	var sk: Resource = DataRegistry.get_skill_data("enemy_crystal_trampling")
	assert_not_null(sk)
	assert_eq(str(sk.effect_type), "damage")
	assert_eq(str(sk.target_type), "all_party")
	assert_true(bool(sk.ignore_defense))
	assert_almost_eq(float(sk.cast_time), 1.0, 0.001)
	assert_gt(float(sk.power_multiplier), 1.2)
	var enm: Resource = DataRegistry.get_enemy_data("glacier_warden")
	assert_true(enm.skill_ids.has("enemy_crystal_trampling"))
	assert_eq(int(enm.enemy_type), 1)
	assert_gt(float(enm.skill_use_chance), 0.3)
	assert_gt(float(enm.skill_weights.get("enemy_crystal_trampling", 0.0)), 2.0)


func test_ignore_defense_bypasses_armor_mitigation() -> void:
	var member: Resource = _Adventurer.new()
	member.id = "def_probe"
	member.job_id = "vanguard"
	member.level = 1
	var stats: Resource = _Stats.new()
	stats.defense = 40
	member.base_stats = stats
	var armor: Resource = _ArmorInstance.new()
	armor.armor_id = "leather_armor"
	armor.rolled_defense = 120
	member.equipped_armor = armor
	GameState.party_members = [member]
	var enemy: Resource = _EnemyData.new()
	enemy.id = "ignore_probe"
	enemy.max_hp = 100
	enemy.attack = 100
	enemy.critical_rate = 0.0
	var cc := CombatController.new()
	add_child_autofree(cc)
	cc.start_combat(enemy, 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var normal: Dictionary = DamageCalculator.enemy_damage_to_member(
		cc, 0, 1.0, 100, 0, rng, "", false
	)
	rng.seed = 42
	var pierced: Dictionary = DamageCalculator.enemy_damage_to_member(
		cc, 0, 1.0, 100, 0, rng, "", true
	)
	assert_false(bool(normal.get("missed", false)))
	assert_false(bool(pierced.get("missed", false)))
	assert_eq(int(normal.get("base", 0)), 100)
	assert_eq(int(pierced.get("base", 0)), 100)
	assert_gt(int(pierced.get("final", 0)), int(normal.get("final", 0)))
	assert_lt(int(pierced.get("mitigated", 0)), int(normal.get("mitigated", 0)))
