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
## フロア数（全フロアが room_sequence に含まれる。出口は別フロアにしない）。
## 1 以上で部屋ランダム抽選を有効化。0 の場合は ROOM_SEQUENCE/room_count の従来固定列。
@export var floor_count: int = 0
@export var enemy_pool: Array[String] = []
## ハード弧の COMBAT プール（空=ノーマル pool）。P3-DG-TIER-STG-001。
@export var enemy_pool_hard: Array[String] = []
## ナイトメア弧の COMBAT プール（空=ハード→ノーマルへフォールバック）。
@export var enemy_pool_nightmare: Array[String] = []
@export var boss_id: String = ""
@export var drop_table_id: String = ""
@export var discovery_unlocks: Dictionary = {}
@export var elite_pool: Array[String] = []
@export var elite_pool_hard: Array[String] = []
@export var elite_pool_nightmare: Array[String] = []

func combat_enemy_pool_for_tier(tier: int) -> Array[String]:
	var t: int = DungeonTierConfig.clamp_tier(tier)
	if t == DungeonTierConfig.TIER_NIGHTMARE and not enemy_pool_nightmare.is_empty():
		return enemy_pool_nightmare
	if t >= DungeonTierConfig.TIER_HARD and not enemy_pool_hard.is_empty():
		return enemy_pool_hard
	return enemy_pool

func elite_enemy_pool_for_tier(tier: int) -> Array[String]:
	var t: int = DungeonTierConfig.clamp_tier(tier)
	if t == DungeonTierConfig.TIER_NIGHTMARE and not elite_pool_nightmare.is_empty():
		return elite_pool_nightmare
	if t >= DungeonTierConfig.TIER_HARD and not elite_pool_hard.is_empty():
		return elite_pool_hard
	return elite_pool
## Biome 属性相性（P3-D099）。この地形で有利な属性 id（fire/ice/lightning/holy/dark 等）。
## 味方攻撃の属性が一致すると与ダメに BIOME_FAVORED_BONUS を乗算。空＝補正なし。
@export var favored_element: String = ""
## フレーバーテキスト（ダンジョン選択フィーチャー表示 / P3-UI2-028）。
@export var flavor_text: String = ""
## メイン=main / 寄り道=side / 征討=apex（P3-LORE-005 伝説個体）。
@export var route_type: String = "main"
## 中間部屋抽選の EVENT 重み（0=グローバル既定15）。増分は COMBAT から差し引く（P3-D5DG-003）。
@export var event_room_weight: int = 0
## 中間部屋の EVENT 最低数（0=自動: 中間≥3かつ event 重み>0 なら1）。
@export var min_event_rooms: int = 0
## ダンジョン別ドロップ・プール（P3-D154）。空＝グローバル既定
## （武器=DungeonController.WEAPON_POOL / 防具=革70%骨30% / 装飾=silver_ring）へフォールバック。
@export var weapon_pool: Array[String] = []
@export var armor_pool: Array[String] = []
@export var accessory_pool: Array[String] = []
## 解放条件（P3-D157）。メインルートは難易度順の直列解放（このフィールド不使用）。
## サブルート等はここに指定したダンジョンのクリアで解放（空＝常時解放）。
@export var unlock_after_dungeon_id: String = ""
