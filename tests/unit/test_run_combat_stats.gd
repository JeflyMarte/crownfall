extends GutTest
## P3-UX-RESULT-003 — ラン戦闘統計。

const _RunCombatStats = preload("res://scripts/result/RunCombatStats.gd")


func test_record_damage_tracks_max_hit_skill() -> void:
	var stats: RefCounted = _RunCombatStats.new()
	stats.record_damage("adv_a", 100, "skill_a", "スキルA")
	stats.record_damage("adv_a", 250, "skill_b", "スキルB")
	var snap: Dictionary = stats.snapshot()
	assert_eq(int(snap["adv_a"]["damage_total"]), 350)
	assert_eq(int(snap["adv_a"]["damage_max_hit"]), 250)
	assert_eq(str(snap["adv_a"]["damage_max_skill_name"]), "スキルB")
