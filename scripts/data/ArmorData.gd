class_name ArmorData
extends Resource

@export var armor_id: String = ""
@export var display_name: String = ""
## 装備説明（由来・用途）。UI の説明文 SSOT。
@export_multiline var description: String = ""
@export var base_defense: int = 0
@export var base_hp_bonus: int = 0
## 旧・汎用耐性（未使用・予約）。属性別耐性は resist_elements で実装（P3-D103）。
@export var base_resistance: float = 0.0
## 属性耐性（P3-D103）。ここに含む属性 id（ElementResolver 準拠）の敵攻撃を被ダメ軽減する。
@export var resist_elements: Array[String] = []
@export var weight: float = 1.0
@export var rarity: int = 0
## レジェンド防具の固有パッシブ id（`CombatPassives` SSOT / 空ならなし）。
@export var fixed_passive_id: String = ""
