extends GutTest
## ガチャプール — ★2×5 / ★3×4 / ★4×2。

const _GachaRarityConfig := preload("res://scripts/gacha/GachaRarityConfig.gd")


func test_pool_has_eleven_helpers_with_expected_rarities() -> void:
	var pool: Array = DataRegistry.get_all_gacha_helper_data()
	assert_eq(pool.size(), 11)
	var counts: Dictionary = {2: 0, 3: 0, 4: 0}
	var ids: Array[String] = []
	for h: Variant in pool:
		assert_not_null(h)
		var rarity: int = int(h.rarity)
		assert_true(counts.has(rarity), "unexpected rarity %d" % rarity)
		counts[rarity] = int(counts[rarity]) + 1
		ids.append(str(h.id))
	assert_eq(int(counts[2]), 5)
	assert_eq(int(counts[3]), 4)
	assert_eq(int(counts[4]), 2)
	ids.sort()
	assert_eq(ids, [
		"helper_a", "helper_b", "helper_c", "helper_e", "helper_f", "helper_i",
		"helper_k", "helper_m", "helper_n", "helper_o", "helper_p",
	])


func test_new_four_rarities() -> void:
	assert_eq(int(DataRegistry.get_gacha_helper_data("helper_k").rarity), 2)
	assert_eq(int(DataRegistry.get_gacha_helper_data("helper_m").rarity), 3)
	assert_eq(int(DataRegistry.get_gacha_helper_data("helper_n").rarity), 3)
	assert_eq(int(DataRegistry.get_gacha_helper_data("helper_o").rarity), 2)


func test_hodaka_in_pool_with_art() -> void:
	var hodaka: Resource = DataRegistry.get_gacha_helper_data("helper_p")
	assert_not_null(hodaka)
	assert_eq(str(hodaka.display_name), "ホダカ")
	assert_eq(int(hodaka.rarity), 4)
	assert_false(str(hodaka.sprite_resource_path).is_empty())
	assert_false(str(hodaka.portrait_resource_path).is_empty())
	assert_true(ResourceLoader.exists(str(hodaka.sprite_resource_path)))
	assert_true(ResourceLoader.exists(str(hodaka.portrait_resource_path)))


func test_omitted_helpers_still_load_by_id() -> void:
	assert_not_null(DataRegistry.get_gacha_helper_data("helper_d"))
	assert_not_null(DataRegistry.get_gacha_helper_data("helper_g"))
	assert_not_null(DataRegistry.get_gacha_helper_data("helper_l"))
	assert_eq(str(DataRegistry.get_gacha_helper_data("helper_a").display_name), "ヴァルデン")


func test_rate_display_omits_star1() -> void:
	var text: String = _GachaRarityConfig.rate_display_text()
	assert_false(text.contains("★1"))
	assert_true(text.contains("★2"))
	assert_true(text.contains("★4"))
	assert_false(text.contains("未所持優先"))
	assert_eq(float(_GachaRarityConfig.RARITY_WEIGHTS.get(1, -1.0)), 0.0)
