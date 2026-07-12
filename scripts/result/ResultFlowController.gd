class_name ResultFlowController
extends RefCounted

## 結果画面ステップ遷移 SSOT（P3-UX-RESULT-001）。

enum Step { REWARDS, LEVELUP, MVP }

const STEP_AUTO_SEC: float = 30.0


static func show_levelup_step(outcome: String, exp_reward: int) -> bool:
	if exp_reward <= 0:
		return false
	if outcome == GameState.RUN_OUTCOME_WIPE:
		return false
	return true


static func total_levels_gained(snapshots: Dictionary) -> int:
	var total: int = 0
	for key in snapshots:
		var snap: Variant = snapshots[key]
		if snap is Dictionary:
			total += int((snap as Dictionary).get("levels_gained", 0))
	return total


static func exp_step_title(snapshots: Dictionary) -> String:
	if total_levels_gained(snapshots) > 0:
		return "レベルアップ！！"
	return "経験値獲得"


static func exp_step_subtitle(snapshots: Dictionary, exp_reward: int) -> String:
	if total_levels_gained(snapshots) > 0:
		return ""
	if exp_reward > 0:
		return "+%d EXP" % exp_reward
	return ""


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
