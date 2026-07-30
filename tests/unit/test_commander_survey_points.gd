extends GutTest
## P3-CMD-001 / P3-CMD-RANK-REWARD-001 — 調査許可等級・調査点（SP）。

const _CommanderSurveyPoints = preload("res://scripts/commander/CommanderSurveyPoints.gd")
const _CommanderProfile = preload("res://scripts/commander/CommanderProfile.gd")
const _CommanderLifetime = preload("res://scripts/commander/CommanderLifetime.gd")
const _CommanderGiftBox = preload("res://scripts/commander/CommanderGiftBox.gd")


func before_each() -> void:
	GameState.discovery_registry = {}
	GameState.stage_progress = {}
	GameState.enemy_codex = {}
	GameState.gold = 0
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
	## C=200 → 敵発見×3 で 67 件以上（201 SP）。
	for i in 66:
		GameState.discovery_registry["enemy:fill_%d" % i] = true
	assert_eq(_CommanderProfile.rank_from_sp_only(), "C")
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


func test_rank_up_pending_and_acknowledge() -> void:
	GameState.commander["acknowledged_rank"] = "D"
	assert_eq(_CommanderProfile.pending_rank_up(), "")
	for i in 70:
		GameState.discovery_registry["enemy:rank_%d" % i] = true
	assert_eq(_CommanderProfile.rank_from_sp_only(), "C")
	assert_eq(_CommanderProfile.pending_rank_up(), "C")
	_CommanderProfile.acknowledge_rank("C")
	assert_eq(_CommanderProfile.get_acknowledged_rank(), "C")
	assert_eq(_CommanderProfile.pending_rank_up(), "")
	assert_eq(_CommanderGiftBox.pending_count(), 1)


func test_missing_acknowledged_rank_bootstraps_to_current() -> void:
	for i in 70:
		GameState.discovery_registry["enemy:boot_%d" % i] = true
	assert_eq(_CommanderProfile.rank_from_sp_only(), "C")
	GameState.commander.erase("acknowledged_rank")
	_CommanderProfile.ensure_commander()
	_CommanderProfile.bootstrap_acknowledged_rank_if_needed()
	assert_eq(_CommanderProfile.get_acknowledged_rank(), "C")
	assert_eq(_CommanderProfile.pending_rank_up(), "")


func test_legacy_curve_migration_floors_rank() -> void:
	## 旧閾値では C（100+）だが新閾値では D 相当の SP。
	for i in 40:
		GameState.discovery_registry["enemy:legacy_%d" % i] = true
	assert_eq(_CommanderSurveyPoints.evaluate(), 120)
	assert_eq(
		_CommanderProfile.rank_for_sp_with(_CommanderProfile.LEGACY_RANK_THRESHOLDS, 120),
		"C"
	)
	assert_eq(_CommanderProfile.rank_from_sp_only(), "D")
	GameState.commander.erase(_CommanderProfile.RANK_CURVE_FLAG)
	GameState.commander["acknowledged_rank"] = "D"
	_CommanderProfile.migrate_rank_curve_v2_if_needed()
	assert_true(bool(GameState.commander.get(_CommanderProfile.RANK_CURVE_FLAG, false)))
	assert_eq(_CommanderProfile.get_acknowledged_rank(), "C")
	assert_eq(_CommanderProfile.current_rank(), "C")
	assert_eq(_CommanderProfile.pending_rank_up(), "")
	assert_eq(_CommanderGiftBox.pending_count(), 0)


func test_title_slot_limits_by_rank() -> void:
	assert_eq(_CommanderProfile.title_slot_limit(), 0)
	for i in 70:
		GameState.discovery_registry["enemy:slot_c_%d" % i] = true
	_CommanderProfile.acknowledge_rank("C", false)
	assert_eq(_CommanderProfile.title_slot_limit(), 1)
	## B=700 → 敵 234 件以上。
	for i in 200:
		GameState.discovery_registry["enemy:slot_b_%d" % i] = true
	_CommanderProfile.acknowledge_rank("B", false)
	assert_eq(_CommanderProfile.title_slot_limit(), 2)
