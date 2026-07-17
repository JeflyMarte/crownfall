class_name TicketData
extends Resource

## 消費チケット定義（招待無料券・限界突破券など）。

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
## "free_gacha" | "limit_break"
@export var effect_type: String = ""
## limit_break 時の対象レア（★）。free_gacha は 0。
@export var target_rarity: int = 0
@export var icon_path: String = ""
@export var sort_order: int = 0
