class_name DungeonData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var difficulty: int = 0
## 推奨レベル（ダンジョン選択画面の表示用）。0 以下は非表示扱い。
@export var recommended_level: int = 0
## 敵レベル（P3-D081）。戦闘開始時に敵ステータス/EXP をスケールする。
## 同一ダンジョンの難易度調整に使用。1 以下は等倍（Lv1＝tres 基準値）。
@export var enemy_level: int = 1
@export var room_count: int = 0
## フロア数（START〜BOSS を含む。EXIT は末尾に自動付与）。
## 1 以上で部屋ランダム抽選を有効化。0 の場合は ROOM_SEQUENCE/room_count の従来固定列。
@export var floor_count: int = 0
@export var enemy_pool: Array[String] = []
@export var boss_id: String = ""
@export var drop_table_id: String = ""
@export var discovery_unlocks: Dictionary = {}
@export var elite_pool: Array[String] = []
## Biome 属性相性（P3-D099）。この地形で有利な属性 id（fire/ice/lightning/holy/dark 等）。
## 味方攻撃の属性が一致すると与ダメに BIOME_FAVORED_BONUS を乗算。空＝補正なし。
@export var favored_element: String = ""
