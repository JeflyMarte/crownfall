extends GutTest
## P3-UX-RESULT-002 — EXP スナップショット。

const _ExpRunSnapshot = preload("res://scripts/result/ExpRunSnapshot.gd")


func test_simulate_multi_level_gain() -> void:
	var member: Resource = GameState.roster[0]
	member.level = 1
	member.exp = 90
	var sim: Dictionary = _ExpRunSnapshot.simulate_member_exp(member, 30)
	assert_eq(int(sim.get("levels_gained", 0)), 1)
	assert_eq(int(sim.get("level_after", 0)), 2)
	assert_eq(int(sim.get("exp_after", 0)), 20)


func test_exp_ratio_clamped() -> void:
	assert_almost_eq(_ExpRunSnapshot.exp_ratio(5, 50), 0.1, 0.001)
