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
@export var passive_tag_ids: Array[String] = []
