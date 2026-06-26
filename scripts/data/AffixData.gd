class_name AffixData
extends Resource

## M6 最小 AffixData。DataRegistry lookup のみ（P2-Task028）。
## affix_category: "prefix" | "suffix"
## stat_type: Affix Bible §6 登録単位（Attack, Defense, …）
## value: サンプル固定値。Roll 時 min/max は将来 Task
## tags: 将来 allowed_item_types 等（weapon / armor / accessory）

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var affix_category: String = "prefix"
@export var rarity: int = 0
@export var stat_type: String = ""
@export var value: float = 0.0
@export var tags: Array[String] = []
