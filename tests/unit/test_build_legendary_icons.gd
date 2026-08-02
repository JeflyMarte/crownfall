extends GutTest
## P3-EQ-LEG-BUILD-001 — ビルド拡張L専用アイコン。

const BUILD_ARMORS: Array[String] = [
	"bloodpact_plate",
	"flurry_light_mail",
	"bulwark_role_plate",
	"cover_aegis_cloak",
	"hexweave_robe",
]

const BUILD_ACCESSORIES: Array[String] = [
	"blade_dance_ring",
	"pierce_charm",
	"pulse_amulet",
	"beastlord_fang",
	"apothecary_vial",
]


func test_build_legendary_icons_are_dedicated() -> void:
	var seen: Dictionary = {}
	for aid: String in BUILD_ARMORS:
		var path: String = str(IconPaths.ICON_MAP.get("armor:%s" % aid, ""))
		assert_false(path.is_empty(), aid)
		assert_true(path.contains("ICO_ARM_"), aid)
		assert_false(path.contains("Generic"), aid)
		assert_false(path.contains("Kaiwan"), aid)
		assert_true(FileAccess.file_exists(path), path)
		var md5: String = FileAccess.get_md5(path)
		assert_false(seen.has(md5), "duplicate %s" % path)
		seen[md5] = path
	for cid: String in BUILD_ACCESSORIES:
		var path2: String = str(IconPaths.ICON_MAP.get("accessory:%s" % cid, ""))
		assert_false(path2.is_empty(), cid)
		assert_true(path2.contains("ICO_ACC_"), cid)
		assert_false(path2.contains("Generic"), cid)
		assert_true(FileAccess.file_exists(path2), path2)
		var md52: String = FileAccess.get_md5(path2)
		assert_false(seen.has(md52), "duplicate %s" % path2)
		seen[md52] = path2
	assert_eq(seen.size(), 10)
