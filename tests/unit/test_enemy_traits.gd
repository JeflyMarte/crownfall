extends GutTest
## 雑魚パッシブ特性（Decision 118）。

const _CombatEnemyTraits = preload("res://scripts/combat/CombatEnemyTraits.gd")


func test_assignments_cover_catalog_and_main_trash() -> void:
	assert_gt(_CombatEnemyTraits.ASSIGNMENTS.size(), 30)
	for eid: String in _CombatEnemyTraits.ASSIGNMENTS.keys():
		var tid: String = str(_CombatEnemyTraits.ASSIGNMENTS[eid])
		assert_true(_CombatEnemyTraits.DEFS.has(tid), eid)
		var data: Resource = DataRegistry.get_enemy_data(eid)
		assert_not_null(data, eid)
		assert_eq(_CombatEnemyTraits.trait_id_of(data), tid, eid)
		assert_eq(str(data.trait_id), tid, eid)


func test_lifesteal_trait_syncs_ratio() -> void:
	var bloom: Resource = DataRegistry.get_enemy_data("blood_bloom")
	assert_eq(_CombatEnemyTraits.trait_id_of(bloom), _CombatEnemyTraits.TRAIT_LIFESTEAL)
	assert_almost_eq(_CombatEnemyTraits.lifesteal_ratio_of(bloom), 0.3, 0.001)
	var hound: Resource = DataRegistry.get_enemy_data("sepia_hound")
	assert_almost_eq(_CombatEnemyTraits.lifesteal_ratio_of(hound), 0.3, 0.001)


func test_damage_helpers() -> void:
	assert_eq(_CombatEnemyTraits.thorns_damage(100), 25)
	assert_eq(_CombatEnemyTraits.death_nova_damage(100), 35)
	assert_eq(_CombatEnemyTraits.thorns_damage(0), 1)


func test_codex_line() -> void:
	var line: String = _CombatEnemyTraits.codex_line(_CombatEnemyTraits.TRAIT_DOUBLE_TAP)
	assert_true(line.contains("追撃"))
	assert_true(line.contains("二度"))


func test_storm_joe_skill_tax() -> void:
	var data: Resource = DataRegistry.get_enemy_data("storm_joe")
	assert_eq(_CombatEnemyTraits.trait_id_of(data), _CombatEnemyTraits.TRAIT_SKILL_TAX)
