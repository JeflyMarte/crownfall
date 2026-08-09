extends GutTest

## P3-UX-BOSS-SUMMON-LAYOUT-001 — ボス呼び出し連れの配置


func test_first_add_is_left_and_forward_of_boss() -> void:
	var boss := Vector2(0.688, 0.34)
	var r0: Vector2 = BossSummonLayout.position_ratio(boss, 0)
	assert_lt(r0.x, boss.x)
	assert_gt(r0.y, boss.y)
	assert_almost_eq(r0.x, boss.x - BossSummonLayout.X_OFF_BASE, 0.001)
	assert_almost_eq(r0.y, boss.y + BossSummonLayout.Y_OFF_BASE, 0.001)


func test_second_add_is_right_and_forward_of_boss() -> void:
	var boss := Vector2(0.688, 0.34)
	var r1: Vector2 = BossSummonLayout.position_ratio(boss, 1)
	assert_gt(r1.x, boss.x)
	assert_gt(r1.y, boss.y)


func test_dual_anchor_keeps_both_sides_off_boss_body() -> void:
	## ネレイオン／クロノス／大宇宙ガモ: 2体召喚時はボス左寄せで左右とも余白。
	var base := Vector2(0.688, 0.34)
	var dual: Vector2 = BossSummonLayout.layout_boss_ratio(base, 2)
	assert_lt(dual.x, base.x)
	assert_almost_eq(dual.x, BossSummonLayout.BOSS_ANCHOR_DUAL_X, 0.001)
	var left: Vector2 = BossSummonLayout.position_ratio(dual, 0)
	var right: Vector2 = BossSummonLayout.position_ratio(dual, 1)
	assert_lt(left.x, dual.x - 0.20)
	assert_gt(right.x, dual.x + 0.20)
	## 旧ソロ錨のまま右連れすると X_MAX に張り付き胴へ戻る。
	var clamped_right: Vector2 = BossSummonLayout.position_ratio(base, 1)
	assert_lt(clamped_right.x - base.x, right.x - dual.x + 0.001)


func test_solo_anchor_unchanged() -> void:
	var base := Vector2(0.688, 0.34)
	assert_eq(BossSummonLayout.layout_boss_ratio(base, 0), base)
	assert_eq(BossSummonLayout.layout_boss_ratio(base, 1), base)


func test_wider_offsets_than_initial_layout() -> void:
	## 胴体／ネーム重なり対策で 0.17/0.12 より広いこと。
	assert_gt(BossSummonLayout.X_OFF_BASE, 0.17)
	assert_gt(BossSummonLayout.Y_OFF_BASE, 0.12)
	assert_gte(BossSummonLayout.OVERLAY_OUTWARD_PX, 24.0)
	assert_gte(BossSummonLayout.OVERLAY_EXTRA_GAP_Y, 16.0)


func test_overlay_nudge_pushes_outward() -> void:
	var n0: Vector2 = BossSummonLayout.overlay_nudge_px(0)
	var n1: Vector2 = BossSummonLayout.overlay_nudge_px(1)
	assert_lt(n0.x, 0.0)
	assert_gt(n1.x, 0.0)
	assert_gt(n0.y, 0.0)
	assert_eq(n0.y, n1.y)
	var dual: Vector2 = BossSummonLayout.overlay_nudge_px(0, 2)
	assert_gt(absf(dual.x), absf(n0.x))


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
