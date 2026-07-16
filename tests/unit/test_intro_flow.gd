extends GutTest
## P3-INTRO-001/002 — 導入文案・隊長名設定・初期隊員選択・アセット存在。

const _IntroLoreContent = preload("res://scripts/intro/IntroLoreContent.gd")
const _IntroUiAssets = preload("res://scripts/intro/IntroUiAssets.gd")
const _CommanderProfile = preload("res://scripts/commander/CommanderProfile.gd")


func before_each() -> void:
	GameState.reset_for_new_game()


func test_lore_has_six_panels_and_three_nina_lines() -> void:
	assert_eq(_IntroLoreContent.PANELS.size(), 6)
	assert_eq(_IntroLoreContent.NINA_LINES.size(), 3)
	assert_true(not _IntroLoreContent.PANELS[0].is_empty())


func test_intro_art_assets_exist() -> void:
	# 初回 import 前でもディスク上の存在を正とする（ResourceLoader.exists は .import 依存）。
	for path: String in [
		_IntroUiAssets.BG_LORE,
		_IntroUiAssets.BG_NAME,
		_IntroUiAssets.BG_STARTER,
		_IntroUiAssets.NINA_PORTRAIT,
		_IntroUiAssets.STARTER_CARD_FRAME,
	]:
		assert_true(FileAccess.file_exists(path), path)


func test_apply_intro_commander_name() -> void:
	assert_true(_CommanderProfile.can_edit_name())
	assert_true(GameState.apply_intro_commander_name("アステル"))
	assert_eq(_CommanderProfile.get_commander_name(), "アステル")
	assert_false(GameState.apply_intro_commander_name("   "))


func test_select_intro_starter_unlocks_one() -> void:
	## P3-STORY-STARTER-001: 選んだ1人のみ解放。他は章クリアで加入。
	assert_true(GameState.select_intro_starter("adventurer_3"))
	assert_eq(str(GameState.party_members[0].id), "adventurer_3")
	assert_eq(GameState.roster.size(), 1)
	assert_eq(str(GameState.roster[0].id), "adventurer_3")
	assert_false(GameState.needs_starter_pick())
