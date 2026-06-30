class_name Adventurer
extends Resource

@export var id: String = ""
@export var display_name: String = ""
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
## 遺物 id（P3-D090・第3装備枠）。空＝なし。与ダメ/被ダメ/行動速度の常時倍率を与える。
@export var relic_id: String = ""
## ジョブ進化（到達形）済みか（P3-D037 / 手動ギルド認定で true）。
@export var is_evolved: bool = false
