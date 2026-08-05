extends GutTest
## P3-UX-ULTIMATE-EFFECT-001 — 必殺カットイン用効果1行。

const _Helper = preload("res://scripts/ui/SkillEffectOneLineHelper.gd")


func test_job_ultimates_one_line() -> void:
	var cases: Dictionary = {
		"ouga_retsudan": "敵全体に大ダメージ＋脆弱",
		"titan_roar": "味方全体に防御＋挑発",
		"dead_eye": "敵1体に大ダメージ＋標的",
		"grand_elixir": "味方全体を大きく回復＋状態異常解除",
		"beast_dominion": "敵全体に大ダメージ＋標的／鈍化／毒",
	}
	for skill_id in cases.keys():
		var skill: Resource = DataRegistry.get_skill_data(str(skill_id))
		assert_not_null(skill, skill_id)
		assert_eq(_Helper.for_combat_ultimate(skill), str(cases[skill_id]), skill_id)


func test_null_skill_returns_empty() -> void:
	assert_eq(_Helper.for_combat_ultimate(null), "")


func test_damage_without_status() -> void:
	var skill: Resource = DataRegistry.get_skill_data("ultimate_strike")
	assert_not_null(skill)
	assert_eq(_Helper.for_combat_ultimate(skill), "敵1体に大ダメージ")


func test_boss_aoe_one_line() -> void:
	var skill: Resource = DataRegistry.get_skill_data("boss_decree_wave")
	assert_not_null(skill)
	assert_eq(_Helper.for_combat_ultimate(skill), "味方全体に大ダメージ")
