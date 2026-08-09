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
## 対象: "enemy" | "all_enemies" | "ally" | "all_party" | "self" | "pet"
## 敵スキル側の列指定: "party" | "party_front" | "party_back"（P3-D106c）。
## 敵サポート: heal/buff の "ally"＝他の生存敵（いなければ self）。"self"＝詠唱者のみ。
## damage: 攻撃倍率。heal（味方）: 対象 maxHP 割合（0.2=20%）。敵healも同型。
@export var power_multiplier: float = 1.0
## このスキル限定の会心率加算（0..1。P3-SKILL-THEME-KIT-001）。
@export var crit_rate_bonus: float = 0.0
@export var cooldown: float = 5.0
@export var trigger_type: String = "cooldown"
## effect_type: "damage" | "heal" | "buff" | "flee" | "explode" | "haste" | "silence" | "dispel" | "summon" | "none"
@export var effect_type: String = "none"
@export var tags: Array[String] = []
@export var element: String = ""
@export var apply_status_id: String = ""
@export var apply_status_chance: float = 0.0
## 副次状態付与（P3-D107）。1スキルで2種目のデバフを付与する場合に使用（空=なし）。
@export var apply_status_id2: String = ""
@export var apply_status_chance2: float = 0.0
## 第3状態（必殺の多重デバフ等。空=なし）。
@export var apply_status_id3: String = ""
@export var apply_status_chance3: float = 0.0
## スロット種別（P3-D085）: "attack" | "defend" | "skill" | "ultimate"。
## 既定 "skill"。必殺技は "ultimate"（長CD・高威力）。AI設定(P3-D086)の選択対象。
@export var slot_type: String = "skill"
## 射程種別（P3-D085・メタ情報）: "melee" | "mid" | "long" | "global"。
## 現状は表示/将来のターゲティング用。MVPでは挙動に未反映。
@export var range_type: String = "melee"
## 詠唱（P3-D112）: 発動前にロックする自分番の回数（0=即時）。1=1回詠唱して次の自分番で発動。
@export var cast_time: float = 0.0
## 温存条件（P3-D113）: 空=常時使用可。CombatTactics の condition id（例 ally_injured / enemy_is_boss）。
@export var reserve_condition: String = ""
## 温存条件の閾値（self_hp_below / enemy_count_gte / self_range 等で使用。空=不要）。
@export var reserve_value: String = ""
## effect_type=summon: 呼ぶ敵 id（空＝詠唱者と同種クローン／既存トリッキー）。
@export var summon_enemy_id: String = ""
## effect_type=summon: 呼ぶ体数（キャップまで）。
@export var summon_count: int = 1
## 敵→味方ダメージ時に味方 DEF 逓減をスキップ（構え／属性耐性／ブロックは残す）。
@export var ignore_defense: bool = false
