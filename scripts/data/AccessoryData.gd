class_name AccessoryData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var rarity: int = 0
@export var icon: String = ""
## 形カテゴリ: ring / charm / talisman / seal（空=IDから推定。汎用アイコン割当用）。
@export var accessory_type: String = ""
@export var description: String = ""
@export var hp_bonus: int = 0
@export var attack_bonus: int = 0
@export var defense_bonus: int = 0
@export var crit_rate_bonus: float = 0.0
## 経験値獲得率（1.0=100%）。装備ベースの加算源。実効=1.0+Σ。
@export var exp_gain_rate: float = 0.0
## ゴールド獲得率（1.0=100%）。装備ベースの加算源。実効=1.0+Σ。
@export var gold_gain_rate: float = 0.0
## レアドロップ率。高レアの抽選重みを tier 比例で底上げ。
@export var rare_drop_rate: float = 0.0
## レジェンド装飾品の固有パッシブ id（`CombatPassives` SSOT / 空ならなし）。
@export var fixed_passive_id: String = ""
## セット装備 id（空=非セット）。P3-DG-EVENT-SET-001。
@export var set_id: String = ""
