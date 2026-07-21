class_name DailyMissionData
extends Resource

## ギルド日課ミッション定義（P3-DAILY）。

@export var id: String = ""
@export var title: String = ""
@export var description: String = ""
## dungeon_clear / kill_enemy / kill_elite / kill_boss /
## craft_item / enhance_item / alchemy_item / dismantle_item / gacha_pull
@export var objective_type: String = ""
@export var target_count: int = 1
@export var target_param: String = ""
@export var reward_gold: int = 0
@export var reward_gacha_token: int = 0
@export var reward_material_id: String = ""
@export var reward_material_qty: int = 0
