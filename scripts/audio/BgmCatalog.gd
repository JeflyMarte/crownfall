class_name BgmCatalog
extends RefCounted

## 論理 BGM ID → アセットパス（オーナー制作 Suno 等）。

const DIR: String = "res://assets/audio/bgm/"

const ID_TITLE: String = "title"
const ID_HUB: String = "hub"
const ID_DUNGEON_EXPLORE: String = "dungeon_explore"
const ID_BATTLE: String = "battle"
const ID_BOSS: String = "boss"
const ID_RESULT: String = "result"
const ID_INTRODUCTION: String = "introduction"
const ID_FORGE: String = "forge"
const ID_SURVEY: String = "survey"
const ID_GACHA: String = "gacha"

## 現行登録（タイトル＋導入＋拠点施設＋探索／戦闘／ボス／リザルト）。
const PATHS: Dictionary = {
	ID_TITLE: DIR + "title.mp3",
	ID_HUB: DIR + "hub.mp3",
	ID_DUNGEON_EXPLORE: DIR + "dungeon_explore.mp3",
	ID_BATTLE: DIR + "battle.mp3",
	ID_BOSS: DIR + "boss.mp3",
	ID_RESULT: DIR + "result.mp3",
	ID_INTRODUCTION: DIR + "introduction.mp3",
	ID_FORGE: DIR + "forge.mp3",
	ID_SURVEY: DIR + "survey.mp3",
	ID_GACHA: DIR + "gacha.mp3",
}

const LOOP_IDS: Dictionary = {
	ID_TITLE: true,
	ID_HUB: true,
	ID_DUNGEON_EXPLORE: true,
	ID_BATTLE: true,
	ID_BOSS: true,
	ID_RESULT: true,
	ID_INTRODUCTION: true,
	ID_FORGE: true,
	ID_SURVEY: true,
	ID_GACHA: true,
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


static func all_ids() -> Array[String]:
	var out: Array[String] = []
	for k: Variant in PATHS.keys():
		out.append(str(k))
	out.sort()
	return out


static func is_available(bgm_id: String) -> bool:
	return not path_for(bgm_id).is_empty()
