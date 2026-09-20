extends GutTest

## P3-DG-EXTREME-001 — 極限任務 Phase 2（EX-01〜10）

const _ExtremeMissionConfig := preload("res://scripts/dungeon/ExtremeMissionConfig.gd")
const _DungeonTierConfig := preload("res://scripts/dungeon/DungeonTierConfig.gd")
const _EventDungeonSchedule := preload("res://scripts/dungeon/EventDungeonSchedule.gd")
const _Adventurer := preload("res://scripts/domain/Adventurer.gd")

const EXPECTED_MISSIONS: Array[Dictionary] = [
	{"id": "ex_tomb_seal", "boss": "serdion", "floors": 10, "cond": "heal_down"},
	{"id": "ex_grave_siege", "boss": "serdion", "floors": 10, "cond": "swarm_pressure"},
	{"id": "ex_spore_dense", "boss": "granvel", "floors": 10, "cond": "long_battle_ramp"},
	{"id": "ex_hunter_woods", "boss": "granvel", "floors": 10, "cond": "rear_pressure"},
	{"id": "ex_miasma_sat", "boss": "moldgar", "floors": 10, "cond": "miasma_saturate"},
	{"id": "ex_infect_chain", "boss": "moldgar", "floors": 10, "cond": "status_require"},
	{"id": "ex_wreck_assault", "boss": "nereion", "floors": 10, "cond": "ultimate_suppress"},
	{"id": "ex_tide_siege", "boss": "nereion", "floors": 10, "cond": "non_crit_pressure"},
	{"id": "ex_polar_silence", "boss": "eldion", "floors": 10, "cond": "ultimate_disabled"},
	{"id": "ex_white_night", "boss": "eldion", "floors": 10, "cond": "element_weakness_pressure"},
]


func before_each() -> void:
	GameState.debug_full_unlock = false
	GameState.dungeon_progress.clear()
	GameState.stage_progress.clear()
	GameState.dungeon_tier_cleared.clear()
	GameState.extreme_mission_progress.clear()
	GameState.extreme_run_ko_count = 0
	GameState.extreme_run_heal_skill_used = false
	GameState.extreme_run_rear_ko_count = 0
	GameState.extreme_run_ultimate_uses = 0
	GameState.extreme_run_banned_status_used = false
	GameState.extreme_run_start_msec = 0
	GameState.extreme_run_elapsed_sec = 0.0
	GameState.last_run_extreme_mission_id = ""
	GameState.last_run_extreme_stars = 0
	GameState.last_run_extreme_orders = {}
	GameState.last_run_extreme_best_stars = 0
	GameState.last_run_extreme_new_record = false
	GameState.party_members.clear()
	GameState.current_dungeon_id = ""


func _clear_all_main_normal() -> void:
	for biome_id: String in _DungeonTierConfig.MAIN_BIOME_IDS:
		GameState.mark_dungeon_cleared(biome_id)
		GameState.mark_dungeon_tier_cleared(biome_id, _DungeonTierConfig.TIER_NORMAL)


func _make_member(job_id: String) -> Resource:
	var adv: Resource = _Adventurer.new()
	adv.id = "test_%s" % job_id
	adv.display_name = job_id
	adv.job_id = job_id
	return adv


func test_all_ten_mission_ids_valid() -> void:
	assert_eq(Constants.EXTREME_MISSION_PLAYABLE_IDS.size(), 10)
	assert_eq(_ExtremeMissionConfig.MISSIONS.size(), 10)
	for raw: Variant in EXPECTED_MISSIONS:
		var mid: String = str(raw["id"])
		assert_true(Constants.is_extreme_mission_playable(mid), mid)
		assert_true(_ExtremeMissionConfig.is_extreme_mission(mid), mid)
		var data: Resource = DataRegistry.get_dungeon_data(mid)
		assert_not_null(data, mid)
		assert_eq(str(data.route_type), "extreme", mid)
		assert_eq(int(data.floor_count), int(raw["floors"]), mid)
		assert_eq(str(data.boss_id), str(raw["boss"]), mid)
		assert_true(bool(data.disable_wandering), mid)
		assert_eq(int(data.daily_attempt_limit), 0, mid)
		assert_eq(
			_ExtremeMissionConfig.special_condition_id(mid),
			str(raw["cond"]),
			mid
		)
		var hud: String = _ExtremeMissionConfig.special_condition_hud_label(mid)
		assert_false(hud.is_empty(), mid)
		assert_lte(hud.length(), _ExtremeMissionConfig.HUD_LABEL_MAX_LEN, mid)
		var stage: Resource = DataRegistry.get_stage_data("%s_1_1" % mid)
		assert_not_null(stage, mid)
		assert_eq(str(stage.boss_id), str(raw["boss"]), mid)
		assert_eq(int(stage.floor_count), 10, mid)
		assert_eq(str(stage.closing_type), "boss", mid)


func test_unlock_requires_main5_normal_for_all() -> void:
	for mid: String in Constants.EXTREME_MISSION_PLAYABLE_IDS:
		assert_false(GameState.is_dungeon_unlocked(mid), mid)
	_clear_all_main_normal()
	assert_true(_ExtremeMissionConfig.is_content_unlocked())
	for mid: String in Constants.EXTREME_MISSION_PLAYABLE_IDS:
		assert_true(GameState.is_dungeon_unlocked(mid), mid)
		assert_true(_EventDungeonSchedule.is_open_now(mid), mid)


func test_always_open_schedule() -> void:
	assert_true(_EventDungeonSchedule.is_open_now(Constants.EX_TOMB_SEAL_DUNGEON_ID))
	assert_eq(_EventDungeonSchedule.open_schedule_label(Constants.EX_TOMB_SEAL_DUNGEON_ID), "極限・常設")


func test_heal_mult_only_on_heal_down_missions() -> void:
	GameState.current_dungeon_id = "mourngate"
	assert_eq(_ExtremeMissionConfig.heal_effectiveness_mult_for_active_run(), 1.0)
	GameState.current_dungeon_id = Constants.EX_TOMB_SEAL_DUNGEON_ID
	assert_eq(
		_ExtremeMissionConfig.heal_effectiveness_mult_for_active_run(),
		float(_ExtremeMissionConfig.TUNING["heal_effectiveness_mult"])
	)
	## EX-05 は miasma_saturate（heal_down ではない）
	GameState.current_dungeon_id = Constants.EX_MIASMA_SAT_DUNGEON_ID
	assert_eq(_ExtremeMissionConfig.heal_effectiveness_mult_for_active_run(), 1.0)
	GameState.current_dungeon_id = Constants.EX_GRAVE_SIEGE_DUNGEON_ID
	assert_eq(_ExtremeMissionConfig.heal_effectiveness_mult_for_active_run(), 1.0)


func test_modifier_scope_does_not_leak_to_main() -> void:
	GameState.current_dungeon_id = Constants.EX_GRAVE_SIEGE_DUNGEON_ID
	assert_gt(_ExtremeMissionConfig.swarm_chance_bonus_for_active_run(), 0.0)
	assert_eq(_ExtremeMissionConfig.swarm_size_bonus_for_active_run(), 1)
	GameState.current_dungeon_id = "mourngate"
	assert_eq(_ExtremeMissionConfig.swarm_chance_bonus_for_active_run(), 0.0)
	assert_eq(_ExtremeMissionConfig.swarm_size_bonus_for_active_run(), 0)
	## EX-08 は非クリ制約。群れボーナスなし
	GameState.current_dungeon_id = Constants.EX_TIDE_SIEGE_DUNGEON_ID
	assert_eq(_ExtremeMissionConfig.swarm_chance_bonus_for_active_run(), 0.0)
	assert_eq(_ExtremeMissionConfig.swarm_size_bonus_for_active_run(), 0)
	GameState.current_dungeon_id = Constants.EX_HUNTER_WOODS_DUNGEON_ID
	assert_gt(_ExtremeMissionConfig.rear_pressure_incoming_mult_for_active_run(), 1.0)
	GameState.current_dungeon_id = "whisperwood"
	assert_eq(_ExtremeMissionConfig.rear_pressure_incoming_mult_for_active_run(), 1.0)
	GameState.current_dungeon_id = Constants.EX_WRECK_ASSAULT_DUNGEON_ID
	assert_lt(_ExtremeMissionConfig.ultimate_charge_gain_mult_for_active_run(), 1.0)
	GameState.current_dungeon_id = Constants.EX_POLAR_SILENCE_DUNGEON_ID
	assert_true(_ExtremeMissionConfig.is_ultimate_disabled_for_active_run())
	assert_eq(_ExtremeMissionConfig.ultimate_charge_gain_mult_for_active_run(), 0.0)
	GameState.current_dungeon_id = "blackshore"
	assert_false(_ExtremeMissionConfig.is_ultimate_disabled_for_active_run())
	assert_eq(_ExtremeMissionConfig.ultimate_charge_gain_mult_for_active_run(), 1.0)


func test_long_battle_ramp_only_on_ex03() -> void:
	GameState.current_dungeon_id = Constants.EX_SPORE_DENSE_DUNGEON_ID
	GameState.begin_extreme_run_tracking(Constants.EX_SPORE_DENSE_DUNGEON_ID)
	GameState.extreme_run_elapsed_sec = 10.0
	assert_eq(_ExtremeMissionConfig.enemy_outgoing_modifier_mult_for_active_run(), 1.0)
	var start_sec: float = float(_ExtremeMissionConfig.TUNING["long_battle_ramp_start_sec"])
	GameState.extreme_run_elapsed_sec = start_sec + 60.0
	assert_gt(_ExtremeMissionConfig.enemy_outgoing_modifier_mult_for_active_run(), 1.0)
	## EX-10 は element_weakness_pressure（長期戦ランプなし）
	GameState.current_dungeon_id = Constants.EX_WHITE_NIGHT_DUNGEON_ID
	GameState.begin_extreme_run_tracking(Constants.EX_WHITE_NIGHT_DUNGEON_ID)
	GameState.extreme_run_elapsed_sec = start_sec + 60.0
	assert_eq(_ExtremeMissionConfig.enemy_outgoing_modifier_mult_for_active_run(), 1.0)
	GameState.current_dungeon_id = "mourngate"
	assert_eq(_ExtremeMissionConfig.enemy_outgoing_modifier_mult_for_active_run(), 1.0)
	## 旧 status_empower の banned は廃止
	GameState.current_dungeon_id = Constants.EX_INFECT_CHAIN_DUNGEON_ID
	assert_false(_ExtremeMissionConfig.is_banned_status_for_active_run("poison"))
	assert_false(_ExtremeMissionConfig.is_banned_status_for_active_run("bleed"))


func test_miasma_saturate_hp_and_dot_duration() -> void:
	GameState.current_dungeon_id = Constants.EX_MIASMA_SAT_DUNGEON_ID
	assert_eq(
		_ExtremeMissionConfig.enemy_hp_mult_for_active_run(),
		float(_ExtremeMissionConfig.TUNING["miasma_enemy_hp_mult"])
	)
	assert_eq(
		_ExtremeMissionConfig.enemy_dot_duration_mult_for_active_run("poison"),
		float(_ExtremeMissionConfig.TUNING["miasma_dot_duration_mult"])
	)
	assert_eq(
		_ExtremeMissionConfig.enemy_dot_duration_mult_for_active_run("bleed"),
		float(_ExtremeMissionConfig.TUNING["miasma_dot_duration_mult"])
	)
	assert_eq(
		_ExtremeMissionConfig.enemy_dot_duration_mult_for_active_run("ignite"),
		float(_ExtremeMissionConfig.TUNING["miasma_dot_duration_mult"])
	)
	assert_eq(_ExtremeMissionConfig.enemy_dot_duration_mult_for_active_run("stun"), 1.0)
	GameState.current_dungeon_id = "mistfen"
	assert_eq(_ExtremeMissionConfig.enemy_hp_mult_for_active_run(), 1.0)
	assert_eq(_ExtremeMissionConfig.enemy_dot_duration_mult_for_active_run("poison"), 1.0)

	## 実付与で持続が延びる（ベース duration_ticks × 倍率）
	GameState.current_dungeon_id = Constants.EX_MIASMA_SAT_DUNGEON_ID
	var poison_fx: Resource = DataRegistry.get_status_effect("poison")
	assert_not_null(poison_fx)
	var base_ticks: int = int(poison_fx.duration_ticks)
	assert_gt(base_ticks, 0)
	var cc: CombatController = CombatController.new()
	add_child_autofree(cc)
	cc.swarm_data = [DataRegistry.get_enemy_data("sepia_hound")]
	cc.swarm_hp = [1000]
	cc.swarm_max_hp = [1000]
	cc.active_enemy_index = 0
	assert_true(cc.apply_status_to_enemy_slot(0, "poison", 1, 50))
	var list: Array = cc.get_enemy_status_list_at(0)
	assert_false(list.is_empty())
	var expected_ticks: int = maxi(
		1,
		int(round(float(base_ticks) * float(_ExtremeMissionConfig.TUNING["miasma_dot_duration_mult"])))
	)
	assert_eq(int(list[0].get("remaining_ticks", 0)), expected_ticks)


func test_status_require_outgoing_with_and_without_status() -> void:
	GameState.current_dungeon_id = Constants.EX_INFECT_CHAIN_DUNGEON_ID
	var expect_down: float = float(_ExtremeMissionConfig.TUNING["status_require_outgoing_mult"])
	var cc: CombatController = CombatController.new()
	add_child_autofree(cc)
	cc.swarm_data = [DataRegistry.get_enemy_data("sepia_hound")]
	cc.swarm_hp = [1000]
	cc.swarm_max_hp = [1000]
	cc.active_enemy_index = 0
	assert_eq(
		_ExtremeMissionConfig.status_require_outgoing_mult_for_active_run(cc, 0),
		expect_down
	)
	assert_true(cc.apply_status_to_enemy_slot(0, "poison", 1, 50))
	assert_eq(
		_ExtremeMissionConfig.status_require_outgoing_mult_for_active_run(cc, 0),
		1.0
	)
	GameState.current_dungeon_id = "mistfen"
	assert_eq(_ExtremeMissionConfig.status_require_outgoing_mult_for_active_run(cc, 0), 1.0)


func test_non_crit_hit_outgoing_mult() -> void:
	GameState.current_dungeon_id = Constants.EX_TIDE_SIEGE_DUNGEON_ID
	var expect: float = float(_ExtremeMissionConfig.TUNING["non_crit_hit_outgoing_mult"])
	assert_eq(_ExtremeMissionConfig.hit_outgoing_mult_for_active_run(false), expect)
	assert_eq(_ExtremeMissionConfig.hit_outgoing_mult_for_active_run(true), 1.0)
	GameState.current_dungeon_id = "blackshore"
	assert_eq(_ExtremeMissionConfig.hit_outgoing_mult_for_active_run(false), 1.0)


func test_element_weakness_pressure_match_mismatch_empty() -> void:
	GameState.current_dungeon_id = Constants.EX_WHITE_NIGHT_DUNGEON_ID
	var expect: float = float(_ExtremeMissionConfig.TUNING["non_weakness_outgoing_mult"])
	var eldion: Resource = DataRegistry.get_enemy_data("eldion")
	assert_not_null(eldion)
	assert_eq(
		_ExtremeMissionConfig.element_match_outgoing_mult_for_active_run("fire", eldion),
		1.0
	)
	assert_eq(
		_ExtremeMissionConfig.element_match_outgoing_mult_for_active_run("ice", eldion),
		expect
	)
	assert_eq(
		_ExtremeMissionConfig.element_match_outgoing_mult_for_active_run("", eldion),
		expect
	)
	## 弱点未設定の敵はペナルティなし
	const _EnemyData := preload("res://scripts/data/EnemyData.gd")
	var blank: Resource = _EnemyData.new()
	blank.element_weakness = [] as Array[String]
	assert_eq(
		_ExtremeMissionConfig.element_match_outgoing_mult_for_active_run("fire", blank),
		1.0
	)
	GameState.current_dungeon_id = "frostridge"
	assert_eq(
		_ExtremeMissionConfig.element_match_outgoing_mult_for_active_run("", eldion),
		1.0
	)

func test_star_evaluation_and_orders_ex01() -> void:
	GameState.current_dungeon_id = Constants.EX_TOMB_SEAL_DUNGEON_ID
	GameState.begin_extreme_run_tracking(Constants.EX_TOMB_SEAL_DUNGEON_ID)
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


func test_phase2_order_evaluations() -> void:
	## no_same_job
	GameState.party_members = [_make_member("swordsman"), _make_member("ranger")]
	GameState.current_dungeon_id = Constants.EX_GRAVE_SIEGE_DUNGEON_ID
	GameState.begin_extreme_run_tracking(Constants.EX_GRAVE_SIEGE_DUNGEON_ID)
	var orders: Dictionary = _ExtremeMissionConfig.evaluate_orders_for_run(
		Constants.EX_GRAVE_SIEGE_DUNGEON_ID
	)
	assert_true(bool(orders.get("no_same_job", false)))
	GameState.party_members = [_make_member("swordsman"), _make_member("swordsman")]
	orders = _ExtremeMissionConfig.evaluate_orders_for_run(Constants.EX_GRAVE_SIEGE_DUNGEON_ID)
	assert_false(bool(orders.get("no_same_job", true)))

	## all_unique_jobs（人間満員4・別職。Jack対象外）
	GameState.party_members = [
		_make_member("swordsman"),
		_make_member("ranger"),
		_make_member("vanguard"),
		_make_member("alchemist"),
	]
	GameState.current_dungeon_id = Constants.EX_POLAR_SILENCE_DUNGEON_ID
	orders = _ExtremeMissionConfig.evaluate_orders_for_run(Constants.EX_POLAR_SILENCE_DUNGEON_ID)
	assert_true(bool(orders.get("all_unique_jobs", false)))
	## 3人だけでは未達成
	GameState.party_members = [
		_make_member("swordsman"),
		_make_member("ranger"),
		_make_member("vanguard"),
	]
	orders = _ExtremeMissionConfig.evaluate_orders_for_run(Constants.EX_POLAR_SILENCE_DUNGEON_ID)
	assert_false(bool(orders.get("all_unique_jobs", true)))
	## 4人でも同職がいれば未達成
	GameState.party_members = [
		_make_member("swordsman"),
		_make_member("ranger"),
		_make_member("vanguard"),
		_make_member("swordsman_b"),
	]
	GameState.party_members[3].job_id = "swordsman"
	orders = _ExtremeMissionConfig.evaluate_orders_for_run(Constants.EX_POLAR_SILENCE_DUNGEON_ID)
	assert_false(bool(orders.get("all_unique_jobs", true)))

	## ultimate_limit / no_ultimate
	GameState.current_dungeon_id = Constants.EX_SPORE_DENSE_DUNGEON_ID
	GameState.begin_extreme_run_tracking(Constants.EX_SPORE_DENSE_DUNGEON_ID)
	GameState.extreme_run_ultimate_uses = _ExtremeMissionConfig.ultimate_use_limit()
	orders = _ExtremeMissionConfig.evaluate_orders_for_run(Constants.EX_SPORE_DENSE_DUNGEON_ID)
	assert_true(bool(orders.get("ultimate_limit", false)))
	GameState.extreme_run_ultimate_uses = _ExtremeMissionConfig.ultimate_use_limit() + 1
	orders = _ExtremeMissionConfig.evaluate_orders_for_run(Constants.EX_SPORE_DENSE_DUNGEON_ID)
	assert_false(bool(orders.get("ultimate_limit", true)))

	GameState.current_dungeon_id = Constants.EX_WRECK_ASSAULT_DUNGEON_ID
	GameState.begin_extreme_run_tracking(Constants.EX_WRECK_ASSAULT_DUNGEON_ID)
	orders = _ExtremeMissionConfig.evaluate_orders_for_run(Constants.EX_WRECK_ASSAULT_DUNGEON_ID)
	assert_true(bool(orders.get("no_ultimate", false)))
	GameState.note_extreme_ultimate_used()
	orders = _ExtremeMissionConfig.evaluate_orders_for_run(Constants.EX_WRECK_ASSAULT_DUNGEON_ID)
	assert_false(bool(orders.get("no_ultimate", true)))

	## no_rear_ko（EX-04）／EX-06 は time_limit（旧 no_banned_status 廃止）
	GameState.current_dungeon_id = Constants.EX_HUNTER_WOODS_DUNGEON_ID
	GameState.begin_extreme_run_tracking(Constants.EX_HUNTER_WOODS_DUNGEON_ID)
	orders = _ExtremeMissionConfig.evaluate_orders_for_run(Constants.EX_HUNTER_WOODS_DUNGEON_ID)
	assert_true(bool(orders.get("no_rear_ko", false)))
	GameState.extreme_run_rear_ko_count = 1
	orders = _ExtremeMissionConfig.evaluate_orders_for_run(Constants.EX_HUNTER_WOODS_DUNGEON_ID)
	assert_false(bool(orders.get("no_rear_ko", true)))

	GameState.current_dungeon_id = Constants.EX_INFECT_CHAIN_DUNGEON_ID
	GameState.begin_extreme_run_tracking(Constants.EX_INFECT_CHAIN_DUNGEON_ID)
	GameState.extreme_run_elapsed_sec = 30.0
	orders = _ExtremeMissionConfig.evaluate_orders_for_run(Constants.EX_INFECT_CHAIN_DUNGEON_ID)
	assert_true(bool(orders.has("time_limit")))
	assert_false(bool(orders.has("no_banned_status")))
	assert_true(bool(orders.get("time_limit", false)))
	GameState.extreme_run_elapsed_sec = float(_ExtremeMissionConfig.order_time_limit_sec()) + 1.0
	orders = _ExtremeMissionConfig.evaluate_orders_for_run(Constants.EX_INFECT_CHAIN_DUNGEON_ID)
	assert_false(bool(orders.get("time_limit", true)))


func test_time_order_uses_accumulated_not_wall_clock() -> void:
	GameState.current_dungeon_id = Constants.EX_TOMB_SEAL_DUNGEON_ID
	GameState.begin_extreme_run_tracking(Constants.EX_TOMB_SEAL_DUNGEON_ID)
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
	GameState.current_dungeon_id = "mourngate"
	GameState.add_extreme_run_elapsed(10.0)
	assert_eq(GameState.extreme_run_elapsed_sec, 5.0)


func test_heal_mult_applies_even_when_received_mult_false() -> void:
	GameState.current_dungeon_id = Constants.EX_TOMB_SEAL_DUNGEON_ID
	var cc: CombatController = CombatController.new()
	add_child_autofree(cc)
	cc.party_combat_hp = [100]
	cc.party_max_hp = [200]
	var healed: int = cc.heal_member(0, 100, false)
	var expected: int = int(round(100.0 * float(_ExtremeMissionConfig.TUNING["heal_effectiveness_mult"])))
	assert_eq(healed, expected)
	GameState.current_dungeon_id = "mourngate"
	cc.party_combat_hp = [100]
	healed = cc.heal_member(0, 100, false)
	assert_eq(healed, 100)


func test_missions_progress_isolated() -> void:
	var a: String = Constants.EX_TOMB_SEAL_DUNGEON_ID
	var b: String = Constants.EX_WHITE_NIGHT_DUNGEON_ID
	GameState.record_extreme_mission_clear(a, 4, {"no_ko": true, "time_limit": true, "no_heal_skill": true})
	assert_true(GameState.is_extreme_mission_cleared(a))
	assert_false(GameState.is_extreme_mission_cleared(b))
	assert_eq(GameState.get_extreme_mission_best_stars(a), 4)
	assert_eq(GameState.get_extreme_mission_best_stars(b), 0)
	GameState.record_extreme_mission_clear(b, 2, {"no_ko": true, "time_limit": false, "no_same_job": false})
	assert_eq(GameState.get_extreme_mission_best_stars(a), 4)
	assert_eq(GameState.get_extreme_mission_best_stars(b), 2)


func test_vertical_slice_unlock_select_clear_save() -> void:
	var mid: String = Constants.EX_TOMB_SEAL_DUNGEON_ID
	assert_false(GameState.is_dungeon_unlocked(mid))
	_clear_all_main_normal()
	assert_true(GameState.is_dungeon_unlocked(mid))
	assert_true(_EventDungeonSchedule.is_open_now(mid))
	var stage: Resource = DataRegistry.get_stage_data("ex_tomb_seal_1_1")
	assert_not_null(stage)
	assert_eq(str(stage.boss_id), "serdion")
	assert_eq(int(stage.floor_count), 10)
	GameState.current_dungeon_id = mid
	GameState.begin_extreme_run_tracking(mid)
	GameState.extreme_run_elapsed_sec = 120.0
	_ExtremeMissionConfig.commit_clear_result(mid)
	assert_true(GameState.is_extreme_mission_cleared(mid))
	assert_eq(GameState.last_run_extreme_stars, 4)
	assert_eq(GameState.get_extreme_mission_best_stars(mid), 4)
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
	var mid: String = Constants.EX_GRAVE_SIEGE_DUNGEON_ID
	GameState.record_extreme_mission_clear(mid, 3, {"no_ko": true, "time_limit": true, "no_same_job": false})
	var payload: Dictionary = {
		"extreme_mission_progress": GameState.extreme_mission_progress.duplicate(true),
	}
	assert_true(payload.has("extreme_mission_progress"))
	var prog: Dictionary = payload["extreme_mission_progress"]
	assert_true(prog.has(mid))
	assert_eq(int(prog[mid].get("best_stars", 0)), 3)


func test_old_save_without_extreme_key_loads() -> void:
	var data: Dictionary = {
		"save_version": 17,
		"party": [],
	}
	if data.has("extreme_mission_progress") and data["extreme_mission_progress"] is Dictionary:
		GameState.extreme_mission_progress = (data["extreme_mission_progress"] as Dictionary).duplicate(true)
	else:
		GameState.extreme_mission_progress = {}
	assert_eq(GameState.extreme_mission_progress, {})


func test_extreme_missions_use_dedicated_route_tab() -> void:
	## 極限はイベントタブではなく専用「極限任務」タブ。
	GameState.debug_full_unlock = true
	var packed: PackedScene = load("res://scenes/dungeon/DungeonSelectScene.tscn")
	var scene: Control = packed.instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	var mid: String = Constants.EX_TOMB_SEAL_DUNGEON_ID
	scene.call("_set_featured_dungeon", mid)
	assert_eq(str(scene.get("_route_tab")), "extreme", "極限 Featured は極限タブ")
	scene.set("_route_tab", "extreme")
	var extreme_list: Array = scene.call("_dungeons_for_route_tab")
	var found: bool = false
	for d in extreme_list:
		if d != null and str(d.id) == mid:
			found = true
			break
	assert_true(found, "極限タブ一覧に EX-01")
	scene.set("_route_tab", "event")
	var event_list: Array = scene.call("_dungeons_for_route_tab")
	for d2 in event_list:
		if d2 != null:
			assert_false(Constants.is_extreme_mission_playable(str(d2.id)), "イベントタブに極限を載せない")
	var btn: Button = scene.get_node_or_null(
		"MainColumn/RouteTabsRow/ButtonExtremeMission"
	) as Button
	assert_not_null(btn)
	assert_eq(btn.text, "極限任務")


func test_extreme_display_copy_matches_impl() -> void:
	## 表示文と special_condition id が実挙動と一致すること。
	assert_eq(_ExtremeMissionConfig.order_display_label("time_limit"), "10分以内にクリア")
	assert_eq(_ExtremeMissionConfig.order_time_limit_sec(), 600)
	assert_eq(_ExtremeMissionConfig.special_condition_id("ex_tide_siege"), "non_crit_pressure")
	assert_eq(_ExtremeMissionConfig.special_condition_label("ex_tide_siege"), "非クリティカル弱体")
	assert_eq(_ExtremeMissionConfig.special_condition_hud_label("ex_tide_siege"), "非会心弱体")
	assert_true(
		_ExtremeMissionConfig.special_condition_desc("ex_tide_siege").find("DoT") >= 0
	)
	assert_eq(_ExtremeMissionConfig.special_condition_id("ex_grave_siege"), "swarm_pressure")
	assert_eq(_ExtremeMissionConfig.special_condition_hud_label("ex_grave_siege"), "群れ増加")
	assert_true(
		_ExtremeMissionConfig.special_condition_desc("ex_grave_siege").find("群れ出現時") >= 0
	)
	assert_true(
		_ExtremeMissionConfig.special_condition_desc("ex_hunter_woods").find("編成") >= 0
	)
	assert_eq(_ExtremeMissionConfig.special_condition_hud_label("ex_tomb_seal"), "回復50%")
	assert_eq(_ExtremeMissionConfig.special_condition_id("ex_miasma_sat"), "miasma_saturate")
	assert_eq(_ExtremeMissionConfig.special_condition_id("ex_infect_chain"), "status_require")
	assert_eq(
		_ExtremeMissionConfig.special_condition_id("ex_white_night"),
		"element_weakness_pressure"
	)
	assert_eq(_ExtremeMissionConfig.special_condition_hud_label("ex_white_night"), "弱点必須")
	assert_true(
		_ExtremeMissionConfig.special_condition_tip("ex_white_night").find("炎") >= 0
	)
	assert_eq(
		_ExtremeMissionConfig.swarm_chance_bonus_for_active_run(),
		0.0
	)  ## 非アクティブ時
	var brief: PackedStringArray = _ExtremeMissionConfig.featured_brief_lines("ex_tomb_seal")
	assert_true(brief.size() >= 5)
	assert_eq(brief[0], "特殊制約｜回復効果半減")
	assert_true(("\n".join(brief)).find("極限指令｜以下を達成すると報酬アップ。キャラを王痕強化できる破片を入手できます。") >= 0)
	assert_true(("\n".join(brief)).find("規定時間") < 0)
	assert_true(("\n".join(brief)).find("10分以内にクリア") >= 0)
	assert_true(("\n".join(brief)).find("CLEAR ★") < 0)
	var bb: String = _ExtremeMissionConfig.featured_brief_bbcode("ex_tomb_seal")
	assert_true(bb.find("王痕強化できる破片") >= 0)
	assert_true(bb.find("CLEAR ★") < 0)
	assert_eq(
		_ExtremeMissionConfig.special_condition_label("ex_polar_silence"),
		"必殺技使用不可"
	)
	assert_eq(_ExtremeMissionConfig.special_condition_hud_label("ex_polar_silence"), "必殺不可")
	assert_eq(_ExtremeMissionConfig.special_condition_hud_label("mourngate"), "")
	assert_true(
		FileAccess.file_exists("res://assets/ui/dungeon/ICO_ExtremeMission_Legend.png")
	)
	assert_true(FileAccess.file_exists("res://assets/ui/result/ICO_Result_Extreme.png"))
	assert_true(FileAccess.file_exists("res://assets/ui/result/ICO_Result_ExtremeStar.png"))
	assert_true(FileAccess.file_exists("res://assets/ui/result/ICO_Result_ExtremeRecord.png"))
	assert_true(FileAccess.file_exists("res://assets/ui/result/ICO_Result_RoyalMarkShard.png"))
	assert_eq(
		str(IconPaths.ICON_MAP.get("ui:royal_mark_shard", "")),
		"res://assets/ui/result/ICO_Result_RoyalMarkShard.png"
	)
	## UI ラベルと modifier API の対応（EX-02 群れサイズ）
	GameState.current_dungeon_id = Constants.EX_GRAVE_SIEGE_DUNGEON_ID
	assert_eq(_ExtremeMissionConfig.swarm_size_bonus_for_active_run(), 1)


func test_extreme_legendary_and_mythic_drop_bonus() -> void:
	## 極限のみ LEGENDARY 別枠 +10pt／神話再クリア 1%+10pt。本編は据置。
	GameState.current_dungeon_id = "mourngate"
	assert_eq(_ExtremeMissionConfig.equip_legendary_chance_bonus_for_active_run(), 0.0)
	assert_eq(_ExtremeMissionConfig.boss_mythic_chance_bonus_for_active_run(), 0.0)
	assert_almost_eq(MythicLoot.chance_for_dungeon("mourngate"), 0.01, 0.0001)
	GameState.current_dungeon_id = Constants.EX_TOMB_SEAL_DUNGEON_ID
	assert_almost_eq(
		_ExtremeMissionConfig.equip_legendary_chance_bonus_for_active_run(), 0.10, 0.0001
	)
	assert_almost_eq(
		_ExtremeMissionConfig.boss_mythic_chance_bonus_for_active_run(), 0.10, 0.0001
	)
	assert_almost_eq(
		MythicLoot.chance_for_dungeon(Constants.EX_TOMB_SEAL_DUNGEON_ID), 0.11, 0.0001
	)
	assert_true(
		MythicLoot.is_eligible_dungeon(Constants.EX_TOMB_SEAL_DUNGEON_ID, "ex_tomb_seal_1_1")
	)
	var dc: Node = preload("res://scripts/dungeon/DungeonController.gd").new()
	add_child_autofree(dc)
	var leg_id: String = "coil_spring_dual"
	assert_eq(int(DataRegistry.get_weapon_data(leg_id).rarity), Enums.Rarity.LEGENDARY)
	var pool: Array = ["iron_sword", leg_id]
	var picked: String = ""
	for s: int in range(1, 400):
		var probe := RandomNumberGenerator.new()
		probe.seed = s
		if probe.randf() >= 0.10:
			continue
		var rng := RandomNumberGenerator.new()
		rng.seed = s
		picked = dc.call("_try_extreme_legendary_bonus_pick", pool, "weapon", null, rng)
		if not picked.is_empty():
			break
	assert_eq(picked, leg_id)
	GameState.current_dungeon_id = "mourngate"
	var rng_main := RandomNumberGenerator.new()
	rng_main.seed = 1
	assert_eq(dc.call("_try_extreme_legendary_bonus_pick", pool, "weapon", null, rng_main), "")


func test_extreme_mythic_reclear_roll() -> void:
	## 極限ボス再クリアで神話候補になり、強制低ロールで必ず当たる。
	var mid: String = Constants.EX_TOMB_SEAL_DUNGEON_ID
	var stage_id: String = "ex_tomb_seal_1_1"
	GameState.current_dungeon_id = mid
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NORMAL
	GameState.mark_stage_cleared(stage_id, _DungeonTierConfig.TIER_NORMAL)
	GameState.inventory.clear()
	GameState.armor_inventory.clear()
	GameState.accessory_inventory.clear()
	var stage: Resource = DataRegistry.get_stage_data(stage_id)
	assert_not_null(stage)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	## chance 0.11 未満になるまで seed 探索
	var hit: Dictionary = {}
	for s: int in range(1, 500):
		rng = RandomNumberGenerator.new()
		rng.seed = s
		if rng.randf() > 0.11:
			continue
		rng = RandomNumberGenerator.new()
		rng.seed = s
		hit = MythicLoot.roll_for_boss_reclear(stage, rng)
		if not hit.is_empty():
			break
	assert_false(hit.is_empty(), "extreme reclear should allow mythic at 11%")
	assert_true(MythicLoot.is_mythic_id(str(hit.get("id", ""))))
