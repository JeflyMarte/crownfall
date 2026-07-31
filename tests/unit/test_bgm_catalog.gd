extends GutTest
## P3-AUDIO-BGM-001 — BGM カタログと AudioManager。

const _BgmCatalog := preload("res://scripts/audio/BgmCatalog.gd")

const REQUIRED_IDS: Array[String] = [
	_BgmCatalog.ID_TITLE,
	_BgmCatalog.ID_HUB,
	_BgmCatalog.ID_DUNGEON_EXPLORE,
	_BgmCatalog.ID_MOURNGATE,
	_BgmCatalog.ID_WHISPERWOOD,
	_BgmCatalog.ID_MISTFEN,
	_BgmCatalog.ID_BLACKSHORE,
	_BgmCatalog.ID_FROSTRIDGE,
	_BgmCatalog.ID_BATTLE,
	_BgmCatalog.ID_SHADOW_HUNT,
	_BgmCatalog.ID_EVENT_DUNGEON,
	_BgmCatalog.ID_CHRONOS_MAUSOLEUM,
	_BgmCatalog.ID_CHRONOS_WAVE,
	_BgmCatalog.ID_VALGARD_BOUNDARY,
	_BgmCatalog.ID_VALGARD,
	_BgmCatalog.ID_BOSS,
	_BgmCatalog.ID_FINAL_BOSS,
	_BgmCatalog.ID_RESULT,
	_BgmCatalog.ID_RESULT_DEFEAT,
	_BgmCatalog.ID_INTRODUCTION,
	_BgmCatalog.ID_FORGE,
	_BgmCatalog.ID_SURVEY,
	_BgmCatalog.ID_GACHA,
]


func test_required_bgm_files_exist() -> void:
	for bgm_id in REQUIRED_IDS:
		var path: String = _BgmCatalog.path_for(bgm_id)
		assert_false(path.is_empty(), bgm_id)
		assert_true(FileAccess.file_exists(path), path)


func test_explore_is_registered() -> void:
	assert_true(_BgmCatalog.is_available(_BgmCatalog.ID_DUNGEON_EXPLORE))
	assert_true(_BgmCatalog.is_available(_BgmCatalog.ID_WHISPERWOOD))
	assert_true(_BgmCatalog.is_available(_BgmCatalog.ID_MISTFEN))
	assert_true(_BgmCatalog.is_available(_BgmCatalog.ID_BLACKSHORE))
	assert_true(_BgmCatalog.is_available(_BgmCatalog.ID_FROSTRIDGE))
	assert_true(_BgmCatalog.is_available(_BgmCatalog.ID_FINAL_BOSS))


func test_battle_bgm_for_dungeon_maps_biome() -> void:
	assert_eq(
		_BgmCatalog.battle_bgm_for_dungeon("whisperwood"),
		_BgmCatalog.ID_WHISPERWOOD
	)
	assert_eq(
		_BgmCatalog.battle_bgm_for_dungeon("green_hollow"),
		_BgmCatalog.ID_WHISPERWOOD
	)
	assert_eq(
		_BgmCatalog.battle_bgm_for_dungeon("mistfen"),
		_BgmCatalog.ID_MISTFEN
	)
	assert_eq(
		_BgmCatalog.battle_bgm_for_dungeon("mistfen_depths"),
		_BgmCatalog.ID_MISTFEN
	)
	assert_eq(
		_BgmCatalog.battle_bgm_for_dungeon("blackshore"),
		_BgmCatalog.ID_BLACKSHORE
	)
	assert_eq(
		_BgmCatalog.battle_bgm_for_dungeon("blackshore_abyss"),
		_BgmCatalog.ID_BLACKSHORE
	)
	assert_eq(
		_BgmCatalog.battle_bgm_for_dungeon("frostridge"),
		_BgmCatalog.ID_FROSTRIDGE
	)
	assert_eq(
		_BgmCatalog.battle_bgm_for_dungeon("north_reach"),
		_BgmCatalog.ID_FROSTRIDGE
	)
	assert_eq(
		_BgmCatalog.battle_bgm_for_dungeon("mourngate"),
		_BgmCatalog.ID_MOURNGATE
	)
	assert_eq(
		_BgmCatalog.battle_bgm_for_dungeon("abyss_mourngate"),
		_BgmCatalog.ID_MOURNGATE
	)
	assert_eq(
		_BgmCatalog.battle_bgm_for_dungeon("abyss_whisperwood"),
		_BgmCatalog.ID_WHISPERWOOD
	)
	assert_eq(
		_BgmCatalog.battle_bgm_for_dungeon("abyss_mistfen"),
		_BgmCatalog.ID_MISTFEN
	)
	assert_eq(
		_BgmCatalog.battle_bgm_for_dungeon("abyss_blackshore"),
		_BgmCatalog.ID_BLACKSHORE
	)
	assert_eq(
		_BgmCatalog.battle_bgm_for_dungeon("abyss_frostridge"),
		_BgmCatalog.ID_FROSTRIDGE
	)
	assert_eq(
		_BgmCatalog.battle_bgm_for_dungeon("shadow_hunt"),
		_BgmCatalog.ID_SHADOW_HUNT
	)
	assert_eq(
		_BgmCatalog.battle_bgm_for_dungeon("golden_nest"),
		_BgmCatalog.ID_EVENT_DUNGEON
	)
	assert_eq(
		_BgmCatalog.battle_bgm_for_dungeon("cosmic_rift"),
		_BgmCatalog.ID_EVENT_DUNGEON
	)
	assert_eq(
		_BgmCatalog.battle_bgm_for_dungeon("crown_rookery"),
		_BgmCatalog.ID_EVENT_DUNGEON
	)
	assert_eq(
		_BgmCatalog.battle_bgm_for_dungeon("rock_stampede"),
		_BgmCatalog.ID_EVENT_DUNGEON
	)
	assert_eq(
		_BgmCatalog.battle_bgm_for_dungeon("chronos_mausoleum"),
		_BgmCatalog.ID_CHRONOS_MAUSOLEUM
	)
	assert_eq(
		_BgmCatalog.battle_bgm_for_dungeon("valgard_boundary"),
		_BgmCatalog.ID_VALGARD_BOUNDARY
	)


func test_explore_bgm_for_dungeon_chronos() -> void:
	assert_eq(
		_BgmCatalog.explore_bgm_for_dungeon("chronos_mausoleum"),
		_BgmCatalog.ID_CHRONOS_MAUSOLEUM
	)
	assert_eq(
		_BgmCatalog.explore_bgm_for_dungeon("valgard_boundary"),
		_BgmCatalog.ID_VALGARD_BOUNDARY
	)
	assert_eq(
		_BgmCatalog.explore_bgm_for_dungeon("mourngate"),
		_BgmCatalog.ID_DUNGEON_EXPLORE
	)


func test_boss_bgm_for_dungeon_final_on_frostridge() -> void:
	assert_eq(
		_BgmCatalog.boss_bgm_for_dungeon("frostridge"),
		_BgmCatalog.ID_FINAL_BOSS
	)
	assert_eq(
		_BgmCatalog.boss_bgm_for_dungeon("north_reach"),
		_BgmCatalog.ID_BOSS
	)
	assert_eq(
		_BgmCatalog.boss_bgm_for_dungeon("mourngate"),
		_BgmCatalog.ID_BOSS
	)
	assert_eq(
		_BgmCatalog.boss_bgm_for_dungeon("blackshore"),
		_BgmCatalog.ID_BOSS
	)
	assert_eq(
		_BgmCatalog.boss_bgm_for_dungeon("chronos_mausoleum"),
		_BgmCatalog.ID_CHRONOS_WAVE
	)
	assert_eq(
		_BgmCatalog.boss_bgm_for_dungeon("valgard_boundary"),
		_BgmCatalog.ID_VALGARD
	)


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


func test_scene_bgm_maps_hub_and_facility() -> void:
	assert_eq(
		_BgmCatalog.bgm_for_scene("res://scenes/equipment/EquipmentScene.tscn"),
		_BgmCatalog.ID_HUB
	)
	assert_eq(
		_BgmCatalog.bgm_for_scene("res://scenes/gacha/GachaScene.tscn"),
		_BgmCatalog.ID_GACHA
	)
	assert_eq(
		_BgmCatalog.bgm_for_scene("res://scenes/blacksmith/BlacksmithScene.tscn"),
		_BgmCatalog.ID_FORGE
	)
	assert_eq(_BgmCatalog.bgm_for_scene("res://scenes/unknown/NoScene.tscn"), "")
	## 結果／ダンジョンは SCENE_BGM 非掲載（勝敗切替／DungeonScene 側で battle 同期）。
	assert_eq(_BgmCatalog.bgm_for_scene("res://scenes/result/ResultScene.tscn"), "")
	assert_eq(_BgmCatalog.bgm_for_scene("res://scenes/dungeon/DungeonScene.tscn"), "")


func test_dungeon_explore_bgm_omitted_from_scene_map() -> void:
	## P3-AUDIO-BGM-EXPLORE-OMIT-001: 探索曲アセットは残るがダンジョン入場では使わない。
	assert_true(_BgmCatalog.is_available(_BgmCatalog.ID_DUNGEON_EXPLORE))
	assert_eq(_BgmCatalog.bgm_for_scene("res://scenes/dungeon/DungeonScene.tscn"), "")
	assert_eq(
		_BgmCatalog.battle_bgm_for_dungeon("mourngate"),
		_BgmCatalog.ID_MOURNGATE
	)
	assert_eq(
		_BgmCatalog.battle_bgm_for_dungeon("abyss_mourngate"),
		_BgmCatalog.ID_MOURNGATE
	)


func test_leaving_gacha_to_equipment_switches_to_hub() -> void:
	AudioManager.play_bgm(_BgmCatalog.ID_GACHA)
	assert_eq(AudioManager.current_bgm_id(), _BgmCatalog.ID_GACHA)
	var hub_id: String = _BgmCatalog.bgm_for_scene(
		"res://scenes/equipment/EquipmentScene.tscn"
	)
	AudioManager.play_bgm(hub_id)
	assert_eq(AudioManager.current_bgm_id(), _BgmCatalog.ID_HUB)
