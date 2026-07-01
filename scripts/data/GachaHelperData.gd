class_name GachaHelperData
extends Resource

## ガチャ排出ユニーク助っ人の定義（P3-D036b）。
## 取得すると Adventurer 化され、ロスター（編成枠3の選択肢）へ加わる。

@export var id: String = ""
@export var display_name: String = ""
@export var job_id: String = ""
## 来歴一行（排出ラインナップ等の表示用 / P3-GACHA-002）。
@export var origin_note: String = ""
## レアリティ（★表示・排出率・重複還元。プールは `gacha_helpers/` 全件 / P3-GACHA-004）。
@export var rarity: int = 3
## 専用スプライト animation resource パス（空なら job 既定）。
@export var sprite_resource_path: String = ""
## 専用立ち絵 PNG パス（召喚演出・編成等。空なら job バストへフォールバック / P3-GACHA-003）。
@export var portrait_resource_path: String = ""
## 基礎ステータス（空欄なら Stats 既定）。
@export var base_stats: Stats

func get_portrait_texture() -> Texture2D:
	if not portrait_resource_path.is_empty() and ResourceLoader.exists(portrait_resource_path):
		return load(portrait_resource_path) as Texture2D
	return IconPaths.get_icon_texture(job_id, "chr")
