class_name DungeonStageData
extends Resource

@export var id: String = ""
@export var biome_id: String = ""
## メイン Biome 番号（1〜5）。`stage_id` = `{biome_id}_{biome_index}_{chapter_index}`。
@export var biome_index: int = 1
## Biome 内章番号（1〜5）。
@export var chapter_index: int = 1
@export var display_name: String = ""
@export var floor_count: int = 6
@export var enemy_level: int = 1
@export var recommended_level: int = 0
## `exit` = EXIT 締め（Boss なし） / `boss` = 最終F に Boss。
@export var closing_type: String = "exit"
@export var boss_id: String = ""
## x-5 初回ボス討伐（ノーマル）の確定レジェンド防具 id。空=なし。
@export var legendary_armor_id: String = ""
## x-5 初回ボス討伐（ノーマル）の確定レジェンド装飾 id。空=なし。
@export var legendary_accessory_id: String = ""
## x-4 相当: 中間部屋に ELITE を最低 1 回必須。
@export var requires_elite: bool = false
## COMBAT 雑魚 spawn 重み（P3-ENEMY-001）。キー=`codex_danger` 文字列、値=整数重み。
@export var spawn_weights: Dictionary = {}
## 0 = Biome `DungeonData` を継承。
@export var event_room_weight: int = 0
## -1 = Biome 継承 / 0 以上で上書き。
@export var min_event_rooms: int = -1


func has_boss_floor() -> bool:
	return closing_type == "boss"
