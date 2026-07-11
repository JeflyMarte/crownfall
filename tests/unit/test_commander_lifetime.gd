extends GutTest
## P3-CMD-002 — 指揮官通算統計。

const _RunCombatStats = preload("res://scripts/result/RunCombatStats.gd")
const _CommanderLifetime = preload("res://scripts/commander/CommanderLifetime.gd")
const _CommanderProfile = preload("res://scripts/commander/CommanderProfile.gd")
const _CommanderTitles = preload("res://scripts/commander/CommanderTitles.gd")


func before_each() -> void:
	GameState.commander = _CommanderLifetime.default_commander_dict()
	GameState.party_members = []


func after_each() -> void:
	GameState._init_party()


func test_record_run_finished_tracks_max_hit() -> void:
	var stats: RefCounted = _RunCombatStats.new()
	stats.record_damage("adv_a", 900, "skill_a", "スキルA")
	stats.record_damage("adv_a", 1200, "skill_b", "スキルB")
	_CommanderLifetime.record_run_finished(
		GameState.RUN_OUTCOME_CLEAR,
		stats.snapshot(),
		{"dungeon_id": Constants.MOURNGATE_DUNGEON_ID, "stage_id": ""}
	)
	var lifetime: Dictionary = _CommanderProfile.get_lifetime()
	assert_eq(int(lifetime.get("damage_max_hit", 0)), 1200)
	assert_eq(str(lifetime.get("damage_max_hit_skill_name", "")), "スキルB")
	assert_eq(int(lifetime.get("runs_cleared", 0)), 1)


func test_title_first_clear_unlocks() -> void:
	_CommanderLifetime.record_run_finished(GameState.RUN_OUTCOME_CLEAR, {}, {})
	_CommanderTitles.refresh_unlocks()
	assert_true("title_first_clear" in _CommanderProfile.get_unlocked_titles())
