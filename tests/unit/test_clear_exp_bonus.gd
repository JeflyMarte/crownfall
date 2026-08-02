extends GutTest
## P3-BAL-CLEAR-EXP-001 — CLEAR 時のみ獲得 EXP +25%。


const _DungeonController = preload("res://scripts/dungeon/DungeonController.gd")


func test_clear_exp_bonus_ratio_constant() -> void:
	assert_almost_eq(BalanceConfig.CLEAR_EXP_BONUS_RATIO, 0.25, 0.0001)


func test_apply_clear_exp_bonus_adds_quarter() -> void:
	var dc: Node = _DungeonController.new()
	add_child_autofree(dc)
	dc.run_exp_reward = 100
	dc.run_exp_by_member = {"a": 100, "b": 80}
	var bonus: int = dc.apply_clear_exp_bonus()
	assert_eq(bonus, 25)
	assert_eq(dc.run_exp_reward, 125)
	assert_eq(int(dc.run_exp_by_member["a"]), 125)
	assert_eq(int(dc.run_exp_by_member["b"]), 100)


func test_apply_clear_exp_bonus_zero_when_no_exp() -> void:
	var dc: Node = _DungeonController.new()
	add_child_autofree(dc)
	dc.run_exp_reward = 0
	dc.run_exp_by_member = {}
	assert_eq(dc.apply_clear_exp_bonus(), 0)
	assert_eq(dc.run_exp_reward, 0)
