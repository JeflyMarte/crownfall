extends GutTest
## P3-INTRO-001/002 / SCROLL-001 — 導入文案・自動クロール・隊長名・初期隊員・アセット。

const _IntroLoreContent = preload("res://scripts/intro/IntroLoreContent.gd")
const _IntroUiAssets = preload("res://scripts/intro/IntroUiAssets.gd")
const _IntroLoreSceneScript = preload("res://scripts/intro/IntroLoreScene.gd")
const _IntroNinaSceneScript = preload("res://scripts/intro/IntroNinaScene.gd")
const _CommanderProfile = preload("res://scripts/commander/CommanderProfile.gd")


func before_each() -> void:
	GameState.reset_for_new_game()


func test_lore_has_six_panels_and_three_nina_lines() -> void:
	assert_eq(_IntroLoreContent.PANELS.size(), 6)
	assert_eq(_IntroLoreContent.NINA_LINES.size(), 3)
	assert_true(not _IntroLoreContent.PANELS[0].is_empty())


func test_lore_auto_crawl_params() -> void:
	## 案A: 自動クロール速度・開始遅延・加速倍率が妥当域。
	assert_gt(_IntroLoreSceneScript.CRAWL_SPEED_PX_PER_SEC, 20.0)
	assert_lt(_IntroLoreSceneScript.CRAWL_SPEED_PX_PER_SEC, 120.0)
	assert_gt(_IntroLoreSceneScript.CRAWL_START_DELAY_SEC, 0.0)
	assert_lte(_IntroLoreSceneScript.CRAWL_START_DELAY_SEC, 2.0)
	assert_gt(_IntroLoreSceneScript.CRAWL_BOOST_MULT, 1.0)
	assert_gt(_IntroLoreSceneScript.FADE_BAND_PX, 24.0)
	assert_lt(_IntroLoreSceneScript.PANEL_DWELL_SPEED_MULT, 1.0)


func test_nina_typewriter_interval() -> void:
	## ドラクエ風文字送りの間隔が妥当域。
	assert_gt(_IntroNinaSceneScript.CHAR_INTERVAL_SEC, 0.01)
	assert_lt(_IntroNinaSceneScript.CHAR_INTERVAL_SEC, 0.2)


func test_starter_jobs_have_one_line_blurb() -> void:
	## 隊員選択カード用に、初期5職すべて一行説明を持つ。
	for def: Variant in GameState.BASE_ROSTER_DEFS:
		var job_id: String = str(def["job"])
		var job_data: Resource = DataRegistry.get_job_data(job_id)
		assert_true(job_data != null, job_id)
		var desc: String = str(job_data.description).strip_edges()
		assert_true(not desc.is_empty(), job_id)
		assert_true(not desc.contains("将来実装"), job_id)
		assert_true(desc.ends_with("。"), "%s は句点で終わる" % job_id)


func test_gacha_origin_notes_end_with_period() -> void:
	for helper in DataRegistry.get_all_gacha_helper_data():
		if helper == null:
			continue
		var note: String = str(helper.origin_note).strip_edges()
		if note.is_empty():
			continue
		assert_true(note.ends_with("。"), "%s origin_note" % str(helper.id))


func test_battle_log_font_is_readable_body_small() -> void:
	assert_eq(UiTypography.SIZE_LOG, UiTypography.SIZE_BODY_SMALL)
	assert_lt(UiTypography.SIZE_LOG, UiTypography.SIZE_BODY)


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
