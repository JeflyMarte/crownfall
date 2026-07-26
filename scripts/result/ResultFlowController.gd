class_name ResultFlowController
extends RefCounted

## 結果画面ステップ遷移 SSOT（P3-UX-RESULT-001）。

enum Step { REWARDS, LEVELUP, MVP }

const STEP_AUTO_SEC: float = 30.0


static func show_levelup_step(outcome: String, exp_reward: int) -> bool:
	## クリア／リタイア／全滅いずれも、獲得EXPがあればレベルアップ表示＋付与。
	if exp_reward <= 0:
		return false
	return true


static func next_step(current: Step, outcome: String, exp_reward: int) -> Step:
	match current:
		Step.REWARDS:
			if show_levelup_step(outcome, exp_reward):
				return Step.LEVELUP
			return Step.MVP
		Step.LEVELUP:
			return Step.MVP
		_:
			return Step.MVP
