class_name IconPaths
extends RefCounted

const BASE_PATH: String = "res://assets/ui/batch2/"

const ICON_MAP: Dictionary = {
	"weapon:iron_sword":           "ICO_WPN_IronSword.png",
	"weapon:rusted_blade":         "ICO_WPN_RustedBlade.png",
	"weapon:unidentified":         "ICO_WPN_Unidentified.png",
	"armor:leather_armor":         "ICO_ARM_LeatherArmor.png",
	"armor:bone_armor":            "ICO_ARM_BoneArmor.png",
	"armor:unidentified":          "ICO_ARM_Unidentified.png",
	"accessory:silver_ring":       "ICO_ACC_SilverRing.png",
	"accessory:unidentified":      "ICO_ACC_Unidentified.png",
	"material:relic_shard":        "ICO_MAT_RelicShard.png",
	"material:elite_relic_shard":  "ICO_MAT_EliteRelicShard.png",
	"material:ancient_bone":       "ICO_MAT_AncientBone.png",
	"material:cursed_iron":        "ICO_MAT_CursedIron.png",
	"material:leather":            "ICO_MAT_Leather.png",
}

static func get_icon_texture(id: String, category: String) -> Texture2D:
	if id.is_empty() or category.is_empty():
		return null
	var filename: String = ICON_MAP.get("%s:%s" % [category, id], "")
	if filename.is_empty():
		return null
	var path: String = BASE_PATH + filename
	if not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
