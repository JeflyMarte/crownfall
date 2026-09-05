class_name StatusEffectData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var tier: int = 1
@export var max_stacks: int = 1
@export var duration_ticks: int = 3
@export var effect_type: String = "dot"  # "dot" | "stat_mod" | "hot"
@export var element_tag: String = ""
@export var dot_percent_of_attack: float = 0.0
@export var dot_flat: int = 0
## effect_type=hot: 対象 maxHP 割合×stacks を毎 tick 回復（例 0.04＝4%）。
@export var hot_percent_of_max: float = 0.0
@export var interval_multiplier: float = 1.0  # slow: 1.5, others: 1.0
@export var skip_action_chance: float = 0.0  # stun: 1.0 = 行動不能
@export var outgoing_damage_multiplier: float = 1.0  # weak: 0.75
@export var incoming_damage_multiplier: float = 1.0  # burn 被ダメ増など
@export var defense_reduction: float = 0.0  # armor_break: 0.5 = 対象 DEF を半減（0..1・P3-D107）
## 被回復倍率（heal_block=0）。複数付与時は乗算。
@export var healing_received_multiplier: float = 1.0
## 会心率加算（0..1。クリティカルストーム等・P3-BAL-CHAR-ULTIMATE-001）。
@export var crit_rate_add: float = 0.0
## 与ダメ吸血割合加算（ブラッドドレイン等）。
@export var lifesteal_ratio: float = 0.0
## 属性つき攻撃の与ダメ倍率（1.0=なし。エレメンタルブースト等）。
@export var elemental_outgoing_mult: float = 1.0
## 被状態異常付与率倍率（1.0=なし。アイアンオーラ等）。
@export var incoming_status_chance_mult: float = 1.0
