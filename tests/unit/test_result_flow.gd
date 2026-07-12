extends GutTest
## P3-UX-RESULT-001 — 結果画面ステップ遷移。

const _ResultFlow = preload("res://scripts/result/ResultFlowController.gd")


func test_clear_with_exp_goes_through_levelup() -> void:
	assert_eq(
		_ResultFlow.next_step(_ResultFlow.Step.REWARDS, GameState.RUN_OUTCOME_CLEAR, 100),
		_ResultFlow.Step.LEVELUP
	)
	assert_eq(
		_ResultFlow.next_step(_ResultFlow.Step.LEVELUP, GameState.RUN_OUTCOME_CLEAR, 100),
		_ResultFlow.Step.MVP
	)


func test_wipe_skips_levelup() -> void:
	assert_eq(
		_ResultFlow.next_step(_ResultFlow.Step.REWARDS, GameState.RUN_OUTCOME_WIPE, 100),
		_ResultFlow.Step.MVP
	)


func test_exp_step_title_when_no_level_up() -> void:
	var snapshots: Dictionary = {
		"m1": {"levels_gained": 0, "level_before": 5, "level_after": 5},
	}
	assert_eq(_ResultFlow.exp_step_title(snapshots), "経験値獲得")
	assert_eq(_ResultFlow.exp_step_subtitle(snapshots, 80), "+80 EXP")


func test_exp_step_title_when_level_up() -> void:
	var snapshots: Dictionary = {
		"m1": {"levels_gained": 1, "level_before": 5, "level_after": 6},
		"m2": {"levels_gained": 0, "level_before": 3, "level_after": 3},
	}
	assert_eq(_ResultFlow.exp_step_title(snapshots), "レベルアップ！！")
	assert_eq(_ResultFlow.exp_step_subtitle(snapshots, 120), "")
