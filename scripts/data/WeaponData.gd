class_name WeaponData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
## 装備説明（由来・用途）。UI の説明文 SSOT。
@export_multiline var description: String = ""
@export var fixed_skill_id: String = ""
## レジェンド固有効果 id（P3-WPN-LEG-EFFECT）。`CombatPassives` の `eq_wpn_*`。
@export var fixed_passive_id: String = ""
@export var base_attack: int = 0
@export var rarity: int = 0
@export var base_attack_speed: float = 1.0
@export var base_critical_rate: float = 0.0
@export var base_knockback: float = 0.0
@export var base_stagger_power: float = 0.0
## 射程: CombatRange がカテゴリ解決に使用（P3-D106f）。UI 非表示。
@export var base_attack_range: float = 1.0
@export var weight: float = 1.0
@export var element: String = ""
@export var weapon_type: String = ""
## 属性値の基準（P3-EQ-STAT-005）。ドロップ時にレア度レンジで上乗せロール。
@export var base_element_power: int = 0
## シナジータグ（P3-D094）。攻撃の性質（斬撃/刺突/打撃・炎/氷/雷…）。
## 状態異常コンボの起爆条件（require_tag）等に用いる。CombatTags が正式定義。
@export var tags: Array[String] = []
## 生態特効（P3-D087）。bane_class が敵の codex_class と一致すると与ダメ ×bane_multiplier。
## 空なら特効なし。属性弱点/耐性とは乗算で併用。
@export var bane_class: String = ""
@export var bane_multiplier: float = 1.3
## 公開断片フレーバー（P3-LORE-002）。空なら `WeaponFlavorHelper` の既定文案を参照。
@export_multiline var flavor_text: String = ""
