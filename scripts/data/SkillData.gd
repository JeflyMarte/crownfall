class_name SkillData
extends Resource

## M3 最小 SkillData。SkillExecutor 接続済（P2-Task025 — damage / cooldown）。
## skill_type: "player" | "enemy" | "boss" | "job"
## trigger_type: "cooldown"（M3 placeholder）| 将来 "on_hit" 等
## effect_type: "damage" | "heal" | "buff" | "none"

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var skill_type: String = "player"
@export var target_type: String = "enemy"
@export var power_multiplier: float = 1.0
@export var cooldown: float = 5.0
@export var trigger_type: String = "cooldown"
@export var effect_type: String = "none"
@export var tags: Array[String] = []
@export var element: String = ""
@export var apply_status_id: String = ""
@export var apply_status_chance: float = 0.0
## スロット種別（P3-D085）: "attack" | "defend" | "skill" | "ultimate"。
## 既定 "skill"。必殺技は "ultimate"（長CD・高威力）。AI設定(P3-D086)の選択対象。
@export var slot_type: String = "skill"
## 射程種別（P3-D085・メタ情報）: "melee" | "mid" | "long" | "global"。
## 現状は表示/将来のターゲティング用。MVPでは挙動に未反映。
@export var range_type: String = "melee"
