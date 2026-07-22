extends GutTest

const _SettingsPrefs := preload("res://scripts/settings/SettingsPrefs.gd")

var _prev_path_backup: String = ""


func before_each() -> void:
	## テスト isolation: ConfigFile を専用パスへ退避してからリセット。
	_SettingsPrefs._loaded = false
	_SettingsPrefs._reset_defaults()
	if FileAccess.file_exists(_SettingsPrefs.PATH):
		_prev_path_backup = FileAccess.get_file_as_string(_SettingsPrefs.PATH)
		_remove_settings_file()
	else:
		_prev_path_backup = ""


func after_each() -> void:
	_remove_settings_file()
	if not _prev_path_backup.is_empty():
		var f: FileAccess = FileAccess.open(_SettingsPrefs.PATH, FileAccess.WRITE)
		if f != null:
			f.store_string(_prev_path_backup)
			f.close()
	_SettingsPrefs._loaded = false
	_SettingsPrefs.load_from_disk()
	_SettingsPrefs.apply_audio()
	_SettingsPrefs._loaded = true


func _remove_settings_file() -> void:
	if not FileAccess.file_exists(_SettingsPrefs.PATH):
		return
	var dir := DirAccess.open("user://")
	if dir != null:
		dir.remove("settings.cfg")


func test_defaults() -> void:
	_SettingsPrefs.ensure_loaded()
	assert_eq(_SettingsPrefs.get_master_volume(), 1.0)
	assert_eq(_SettingsPrefs.get_combat_speed_id(), _SettingsPrefs.SPEED_ID_X1)
	assert_true(_SettingsPrefs.show_damage_numbers())
	assert_true(_SettingsPrefs.show_battle_log())
	assert_true(_SettingsPrefs.is_vibration_enabled())
	assert_false(_SettingsPrefs.is_muted())


func test_persist_volume_and_toggles() -> void:
	_SettingsPrefs.ensure_loaded()
	_SettingsPrefs.set_master_volume(0.4)
	_SettingsPrefs.set_bgm_volume(0.6)
	_SettingsPrefs.set_sfx_volume(0.2)
	_SettingsPrefs.set_muted(true)
	_SettingsPrefs.set_show_damage_numbers(false)
	_SettingsPrefs.set_show_battle_log(false)
	_SettingsPrefs.set_vibration_enabled(false)
	_SettingsPrefs.set_combat_speed_id(_SettingsPrefs.SPEED_ID_X15)
	_SettingsPrefs._loaded = false
	_SettingsPrefs.ensure_loaded()
	assert_almost_eq(_SettingsPrefs.get_master_volume(), 0.4, 0.001)
	assert_almost_eq(_SettingsPrefs.get_bgm_volume(), 0.6, 0.001)
	assert_almost_eq(_SettingsPrefs.get_sfx_volume(), 0.2, 0.001)
	assert_true(_SettingsPrefs.is_muted())
	assert_false(_SettingsPrefs.show_damage_numbers())
	assert_false(_SettingsPrefs.show_battle_log())
	assert_false(_SettingsPrefs.is_vibration_enabled())
	assert_eq(_SettingsPrefs.get_combat_speed_id(), _SettingsPrefs.SPEED_ID_X15)
	assert_almost_eq(_SettingsPrefs.get_combat_speed_mult(), _SettingsPrefs.SPEED_X15, 0.001)


func test_speed_id_mult_roundtrip() -> void:
	assert_eq(_SettingsPrefs.speed_id_for_mult(_SettingsPrefs.SPEED_X15), _SettingsPrefs.SPEED_ID_X15)
	assert_eq(_SettingsPrefs.speed_mult_for_id(_SettingsPrefs.SPEED_ID_X1), _SettingsPrefs.SPEED_X1)
	assert_almost_eq(_SettingsPrefs.speed_mult_for_id(_SettingsPrefs.SPEED_ID_X1), 1.0, 0.001)
	assert_almost_eq(_SettingsPrefs.speed_mult_for_id(_SettingsPrefs.SPEED_ID_X15), 1.5, 0.001)
	assert_eq(_SettingsPrefs._normalize_speed_id("medium"), _SettingsPrefs.SPEED_ID_X15)
	## 旧 ×2 設定は ×1.5 へ統合。
	assert_eq(_SettingsPrefs._normalize_speed_id("x2"), _SettingsPrefs.SPEED_ID_X15)
	assert_eq(_SettingsPrefs.speed_id_for_mult(1.5), _SettingsPrefs.SPEED_ID_X15)
	assert_eq(_SettingsPrefs.speed_id_for_mult(0.75), _SettingsPrefs.SPEED_ID_X1)


func test_audio_buses_created() -> void:
	_SettingsPrefs.ensure_loaded()
	assert_gte(AudioServer.get_bus_index(_SettingsPrefs.BUS_BGM), 0)
	assert_gte(AudioServer.get_bus_index(_SettingsPrefs.BUS_SFX), 0)


func test_settings_scene_exists() -> void:
	assert_true(ResourceLoader.exists("res://scenes/settings/SettingsScene.tscn"))


func test_side_menu_settings_unlocked() -> void:
	var entry: Dictionary = BottomNavHelper.get_entry_by_id("settings")
	assert_false(entry.is_empty())
	assert_false(bool(entry.get("locked", true)))
