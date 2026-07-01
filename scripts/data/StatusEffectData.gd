class_name StatusEffectData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var tier: int = 1
@export var max_stacks: int = 1
@export var duration_ticks: int = 3
@export var effect_type: String = "dot"  # "dot" | "stat_mod"
@export var element_tag: String = ""
@export var dot_percent_of_attack: float = 0.0
@export var dot_flat: int = 0
@export var interval_multiplier: float = 1.0  # slow: 1.5, others: 1.0
@export var skip_action_chance: float = 0.0  # stun: 1.0 = 行動不能
@export var outgoing_damage_multiplier: float = 1.0  # weak: 0.75
@export var incoming_damage_multiplier: float = 1.0  # burn 被ダメ増など
@export var defense_reduction: float = 0.0  # armor_break: 0.5 = 対象 DEF を半減（0..1・P3-D107）
