extends GutTest

## P3-UX-BOSS-SUMMON-LAYOUT-001 — ボス呼び出し連れの配置


func test_first_add_is_left_and_forward_of_boss() -> void:
	var boss := Vector2(0.688, 0.34)
	var r0: Vector2 = BossSummonLayout.position_ratio(boss, 0)
	assert_lt(r0.x, boss.x)
	assert_gt(r0.y, boss.y)


func test_second_add_is_right_and_forward_of_boss() -> void:
	var boss := Vector2(0.688, 0.34)
	var r1: Vector2 = BossSummonLayout.position_ratio(boss, 1)
	assert_gt(r1.x, boss.x)
	assert_gt(r1.y, boss.y)


func test_add_z_is_above_boss() -> void:
	assert_gt(BossSummonLayout.add_z_index(0), BossSummonLayout.BOSS_Z)
	assert_gte(BossSummonLayout.add_z_index(2), BossSummonLayout.add_z_index(0))


func test_boss_lead_detects_enemy_type() -> void:
	var boss: Resource = DataRegistry.get_enemy_data("moldgar")
	assert_not_null(boss)
	assert_true(BossSummonLayout.is_boss_lead_enemy(boss))
	var fodder: Resource = DataRegistry.get_enemy_data("marsh_king")
	assert_not_null(fodder)
	assert_false(BossSummonLayout.is_boss_lead_enemy(fodder))
