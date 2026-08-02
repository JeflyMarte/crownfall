extends GutTest
## P3-CMD-001 / P3-CMD-RANK-CURVE-003 — 調査許可等級・調査点（SP）。

const _CommanderSurveyPoints = preload("res://scripts/commander/CommanderSurveyPoints.gd")
const _CommanderProfile = preload("res://scripts/commander/CommanderProfile.gd")
const _CommanderLifetime = preload("res://scripts/commander/CommanderLifetime.gd")
const _CommanderGiftBox = preload("res://scripts/commander/CommanderGiftBox.gd")


func before_each() -> void:
	GameState.discovery_registry = {}
	GameState.stage_progress = {}
	GameState.enemy_codex = {}
	GameState.gold = 0
	GameState.gacha_token = 0
	GameState.commander = _CommanderLifetime.default_commander_dict()


func _fill_enemy_discovery_for_sp(target_sp: int) -> void:
	## 敵発見は各 3 SP。
	var need: int = int(ceili(float(target_sp) / 3.0))
	GameState.discovery_registry.clear()
	for i in need:
		GameState.discovery_registry["enemy:fill_%d" % i] = true


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
	## C=400 → 敵発見×3 で 134 件以上。
	_fill_enemy_discovery_for_sp(400)
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
	_fill_enemy_discovery_for_sp(400)
	assert_eq(_CommanderProfile.rank_from_sp_only(), "C")
	assert_eq(_CommanderProfile.pending_rank_up(), "C")
	_CommanderProfile.acknowledge_rank("C")
	assert_eq(_CommanderProfile.get_acknowledged_rank(), "C")
	assert_eq(_CommanderProfile.pending_rank_up(), "")
	assert_eq(_CommanderGiftBox.pending_count(), 1)
	var entry: Dictionary = _CommanderGiftBox.get_pending_entries()[0]
	assert_eq(int(entry.get("gold", 0)), 800)
	assert_eq(int(entry.get("gacha_token", 0)), 10)


func test_missing_acknowledged_rank_bootstraps_to_current() -> void:
	_fill_enemy_discovery_for_sp(400)
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
	GameState.commander.erase(_CommanderProfile.RANK_CURVE_V3_FLAG)
	GameState.commander.erase(_CommanderProfile.RANK_CURVE_V4_FLAG)
	GameState.commander["acknowledged_rank"] = "D"
	_CommanderProfile.migrate_rank_curve_v2_if_needed()
	assert_true(bool(GameState.commander.get(_CommanderProfile.RANK_CURVE_FLAG, false)))
	assert_eq(_CommanderProfile.get_acknowledged_rank(), "C")
	assert_eq(_CommanderProfile.current_rank(), "C")
	assert_eq(_CommanderProfile.pending_rank_up(), "")
	assert_eq(_CommanderGiftBox.pending_count(), 0)


func test_rank_curve_v3_migration_floors_rank() -> void:
	## v2 閾値では C（200+）だが現行では D 相当の SP。
	for i in 80:
		GameState.discovery_registry["enemy:v3_%d" % i] = true
	assert_eq(_CommanderSurveyPoints.evaluate(), 240)
	assert_eq(
		_CommanderProfile.rank_for_sp_with(_CommanderProfile.RANK_THRESHOLDS_V2, 240),
		"C"
	)
	assert_eq(_CommanderProfile.rank_from_sp_only(), "D")
	GameState.commander[_CommanderProfile.RANK_CURVE_FLAG] = true
	GameState.commander.erase(_CommanderProfile.RANK_CURVE_V3_FLAG)
	GameState.commander.erase(_CommanderProfile.RANK_CURVE_V4_FLAG)
	GameState.commander["acknowledged_rank"] = "D"
	_CommanderProfile.migrate_rank_curve_v3_if_needed()
	assert_true(bool(GameState.commander.get(_CommanderProfile.RANK_CURVE_V3_FLAG, false)))
	assert_eq(_CommanderProfile.get_acknowledged_rank(), "C")
	assert_eq(_CommanderProfile.current_rank(), "C")
	assert_eq(_CommanderProfile.pending_rank_up(), "")
	assert_eq(_CommanderGiftBox.pending_count(), 0)


func test_rank_curve_v4_migration_floors_rank() -> void:
	## v3 閾値では C（300+）だが現行（400）では D 相当。
	for i in 100:
		GameState.discovery_registry["enemy:v4_%d" % i] = true
	assert_eq(_CommanderSurveyPoints.evaluate(), 300)
	assert_eq(
		_CommanderProfile.rank_for_sp_with(_CommanderProfile.RANK_THRESHOLDS_V3, 300),
		"C"
	)
	assert_eq(_CommanderProfile.rank_from_sp_only(), "D")
	GameState.commander[_CommanderProfile.RANK_CURVE_FLAG] = true
	GameState.commander[_CommanderProfile.RANK_CURVE_V3_FLAG] = true
	GameState.commander.erase(_CommanderProfile.RANK_CURVE_V4_FLAG)
	GameState.commander["acknowledged_rank"] = "D"
	_CommanderProfile.migrate_rank_curve_v4_if_needed()
	assert_true(bool(GameState.commander.get(_CommanderProfile.RANK_CURVE_V4_FLAG, false)))
	assert_eq(_CommanderProfile.get_acknowledged_rank(), "C")
	assert_eq(_CommanderProfile.current_rank(), "C")
	assert_eq(_CommanderProfile.pending_rank_up(), "")
	assert_eq(_CommanderGiftBox.pending_count(), 0)


func test_title_slot_limits_by_rank() -> void:
	assert_eq(_CommanderProfile.title_slot_limit(), 0)
	_fill_enemy_discovery_for_sp(400)
	_CommanderProfile.acknowledge_rank("C", false)
	assert_eq(_CommanderProfile.title_slot_limit(), 1)
	## B=900
	_fill_enemy_discovery_for_sp(900)
	_CommanderProfile.acknowledge_rank("B", false)
	assert_eq(_CommanderProfile.title_slot_limit(), 2)


func test_pending_rank_gift_gold_sums_unrewarded() -> void:
	GameState.commander["acknowledged_rank"] = "D"
	GameState.commander["rank_reward_ranks"] = []
	assert_eq(_CommanderProfile.pending_rank_gift_gold("C"), 800)
	assert_eq(_CommanderProfile.pending_rank_gift_gold("B"), 2800)
	var summary: String = _CommanderProfile.pending_rank_gift_summary("C")
	assert_true(summary.contains("800"), summary)
	assert_true(summary.contains("10"), summary)
	_CommanderProfile.acknowledge_rank("C")
	assert_eq(_CommanderGiftBox.pending_count(), 1)
	assert_eq(_CommanderProfile.pending_rank_gift_gold("C"), 0)
	assert_eq(_CommanderProfile.pending_rank_gift_gold("B"), 2000)


func test_rank_a_gift_includes_materials() -> void:
	GameState.commander["acknowledged_rank"] = "B"
	GameState.commander["rank_reward_ranks"] = ["C", "B"]
	_fill_enemy_discovery_for_sp(1500)
	_CommanderProfile.acknowledge_rank("A")
	assert_eq(_CommanderGiftBox.pending_count(), 1)
	var entry: Dictionary = _CommanderGiftBox.get_pending_entries()[0]
	assert_eq(int(entry.get("gold", 0)), 4000)
	assert_eq(int(entry.get("gacha_token", 0)), 50)
	var mats: Dictionary = entry.get("materials", {})
	assert_eq(int(mats.get("base_ore", 0)), 20)
	assert_eq(int(mats.get("relic_shard", 0)), 15)
