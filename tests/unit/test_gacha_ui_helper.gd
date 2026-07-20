extends GutTest

## 招待状 UI helper（GachaUiHelper）— headless 検証。

func test_sorted_helpers_respects_omit_flag() -> void:
	var helpers: Array = GachaUiHelper.sorted_helpers()
	if Constants.are_gacha_helpers_playable():
		assert_gt(helpers.size(), 0)
	else:
		assert_eq(helpers.size(), 0, "P3-CHR-OMIT-001: 助っ人オミット時は空")

func test_catchcopy() -> void:
	assert_eq(GachaUiHelper.catchcopy(), GachaUiTokens.BANNER_CATCHCOPY)

func test_pull_title_world_flavor() -> void:
	assert_eq(GachaUiHelper.pull_title(), "招待状を開く")
	assert_eq(GachaUiHelper.ticket_pull_title(), "チケットで招待")

func test_pull_cost_amount() -> void:
	assert_eq(GachaUiHelper.pull_cost_amount(), GachaSystem.PULL_COST)
	assert_eq(GachaUiHelper.pull_cost_amount(1), GachaSystem.PULL_COST)

func test_banner_portrait_textures_caps_at_three() -> void:
	var textures: Array[Texture2D] = GachaUiHelper.banner_portrait_textures()
	assert_lte(textures.size(), GachaUiHelper.BANNER_PORTRAIT_MAX)


func test_featured_helpers_are_star3_plus_ordered() -> void:
	if not Constants.are_gacha_helpers_playable():
		assert_eq(GachaUiHelper.featured_helpers().size(), 0)
		return
	var featured: Array = GachaUiHelper.featured_helpers()
	assert_gt(featured.size(), 0)
	var prev_rarity: int = 99
	var prev_name: String = ""
	for helper in featured:
		var rarity: int = int(helper.rarity)
		assert_gte(rarity, GachaUiHelper.FEATURED_MIN_RARITY, "★2以下は Featured に出さない")
		assert_lte(rarity, prev_rarity)
		if rarity == prev_rarity:
			assert_true(str(helper.display_name) >= prev_name, "同★帯は名前昇順")
		prev_rarity = rarity
		prev_name = str(helper.display_name)


func test_preview_combat_stats_positive() -> void:
	var helpers: Array = GachaUiHelper.featured_helpers()
	if helpers.is_empty():
		return
	var stats: Dictionary = GachaUiHelper.preview_combat_stats(helpers[0])
	assert_gt(int(stats.get("hp", 0)), 0)
	assert_gt(int(stats.get("attack", 0)), 0)
	assert_gt(int(stats.get("defense", 0)), 0)
	assert_false(GachaUiHelper.unique_line_for_helper(helpers[0]).is_empty())


func test_make_lineup_row_has_name() -> void:
	var helpers: Array = GachaUiHelper.sorted_helpers()
	if helpers.is_empty():
		return
	var row: PanelContainer = GachaUiHelper.make_lineup_row(helpers[0])
	assert_not_null(row)
	assert_gt(row.get_child_count(), 0)


func test_make_pool_icon_button_sets_helper_id() -> void:
	var helpers: Array = GachaUiHelper.sorted_helpers()
	if helpers.is_empty():
		return
	var btn: Button = GachaUiHelper.make_pool_icon_button(helpers[0])
	assert_not_null(btn)
	assert_eq(str(btn.get_meta("helper_id", "")), str(helpers[0].id))
	assert_eq(btn.custom_minimum_size.x, float(GachaUiHelper.POOL_ICON_PX))


func test_job_display_is_job_name_not_role() -> void:
	var helpers: Array = GachaUiHelper.sorted_helpers()
	if helpers.is_empty():
		return
	var helper: Resource = null
	for h in helpers:
		if h != null and str(h.job_id) == "vanguard":
			helper = h
			break
	if helper == null:
		helper = helpers[0]
	var job_label: String = GachaUiHelper.job_display_name_for_helper(helper)
	assert_false(job_label.is_empty())
	assert_ne(job_label, "タンク")
	assert_false(GachaUiHelper.summon_quote_for_helper(helper).is_empty())
