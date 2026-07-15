extends GutTest
## P3-AUDIO-BGM-001 — BGM カタログと AudioManager。

const _BgmCatalog := preload("res://scripts/audio/BgmCatalog.gd")

const REQUIRED_IDS: Array[String] = [
	_BgmCatalog.ID_TITLE,
	_BgmCatalog.ID_HUB,
	_BgmCatalog.ID_DUNGEON_EXPLORE,
	_BgmCatalog.ID_BATTLE,
	_BgmCatalog.ID_BOSS,
	_BgmCatalog.ID_RESULT,
]


func test_required_bgm_files_exist() -> void:
	for bgm_id in REQUIRED_IDS:
		var path: String = _BgmCatalog.path_for(bgm_id)
		assert_false(path.is_empty(), bgm_id)
		assert_true(FileAccess.file_exists(path), path)


func test_explore_is_registered() -> void:
	assert_true(_BgmCatalog.is_available(_BgmCatalog.ID_DUNGEON_EXPLORE))


func test_audio_manager_play_bgm_does_not_crash() -> void:
	assert_not_null(AudioManager)
	AudioManager.play_bgm(_BgmCatalog.ID_HUB)
	assert_eq(AudioManager.current_bgm_id(), _BgmCatalog.ID_HUB)
	AudioManager.play_bgm(_BgmCatalog.ID_DUNGEON_EXPLORE)
	assert_eq(AudioManager.current_bgm_id(), _BgmCatalog.ID_DUNGEON_EXPLORE)
	AudioManager.stop_bgm()
	assert_eq(AudioManager.current_bgm_id(), "")


func test_play_unknown_bgm_is_noop() -> void:
	AudioManager.stop_bgm()
	AudioManager.play_bgm("not_a_real_bgm")
	assert_eq(AudioManager.current_bgm_id(), "")
