class_name PetData
extends Resource

## 随伴ペット定義（P3-PET-OTOMO-001）。職ではない。戦闘は人間4の外。

@export var id: String = ""
@export var display_name: String = ""
@export var rarity: int = 1
@export var base_stats: Stats
## フォールバック用（skill_unlocks 未設定時は Lv1 全解放扱い）。
@export var skill_ids: Array[String] = []
## レベル習得表（P3-PET-SKILL-001）。[{ "skill_id": String, "level": int }, ...]
@export var skill_unlocks: Array[Dictionary] = []
## 戦闘 SpriteFrames。空ならプレースホルダ敵スプライト。
@export var sprite_resource_path: String = ""
@export var origin_note: String = ""
