extends GutTest

## P3-LV-099 — プレイヤーレベル上限99・マスタリーティア逓減成長。

func test_soft_cap_hp_bonus_unchanged() -> void:
	assert_eq(LevelSystem.level_hp_bonus(50), 49 * BalanceConfig.HP_PER_LEVEL)
	assert_eq(LevelSystem.level_attack_bonus(50), 49 * BalanceConfig.ATTACK_PER_LEVEL)

func test_master_tier_adds_diminished_growth() -> void:
	assert_eq(
		LevelSystem.level_hp_bonus(51),
		49 * BalanceConfig.HP_PER_LEVEL + BalanceConfig.HP_PER_LEVEL_MASTER
	)
	assert_eq(
		LevelSystem.level_attack_bonus(51),
		49 * BalanceConfig.ATTACK_PER_LEVEL + BalanceConfig.ATTACK_PER_LEVEL_MASTER
	)
	assert_eq(
		LevelSystem.level_hp_bonus(99),
		49 * BalanceConfig.HP_PER_LEVEL + 49 * BalanceConfig.HP_PER_LEVEL_MASTER
	)
	assert_eq(
		LevelSystem.level_attack_bonus(99),
		49 * BalanceConfig.ATTACK_PER_LEVEL + 49 * BalanceConfig.ATTACK_PER_LEVEL_MASTER
	)

func test_grant_exp_caps_at_99() -> void:
	var member: Resource = GameState.roster[0]
	member.level = 98
	member.exp = 0
	var gained: int = LevelSystem.grant_exp(member, 999999)
	assert_eq(gained, 1)
	assert_eq(int(member.level), 99)
	assert_eq(int(member.exp), 0)

func test_skill_unlocks_still_cap_at_job_data() -> void:
	var member: Resource = GameState.roster[0]
	member.level = 99
	var ids: Array[String] = SkillProgression.get_unlocked_job_skill_ids(member)
	assert_eq(ids.size(), 10, "Lv50習得10のまま")
