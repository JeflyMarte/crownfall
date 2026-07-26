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


func test_record_detail_stats() -> void:
	var stats: RefCounted = _RunCombatStats.new()
	stats.record_damage("adv_a", 40, "basic", "通常", true)
	stats.record_damage("adv_a", 10, "basic", "通常", false)
	stats.record_kill("adv_a")
	stats.record_kill("adv_a")
	stats.record_damage_taken("adv_a", 15)
	stats.record_ultimate("adv_a")
	var row: Dictionary = stats.snapshot()["adv_a"]
	assert_eq(int(row["crit_count"]), 1)
	assert_eq(int(row["kill_count"]), 2)
	assert_eq(int(row["damage_taken"]), 15)
	assert_eq(int(row["ultimate_count"]), 1)
