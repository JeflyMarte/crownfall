extends GutTest

## ペット／ヒーラービルドL専用アイコン（Decision 54）


func test_legend_icons_are_unique_files() -> void:
	var mantle: String = str(IconPaths.ICON_MAP.get("armor:beastcall_mantle", ""))
	var robe: String = str(IconPaths.ICON_MAP.get("armor:field_salve_robe", ""))
	var staff: String = str(IconPaths.ICON_MAP.get("weapon:mendweaver_staff", ""))
	assert_true(mantle.ends_with("ICO_ARM_BeastcallMantle.png"), mantle)
	assert_true(robe.ends_with("ICO_ARM_FieldSalveRobe.png"), robe)
	assert_true(staff.ends_with("ICO_WPN_MendweaverStaff.png"), staff)
	## .import 未生成の headless でも実ファイルを確認する。
	assert_true(FileAccess.file_exists(mantle), mantle)
	assert_true(FileAccess.file_exists(robe), robe)
	assert_true(FileAccess.file_exists(staff), staff)
	## 流用元と別ファイルであること
	assert_ne(mantle, str(IconPaths.ICON_MAP.get("armor:hexweave_robe", "")))
	assert_ne(robe, str(IconPaths.ICON_MAP.get("armor:cover_aegis_cloak", "")))
	assert_ne(staff, str(IconPaths.ICON_MAP.get("weapon:silent_rite_staff", "")))
	assert_ne(staff, str(IconPaths.ICON_MAP.get("weapon:packbond_staff", "")))
