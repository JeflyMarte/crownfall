class_name AccessoryData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var rarity: int = 0
@export var icon: String = ""
@export var description: String = ""
@export var hp_bonus: int = 0
@export var attack_bonus: int = 0
@export var defense_bonus: int = 0
@export var crit_rate_bonus: float = 0.0
## 幸運: 現状ドロップ/報酬計算に未反映のため未使用（将来用に予約・UI非表示）。
@export var luck_bonus: float = 0.0
