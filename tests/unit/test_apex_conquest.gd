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


## P3-DG-APEX-TIER-001 — 征討も降臨同型で N/H/NM 自由選択
func test_north_reach_free_hard_nightmare_tiers() -> void:
	const _DungeonTierConfig := preload("res://scripts/dungeon/DungeonTierConfig.gd")
	GameState.debug_full_unlock = true
	GameState.current_dungeon_tier = _DungeonTierConfig.TIER_NORMAL
	var packed: PackedScene = load("res://scenes/dungeon/DungeonSelectScene.tscn")
	assert_not_null(packed)
	var scene: Control = packed.instantiate()
	add_child_autofree(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	## 征討 Featured 相当へ寄せる（イベント枠・常設）
	scene.set("_featured_dungeon_id", "north_reach")
	scene.set("_expanded_biome_id", "north_reach")
	scene.call("_clamp_selected_tier")
	scene.call("_refresh_tier_tabs")
	var btn_hard: Button = scene.get_node("MainColumn/TabsRow/ButtonHard") as Button
	var btn_nm: Button = scene.get_node("MainColumn/TabsRow/ButtonNightmare") as Button
	assert_not_null(btn_hard)
	assert_not_null(btn_nm)
	assert_false(btn_hard.disabled, "征討 Hard はキャンペーン条件なしで選択可")
	assert_false(btn_nm.disabled, "征討 NM はキャンペーン条件なしで選択可")
	scene.call("_on_tier_pressed", _DungeonTierConfig.TIER_HARD)
	assert_eq(GameState.current_dungeon_tier, _DungeonTierConfig.TIER_HARD)
	scene.call("_on_tier_pressed", _DungeonTierConfig.TIER_NIGHTMARE)
	assert_eq(GameState.current_dungeon_tier, _DungeonTierConfig.TIER_NIGHTMARE)
	## 進入行ラベルは選択難度を反映
	var card: Control = scene.call("_make_event_free_tier_enter_card", "north_reach") as Control
	assert_not_null(card)
	var rich: RichTextLabel = _find_rich_label(card)
	assert_not_null(rich)
	assert_true(str(rich.text).contains("天望の塔"))
	assert_true(str(rich.text).contains("ナイトメア"))
	## 時王も同経路（回帰）
	assert_true(bool(scene.call("_is_event_free_tier_dungeon", "chronos_mausoleum")))
	assert_true(bool(scene.call("_is_event_free_tier_dungeon", "valgard_boundary")))
	assert_true(bool(scene.call("_is_event_free_tier_dungeon", "north_reach")))
	assert_false(bool(scene.call("_is_event_free_tier_dungeon", "golden_nest")))


func _find_rich_label(node: Node) -> RichTextLabel:
	if node is RichTextLabel:
		return node as RichTextLabel
	for child in node.get_children():
		var found: RichTextLabel = _find_rich_label(child)
		if found != null:
			return found
	return null
