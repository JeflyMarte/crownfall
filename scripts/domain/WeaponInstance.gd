class_name WeaponInstance
extends Resource

@export var instance_id: String = ""
@export var weapon_id: String = ""
@export var is_appraised: bool = false
@export var rolled_attack: int = 0
@export var attack_speed: float = 1.0
@export var critical_rate: float = 0.0
@export var knockback: float = 0.0
@export var stagger_power: float = 0.0
## 射程: CombatRange がカテゴリ解決に使用（P3-D106f）。UI 非表示。
@export var attack_range: float = 1.0
@export var weight: float = 1.0
@export var prefix_ids: Array[String] = []
@export var suffix_ids: Array[String] = []
## 炉研ぎ段階（0〜5）。実効 ATK = rolled_attack + enhance_level（P3-D152）。
@export var enhance_level: int = 0
