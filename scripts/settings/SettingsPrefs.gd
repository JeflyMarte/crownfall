class_name SettingsPrefs
extends RefCounted

## プレイヤー設定（セーブと分離・`user://settings.cfg`）。

const PATH: String = "user://settings.cfg"
const SECTION: String = "settings"

const KEY_MASTER: String = "master_volume"
const KEY_BGM: String = "bgm_volume"
const KEY_SFX: String = "sfx_volume"
const KEY_MUTED: String = "muted"
const KEY_COMBAT_SPEED: String = "combat_speed"
const KEY_DAMAGE_NUMBERS: String = "show_damage_numbers"
const KEY_BATTLE_LOG: String = "show_battle_log"
const KEY_VIBRATION: String = "vibration_enabled"

const BUS_MASTER: String = "Master"
const BUS_BGM: String = "BGM"
const BUS_SFX: String = "SFX"

## DungeonScene の SPEED_MULT_* と揃える（×1 / ×1.5 の2択）。
const SPEED_X1: float = 1.0
const SPEED_X15: float = 1.5

const SPEED_ID_X1: String = "x1"
const SPEED_ID_X15: String = "x1_5"

static var _loaded: bool = false
static var _master: float = 1.0
static var _bgm: float = 1.0
static var _sfx: float = 1.0
static var _muted: bool = false
static var _combat_speed_id: String = SPEED_ID_X1
static var _show_damage_numbers: bool = true
static var _show_battle_log: bool = true
static var _vibration_enabled: bool = true


static func ensure_loaded() -> void:
	if _loaded:
		return
	load_from_disk()
	ensure_audio_buses()
	apply_audio()
	_loaded = true


static func load_from_disk() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		_reset_defaults()
		return
	_master = clampf(float(cfg.get_value(SECTION, KEY_MASTER, 1.0)), 0.0, 1.0)
	_bgm = clampf(float(cfg.get_value(SECTION, KEY_BGM, 1.0)), 0.0, 1.0)
	_sfx = clampf(float(cfg.get_value(SECTION, KEY_SFX, 1.0)), 0.0, 1.0)
	_muted = bool(cfg.get_value(SECTION, KEY_MUTED, false))
	_combat_speed_id = _normalize_speed_id(str(cfg.get_value(SECTION, KEY_COMBAT_SPEED, SPEED_ID_X1)))
	_show_damage_numbers = bool(cfg.get_value(SECTION, KEY_DAMAGE_NUMBERS, true))
	_show_battle_log = bool(cfg.get_value(SECTION, KEY_BATTLE_LOG, true))
	_vibration_enabled = bool(cfg.get_value(SECTION, KEY_VIBRATION, true))


static func save_to_disk() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(SECTION, KEY_MASTER, _master)
	cfg.set_value(SECTION, KEY_BGM, _bgm)
	cfg.set_value(SECTION, KEY_SFX, _sfx)
	cfg.set_value(SECTION, KEY_MUTED, _muted)
	cfg.set_value(SECTION, KEY_COMBAT_SPEED, _combat_speed_id)
	cfg.set_value(SECTION, KEY_DAMAGE_NUMBERS, _show_damage_numbers)
	cfg.set_value(SECTION, KEY_BATTLE_LOG, _show_battle_log)
	cfg.set_value(SECTION, KEY_VIBRATION, _vibration_enabled)
	cfg.save(PATH)


static func _reset_defaults() -> void:
	_master = 1.0
	_bgm = 1.0
	_sfx = 1.0
	_muted = false
	_combat_speed_id = SPEED_ID_X1
	_show_damage_numbers = true
	_show_battle_log = true
	_vibration_enabled = true


static func ensure_audio_buses() -> void:
	_ensure_named_bus(BUS_BGM)
	_ensure_named_bus(BUS_SFX)


static func _ensure_named_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var idx: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, BUS_MASTER)


static func apply_audio() -> void:
	ensure_audio_buses()
	_set_bus_linear(BUS_MASTER, _master)
	_set_bus_linear(BUS_BGM, _bgm)
	_set_bus_linear(BUS_SFX, _sfx)
	var master_idx: int = AudioServer.get_bus_index(BUS_MASTER)
	if master_idx >= 0:
		AudioServer.set_bus_mute(master_idx, _muted)


static func _set_bus_linear(bus_name: String, linear: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	var v: float = clampf(linear, 0.0, 1.0)
	if v <= 0.0001:
		AudioServer.set_bus_volume_db(idx, -80.0)
	else:
		AudioServer.set_bus_volume_db(idx, linear_to_db(v))


static func get_master_volume() -> float:
	ensure_loaded()
	return _master


static func get_bgm_volume() -> float:
	ensure_loaded()
	return _bgm


static func get_sfx_volume() -> float:
	ensure_loaded()
	return _sfx


static func is_muted() -> bool:
	ensure_loaded()
	return _muted


static func set_master_volume(v: float) -> void:
	ensure_loaded()
	_master = clampf(v, 0.0, 1.0)
	apply_audio()
	save_to_disk()


static func set_bgm_volume(v: float) -> void:
	ensure_loaded()
	_bgm = clampf(v, 0.0, 1.0)
	apply_audio()
	save_to_disk()


static func set_sfx_volume(v: float) -> void:
	ensure_loaded()
	_sfx = clampf(v, 0.0, 1.0)
	apply_audio()
	save_to_disk()


static func set_muted(v: bool) -> void:
	ensure_loaded()
	_muted = v
	apply_audio()
	save_to_disk()


static func get_combat_speed_id() -> String:
	ensure_loaded()
	return _combat_speed_id


static func get_combat_speed_mult() -> float:
	ensure_loaded()
	return speed_mult_for_id(_combat_speed_id)


static func set_combat_speed_id(speed_id: String) -> void:
	ensure_loaded()
	_combat_speed_id = _normalize_speed_id(speed_id)
	save_to_disk()


static func set_combat_speed_mult(mult: float) -> void:
	ensure_loaded()
	_combat_speed_id = speed_id_for_mult(mult)
	save_to_disk()


static func show_damage_numbers() -> bool:
	ensure_loaded()
	return _show_damage_numbers


static func set_show_damage_numbers(v: bool) -> void:
	ensure_loaded()
	_show_damage_numbers = v
	save_to_disk()


static func show_battle_log() -> bool:
	ensure_loaded()
	return _show_battle_log


static func set_show_battle_log(v: bool) -> void:
	ensure_loaded()
	_show_battle_log = v
	save_to_disk()


static func is_vibration_enabled() -> bool:
	ensure_loaded()
	return _vibration_enabled


static func set_vibration_enabled(v: bool) -> void:
	ensure_loaded()
	_vibration_enabled = v
	save_to_disk()


static func speed_mult_for_id(speed_id: String) -> float:
	match _normalize_speed_id(speed_id):
		SPEED_ID_X15:
			return SPEED_X15
		_:
			return SPEED_X1


static func speed_id_for_mult(mult: float) -> String:
	## 旧 ×2(1.5) / 旧 ×1.5(1.125) / 新 ×1.5 をまとめて ×1.5 扱い。
	if mult >= 1.25:
		return SPEED_ID_X15
	return SPEED_ID_X1


static func speed_label(speed_id: String) -> String:
	match _normalize_speed_id(speed_id):
		SPEED_ID_X15:
			return "×1.5"
		_:
			return "×1"


static func _normalize_speed_id(speed_id: String) -> String:
	match speed_id:
		SPEED_ID_X15, "x1.5", "1.5", "medium", "x2", "2", "fast":
			## 旧 ×2 設定は ×1.5 へ統合。
			return SPEED_ID_X15
		_:
			return SPEED_ID_X1

static func app_version_text() -> String:
	return str(ProjectSettings.get_setting("application/config/version", "0.1.0"))


static func save_status_text() -> String:
	if FileAccess.file_exists(SaveManager.SAVE_PATH):
		return "セーブデータあり"
	return "セーブデータなし"
