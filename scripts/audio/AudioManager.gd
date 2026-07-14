extends Node

## 音声再生の単一入口。SE は SFX バス、BGM は BGM バス（SettingsPrefs 音量連動）。

const _SettingsPrefs := preload("res://scripts/settings/SettingsPrefs.gd")
const _SfxCatalog := preload("res://scripts/audio/SfxCatalog.gd")
const _BgmCatalog := preload("res://scripts/audio/BgmCatalog.gd")

const SFX_POOL_SIZE: int = 8
const DEFAULT_SFX_COOLDOWN_SEC: float = 0.045

var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_rr: int = 0
var _stream_cache: Dictionary = {}
var _sfx_cooldown_until: Dictionary = {}
var _bgm_player: AudioStreamPlayer = null
var _current_bgm_id: String = ""
var _bgm_stream_cache: Dictionary = {}


func _ready() -> void:
	_SettingsPrefs.ensure_loaded()
	for _i: int in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = _SettingsPrefs.BUS_SFX
		add_child(p)
		_sfx_players.append(p)
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = _SettingsPrefs.BUS_BGM
	add_child(_bgm_player)


func play_sfx(sfx_id: String, pitch_scale: float = 1.0, cooldown_sec: float = DEFAULT_SFX_COOLDOWN_SEC) -> void:
	if sfx_id.is_empty():
		return
	var now_ms: int = Time.get_ticks_msec()
	if cooldown_sec > 0.0:
		var until_ms: int = int(_sfx_cooldown_until.get(sfx_id, 0))
		if now_ms < until_ms:
			return
		_sfx_cooldown_until[sfx_id] = now_ms + int(cooldown_sec * 1000.0)
	var stream: AudioStream = _load_sfx_stream(sfx_id)
	if stream == null:
		return
	if _sfx_players.is_empty():
		return
	var player: AudioStreamPlayer = _sfx_players[_sfx_rr % _sfx_players.size()]
	_sfx_rr = (_sfx_rr + 1) % _sfx_players.size()
	player.stream = stream
	player.pitch_scale = clampf(pitch_scale, 0.5, 2.0)
	player.play()


func play_bgm(bgm_id: String, path: String = "") -> void:
	if bgm_id.is_empty():
		return
	if path.is_empty():
		path = _BgmCatalog.path_for(bgm_id)
	if path.is_empty():
		return
	if _current_bgm_id == bgm_id and _bgm_player != null and _bgm_player.playing:
		return
	var stream: AudioStream = _load_bgm_stream(bgm_id, path)
	if stream == null or _bgm_player == null:
		return
	_bgm_player.stream = stream
	_current_bgm_id = bgm_id
	_bgm_player.play()


func stop_bgm() -> void:
	if _bgm_player != null and _bgm_player.playing:
		_bgm_player.stop()
	_current_bgm_id = ""


func current_bgm_id() -> String:
	return _current_bgm_id


func _load_sfx_stream(sfx_id: String) -> AudioStream:
	if _stream_cache.has(sfx_id):
		return _stream_cache[sfx_id] as AudioStream
	var path: String = _SfxCatalog.path_for(sfx_id)
	if path.is_empty() or not ResourceLoader.exists(path):
		if path.is_empty() or not FileAccess.file_exists(path):
			return null
	var stream: AudioStream = load(path) as AudioStream
	if stream != null:
		_stream_cache[sfx_id] = stream
	return stream


func _load_bgm_stream(bgm_id: String, path: String) -> AudioStream:
	if _bgm_stream_cache.has(bgm_id):
		return _bgm_stream_cache[bgm_id] as AudioStream
	if not ResourceLoader.exists(path) and not FileAccess.file_exists(path):
		return null
	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		return null
	_apply_bgm_loop(stream, _BgmCatalog.should_loop(bgm_id))
	_bgm_stream_cache[bgm_id] = stream
	return stream


func _apply_bgm_loop(stream: AudioStream, do_loop: bool) -> void:
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = do_loop
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = do_loop
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = (
			AudioStreamWAV.LOOP_FORWARD if do_loop else AudioStreamWAV.LOOP_DISABLED
		)
