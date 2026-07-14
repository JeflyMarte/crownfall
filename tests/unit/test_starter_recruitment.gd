extends GutTest

## P3-STORY-STARTER-001 — 開始1人＋章クリア加入。

const _StarterRecruitment = preload("res://scripts/roster/StarterRecruitment.gd")
const _DungeonTierConfig = preload("res://scripts/dungeon/DungeonTierConfig.gd")


func before_each() -> void:
	# GUT シードを崩してストーリー経路を単体検証する
	GameState.roster.clear()
	GameState.party_members.clear()
	GameState.starter_unlocked_ids.clear()
	GameState.starter_pick_pending = true
	GameState.stage_progress.clear()
	GameState.last_run_starter_recruited_id = ""
	GameState.last_run_starter_recruited_name = ""
	GameState.inventory.clear()
	GameState.armor_inventory.clear()
	GameState.accessory_inventory.clear()


func after_each() -> void:
	GameState.seed_all_starters_unlocked()


func test_select_starting_sets_single_roster() -> void:
	assert_true(GameState.select_starting_adventurer("adventurer_0"))
	assert_false(GameState.starter_pick_pending)
	assert_eq(GameState.roster.size(), 1)
	assert_eq(str(GameState.roster[0].id), "adventurer_0")
	assert_true(GameState.is_starter_unlocked("adventurer_0"))
	assert_false(GameState.is_starter_unlocked("adventurer_1"))


func test_ensure_does_not_force_locked_starters() -> void:
	GameState.select_starting_adventurer("adventurer_2")
	GameState.ensure_base_roster_complete()
	assert_eq(GameState.roster.size(), 1)
	assert_eq(str(GameState.roster[0].id), "adventurer_2")


func test_chapter5_normal_recruits() -> void:
	GameState.select_starting_adventurer("adventurer_0")
	assert_true(
		_StarterRecruitment.is_recruit_eligible_stage(
			"mourngate_1_5", _DungeonTierConfig.TIER_NORMAL
		)
	)
	assert_false(
		_StarterRecruitment.is_recruit_eligible_stage(
			"mourngate_1_5", _DungeonTierConfig.TIER_HARD
		)
	)
	GameState.mark_stage_cleared("mourngate_1_5", _DungeonTierConfig.TIER_NORMAL)
	assert_eq(GameState.roster.size(), 2)
	assert_false(GameState.last_run_starter_recruited_name.is_empty())


func test_beta_extra_chapters_2_to_4() -> void:
	GameState.select_starting_adventurer("adventurer_0")
	assert_true(
		_StarterRecruitment.is_recruit_eligible_stage(
			"mourngate_1_2", _DungeonTierConfig.TIER_NORMAL
		)
	)
	GameState.mark_stage_cleared("mourngate_1_2", _DungeonTierConfig.TIER_NORMAL)
	assert_eq(GameState.roster.size(), 2)
	# 二重クリアでは増えない
	GameState.mark_stage_cleared("mourngate_1_2", _DungeonTierConfig.TIER_NORMAL)
	assert_eq(GameState.roster.size(), 2)


func test_old_save_migration_unlocks_present_starters() -> void:
	for def: Variant in GameState.BASE_ROSTER_DEFS:
		GameState.roster.append(GameState._create_base_adventurer(def))
	GameState.starter_unlocked_ids.clear()
	GameState.migrate_starter_unlock_state()
	assert_eq(GameState.starter_unlocked_ids.size(), 5)
	assert_false(GameState.starter_pick_pending)
