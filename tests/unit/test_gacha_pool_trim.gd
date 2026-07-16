extends GutTest
## P3-GACHA-008 — プール ★2×3 / ★3×2 / ★4×1。

const _GachaRarityConfig := preload("res://scripts/gacha/GachaRarityConfig.gd")


func test_pool_has_six_helpers_with_expected_rarities() -> void:
	var pool: Array = DataRegistry.get_all_gacha_helper_data()
	assert_eq(pool.size(), 6)
	var counts: Dictionary = {2: 0, 3: 0, 4: 0}
	var ids: Array[String] = []
	for h: Variant in pool:
		assert_not_null(h)
		var rarity: int = int(h.rarity)
		assert_true(counts.has(rarity), "unexpected rarity %d" % rarity)
		counts[rarity] = int(counts[rarity]) + 1
		ids.append(str(h.id))
	assert_eq(int(counts[2]), 3)
	assert_eq(int(counts[3]), 2)
	assert_eq(int(counts[4]), 1)
	ids.sort()
	assert_eq(ids, ["helper_a", "helper_b", "helper_c", "helper_e", "helper_f", "helper_i"])


func test_omitted_helpers_still_load_by_id() -> void:
	assert_not_null(DataRegistry.get_gacha_helper_data("helper_d"))
	assert_not_null(DataRegistry.get_gacha_helper_data("helper_g"))
	assert_eq(str(DataRegistry.get_gacha_helper_data("helper_a").display_name), "ヴァルデン")


func test_rate_display_omits_star1() -> void:
	var text: String = _GachaRarityConfig.rate_display_text()
	assert_false(text.contains("★1"))
	assert_true(text.contains("★2"))
	assert_true(text.contains("★4"))
	assert_eq(float(_GachaRarityConfig.RARITY_WEIGHTS.get(1, -1.0)), 0.0)
