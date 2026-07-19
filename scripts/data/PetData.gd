class_name PetData
extends Resource

## 随伴オトモ定義（P3-PET-OTOMO-001）。職ではない。戦闘は人間4の外。

@export var id: String = ""
@export var display_name: String = ""
@export var rarity: int = 1
@export var base_stats: Stats
@export var skill_ids: Array[String] = []
## 戦闘 SpriteFrames。空ならプレースホルダ敵スプライト。
@export var sprite_resource_path: String = ""
@export var origin_note: String = ""
