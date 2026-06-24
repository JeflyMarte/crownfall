class_name IconPaths
extends RefCounted

const ICON_MAP: Dictionary = {
	"weapon:iron_sword":           "res://assets/ui/batch2/ICO_WPN_IronSword.png",
	"weapon:rusted_blade":         "res://assets/ui/batch2/ICO_WPN_RustedBlade.png",
	"weapon:unidentified":         "res://assets/ui/batch2/ICO_WPN_Unidentified.png",
	"armor:leather_armor":         "res://assets/ui/batch2/ICO_ARM_LeatherArmor.png",
	"armor:bone_armor":            "res://assets/ui/batch7/ICO_ARM_BoneArmor.png",
	"armor:unidentified":          "res://assets/ui/batch2/ICO_ARM_Unidentified.png",
	"accessory:silver_ring":       "res://assets/ui/batch2/ICO_ACC_SilverRing.png",
	"accessory:unidentified":      "res://assets/ui/batch2/ICO_ACC_Unidentified.png",
	"material:relic_shard":        "res://assets/ui/batch2/ICO_MAT_RelicShard.png",
	"material:elite_relic_shard":  "res://assets/ui/batch7/ICO_MAT_EliteRelicShard.png",
	"material:ancient_bone":       "res://assets/ui/batch7/ICO_MAT_AncientBone.png",
	"material:cursed_iron":        "res://assets/ui/batch7/ICO_MAT_CursedIron.png",
	"material:leather":            "res://assets/ui/batch7/ICO_MAT_Leather.png",
}

static func get_icon_texture(id: String, category: String) -> Texture2D:
	if id.is_empty() or category.is_empty():
		return null
	var path: String = ICON_MAP.get("%s:%s" % [category, id], "")
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
