class_name DailyMissionData
extends Resource

## ギルド日課ミッション定義（P3-DAILY / P3-BAL-DAILY-REWARD-VARIETY-001）。

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
## ランダム装備1点（武／防／飾・N〜E）。P3-BAL-DAILY-REWARD-VARIETY-001。
@export var reward_equip: bool = false
## true のとき E 寄りレア重み（ボス日課）。
@export var reward_equip_epic_bias: bool = false
