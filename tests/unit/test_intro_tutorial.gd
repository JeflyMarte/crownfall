extends GutTest
## P3-INTRO-TUTORIAL-001 — 導入 0-0 訓練坑。

const _IntroTutorialConfig = preload("res://scripts/intro/IntroTutorialConfig.gd")
const _IntroLoreContent = preload("res://scripts/intro/IntroLoreContent.gd")


func before_each() -> void:
	GameState.reset_for_new_game()


func test_stage_and_dungeon_exist() -> void:
	var dungeon: Resource = DataRegistry.get_dungeon_data(_IntroTutorialConfig.DUNGEON_ID)
	assert_true(dungeon != null)
	assert_eq(str(dungeon.route_type), "tutorial")
	assert_true(bool(dungeon.disable_wandering))
	var stage: Resource = DataRegistry.get_stage_data(_IntroTutorialConfig.STAGE_ID)
	assert_true(stage != null)
	assert_eq(int(stage.biome_index), 0)
	assert_eq(int(stage.chapter_index), 0)
	assert_false(Constants.is_playable_dungeon_route(str(dungeon.route_type)))
	assert_false(GameState.is_dungeon_unlocked(_IntroTutorialConfig.DUNGEON_ID))


func test_pending_flag_after_starter_pick() -> void:
	assert_false(_IntroTutorialConfig.needs_run())
	assert_true(GameState.select_intro_starter("adventurer_0"))
	_IntroTutorialConfig.mark_pending()
	_IntroTutorialConfig.begin_run()
	assert_true(_IntroTutorialConfig.needs_run())
	assert_eq(GameState.current_stage_id, _IntroTutorialConfig.STAGE_ID)
	assert_eq(GameState.current_dungeon_id, _IntroTutorialConfig.DUNGEON_ID)
	assert_eq(GameState.roster.size(), 1)
	var _PetSystem = preload("res://scripts/pets/PetSystem.gd")
	assert_false(_PetSystem.is_starter_pet_granted())


func test_existing_save_without_pending_skips_tutorial() -> void:
	GameState.tutorial_flags["hub_simple_guide_done"] = true
	assert_false(_IntroTutorialConfig.needs_run())


func test_room_sequence_is_combat_treasure_combat() -> void:
	var dc: Node = preload("res://scripts/dungeon/DungeonController.gd").new()
	add_child_autofree(dc)
	dc.start_stage(_IntroTutorialConfig.STAGE_ID)
	assert_eq(dc.room_sequence, _IntroTutorialConfig.room_sequence())
	assert_eq(dc.room_sequence.size(), 3)
	assert_eq(int(dc.room_sequence[0]), Enums.RoomType.COMBAT)
	assert_eq(int(dc.room_sequence[1]), Enums.RoomType.TREASURE)
	assert_eq(int(dc.room_sequence[2]), Enums.RoomType.COMBAT)


func test_tutorial_enemies_are_weak_single_and_do_not_flee() -> void:
	var dc: Node = preload("res://scripts/dungeon/DungeonController.gd").new()
	add_child_autofree(dc)
	dc.start_stage(_IntroTutorialConfig.STAGE_ID)
	var g1: Array[Resource] = dc.pick_combat_enemy_group()
	assert_eq(g1.size(), 1)
	assert_eq(int(g1[0].max_hp), _IntroTutorialConfig.TRAIN_HP)
	assert_eq(int(g1[0].attack), _IntroTutorialConfig.TRAIN_ATK)
	assert_eq(int(g1[0].wander_flee_after_turns), 0)
	assert_false(bool(g1[0].can_swarm))
	assert_eq(g1[0].skill_ids.size(), 0)
	dc.current_room_index = 2
	dc.current_room_type = Enums.RoomType.COMBAT
	var g2: Array[Resource] = dc.pick_combat_enemy_group()
	assert_eq(g2.size(), 1)
	assert_ne(str(g1[0].id), str(g2[0].id))


func test_treasure_gold_only() -> void:
	var dc: Node = preload("res://scripts/dungeon/DungeonController.gd").new()
	add_child_autofree(dc)
	dc.start_stage(_IntroTutorialConfig.STAGE_ID)
	dc.current_room_index = 1
	dc.current_room_type = Enums.RoomType.TREASURE
	var loot: Dictionary = dc.generate_treasure_loot()
	assert_eq(int(loot.get("gold", 0)), _IntroTutorialConfig.TREASURE_GOLD)
	assert_eq(str(loot.get("weapon_id", "")), "")
	assert_eq(str(loot.get("armor_id", "")), "")
	assert_eq(str(loot.get("accessory_id", "")), "")


func test_choice_guide_mentions_auto_select() -> void:
	var page: Dictionary = _IntroTutorialConfig.page_for(_IntroTutorialConfig.STEP_CHOICE)
	var body: String = str(page.get("body", ""))
	assert_true(body.contains("秒"))
	assert_true(body.contains("自動"))


func test_desktop_safe_area_insets_zero_without_simulate() -> void:
	if OS.get_name() == "iOS" or OS.get_name() == "Android":
		pass
		return
	if bool(ProjectSettings.get_setting("crownfall/ui/simulate_mobile_safe_area", false)):
		pending("simulate_mobile_safe_area is ON")
		return
	var helper = preload("res://scripts/ui/SafeAreaHelper.gd")
	assert_eq(helper.top_inset(), 0.0)
	assert_eq(helper.bottom_inset(), 0.0)


func test_nina_lines_setup_training() -> void:
	assert_eq(_IntroLoreContent.NINA_LINES.size(), 3)
	assert_true(str(_IntroLoreContent.NINA_LINES[1]).contains("訓練坑"))


func test_mark_done_clears_pending() -> void:
	_IntroTutorialConfig.mark_pending()
	assert_true(_IntroTutorialConfig.needs_run())
	_IntroTutorialConfig.mark_done()
	assert_false(_IntroTutorialConfig.needs_run())
	assert_true(_IntroTutorialConfig.is_done())
