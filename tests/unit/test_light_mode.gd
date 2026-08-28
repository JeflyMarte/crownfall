extends GutTest

## 設定「軽量モード」: 既定オフ・永続・VFX 抑止。

const _SettingsPrefs := preload("res://scripts/settings/SettingsPrefs.gd")
const _CombatVfxManager := preload("res://scripts/combat/CombatVfxManager.gd")

var _prev_path_backup: String = ""


func before_each() -> void:
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


func test_light_mode_default_off() -> void:
	_SettingsPrefs.ensure_loaded()
	if _SettingsPrefs.is_mobile_platform():
		assert_true(_SettingsPrefs.is_light_mode(), "mobile first-run default is light")
	else:
		assert_false(_SettingsPrefs.is_light_mode())


func test_apply_performance_settings_exists() -> void:
	var src: String = FileAccess.get_file_as_string("res://scripts/settings/SettingsPrefs.gd")
	assert_true(src.contains("apply_performance_settings"), "performance apply helper")
	assert_true(src.contains("FPS_MOBILE_LIGHT"), "mobile light fps cap")
	assert_eq(_SettingsPrefs.FPS_MOBILE_NORMAL, 45, "mobile normal fps cap")
	assert_true(src.contains("mobile_throttle_idle_loops"), "mobile idle loop throttle")
	assert_true(src.contains("Engine.max_fps"), "sets max fps")


func test_light_mode_skips_status_auras() -> void:
	_SettingsPrefs.ensure_loaded()
	_SettingsPrefs.set_light_mode(true)
	var anchor := Node2D.new()
	add_child_autofree(anchor)
	var mgr: RefCounted = _CombatVfxManager.new()
	var statuses: Array = [{"effect_id": "ignite", "stacks": 1, "remaining_ticks": 3}]
	mgr.sync_unit_auras("enemy_0", anchor, statuses, true)
	assert_false(anchor.has_node("StatusAuraHost"), "light mode must not spawn aura host")


func test_light_mode_skips_apply_burst_particles() -> void:
	_SettingsPrefs.ensure_loaded()
	_SettingsPrefs.set_light_mode(true)
	var host := Node2D.new()
	add_child_autofree(host)
	var before: int = host.get_child_count()
	var mgr: RefCounted = _CombatVfxManager.new()
	mgr.spawn_apply_burst(host, Vector2(10, 10), "poison")
	assert_eq(host.get_child_count(), before, "light mode must not spawn burst particles")


func test_dungeon_weather_and_band_gate_light_mode() -> void:
	var src: String = FileAccess.get_file_as_string("res://scripts/dungeon/DungeonScene.gd")
	assert_true(src.contains("SettingsPrefs.is_light_mode()"), "DungeonScene gates light mode")
	assert_true(src.contains("_setup_weather_light_static"), "static weather in light mode")
	assert_true(src.contains("_setup_weather_mobile_reduced"), "reduced weather on mobile normal")
	assert_true(src.contains("mobile_throttle_idle_loops"), "mobile idle loop throttle")
	assert_true(src.contains("_play_combat_idle"), "idle freeze helper")
	assert_true(src.contains("_refresh_weather()"), "settings close refreshes weather")
	assert_true(src.contains("play_ultimate_band"), "ultimate band path present")
	assert_true(
		src.contains("not SettingsPrefs.is_light_mode()") and src.contains("play_ultimate_band"),
		"ultimate band gated by light mode"
	)
	assert_true(src.contains("_spawn_combat_clear_confetti"), "clear confetti present")
	assert_true(src.contains("HitVfxPool"), "hit vfx pool wired")
	var settings_src: String = FileAccess.get_file_as_string("res://scripts/settings/SettingsScene.gd")
	assert_true(settings_src.contains("軽量モード"), "settings UI has light mode toggle")
	assert_true(settings_src.contains("45fps"), "settings caption mentions mobile normal fps")
	var overlay_src: String = FileAccess.get_file_as_string("res://scripts/ui/InGameSettingsOverlay.gd")
	assert_true(overlay_src.contains("軽量モード"), "in-game settings has light mode toggle")
	assert_true(overlay_src.contains("45fps"), "overlay caption mentions mobile normal fps")
