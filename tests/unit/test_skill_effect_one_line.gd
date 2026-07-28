extends GutTest
## P3-UX-ULTIMATE-EFFECT-001 — 必殺カットイン用効果1行。

const _Helper = preload("res://scripts/ui/SkillEffectOneLineHelper.gd")


func test_job_ultimates_one_line() -> void:
	var cases: Dictionary = {
		"ouga_retsudan": "敵1体に大ダメージ＋脆弱",
		"titan_roar": "敵1体に大ダメージ＋スタン／恐怖",
		"dead_eye": "敵1体に大ダメージ＋標的",
		"grand_elixir": "味方1体を大きく回復",
		"beast_dominion": "敵1体に大ダメージ＋冷却／毒",
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
