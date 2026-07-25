extends GutTest

## プール外助っ人は排出に出ない。


func test_pool_eleven() -> void:
	var pool: Array = DataRegistry.get_all_gacha_helper_data()
	assert_eq(pool.size(), 11)


func test_torva_still_omitted() -> void:
	var data: Resource = DataRegistry.get_gacha_helper_data("helper_l")
	assert_not_null(data)
	assert_eq(str(data.display_name), "トルヴァ")
	var ids: Dictionary = {}
	for h: Resource in DataRegistry.get_all_gacha_helper_data():
		ids[str(h.id)] = true
	assert_false(ids.has("helper_l"))
	assert_false(ids.has("helper_d"))
