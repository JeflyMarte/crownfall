extends GutTest

## P3-BAL-COMBAT-ATTRITION-001: 怒涛倍率と硬殻バースト技能値。


func test_attrition_grace_is_neutral() -> void:
	assert_eq(BalanceConfig.attrition_step(0.0), 0)
	assert_eq(BalanceConfig.attrition_step(BalanceConfig.ATTRITION_GRACE_CT), 0)
	assert_almost_eq(BalanceConfig.attrition_outgoing_mult(0.0), 1.0, 0.001)
	assert_almost_eq(
		BalanceConfig.attrition_outgoing_mult(BalanceConfig.ATTRITION_GRACE_CT), 1.0, 0.001
	)


func test_attrition_steps_and_cap() -> void:
	var grace: float = BalanceConfig.ATTRITION_GRACE_CT
	var step_ct: float = BalanceConfig.ATTRITION_STEP_CT
	assert_eq(BalanceConfig.attrition_step(grace + 0.01), 1)
	assert_almost_eq(
		BalanceConfig.attrition_outgoing_mult(grace + 0.01),
		1.0 + BalanceConfig.ATTRITION_MULT_PER_STEP,
		0.001
	)
	assert_eq(BalanceConfig.attrition_step(grace + step_ct), 2)
	assert_almost_eq(
		BalanceConfig.attrition_outgoing_mult(grace + step_ct),
		1.0 + BalanceConfig.ATTRITION_MULT_PER_STEP * 2.0,
		0.001
	)
	assert_almost_eq(
		BalanceConfig.attrition_outgoing_mult(999.0),
		1.0 + BalanceConfig.ATTRITION_MULT_CAP,
		0.001
	)


func test_hard_shell_burst_skills() -> void:
	var bash: Resource = load("res://resources/skills/enemy_skull_bash.tres")
	assert_not_null(bash)
	assert_gt(float(bash.power_multiplier), 1.5)
	assert_gte(float(bash.cooldown), 7.5)
	var crush: Resource = load("res://resources/skills/enemy_hull_crush.tres")
	assert_not_null(crush)
	assert_gt(float(crush.power_multiplier), 1.5)
	assert_gte(float(crush.cooldown), 8.0)
