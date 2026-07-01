class_name GachaHelperData
extends Resource

## ガチャ排出ユニーク助っ人の定義（P3-D036b）。
## 取得すると Adventurer 化され、ロスター（編成枠3の選択肢）へ加わる。

@export var id: String = ""
@export var display_name: String = ""
@export var job_id: String = ""
## 来歴一行（排出ラインナップ等の表示用 / P3-GACHA-002）。
@export var origin_note: String = ""
## レアリティ（★表示・排出率・重複還元に使用。プール=★4×1+★3×2 / P3-D036b）。
@export var rarity: int = 3
## 専用スプライト animation resource パス（空なら job 既定）。
@export var sprite_resource_path: String = ""
## 基礎ステータス（空欄なら Stats 既定）。
@export var base_stats: Stats
