class_name JobData
extends Resource

## M5 最小 JobData。DataRegistry lookup のみ。戦闘 / UI 未接続。
## role: 将来 build 分類用（例: dps / tank / scout）
## *_modifier: 基礎ステ補正倍率（1.0 = 変更なし）
## preferred_weapon_types: 文字列タグ（将来 WeaponType と対応）
## starting_skill_ids: 将来ジョブスキル接続用 SkillData id リスト
## passive_tag_ids: 将来パッシブ分類用タグ

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var role: String = ""
@export var base_hp_modifier: float = 1.0
@export var base_attack_modifier: float = 1.0
@export var base_defense_modifier: float = 1.0
@export var base_initiative_modifier: float = 1.0
@export var preferred_weapon_types: Array[String] = []
@export var starting_skill_ids: Array[String] = []
## レベルごとのジョブスキル解放（P3-SKILL-001）。`{skill_id, level}` の配列。
@export var skill_unlocks: Array[Dictionary] = []
## このジョブが装備可能なスキル id プール（skill_unlocks 未設定時のフォールバック）。
@export var learnable_skill_ids: Array[String] = []
## 必殺技スロットのスキル id（P3-D085）。空なら Constants.DEFAULT_ULTIMATE_SKILL_ID にフォールバック。
@export var ultimate_skill_id: String = ""
@export var passive_tag_ids: Array[String] = []
## ジョブ進化（到達形）の表示名（P3-D037）。空なら進化先なし。
@export var evolved_display_name: String = ""
## 進化に必要なキャラレベル（0 = 進化不可）。
@export var evolution_level: int = 0
