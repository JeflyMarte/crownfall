class_name GachaHelperData
extends Resource

## ガチャ排出ユニーク助っ人の定義（P3-D036b / P3-GACHA-005）。
## 取得すると Adventurer 化され、ロスター（編成枠の選択肢）へ加わる。
## 基本5職スターター（adventurer_0..4）は本プールに含めない。

@export var id: String = ""
@export var display_name: String = ""
@export var job_id: String = ""
## 来歴一行（排出ラインナップ等の表示用 / P3-GACHA-002）。
@export var origin_note: String = ""
## 召喚入手時の一言セリフ（空なら origin_note をフォールバック）。
@export_multiline var summon_quote: String = ""
## レアリティ ★1〜4（ノーマル〜超レア）。全員いずれかの基本5職に属する。
@export var rarity: int = 1
## 戦闘パッシブ id（`CombatPassives` SSOT / 空ならジョブフォールバック）。
@export var passive_id: String = ""
## キャラ別必殺 id（空なら `JobData.ultimate_skill_id` へフォールバック / P3-JOB-ENGINEER-001）。
@export var ultimate_skill_id: String = ""
## 職習得表の差替え（P3-SKILL-CHAR-SLOT-001）。例: {level, replaces, skill_id}。
@export var skill_slot_replacements: Array[Dictionary] = []
## 専用スプライト animation resource パス（空なら job 既定）。
@export var sprite_resource_path: String = ""
## 専用立ち絵 PNG パス（召喚演出・編成等。空なら job バストへフォールバック / P3-GACHA-003）。
@export var portrait_resource_path: String = ""
## 基礎ステータス（空欄なら Stats 既定）。
@export var base_stats: Stats

## 図鑑・人物録（所持時のみ開示）。
@export var hometown: String = ""
@export var height_cm: int = 0
@export var likes: String = ""
@export var dislikes: String = ""
@export_multiline var backstory: String = ""
## ギルド記録部の短い注記（余白・未確定メモ）。
@export_multiline var record_note: String = ""

func get_portrait_texture() -> Texture2D:
	if not portrait_resource_path.is_empty() and ResourceLoader.exists(portrait_resource_path):
		return load(portrait_resource_path) as Texture2D
	return IconPaths.get_icon_texture(job_id, "chr")
