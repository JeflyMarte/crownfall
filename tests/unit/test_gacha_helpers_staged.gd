extends GutTest

## P3-GACHA-STAGED-001 — プール外助っ人は排出に出ない。


func test_pool_still_six() -> void:
	var pool: Array = DataRegistry.get_all_gacha_helper_data()
	assert_eq(pool.size(), 6)


func test_staged_helpers_load_from_omitted() -> void:
	for hid: String in ["helper_k", "helper_l", "helper_m", "helper_n", "helper_o"]:
		var data: Resource = DataRegistry.get_gacha_helper_data(hid)
		assert_not_null(data, hid)
		assert_eq(str(data.id), hid)
	var lenore: Resource = DataRegistry.get_gacha_helper_data("helper_k")
	assert_eq(str(lenore.display_name), "レノール")
	assert_eq(int(lenore.rarity), 4)
	assert_eq(str(lenore.job_id), "alchemist")


func test_staged_not_in_pool_ids() -> void:
	var ids: Dictionary = {}
	for h: Resource in DataRegistry.get_all_gacha_helper_data():
		ids[str(h.id)] = true
	for hid: String in ["helper_k", "helper_l", "helper_m", "helper_n", "helper_o"]:
		assert_false(ids.has(hid), hid)
