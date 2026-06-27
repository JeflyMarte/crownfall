class_name EnemyData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var max_hp: int = 0
@export var attack: int = 0
@export var defense: int = 0
@export var attack_speed: float = 1.0
@export var critical_rate: float = 0.0
@export var move_speed: float = 1.0
@export var detection_range: float = 5.0
@export var attack_range: float = 1.0
@export var enemy_type: int = 0
@export var ai_type: String = "default"
@export var exp_reward: int = 0
@export var gold_reward: int = 0
@export var drop_table_id: String = ""
@export var element_weakness: Array[String] = []
@export var element_resist: Array[String] = []
@export var on_hit_status_id: String = ""
@export var on_hit_status_chance: float = 0.0
@export var codex_class: String = ""
@export var codex_danger: int = 0
@export var codex_habitat: String = ""
@export_multiline var codex_research_note: String = ""
