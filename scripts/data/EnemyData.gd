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
## 射程: 全自動戦闘では未使用（将来用に予約）。
@export var attack_range: float = 1.0
@export var enemy_type: int = 0
@export var ai_type: String = "default"
@export var exp_reward: int = 0
@export var gold_reward: int = 0
@export var drop_table_id: String = ""
@export var element_weakness: Array[String] = []
@export var element_resist: Array[String] = []
## 攻撃属性（P3-D103）。この敵の攻撃が持つ属性 id（空=無属性）。防具の resist_elements で軽減される。
@export var attack_element: String = ""
@export var on_hit_status_id: String = ""
@export var on_hit_status_chance: float = 0.0
## ボス/エリート用スキル。skill_ids の中から skill_use_chance で発動を試行する。
@export var skill_ids: Array[String] = []
@export var skill_use_chance: float = 0.0
## 群れ出現（P3-D082）。true の敵は COMBAT 部屋で一定確率により複数体（同種）で出現する。
## ELITE/BOSS 部屋は対象外。swarm_min..swarm_max からサイズを抽選。
@export var can_swarm: bool = false
@export var swarm_min: int = 2
@export var swarm_max: int = 3
@export var codex_class: String = ""
@export var codex_danger: int = 0
@export var codex_habitat: String = ""
@export_multiline var codex_research_note: String = ""
@export var codex_materials: Array[String] = []
## 味方狙いの偏重（P3-D145）。max_threat=最大Threat / lowest_hp=低HP優先 / back_row=後列優先 / lowest_threat=最小Threat
@export var threat_target_bias: String = "max_threat"
## 遍在希少種（放浪個体 / P3-WANDER-001）。全 Biome の COMBAT に低確率差し込み。
@export var is_wandering: bool = false
## 放浪個体の逃走。0=逃走なし。N=自身の行動 N 回後に逃走（遠旅スズメ=3）。
@export var wander_flee_after_turns: int = 0
## 撃破時武器ドロップ率。-1=部屋種別既定 / 0〜1=上書き（聖遺甲虫=0.85）。
@export var weapon_drop_chance: float = -1.0
## 武器レア度重み上書き（空=既定 RARITY_DROP_WEIGHT）。キー=Enums.Rarity 値。
@export var weapon_rarity_weights: Dictionary = {}
