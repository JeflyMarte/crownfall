extends GutTest
## P3-UX-RESULT-004 — MVP スコア。

const _MvpScore = preload("res://scripts/result/MvpScore.gd")


func test_mvp_prefers_damage_then_heal_weight() -> void:
	var member_a: Resource = GameState.roster[0]
	var member_b: Resource = GameState.roster[1]
	member_a.id = "mvp_a"
	member_a.display_name = "A"
	member_b.id = "mvp_b"
	member_b.display_name = "B"
	var stats: Dictionary = {
		"mvp_a": {"damage_total": 100, "damage_max_hit": 50, "heal_total": 0, "damage_max_skill_name": ""},
		"mvp_b": {"damage_total": 80, "damage_max_hit": 40, "heal_total": 100, "damage_max_skill_name": ""},
	}
	var mvp: Dictionary = _MvpScore.pick_mvp(stats, [member_a, member_b])
	assert_eq(str(mvp.get("member_id", "")), "mvp_b")
