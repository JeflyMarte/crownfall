class_name ArmorInstance
extends Resource

@export var instance_id: String = ""
@export var armor_id: String = ""
@export var rolled_defense: int = 0
@export var hp_bonus: int = 0
## 個体ロール属性耐性（P3-EQ-STAT-006）。空=なし。
@export var resist_elements: Array[String] = []
## 属性耐性の被ダメ倍率（0=未設定→SSOT 既定）。低いほど軽減大。
@export var resist_multiplier: float = 0.0
@export var exp_gain_rate: float = 0.0
@export var gold_gain_rate: float = 0.0
@export var rare_drop_rate: float = 0.0
## 回避率（0.0〜1.0）。敵攻撃を完全回避。
@export var evasion_rate: float = 0.0
## 状態異常無効（poison/chill/shock/ignite/curse/stun）。
@export var status_immunities: Array[String] = []
@export var resistance: float = 0.0
@export var weight: float = 1.0
@export var rarity: int = 0
@export var is_appraised: bool = false
@export var prefix_ids: Array[String] = []
@export var suffix_ids: Array[String] = []
## 装備レベル（1〜99）。ドロップ時 Biome 連動・戦闘で成長（P3-EQ-LVL-001）。
@export var equip_level: int = 1
@export var equip_exp: int = 0
## ドロップ時に付与したランダムステータス id 一覧。
@export var rolled_bonus_stats: Array[String] = []
## ランダムステータスで最高値を引いた数（表示名⭐️用）。
@export var perfect_roll_count: int = 0
