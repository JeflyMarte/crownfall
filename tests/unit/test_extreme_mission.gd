extends GutTest

## P3-DG-EXTREME-001 — 極限任務 Phase 1（EX-01 王墓封鎖）

const _ExtremeMissionConfig := preload("res://scripts/dungeon/ExtremeMissionConfig.gd")
const _DungeonTierConfig := preload("res://scripts/dungeon/DungeonTierConfig.gd")
const _EventDungeonSchedule := preload("res://scripts/dungeon/EventDungeonSchedule.gd")


func before_each() -> void:
	GameState.debug_full_unlock = false
	GameState.dungeon_progress.clear()
	GameState.stage_progress.clear()
	GameState.dungeon_tier_cleared.clear()
	GameState.extreme_mission_progress.clear()
	GameState.extreme_run_ko_count = 0
	GameState.extreme_run_heal_skill_used = false
	GameState.extreme_run_start_msec = 0
	GameState.last_run_extreme_mission_id = ""
	GameState.last_run_extreme_stars = 0
	GameState.last_run_extreme_orders = {}
	GameState.last_run_extreme_best_stars = 0
	GameState.last_run_extreme_new_record = false


func _clear_all_main_normal() -> void:
	for biome_id: String in _DungeonTierConfig.MAIN_BIOME_IDS:
		GameState.mark_dungeon_cleared(biome_id)
		GameState.mark_dungeon_tier_cleared(biome_id, _DungeonTierConfig.TIER_NORMAL)


func test_ex01_dungeon_data() -> void:
	var data: Resource = DataRegistry.get_dungeon_data(Constants.EX_TOMB_SEAL_DUNGEON_ID)
	assert_not_null(data)
	assert_eq(str(data.route_type), "extreme")
	assert_eq(int(data.floor_count), 5)
	assert_eq(str(data.boss_id), "serdion")
	assert_true(bool(data.disable_wandering))
	assert_eq(int(data.daily_attempt_limit), 0)
	assert_eq(str(data.unlock_after_dungeon_id), "frostridge")
	assert_true(Constants.is_extreme_mission_playable(Constants.EX_TOMB_SEAL_DUNGEON_ID))
	assert_true(Constants.is_playable_dungeon(Constants.EX_TOMB_SEAL_DUNGEON_ID, "extreme"))


func test_ex01_stage_boss() -> void:
	var stage: Resource = DataRegistry.get_stage_data("ex_tomb_seal_1_1")
	assert_not_null(stage)
	assert_eq(str(stage.biome_id), "ex_tomb_seal")
	assert_eq(int(stage.floor_count), 5)
	assert_eq(str(stage.closing_type), "boss")
	assert_eq(str(stage.boss_id), "serdion")
	assert_true(bool(stage.requires_elite))


func test_unlock_requires_main5_normal() -> void:
	assert_false(GameState.is_dungeon_unlocked(Constants.EX_TOMB_SEAL_DUNGEON_ID))
	GameState.mark_dungeon_cleared("mourngate")
	assert_false(GameState.is_dungeon_unlocked(Constants.EX_TOMB_SEAL_DUNGEON_ID))
	_clear_all_main_normal()
	assert_true(_ExtremeMissionConfig.is_content_unlocked())
	assert_true(GameState.is_dungeon_unlocked(Constants.EX_TOMB_SEAL_DUNGEON_ID))


func test_always_open_schedule() -> void:
	assert_true(_EventDungeonSchedule.is_open_now(Constants.EX_TOMB_SEAL_DUNGEON_ID))
	assert_eq(_EventDungeonSchedule.open_schedule_label(Constants.EX_TOMB_SEAL_DUNGEON_ID), "極限・常設")


func test_heal_mult_only_on_extreme_run() -> void:
	GameState.current_dungeon_id = "mourngate"
	assert_eq(_ExtremeMissionConfig.heal_effectiveness_mult_for_active_run(), 1.0)
	GameState.current_dungeon_id = Constants.EX_TOMB_SEAL_DUNGEON_ID
	assert_eq(
		_ExtremeMissionConfig.heal_effectiveness_mult_for_active_run(),
		float(_ExtremeMissionConfig.TUNING["heal_effectiveness_mult"])
	)


func test_star_evaluation_and_orders() -> void:
	GameState.current_dungeon_id = Constants.EX_TOMB_SEAL_DUNGEON_ID
	GameState.begin_extreme_run_tracking(Constants.EX_TOMB_SEAL_DUNGEON_ID)
	## 全指令達成想定
	GameState.extreme_run_ko_count = 0
	GameState.extreme_run_heal_skill_used = false
	GameState.extreme_run_elapsed_sec = 10.0
	var orders: Dictionary = _ExtremeMissionConfig.evaluate_orders_for_run(
		Constants.EX_TOMB_SEAL_DUNGEON_ID
	)
	assert_true(bool(orders.get("no_ko", false)))
	assert_true(bool(orders.get("time_limit", false)))
	assert_true(bool(orders.get("no_heal_skill", false)))
	assert_eq(_ExtremeMissionConfig.stars_for_clear(orders), 4)

	GameState.extreme_run_ko_count = 1
	GameState.note_extreme_heal_skill_used()
	orders = _ExtremeMissionConfig.evaluate_orders_for_run(Constants.EX_TOMB_SEAL_DUNGEON_ID)
	assert_false(bool(orders.get("no_ko", true)))
	assert_false(bool(orders.get("no_heal_skill", true)))
	assert_eq(_ExtremeMissionConfig.stars_for_clear(orders), 2)


func test_time_order_uses_accumulated_not_wall_clock() -> void:
	GameState.current_dungeon_id = Constants.EX_TOMB_SEAL_DUNGEON_ID
	GameState.begin_extreme_run_tracking(Constants.EX_TOMB_SEAL_DUNGEON_ID)
	## 壁時計を大きく進めても、積算が小さければ時間指令は達成。
	GameState.extreme_run_start_msec = Time.get_ticks_msec() - 900_000
	GameState.extreme_run_elapsed_sec = 30.0
	var orders: Dictionary = _ExtremeMissionConfig.evaluate_orders_for_run(
		Constants.EX_TOMB_SEAL_DUNGEON_ID
	)
	assert_true(bool(orders.get("time_limit", false)))
	GameState.extreme_run_elapsed_sec = float(_ExtremeMissionConfig.order_time_limit_sec()) + 1.0
	orders = _ExtremeMissionConfig.evaluate_orders_for_run(Constants.EX_TOMB_SEAL_DUNGEON_ID)
	assert_false(bool(orders.get("time_limit", true)))


func test_pause_excluded_from_elapsed_accumulation() -> void:
	GameState.current_dungeon_id = Constants.EX_TOMB_SEAL_DUNGEON_ID
	GameState.begin_extreme_run_tracking(Constants.EX_TOMB_SEAL_DUNGEON_ID)
	GameState.add_extreme_run_elapsed(5.0)
	assert_eq(GameState.extreme_run_elapsed_sec, 5.0)
	## 非極限では積算しない
	GameState.current_dungeon_id = "mourngate"
	GameState.add_extreme_run_elapsed(10.0)
	assert_eq(GameState.extreme_run_elapsed_sec, 5.0)


func test_heal_mult_applies_even_when_received_mult_false() -> void:
	## 吸血等の apply_received_mult=false でも極限低下は掛かること。
	GameState.current_dungeon_id = Constants.EX_TOMB_SEAL_DUNGEON_ID
	var cc: CombatController = CombatController.new()
	add_child_autofree(cc)
	cc.party_combat_hp = [100]
	cc.party_max_hp = [200]
	var healed: int = cc.heal_member(0, 100, false)
	var expected: int = int(round(100.0 * float(_ExtremeMissionConfig.TUNING["heal_effectiveness_mult"])))
	assert_eq(healed, expected)
	## 通常DGでは低下なし
	GameState.current_dungeon_id = "mourngate"
	cc.party_combat_hp = [100]
	healed = cc.heal_member(0, 100, false)
	assert_eq(healed, 100)


func test_vertical_slice_unlock_select_clear_save() -> void:
	## 解放→CLEAR→★保存→再挑戦可能のロジック縦切り（UI除く）。
	var mid: String = Constants.EX_TOMB_SEAL_DUNGEON_ID
	assert_false(GameState.is_dungeon_unlocked(mid))
	_clear_all_main_normal()
	assert_true(GameState.is_dungeon_unlocked(mid))
	assert_true(_EventDungeonSchedule.is_open_now(mid))
	var stage: Resource = DataRegistry.get_stage_data("ex_tomb_seal_1_1")
	assert_not_null(stage)
	assert_eq(str(stage.boss_id), "serdion")
	assert_eq(int(stage.floor_count), 5)
	GameState.current_dungeon_id = mid
	GameState.begin_extreme_run_tracking(mid)
	GameState.extreme_run_elapsed_sec = 120.0
	_ExtremeMissionConfig.commit_clear_result(mid)
	assert_true(GameState.is_extreme_mission_cleared(mid))
	assert_eq(GameState.last_run_extreme_stars, 4)
	assert_eq(GameState.get_extreme_mission_best_stars(mid), 4)
	## 再挑戦: 解放・常設は維持
	assert_true(GameState.is_dungeon_unlocked(mid))
	assert_true(_EventDungeonSchedule.is_open_now(mid))
	assert_eq(int(DataRegistry.get_dungeon_data(mid).daily_attempt_limit), 0)


func test_progress_persists_best_stars() -> void:
	var mid: String = Constants.EX_TOMB_SEAL_DUNGEON_ID
	GameState.record_extreme_mission_clear(mid, 2, {"no_ko": true, "time_limit": false, "no_heal_skill": false})
	assert_true(GameState.is_extreme_mission_cleared(mid))
	assert_eq(GameState.get_extreme_mission_best_stars(mid), 2)
	GameState.record_extreme_mission_clear(mid, 4, {"no_ko": true, "time_limit": true, "no_heal_skill": true})
	assert_eq(GameState.get_extreme_mission_best_stars(mid), 4)
	var saved_orders: Dictionary = GameState.get_extreme_mission_orders(mid)
	assert_true(bool(saved_orders.get("no_ko", false)))
	assert_true(bool(saved_orders.get("time_limit", false)))
	assert_true(bool(saved_orders.get("no_heal_skill", false)))


func test_save_payload_includes_extreme_progress() -> void:
	var mid: String = Constants.EX_TOMB_SEAL_DUNGEON_ID
	GameState.record_extreme_mission_clear(mid, 3, {"no_ko": true, "time_limit": true, "no_heal_skill": false})
	## SaveManager.save_game のペイロード組み立てと同型のキー確認（ディスク非依存）。
	var payload: Dictionary = {
		"extreme_mission_progress": GameState.extreme_mission_progress.duplicate(true),
	}
	assert_true(payload.has("extreme_mission_progress"))
	var prog: Dictionary = payload["extreme_mission_progress"]
	assert_true(prog.has(mid))
	assert_eq(int(prog[mid].get("best_stars", 0)), 3)


func test_old_save_without_extreme_key_loads() -> void:
	## 後方互換: extreme_mission_progress 欠落でも空辞書で起動可。
	var data: Dictionary = {
		"save_version": 17,
		"party": [],
	}
	if data.has("extreme_mission_progress") and data["extreme_mission_progress"] is Dictionary:
		GameState.extreme_mission_progress = (data["extreme_mission_progress"] as Dictionary).duplicate(true)
	else:
		GameState.extreme_mission_progress = {}
	assert_eq(GameState.extreme_mission_progress, {})
