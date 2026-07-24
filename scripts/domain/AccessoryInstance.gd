class_name AccessoryInstance
extends Resource

@export var instance_id: String = ""
@export var accessory_id: String = ""
@export var hp_bonus: int = 0
@export var attack_bonus: int = 0
@export var defense_bonus: int = 0
@export var crit_rate_bonus: float = 0.0
## 回避率（0.0〜1.0）。敵攻撃を完全回避。
@export var evasion_rate: float = 0.0
@export var exp_gain_rate: float = 0.0
@export var gold_gain_rate: float = 0.0
@export var rare_drop_rate: float = 0.0
@export var is_appraised: bool = false
@export var prefix_ids: Array[String] = []
@export var suffix_ids: Array[String] = []
## P3-EQ-DIABLO-001: 統合ランダムステ。
@export var random_mods: Array = []
## 装備レベル（1〜99）。ドロップ時 Biome 連動・戦闘で成長（P3-EQ-LVL-001）。
@export var equip_level: int = 1
@export var equip_exp: int = 0
## 炉研ぎ段階（0〜5）。ロール整数ステ +N×EQUIP_FORGE_FLAT（P3-FORGE-002）。
@export var enhance_level: int = 0
## ドロップ時に付与したランダムステータス id 一覧。
@export var rolled_bonus_stats: Array[String] = []
## ランダムステータスで最高値を引いた数（表示名⭐️用）。
@export var perfect_roll_count: int = 0
