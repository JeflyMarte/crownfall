class_name WeaponData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var fixed_skill_id: String = ""
@export var base_attack: int = 0
@export var rarity: int = 0
@export var base_attack_speed: float = 1.0
@export var base_critical_rate: float = 0.0
@export var base_knockback: float = 0.0
@export var base_stagger_power: float = 0.0
## 射程: 現状の全自動戦闘では未使用（将来用に予約・UI非表示）。
@export var base_attack_range: float = 1.0
@export var weight: float = 1.0
@export var element: String = ""
@export var weapon_type: String = ""
## 生態特効（P3-D087）。bane_class が敵の codex_class と一致すると与ダメ ×bane_multiplier。
## 空なら特効なし。属性弱点/耐性とは乗算で併用。
@export var bane_class: String = ""
@export var bane_multiplier: float = 1.3
