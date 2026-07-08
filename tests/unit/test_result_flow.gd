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
