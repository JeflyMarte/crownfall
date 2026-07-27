extends GutTest
## P3-AUDIO-SE-001 / SE-002 — SE カタログと AudioManager（Kenney + TomMusic）。

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


func test_heal_buff_debuff_paths() -> void:
	assert_eq(_SfxCatalog.path_for(_SfxCatalog.ID_COMBAT_HEAL), "res://assets/audio/sfx/combat_heal.ogg")
	assert_eq(_SfxCatalog.path_for(_SfxCatalog.ID_COMBAT_BUFF), "res://assets/audio/sfx/combat_buff.ogg")
	assert_eq(_SfxCatalog.path_for(_SfxCatalog.ID_COMBAT_DEBUFF), "res://assets/audio/sfx/combat_debuff.ogg")
	for sfx_id in [_SfxCatalog.ID_COMBAT_HEAL, _SfxCatalog.ID_COMBAT_BUFF, _SfxCatalog.ID_COMBAT_DEBUFF]:
		assert_true(FileAccess.file_exists(_SfxCatalog.path_for(sfx_id)), sfx_id)

	## P3-AUDIO-SE-003 — ガチャ入手 SE は level_up と分離
	var gacha_path: String = _SfxCatalog.path_for(_SfxCatalog.ID_GACHA_REVEAL)
	var level_path: String = _SfxCatalog.path_for(_SfxCatalog.ID_LEVEL_UP)
	assert_eq(gacha_path, "res://assets/audio/sfx/gacha_reveal.ogg")
	assert_ne(gacha_path, level_path)
	assert_true(FileAccess.file_exists(gacha_path))
	assert_true(FileAccess.file_exists(level_path))


func test_weapon_hit_sfx_ids() -> void:
	## P3-UX-COMBAT-VFX-001
	assert_eq(_SfxCatalog.hit_sfx_for_weapon("sword"), _SfxCatalog.ID_COMBAT_HIT)
	assert_eq(_SfxCatalog.hit_sfx_for_weapon("dual_blades"), _SfxCatalog.ID_COMBAT_HIT)
	assert_eq(_SfxCatalog.hit_sfx_for_weapon("bow"), _SfxCatalog.ID_COMBAT_HIT_BOW)
	assert_eq(_SfxCatalog.hit_sfx_for_weapon("staff"), _SfxCatalog.ID_COMBAT_HIT_STAFF)
	assert_eq(_SfxCatalog.hit_sfx_for_weapon(""), _SfxCatalog.ID_COMBAT_HIT)
	for sfx_id in [_SfxCatalog.ID_COMBAT_HIT_BOW, _SfxCatalog.ID_COMBAT_HIT_STAFF]:
		assert_true(FileAccess.file_exists(_SfxCatalog.path_for(sfx_id)), sfx_id)
	## 鼓舞用 buff はヒットと別ファイル
	assert_ne(
		FileAccess.get_file_as_bytes(_SfxCatalog.path_for(_SfxCatalog.ID_COMBAT_BUFF)),
		FileAccess.get_file_as_bytes(_SfxCatalog.path_for(_SfxCatalog.ID_COMBAT_HIT))
	)
