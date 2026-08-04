extends GutTest

## P3-LV-099 — プレイヤーレベル上限99・マスタリーティア逓減成長。

func test_soft_cap_hp_bonus_unchanged() -> void:
	assert_eq(LevelSystem.level_hp_bonus(50), 49 * BalanceConfig.HP_PER_LEVEL)
	assert_eq(LevelSystem.level_attack_bonus(50), 49 * BalanceConfig.ATTACK_PER_LEVEL)
	assert_eq(LevelSystem.level_defense_bonus(50), 49 * BalanceConfig.DEFENSE_PER_LEVEL)

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
		LevelSystem.level_defense_bonus(51),
		49 * BalanceConfig.DEFENSE_PER_LEVEL + BalanceConfig.DEFENSE_PER_LEVEL_MASTER
	)
	assert_eq(
		LevelSystem.level_hp_bonus(99),
		49 * BalanceConfig.HP_PER_LEVEL + 49 * BalanceConfig.HP_PER_LEVEL_MASTER
	)
	assert_eq(
		LevelSystem.level_attack_bonus(99),
		49 * BalanceConfig.ATTACK_PER_LEVEL + 49 * BalanceConfig.ATTACK_PER_LEVEL_MASTER
	)
	assert_eq(
		LevelSystem.level_defense_bonus(99),
		49 * BalanceConfig.DEFENSE_PER_LEVEL + 49 * BalanceConfig.DEFENSE_PER_LEVEL_MASTER
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
	assert_eq(ids.size(), 7, "Lv50習得7（P3-SKILL-KIT-001）")

func test_skill_ids_unlocked_between_levels() -> void:
	var member: Resource = GameState.roster[0]
	## P3-SKILL-KIT-001: 解放 Lv=1/8/15/22/30/40/50
	var at_8: Array[String] = SkillProgression.skill_ids_unlocked_between(member, 7, 8)
	assert_eq(at_8.size(), 1, "Lv8ちょうどで1本")
	var none: Array[String] = SkillProgression.skill_ids_unlocked_between(member, 8, 8)
	assert_eq(none.size(), 0)
	var span: Array[String] = SkillProgression.skill_ids_unlocked_between(member, 1, 15)
	assert_eq(span.size(), 2, "Lv8とLv15の2本（Lv1は before に含まれるため除外）")
	## 経験値画面は複数習得時に最後の1本だけ表示する（P3-UX-SKILL-LEARN-PERSIST-001）。
	assert_eq(span[span.size() - 1], span[1], "最後＝Lv15解放")
	var at_level: Array[String] = SkillProgression.skill_ids_unlocked_at_level(member, 15)
	assert_eq(at_level.size(), 1)
	assert_eq(at_level[0], span[span.size() - 1])
