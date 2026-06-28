class_name DungeonData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var difficulty: int = 0
## 推奨レベル（ダンジョン選択画面の表示用）。0 以下は非表示扱い。
@export var recommended_level: int = 0
@export var room_count: int = 0
## フロア数（START〜BOSS を含む。EXIT は末尾に自動付与）。
## 1 以上で部屋ランダム抽選を有効化。0 の場合は ROOM_SEQUENCE/room_count の従来固定列。
@export var floor_count: int = 0
@export var enemy_pool: Array[String] = []
@export var boss_id: String = ""
@export var drop_table_id: String = ""
@export var discovery_unlocks: Dictionary = {}
@export var elite_pool: Array[String] = []
