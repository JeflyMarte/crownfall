extends GutTest
## P3-AUDIO-SE-001 / SE-002 — Kenney SE カタログと AudioManager。

const _SfxCatalog := preload("res://scripts/audio/SfxCatalog.gd")

## P3-AUDIO-SE-002 で配線する ID（カタログ存在の回帰ガード）。
const SE002_WIRED_IDS: Array[String] = [
	_SfxCatalog.ID_COMBAT_SKILL,
	_SfxCatalog.ID_COMBAT_DEATH,
	_SfxCatalog.ID_UI_CANCEL,
	_SfxCatalog.ID_UI_ERROR,
	_SfxCatalog.ID_COMBAT_HIT,
	_SfxCatalog.ID_ROOM_ENTER,
]


func test_all_catalog_files_exist() -> void:
	var ids: Array[String] = _SfxCatalog.all_ids()
	assert_gt(ids.size(), 10)
	for sfx_id in ids:
		var path: String = _SfxCatalog.path_for(sfx_id)
		assert_false(path.is_empty(), sfx_id)
		## headless 初回は .import 前でもディスク上のファイル存在を正とする
		assert_true(FileAccess.file_exists(path), path)


func test_path_for_unknown_is_empty() -> void:
	assert_eq(_SfxCatalog.path_for("not_a_real_sfx"), "")


func test_audio_manager_play_sfx_does_not_crash() -> void:
	assert_not_null(AudioManager)
	AudioManager.play_sfx(_SfxCatalog.ID_UI_CLICK)
	assert_true(true)


func test_se002_wired_ids_in_catalog() -> void:
	for sfx_id in SE002_WIRED_IDS:
		var path: String = _SfxCatalog.path_for(sfx_id)
		assert_false(path.is_empty(), sfx_id)
		assert_true(FileAccess.file_exists(path), path)
		AudioManager.play_sfx(sfx_id)


func test_attribution_doc_exists() -> void:
	assert_true(FileAccess.file_exists("res://assets/audio/sfx/ATTRIBUTION.md"))
