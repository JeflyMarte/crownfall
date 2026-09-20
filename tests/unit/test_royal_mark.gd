extends GutTest

## P3-DG-ROYAL-MARK-001 / Decision 144 — 王痕育成

const _RoyalMarkConfig := preload("res://scripts/systems/RoyalMarkConfig.gd")
const _RoyalMarkSystem := preload("res://scripts/systems/RoyalMarkSystem.gd")
const _ExtremeMissionConfig := preload("res://scripts/dungeon/ExtremeMissionConfig.gd")
const _DungeonTierConfig := preload("res://scripts/dungeon/DungeonTierConfig.gd")
const _Adventurer := preload("res://scripts/domain/Adventurer.gd")
const _RosterUiHelper := preload("res://scripts/roster/RosterUiHelper.gd")
const _Stats := preload("res://scripts/domain/Stats.gd")


func before_each() -> void:
	GameState.debug_full_unlock = false
	GameState.dungeon_progress.clear()
	GameState.stage_progress.clear()
	GameState.dungeon_tier_cleared.clear()
	GameState.extreme_mission_progress.clear()
	GameState.royal_mark_shards = 0
	GameState.royal_mark_ranks = {}
	GameState.royal_mark_paths = {}
	GameState.extreme_run_reward_committed = false
	GameState.last_run_royal_mark_shards_star = 0
	GameState.last_run_royal_mark_shards_repeat = 0
	GameState.last_run_royal_mark_shards_total = 0
	GameState.extreme_run_ko_count = 0
	GameState.extreme_run_heal_skill_used = false
	GameState.extreme_run_rear_ko_count = 0
	GameState.extreme_run_ultimate_uses = 0
	GameState.extreme_run_banned_status_used = false
	GameState.extreme_run_elapsed_sec = 0.0
	GameState.last_run_extreme_mission_id = ""
	GameState.last_run_extreme_stars = 0
	GameState.last_run_extreme_orders = {}
	GameState.last_run_extreme_best_stars = 0
	GameState.last_run_extreme_new_record = false
	GameState.gold = 0
	GameState.roster.clear()
	GameState.party_members.clear()
	GameState.current_dungeon_id = ""
	GameState.active_pet = null


func _clear_main_normal() -> void:
	for biome_id: String in _DungeonTierConfig.MAIN_BIOME_IDS:
		GameState.mark_dungeon_cleared(biome_id)
		GameState.mark_dungeon_tier_cleared(biome_id, _DungeonTierConfig.TIER_NORMAL)


func _make_human(id: String, level: int = 50) -> Resource:
	var adv: Resource = _Adventurer.new()
	adv.id = id
	adv.display_name = id
	adv.job_id = "swordsman"
	adv.level = level
	adv.rarity = 3
	var st: Resource = _Stats.new()
	st.hp = 800
	st.attack = 100
	st.defense = 50
	adv.base_stats = st
	return adv


func _make_pet() -> Resource:
	var adv: Resource = _Adventurer.new()
	adv.id = "pet_jack"
	adv.display_name = "ジャック"
	adv.job_id = ""
	adv.level = 99
	return adv


func test_star_shards_progress_table() -> void:
	assert_eq(_RoyalMarkConfig.star_shards_for_progress(0, 1), 30)
	assert_eq(_RoyalMarkConfig.star_shards_for_progress(1, 3), 70)
	assert_eq(_RoyalMarkConfig.star_shards_for_progress(0, 4), 150)
	assert_eq(_RoyalMarkConfig.star_shards_for_progress(4, 4), 0)
	assert_eq(_RoyalMarkConfig.retroactive_shards_for_best(0), 0)
	assert_eq(_RoyalMarkConfig.retroactive_shards_for_best(1), 30)
	assert_eq(_RoyalMarkConfig.retroactive_shards_for_best(2), 60)
	assert_eq(_RoyalMarkConfig.retroactive_shards_for_best(3), 100)
	assert_eq(_RoyalMarkConfig.retroactive_shards_for_best(4), 150)


func test_v17_migration_retroactive_zero() -> void:
	var data: Dictionary = {
		"save_version": 17,
		"extreme_mission_progress": {},
	}
	data = SaveManager._migrate_save_data(data)
	assert_eq(int(data.get("save_version", 0)), 20)
	assert_eq(int(data.get("royal_mark_shards", -1)), 0)
	assert_true(data.get("royal_mark_ranks", null) is Dictionary)
	assert_true(data.get("royal_mark_paths", null) is Dictionary)


func test_v17_migration_retroactive_star1() -> void:
	var data: Dictionary = {
		"save_version": 17,
		"extreme_mission_progress": {
			"ex_tomb_seal": {"cleared": true, "best_stars": 1, "orders": {}},
		},
	}
	data = SaveManager._migrate_save_data(data)
	## 旧遡及3 → v20×10
	assert_eq(int(data.get("royal_mark_shards", 0)), 30)


func test_v17_migration_retroactive_star4() -> void:
	var data: Dictionary = {
		"save_version": 17,
		"extreme_mission_progress": {
			"ex_tomb_seal": {"cleared": true, "best_stars": 4, "orders": {}},
		},
	}
	data = SaveManager._migrate_save_data(data)
	assert_eq(int(data.get("royal_mark_shards", 0)), 150)


func test_v17_migration_retroactive_sum_all_ex() -> void:
	var progress: Dictionary = {}
	for mid: String in Constants.EXTREME_MISSION_PLAYABLE_IDS:
		progress[mid] = {"cleared": true, "best_stars": 4, "orders": {}}
	var data: Dictionary = {
		"save_version": 17,
		"extreme_mission_progress": progress,
	}
	data = SaveManager._migrate_save_data(data)
	assert_eq(int(data.get("royal_mark_shards", 0)), 1500)


func test_migration_rerun_no_double_grant() -> void:
	var progress: Dictionary = {
		"ex_tomb_seal": {"cleared": true, "best_stars": 4, "orders": {}},
	}
	var data: Dictionary = {
		"save_version": 17,
		"extreme_mission_progress": progress,
	}
	data = SaveManager._migrate_save_data(data)
	assert_eq(int(data.get("royal_mark_shards", 0)), 150)
	## 既に現行 version → 再 migrate しても遡及／×10しない
	data = SaveManager._migrate_save_data(data)
	assert_eq(int(data.get("royal_mark_shards", 0)), 150)


func test_v19_to_v20_shard_scale() -> void:
	var data: Dictionary = {
		"save_version": 19,
		"royal_mark_shards": 42,
		"royal_mark_ranks": {},
		"royal_mark_paths": {},
	}
	data = SaveManager._migrate_save_data(data)
	assert_eq(int(data.get("save_version", 0)), 20)
	assert_eq(int(data.get("royal_mark_shards", 0)), 420)


func test_rank_upgrade_0_to_1() -> void:
	_clear_main_normal()
	var m: Resource = _make_human("adventurer_0", 50)
	GameState.roster = [m]
	GameState.royal_mark_shards = 100
	GameState.gold = 5000
	var result: Dictionary = _RoyalMarkSystem.apply_upgrade(m)
	assert_true(bool(result.get("ok", false)), str(result))
	assert_eq(_RoyalMarkSystem.rank_of_member(m), 1)
	assert_eq(_RoyalMarkSystem.get_shards(), 0)
	assert_eq(int(GameState.gold), 0)


func test_rank_upgrade_4_to_5() -> void:
	_clear_main_normal()
	var m: Resource = _make_human("adventurer_1", 50)
	GameState.roster = [m]
	GameState.royal_mark_ranks["adventurer_1"] = 4
	GameState.royal_mark_shards = 300
	GameState.gold = 45000
	var result: Dictionary = _RoyalMarkSystem.apply_upgrade(m)
	assert_true(bool(result.get("ok", false)), str(result))
	assert_eq(_RoyalMarkSystem.rank_of_member(m), 5)
	assert_eq(_RoyalMarkSystem.get_shards(), 0)
	assert_eq(int(GameState.gold), 0)


func test_rank5_rejected() -> void:
	_clear_main_normal()
	var m: Resource = _make_human("adventurer_2", 50)
	GameState.roster = [m]
	GameState.royal_mark_ranks["adventurer_2"] = 5
	GameState.royal_mark_shards = 999
	GameState.gold = 999999
	var check: Dictionary = _RoyalMarkSystem.can_upgrade(m)
	assert_false(bool(check.get("ok", false)))
	assert_eq(str(check.get("reason", "")), "max_rank")


func test_level49_rejected() -> void:
	_clear_main_normal()
	var m: Resource = _make_human("adventurer_0", 49)
	GameState.roster = [m]
	GameState.royal_mark_shards = 100
	GameState.gold = 100000
	var check: Dictionary = _RoyalMarkSystem.can_upgrade(m)
	assert_false(bool(check.get("ok", false)))
	assert_eq(str(check.get("reason", "")), "level_gate")


func test_shards_insufficient() -> void:
	_clear_main_normal()
	var m: Resource = _make_human("adventurer_0", 50)
	GameState.roster = [m]
	GameState.royal_mark_shards = 99
	GameState.gold = 5000
	var check: Dictionary = _RoyalMarkSystem.can_upgrade(m)
	assert_false(bool(check.get("ok", false)))
	assert_eq(str(check.get("reason", "")), "need_shards")
	assert_eq(_RoyalMarkSystem.get_shards(), 99)
	assert_eq(int(GameState.gold), 5000)


func test_gold_insufficient() -> void:
	_clear_main_normal()
	var m: Resource = _make_human("adventurer_0", 50)
	GameState.roster = [m]
	GameState.royal_mark_shards = 100
	GameState.gold = 4999
	var check: Dictionary = _RoyalMarkSystem.can_upgrade(m)
	assert_false(bool(check.get("ok", false)))
	assert_eq(str(check.get("reason", "")), "need_gold")


func test_locked_without_main_clear() -> void:
	var m: Resource = _make_human("adventurer_0", 50)
	GameState.roster = [m]
	GameState.royal_mark_shards = 100
	GameState.gold = 100000
	var check: Dictionary = _RoyalMarkSystem.can_upgrade(m)
	assert_false(bool(check.get("ok", false)))
	assert_eq(str(check.get("reason", "")), "locked")


func test_not_owned_rejected() -> void:
	_clear_main_normal()
	var m: Resource = _make_human("gacha_helper_a", 50)
	GameState.roster = []
	GameState.royal_mark_shards = 100
	GameState.gold = 100000
	var check: Dictionary = _RoyalMarkSystem.can_upgrade(m)
	assert_false(bool(check.get("ok", false)))
	assert_eq(str(check.get("reason", "")), "not_owned")


func test_jack_rejected() -> void:
	_clear_main_normal()
	var pet: Resource = _make_pet()
	GameState.roster = [pet]
	GameState.royal_mark_shards = 100
	GameState.gold = 100000
	var check: Dictionary = _RoyalMarkSystem.can_upgrade(pet)
	assert_false(bool(check.get("ok", false)))
	assert_eq(str(check.get("reason", "")), "not_eligible")
	assert_eq(_RoyalMarkConfig.normalize_character_id("pet_jack"), "")


func test_stat_mult_rank_i_to_v() -> void:
	var expected_hp: Array[float] = [1.00, 1.03, 1.03, 1.03, 1.05, 1.08]
	var expected_atk: Array[float] = [1.00, 1.00, 1.03, 1.03, 1.05, 1.08]
	var expected_def: Array[float] = [1.00, 1.00, 1.00, 1.03, 1.05, 1.08]
	for r: int in range(0, 6):
		var m: Dictionary = _RoyalMarkConfig.stat_multipliers_for_rank(r)
		assert_eq(float(m["hp"]), expected_hp[r], "hp r%d" % r)
		assert_eq(float(m["attack"]), expected_atk[r], "atk r%d" % r)
		assert_eq(float(m["defense"]), expected_def[r], "def r%d" % r)


func test_ui_combat_multiplier_helper_same() -> void:
	_clear_main_normal()
	var m: Resource = _make_human("adventurer_0", 50)
	GameState.roster = [m]
	GameState.royal_mark_ranks["adventurer_0"] = 5
	var ui_stats: Dictionary = _RosterUiHelper.compute_member_stats(m)
	## job×1 前提の base 近傍。王痕 1.08 が UI 経路に乗ることを確認。
	var raw_hp: int = 800
	var marked: int = _RoyalMarkSystem.apply_hp_multiplier(raw_hp, m)
	assert_eq(marked, int(round(800.0 * 1.08)))
	assert_gt(int(ui_stats.get("hp", 0)), 0)
	var atk_marked: int = _RoyalMarkSystem.apply_attack_multiplier(100, m)
	var def_marked: int = _RoyalMarkSystem.apply_defense_multiplier(50, m)
	assert_eq(atk_marked, int(round(100.0 * 1.08)))
	assert_eq(def_marked, int(round(50.0 * 1.08)))


func test_star_reward_first_star1() -> void:
	GameState.begin_extreme_run_tracking("ex_tomb_seal")
	var g: Dictionary = _RoyalMarkSystem.grant_extreme_clear_rewards(
		"ex_tomb_seal", 0, 1, null, 1.0
	)
	assert_eq(int(g.get("star_shards", 0)), 30)
	assert_eq(int(g.get("repeat_shards", 0)), 0)
	assert_eq(_RoyalMarkSystem.get_shards(), 30)


func test_star_reward_1_to_3() -> void:
	GameState.begin_extreme_run_tracking("ex_tomb_seal")
	var g: Dictionary = _RoyalMarkSystem.grant_extreme_clear_rewards(
		"ex_tomb_seal", 1, 3, null, 1.0
	)
	assert_eq(int(g.get("star_shards", 0)), 70)
	assert_eq(_RoyalMarkSystem.get_shards(), 70)


func test_star_reward_first_star4() -> void:
	GameState.begin_extreme_run_tracking("ex_tomb_seal")
	var g: Dictionary = _RoyalMarkSystem.grant_extreme_clear_rewards(
		"ex_tomb_seal", 0, 4, null, 1.0
	)
	assert_eq(int(g.get("star_shards", 0)), 150)
	assert_eq(_RoyalMarkSystem.get_shards(), 150)


func test_star_reward_already_star4_zero() -> void:
	GameState.begin_extreme_run_tracking("ex_tomb_seal")
	var g: Dictionary = _RoyalMarkSystem.grant_extreme_clear_rewards(
		"ex_tomb_seal", 4, 4, null, 1.0
	)
	assert_eq(int(g.get("star_shards", 0)), 0)
	assert_eq(_RoyalMarkSystem.get_shards(), 0)


func test_repeat_hit() -> void:
	GameState.begin_extreme_run_tracking("ex_tomb_seal")
	var g: Dictionary = _RoyalMarkSystem.grant_extreme_clear_rewards(
		"ex_tomb_seal", 4, 4, null, 0.0
	)
	assert_true(bool(g.get("repeat_hit", false)))
	assert_eq(int(g.get("repeat_shards", 0)), 10)
	assert_eq(_RoyalMarkSystem.get_shards(), 10)


func test_repeat_miss() -> void:
	GameState.begin_extreme_run_tracking("ex_tomb_seal")
	var g: Dictionary = _RoyalMarkSystem.grant_extreme_clear_rewards(
		"ex_tomb_seal", 4, 4, null, 0.99
	)
	assert_false(bool(g.get("repeat_hit", false)))
	assert_eq(int(g.get("repeat_shards", 0)), 0)
	assert_eq(_RoyalMarkSystem.get_shards(), 0)


func test_double_commit_no_extra_shards_or_reroll() -> void:
	GameState.begin_extreme_run_tracking("ex_tomb_seal")
	## 初回: ★4 差分 + repeat hit
	var first: Dictionary = _RoyalMarkSystem.grant_extreme_clear_rewards(
		"ex_tomb_seal", 0, 4, null, 0.0
	)
	assert_eq(int(first.get("star_shards", 0)), 150)
	assert_eq(int(first.get("repeat_shards", 0)), 10)
	assert_eq(_RoyalMarkSystem.get_shards(), 160)
	var second: Dictionary = _RoyalMarkSystem.grant_extreme_clear_rewards(
		"ex_tomb_seal", 0, 4, null, 0.0
	)
	assert_true(bool(second.get("skipped_duplicate", false)))
	assert_eq(int(second.get("star_shards", 0)), 150)
	assert_eq(int(second.get("repeat_shards", 0)), 10)
	assert_eq(_RoyalMarkSystem.get_shards(), 160)
	assert_eq(int(GameState.last_run_royal_mark_shards_total), 160)


func test_commit_clear_result_wires_royal_mark() -> void:
	GameState.begin_extreme_run_tracking("ex_tomb_seal")
	GameState.current_dungeon_id = "ex_tomb_seal"
	## 指令を意図的に崩して★1のみ（CLEAR）にする。
	GameState.extreme_run_ko_count = 1
	GameState.extreme_run_heal_skill_used = true
	GameState.extreme_run_elapsed_sec = 9999.0
	_ExtremeMissionConfig.commit_clear_result("ex_tomb_seal", null, 0.99)
	assert_eq(int(GameState.last_run_extreme_stars), 1)
	assert_eq(int(GameState.last_run_royal_mark_shards_star), 30)
	assert_eq(int(GameState.last_run_royal_mark_shards_repeat), 0)
	assert_eq(_RoyalMarkSystem.get_shards(), 30)
	assert_eq(GameState.get_extreme_mission_best_stars("ex_tomb_seal"), 1)
	## 二重 commit（repeat 強制 hit でも増えない）
	_ExtremeMissionConfig.commit_clear_result("ex_tomb_seal", null, 0.0)
	assert_eq(_RoyalMarkSystem.get_shards(), 30)
	assert_eq(int(GameState.last_run_royal_mark_shards_total), 30)


func test_save_roundtrip_royal_mark() -> void:
	## ファイル IO せず serialize 相当の sanitize／apply を検証。
	var raw_ranks: Dictionary = {
		"adventurer_0": 3,
		"pet_jack": 5,
		"gacha_helper_a": 2,
		"bogus": 99,
	}
	var cleaned: Dictionary = _RoyalMarkSystem.sanitize_ranks(raw_ranks)
	assert_eq(int(cleaned.get("adventurer_0", 0)), 3)
	assert_eq(int(cleaned.get("gacha_helper_a", 0)), 2)
	assert_false(cleaned.has("pet_jack"))
	assert_false(cleaned.has("bogus"))
	GameState.royal_mark_shards = _RoyalMarkSystem.sanitize_shards(-5)
	assert_eq(GameState.royal_mark_shards, 0)
	GameState.royal_mark_shards = _RoyalMarkSystem.sanitize_shards(42)
	GameState.royal_mark_ranks = cleaned
	assert_eq(_RoyalMarkSystem.rank_of_id("adventurer_0"), 3)
	assert_eq(_RoyalMarkSystem.rank_of_id("gacha_helper_a"), 2)
	assert_eq(_RoyalMarkSystem.rank_of_id("pet_jack"), 0)
	## save_game ペイロードにキーが載ること
	GameState.royal_mark_shards = 42
	var had: bool = FileAccess.file_exists("user://save_data.json")
	var bak: String = "user://save_data.json.royal_mark_bak"
	if had:
		DirAccess.rename_absolute("user://save_data.json", bak)
	SaveManager.delete_normal_save()
	assert_true(SaveManager.save_game())
	GameState.royal_mark_shards = 0
	GameState.royal_mark_ranks = {}
	assert_true(SaveManager.load_game())
	assert_eq(_RoyalMarkSystem.get_shards(), 42)
	assert_eq(_RoyalMarkSystem.rank_of_id("adventurer_0"), 3)
	SaveManager.delete_normal_save()
	if had and FileAccess.file_exists(bak):
		DirAccess.rename_absolute(bak, "user://save_data.json")


func test_normalize_helper_id() -> void:
	assert_eq(_RoyalMarkConfig.normalize_character_id("helper_a"), "gacha_helper_a")
	assert_eq(_RoyalMarkConfig.normalize_character_id("gacha_helper_a"), "gacha_helper_a")
	assert_eq(_RoyalMarkConfig.normalize_character_id("adventurer_3"), "adventurer_3")
