class_name Adventurer
extends Resource

## キャラクターレアリティ（★表示用）。基本5職・ガチャ助っ人とも既定★3。
const DEFAULT_RARITY: int = 3

@export var id: String = ""
@export var display_name: String = ""
## キャラクター★（装備レアリティとは別体系）。ガチャ助っ人データの rarity と同型。
@export var rarity: int = DEFAULT_RARITY
@export var level: int = 1
@export var exp: int = 0
@export var job_id: String = ""
@export var base_stats: Stats
@export var equipped_weapon: Resource = null
@export var equipped_armor: Resource = null
@export var equipped_accessory: Resource = null
@export var traits: Array[String] = []
## 装備中スキル id（最大 Constants.MAX_EQUIPPED_SKILLS）。空ならジョブ既定にフォールバック。P3-D077。
@export var equipped_skill_ids: Array[String] = []
## 戦術プリセット id（P3-D086・AI最上位設定）。空なら "balanced"。スロット選択優先度を決める。
@export var tactics_id: String = ""
## カスタム戦術（ガンビット・A1）。ON 時は tactics_custom_* を CombatGambit が優先する。
@export var tactics_custom_enabled: bool = false
@export var tactics_custom_target: String = ""
## 優先度順のルール配列。各要素は {slot, condition, value?}。
@export var tactics_custom_plan: Array = []
## 遺物 id（P3-D090・第3装備枠）。空＝なし。与ダメ/被ダメ/行動速度の常時倍率を与える。
@export var relic_id: String = ""

## 陣形の行（P3-D106）。0=前列 / 1=後列。後列は被ダメ/Threat 減、前列は war_banner 等の前列ボーナス対象。
@export var formation_row: int = 0
## 編成グリッドのマス番号（0〜3）。0,1=前衛列 / 2,3=後衛列。戦闘画面の立ち位置に使用。
@export var formation_slot: int = 0
## ジョブ進化（到達形）済みか（P3-D037 / 手動ギルド認定で true）。
@export var is_evolved: bool = false
