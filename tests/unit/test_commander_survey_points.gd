extends GutTest
## P3-CMD-001 — 調査許可等級・調査点（SP）。

const _CommanderSurveyPoints = preload("res://scripts/commander/CommanderSurveyPoints.gd")
const _CommanderProfile = preload("res://scripts/commander/CommanderProfile.gd")
const _CommanderLifetime = preload("res://scripts/commander/CommanderLifetime.gd")


func before_each() -> void:
	GameState.discovery_registry = {}
	GameState.stage_progress = {}
	GameState.enemy_codex = {}
	GameState.commander = _CommanderLifetime.default_commander_dict()


func test_discovery_weights_sum() -> void:
	GameState.discovery_registry = {
		"enemy:slime": true,
		"lore:HE-001": true,
	}
	assert_eq(_CommanderSurveyPoints.evaluate(), 11)


func test_stage_clear_and_boss_bonus() -> void:
	var stage: Resource = DataRegistry.get_stage_by_chapter(Constants.MOURNGATE_DUNGEON_ID, 5)
	assert_not_null(stage)
	GameState.mark_stage_cleared(str(stage.id), 0)
	var sp: int = _CommanderSurveyPoints.evaluate()
	assert_true(sp >= 50, "Boss章は通常20+ボーナス30以上")


func test_rank_progression_thresholds() -> void:
	GameState.discovery_registry["enemy:a"] = true
	assert_eq(_CommanderProfile.current_rank(), "D")
	for i in 34:
		GameState.discovery_registry["enemy:fill_%d" % i] = true
	assert_eq(_CommanderProfile.current_rank(), "C")


func test_profile_viewable_at_rank_d() -> void:
	assert_eq(_CommanderProfile.current_rank(), "D")
	assert_true(_CommanderProfile.is_profile_unlocked())
	assert_true(_CommanderProfile.can_edit_name())
	assert_true(_CommanderProfile.set_commander_name("テスト隊長"))
	assert_eq(_CommanderProfile.get_commander_name(), "テスト隊長")


func test_lifetime_run_points() -> void:
	var lifetime: Dictionary = _CommanderProfile.get_lifetime()
	lifetime["runs_cleared"] = 2
	lifetime["runs_retired"] = 1
	GameState.commander["lifetime"] = lifetime
	assert_eq(_CommanderSurveyPoints.evaluate(), 5)
