extends GutTest

## P3-BAL-OPENING-001 — 敵グローバル倍率・オトモ人数補正。


func test_enemy_global_mult_constants() -> void:
	assert_almost_eq(BalanceConfig.ENEMY_GLOBAL_HP_MULT, 1.50, 0.001)
	assert_almost_eq(BalanceConfig.ENEMY_GLOBAL_ATK_MULT, 1.30, 0.001)


func test_party_size_balance_includes_pet_slot() -> void:
	## combatant_count=5（人間4+オトモ）想定の倍率。
	var hp_4: float = 1.0 + (4.0 / 3.0 - 1.0) * BalanceConfig.PARTY_BALANCE_HP_SHARE
	var hp_5: float = 1.0 + (5.0 / 3.0 - 1.0) * BalanceConfig.PARTY_BALANCE_HP_SHARE
	assert_gt(hp_5, hp_4)
	assert_almost_eq(hp_5, 1.0 + (2.0 / 3.0) * BalanceConfig.PARTY_BALANCE_HP_SHARE, 0.001)
