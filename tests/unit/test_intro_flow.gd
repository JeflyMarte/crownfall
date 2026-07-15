extends GutTest
## P3-INTRO-001 — 導入文案・隊長名設定・初期隊員先頭化。

const _IntroLoreContent = preload("res://scripts/intro/IntroLoreContent.gd")
const _CommanderProfile = preload("res://scripts/commander/CommanderProfile.gd")


func before_each() -> void:
	GameState.reset_for_new_game()


func test_lore_has_six_panels_and_three_nina_lines() -> void:
	assert_eq(_IntroLoreContent.PANELS.size(), 6)
	assert_eq(_IntroLoreContent.NINA_LINES.size(), 3)
	assert_true(not _IntroLoreContent.PANELS[0].is_empty())


func test_set_name_for_intro_bypasses_rank_lock() -> void:
	assert_eq(_CommanderProfile.current_rank(), "D")
	assert_false(_CommanderProfile.can_edit_name())
	assert_true(GameState.apply_intro_commander_name("アステル"))
	assert_eq(_CommanderProfile.get_commander_name(), "アステル")
	assert_false(GameState.apply_intro_commander_name("   "))


func test_select_intro_starter_puts_member_first() -> void:
	assert_true(GameState.select_intro_starter("adventurer_3"))
	assert_eq(str(GameState.party_members[0].id), "adventurer_3")
	assert_eq(str(GameState.roster[0].id), "adventurer_3")
	assert_eq(GameState.roster.size(), 5)
