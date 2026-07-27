extends GutTest

## バナー重ねタイトルのフォントサイズ統一（文字数閾値の誤適用防止）。

const _BiomeBannerHelper := preload("res://scripts/ui/BiomeBannerHelper.gd")
const _AbyssDungeonConfig := preload("res://scripts/dungeon/AbyssDungeonConfig.gd")


func test_main_biome_banner_titles_share_body_size() -> void:
	## ①〜⑤は表示名の長さ差でサイズが割れないこと。
	var mains: Array[String] = [
		"mourngate",
		"whisperwood",
		"mistfen",
		"blackshore",
		"frostridge",
	]
	var sizes: Array[int] = []
	for dungeon_id: String in mains:
		var data: Resource = DataRegistry.get_dungeon_data(dungeon_id)
		assert_ne(data, null, dungeon_id)
		var name_str: String = str(data.display_name)
		var sz: int = _BiomeBannerHelper.title_font_size(dungeon_id, name_str, false)
		sizes.append(sz)
		assert_eq(sz, UiTypography.SIZE_BODY, "%s (%s) should be BODY" % [dungeon_id, name_str])
	assert_eq(sizes[0], sizes[1])
	assert_eq(sizes[0], sizes[2])
	assert_eq(sizes[0], sizes[3])
	assert_eq(sizes[0], sizes[4])


func test_abyss_banner_title_starts_smaller() -> void:
	var abyss_id: String = "abyss_whisperwood"
	assert_true(_AbyssDungeonConfig.is_abyss_dungeon_id(abyss_id))
	var data: Resource = DataRegistry.get_dungeon_data(abyss_id)
	assert_ne(data, null)
	var sz: int = _BiomeBannerHelper.title_font_size(abyss_id, str(data.display_name), false)
	assert_lte(sz, UiTypography.SIZE_BODY_SMALL)


func test_length_threshold_no_longer_shrinks_whisperwood() -> void:
	## 旧ロジック: length>=12 → SMALL。囁きの森は12文字で誤って縮小されていた。
	var data: Resource = DataRegistry.get_dungeon_data("whisperwood")
	assert_ne(data, null)
	assert_gte(str(data.display_name).length(), 12)
	var sz: int = _BiomeBannerHelper.title_font_size("whisperwood", str(data.display_name), false)
	assert_eq(sz, UiTypography.SIZE_BODY)
