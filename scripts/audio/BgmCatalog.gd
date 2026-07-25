class_name BgmCatalog
extends RefCounted

## 論理 BGM ID → アセットパス（オーナー制作 Suno 等）。

const DIR: String = "res://assets/audio/bgm/"

const ID_TITLE: String = "title"
const ID_HUB: String = "hub"
const ID_DUNGEON_EXPLORE: String = "dungeon_explore"
const ID_WHISPERWOOD: String = "whisperwood"
const ID_MISTFEN: String = "mistfen"
const ID_BLACKSHORE: String = "blackshore"
const ID_FROSTRIDGE: String = "frostridge"
const ID_BATTLE: String = "battle"
const ID_BOSS: String = "boss"
const ID_FINAL_BOSS: String = "final_boss"
const ID_RESULT: String = "result"
const ID_RESULT_DEFEAT: String = "result_defeat"
const ID_INTRODUCTION: String = "introduction"
const ID_FORGE: String = "forge"
const ID_SURVEY: String = "survey"
const ID_GACHA: String = "gacha"

## 現行登録（タイトル＋導入＋拠点施設＋探索／戦闘／ボス／リザルト）。
## 通常戦闘は Biome 別曲あり（未登録は battle）。探索は全ダンジョン共通。
## フロストリッジ本編ボス（エルディオン）は final_boss。
const PATHS: Dictionary = {
	ID_TITLE: DIR + "title.mp3",
	ID_HUB: DIR + "hub.mp3",
	ID_DUNGEON_EXPLORE: DIR + "dungeon_explore.mp3",
	ID_WHISPERWOOD: DIR + "whisperwood.mp3",
	ID_MISTFEN: DIR + "mistfen.mp3",
	ID_BLACKSHORE: DIR + "blackshore.mp3",
	ID_FROSTRIDGE: DIR + "frostridge.mp3",
	ID_BATTLE: DIR + "battle.mp3",
	ID_BOSS: DIR + "boss.mp3",
	ID_FINAL_BOSS: DIR + "final_boss.mp3",
	ID_RESULT: DIR + "result.mp3",
	ID_RESULT_DEFEAT: DIR + "result_defeat.mp3",
	ID_INTRODUCTION: DIR + "introduction.mp3",
	ID_FORGE: DIR + "forge.mp3",
	ID_SURVEY: DIR + "survey.mp3",
	ID_GACHA: DIR + "gacha.mp3",
}

const LOOP_IDS: Dictionary = {
	ID_TITLE: true,
	ID_HUB: true,
	ID_DUNGEON_EXPLORE: true,
	ID_WHISPERWOOD: true,
	ID_MISTFEN: true,
	ID_BLACKSHORE: true,
	ID_FROSTRIDGE: true,
	ID_BATTLE: true,
	ID_BOSS: true,
	ID_FINAL_BOSS: true,
	ID_RESULT: true,
	ID_RESULT_DEFEAT: true,
	ID_INTRODUCTION: true,
	ID_FORGE: true,
	ID_SURVEY: true,
	ID_GACHA: true,
}

## dungeon_id → 通常戦闘 BGM。寄り道／征討は親 Biome 曲を流用。
const BATTLE_BY_DUNGEON: Dictionary = {
	"whisperwood": ID_WHISPERWOOD,
	"green_hollow": ID_WHISPERWOOD,
	"red_ridge_mine": ID_WHISPERWOOD,
	"mistfen": ID_MISTFEN,
	"broken_marsh": ID_MISTFEN,
	"mistfen_depths": ID_MISTFEN,
	"blackshore": ID_BLACKSHORE,
	"westbay_flats": ID_BLACKSHORE,
	"blackshore_abyss": ID_BLACKSHORE,
	"frostridge": ID_FROSTRIDGE,
	"frostwall_path": ID_FROSTRIDGE,
	"north_reach": ID_FROSTRIDGE,
	"red_forge_depths": ID_FROSTRIDGE,
}

## ラスボス曲を使うダンジョン（フロストリッジ本編＝エルディオン）。
const FINAL_BOSS_DUNGEONS: Dictionary = {
	"frostridge": true,
}

## シーンパス → BGM ID。未登録は切替なし（呼び出し側の play_bgm に委ねる）。
## ガチャ／鍛冶は画面限定。拠点タブ群は hub に戻す（P3-AUDIO-BGM-001 後続）。
## ResultScene は勝敗で曲が変わるため SCENE_BGM には載せない（ResultScene 側で再生）。
const SCENE_BGM: Dictionary = {
	"res://scenes/title/TitleScene.tscn": ID_TITLE,
	"res://scenes/intro/IntroLoreScene.tscn": ID_INTRODUCTION,
	"res://scenes/intro/IntroNameScene.tscn": ID_INTRODUCTION,
	"res://scenes/intro/IntroNinaScene.tscn": ID_INTRODUCTION,
	"res://scenes/base/BaseScene.tscn": ID_HUB,
	"res://scenes/equipment/EquipmentScene.tscn": ID_HUB,
	"res://scenes/equipment/EquipmentCatalogScene.tscn": ID_HUB,
	"res://scenes/roster/RosterScene.tscn": ID_HUB,
	"res://scenes/roster/StarterPickScene.tscn": ID_INTRODUCTION,
	"res://scenes/dungeon/DungeonSelectScene.tscn": ID_HUB,
	"res://scenes/codex/CodexScene.tscn": ID_HUB,
	"res://scenes/commander/CommanderScene.tscn": ID_HUB,
	"res://scenes/showcase/ShowcaseScene.tscn": ID_HUB,
	"res://scenes/settings/SettingsScene.tscn": ID_HUB,
	"res://scenes/guild/GuildScene.tscn": ID_HUB,
	"res://scenes/event/EventScene.tscn": ID_HUB,
	"res://scenes/gacha/GachaScene.tscn": ID_GACHA,
	"res://scenes/blacksmith/BlacksmithScene.tscn": ID_FORGE,
	"res://scenes/survey/SurveyScene.tscn": ID_SURVEY,
	"res://scenes/dungeon/DungeonScene.tscn": ID_DUNGEON_EXPLORE,
}


static func path_for(bgm_id: String) -> String:
	var primary: String = str(PATHS.get(bgm_id, ""))
	if not primary.is_empty() and ResourceLoader.exists(primary):
		return primary
	if not primary.is_empty() and FileAccess.file_exists(primary):
		return primary
	## ogg 差し替えに備えフォールバック
	var ogg: String = DIR + "%s.ogg" % bgm_id
	if ResourceLoader.exists(ogg) or FileAccess.file_exists(ogg):
		return ogg
	return ""


static func should_loop(bgm_id: String) -> bool:
	return bool(LOOP_IDS.get(bgm_id, true))


static func bgm_for_scene(scene_path: String) -> String:
	if scene_path.is_empty():
		return ""
	return str(SCENE_BGM.get(scene_path, ""))


## 通常戦闘曲。専用曲が無ければ battle。
static func battle_bgm_for_dungeon(dungeon_id: String) -> String:
	var mapped: String = str(BATTLE_BY_DUNGEON.get(dungeon_id, ""))
	if not mapped.is_empty() and is_available(mapped):
		return mapped
	return ID_BATTLE


## ボス戦曲。フロストリッジ本編はラスボス曲、他は共通 boss。
static func boss_bgm_for_dungeon(dungeon_id: String) -> String:
	if bool(FINAL_BOSS_DUNGEONS.get(dungeon_id, false)) and is_available(ID_FINAL_BOSS):
		return ID_FINAL_BOSS
	return ID_BOSS


static func all_ids() -> Array[String]:
	var out: Array[String] = []
	for k: Variant in PATHS.keys():
		out.append(str(k))
	out.sort()
	return out


static func is_available(bgm_id: String) -> bool:
	return not path_for(bgm_id).is_empty()
