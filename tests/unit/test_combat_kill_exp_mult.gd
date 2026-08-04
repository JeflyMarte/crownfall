extends GutTest
## P3-BAL-KILL-EXP-150-001 — 撃破 EXP ×1.5（クリアボーナスは積立経由で連動）。


const _DungeonController = preload("res://scripts/dungeon/DungeonController.gd")


func test_combat_kill_exp_mult_constant() -> void:
	assert_almost_eq(BalanceConfig.COMBAT_KILL_EXP_MULT, 1.5, 0.0001)


func test_clear_bonus_scales_with_kill_pool() -> void:
	## 撃破プールが 1.5 倍ならクリア +25% の絶対量も 1.5 倍。
	var dc: Node = _DungeonController.new()
	add_child_autofree(dc)
	dc.run_exp_reward = 150  ## 旧100 ×1.5
	dc.run_exp_by_member = {"a": 150}
	var bonus: int = dc.apply_clear_exp_bonus()
	assert_eq(bonus, 38)  ## round(150 * 0.25)
	assert_eq(dc.run_exp_reward, 188)
	assert_eq(int(dc.run_exp_by_member["a"]), 188)
