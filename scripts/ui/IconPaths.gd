class_name IconPaths
extends RefCounted

const ICON_MAP: Dictionary = {
	"chr:swordsman":               "res://assets/ui/chr_icons/ICO_CHR_Swordsman.png",
	"chr:ranger":                  "res://assets/ui/chr_icons/ICO_CHR_Ranger.png",
	"chr:alchemist":               "res://assets/ui/chr_icons/ICO_CHR_Alchemist.png",
	"chr:vanguard":                "res://assets/ui/chr_icons/ICO_CHR_Vanguard.png",
	"chr:beast_tamer":             "res://assets/ui/chr_icons/ICO_CHR_BeastTamer.png",
	"weapon:iron_sword":           "res://assets/ui/batch2/ICO_WPN_IronSword.png",
	"weapon:rusted_blade":         "res://assets/ui/batch2/ICO_WPN_RustedBlade.png",
	"weapon:heater_blade":         "res://assets/ui/batch2/ICO_WPN_HeaterBlade.png",
	"weapon:frost_blade":          "res://assets/ui/batch2/ICO_WPN_FrostBlade.png",
	"weapon:bolt_knife":           "res://assets/ui/batch2/ICO_WPN_BoltKnife.png",
	"weapon:apprentice_staff":     "res://assets/ui/batch2/ICO_WPN_ApprenticeStaff.png",
	"weapon:hunting_bow":          "res://assets/ui/batch2/ICO_WPN_HuntingBow.png",
	"weapon:sanctified_dagger":    "res://assets/ui/batch2/ICO_WPN_SanctifiedDagger.png",
	"weapon:ember_fang":           "res://assets/ui/batch2/ICO_WPN_HeaterBlade.png",
	"weapon:glacier_staff":        "res://assets/ui/batch2/ICO_WPN_FrostBlade.png",
	"weapon:storm_edge":           "res://assets/ui/batch2/ICO_WPN_BoltKnife.png",
	"weapon:umbral_fang":          "res://assets/ui/batch2/ICO_WPN_ApprenticeStaff.png",
	"weapon:consecrated_maul":     "res://assets/ui/batch2/ICO_WPN_SanctifiedDagger.png",
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
	"enemy:sepia_hound":           "res://assets/codex/enemies/ART_ENM_SepiaHound.png",
	"enemy:rune_roach":            "res://assets/codex/enemies/ART_ENM_RuneRoach.png",
	"enemy:crystal_hedgehog":      "res://assets/codex/enemies/ART_ENM_CrystalHedgehog.png",
	"enemy:crown_eater_rat":       "res://assets/codex/enemies/ART_ENM_CrownEaterRat.png",
	"enemy:clock_moth":            "res://assets/codex/enemies/ART_ENM_ClockMoth.png",
	"enemy:serdion":               "res://assets/codex/enemies/ART_BOSS_Serdion.png",
	"dungeon:mourngate":           "res://assets/dungeon/mourngate/ICO_DG_Mourngate.png",
	"currency:arcane_crystal":     "res://assets/ui/batch2/ICO_Currency_Arcanite.png",
}

static func get_icon_texture(id: String, category: String) -> Texture2D:
	if id.is_empty() or category.is_empty():
		return null
	var path: String = ICON_MAP.get("%s:%s" % [category, id], "")
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D
