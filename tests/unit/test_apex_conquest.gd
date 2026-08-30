extends GutTest

## P3-DG-APEX-REDEFINE-001 — 征討パイロット（地図なき主／天望の塔）


func test_north_reach_conquest_data() -> void:
	var data: Resource = DataRegistry.get_dungeon_data(Constants.NORTH_REACH_DUNGEON_ID)
	assert_not_null(data)
	assert_eq(str(data.route_type), "apex")
	assert_eq(int(data.floor_count), 20)
	assert_eq(str(data.boss_id), "albark")
	assert_eq(str(data.display_name), "地図なき主　征討")
	assert_eq(str(data.favored_element), "holy")
	assert_true(bool(data.disable_wandering))
	assert_eq(str(data.unlock_after_dungeon_id), "frostridge")
	assert_true("rock_bison" in data.enemy_pool)
	assert_true("greios" in data.elite_pool)


func test_apex_conquest_playable_helpers() -> void:
	assert_true(Constants.is_apex_conquest_playable("north_reach"))
	assert_false(Constants.is_apex_conquest_playable("thunder_peak"))
	assert_true(Constants.is_playable_dungeon("north_reach", "apex"))
	assert_false(Constants.is_playable_dungeon("thunder_peak", "apex"))
	assert_eq(Constants.is_playable_dungeon_route("apex"), Constants.SUB_DUNGEONS_PLAYABLE)


func test_conquest_always_open_and_unlock() -> void:
	const _Schedule := preload("res://scripts/dungeon/EventDungeonSchedule.gd")
	const _DungeonTierConfig := preload("res://scripts/dungeon/DungeonTierConfig.gd")
	assert_true(_Schedule.is_open_now("north_reach"))
	assert_eq(_Schedule.open_schedule_label("north_reach"), "常設")
	GameState.debug_full_unlock = false
	GameState.dungeon_progress.clear()
	GameState.stage_progress.clear()
	assert_false(GameState.is_dungeon_unlocked("north_reach"))
	GameState.mark_stage_cleared("frostridge_5_5", _DungeonTierConfig.TIER_NORMAL)
	assert_true(GameState.is_dungeon_unlocked("north_reach"))


func test_other_apex_still_omitted() -> void:
	GameState.debug_full_unlock = false
	GameState.dungeon_progress.clear()
	GameState.stage_progress.clear()
	assert_false(GameState.is_dungeon_unlocked("thunder_peak"))
	assert_false(GameState.is_dungeon_unlocked("blackshore_abyss"))


func test_north_reach_enemy_pool_ids() -> void:
	var data: Resource = DataRegistry.get_dungeon_data(Constants.NORTH_REACH_DUNGEON_ID)
	assert_true("rock_bison" in data.enemy_pool)
	assert_true("greios" in data.elite_pool)
	assert_false("sepia_hound" in data.enemy_pool)


func test_north_reach_dedicated_banner_and_icon() -> void:
	const _BiomeBannerHelper := preload("res://scripts/ui/BiomeBannerHelper.gd")
	var ban: String = _BiomeBannerHelper.resolve_path("north_reach")
	assert_eq(ban, "res://assets/ui/dungeon/BAN_DG_NorthReach.png")
	assert_true(FileAccess.file_exists(ban))
	var ico: String = str(IconPaths.ICON_MAP.get("dungeon:north_reach", ""))
	assert_eq(ico, "res://assets/dungeon/north_reach/ICO_DG_NorthReach.png")
	assert_true(FileAccess.file_exists(ico))
	## 境界廊流用を残さない
	assert_false(ban.contains("ValgardBoundary"))
	assert_false(ico.contains("ValgardBoundary"))
