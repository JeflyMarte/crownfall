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


func test_feature_line_uses_origin_note_above_passive() -> void:
	## P3-GACHA-FEATURE-TEASE-001: 特徴=origin_note（煽り）、固有=パッシブ。
	var helpers: Array = GachaUiHelper.featured_helpers()
	if helpers.is_empty():
		return
	var helper: Resource = helpers[0]
	var feature: String = GachaUiHelper.feature_line_for_helper(helper)
	var unique: String = GachaUiHelper.unique_line_for_helper(helper)
	var unique_title: String = GachaUiHelper.unique_title_for_helper(helper)
	var unique_desc: String = GachaUiHelper.unique_desc_for_helper(helper)
	assert_false(feature.is_empty())
	assert_eq(feature, GachaUiHelper.ensure_sentence_period(str(helper.origin_note)))
	assert_ne(feature, unique)
	assert_false(unique_title.is_empty())
	assert_false(unique_desc.is_empty())
	assert_eq(unique, "%s\n%s" % [unique_title, unique_desc])
	assert_eq(GachaUiHelper.FEATURED_IDLE_LIFT_Y, 100.0)


func test_build_featured_shell_has_feature_label() -> void:
	var host := Control.new()
	host.size = Vector2(680, 420)
	add_child_autofree(host)
	var shell: Dictionary = GachaUiHelper.build_featured_shell(host)
	assert_true(shell.has("feature"))
	assert_true(shell.has("unique"))
	assert_true(shell.has("unique_title"))
	assert_true(shell.has("blurb_wrap"))
	var feature_lbl: Label = shell.get("feature") as Label
	var unique_lbl: Label = shell.get("unique") as Label
	var unique_title_lbl: Label = shell.get("unique_title") as Label
	var blurb_wrap: Control = shell.get("blurb_wrap") as Control
	var stats_wrap: Control = shell.get("stats_wrap") as Control
	assert_not_null(feature_lbl)
	assert_not_null(unique_lbl)
	assert_not_null(unique_title_lbl)
	assert_not_null(blurb_wrap)
	assert_not_null(stats_wrap)
	## 煽りは左パネル、パッシブは右ステ内。Shippori・小さめ・右ステより下。
	assert_eq(feature_lbl.get_parent(), blurb_wrap)
	assert_eq(unique_lbl.get_parent().name, "StatsCol")
	assert_eq(unique_title_lbl.get_parent().name, "StatsCol")
	assert_eq(blurb_wrap.offset_left, GachaUiHelper.FEATURED_BLURB_SIDE_PAD)
	assert_gt(blurb_wrap.offset_top, stats_wrap.offset_top)
	assert_eq(int(feature_lbl.get_theme_font_size("font_size")), GachaUiHelper.FEATURED_BLURB_FONT_SIZE)
	assert_eq(feature_lbl.get_theme_font("font"), UiTypography.display_font())
	assert_gt(stats_wrap.offset_left, -400.0)
	var helpers: Array = GachaUiHelper.featured_helpers()
	if helpers.is_empty():
		return
	GachaUiHelper.apply_featured_helper(shell, helpers[0])
	assert_eq(feature_lbl.text, GachaUiHelper.feature_line_for_helper(helpers[0]))
	assert_eq(unique_title_lbl.text, GachaUiHelper.unique_title_for_helper(helpers[0]))
	assert_eq(unique_lbl.text, GachaUiHelper.unique_desc_for_helper(helpers[0]))
	assert_false(unique_title_lbl.text.is_empty())
	assert_false(unique_lbl.text.is_empty())
	assert_true(feature_lbl.visible)
	assert_true(blurb_wrap.visible)
	var stage: Control = shell.get("stage") as Control
	if stage != null:
		var mote_n: int = 0
		for child in stage.get_children():
			if str(child.name).begins_with("FeaturedMote_"):
				mote_n += 1
		assert_eq(mote_n, GachaUiHelper.FEATURED_MOTE_COUNT)
		assert_not_null(stage.get_node_or_null("FeaturedBeamHaze"))


func test_feature_blurbs_end_with_exclamation() -> void:
	for helper in GachaUiHelper.sorted_helpers():
		if helper == null:
			continue
		var note: String = str(helper.origin_note).strip_edges()
		if note.is_empty():
			continue
		assert_true(
			note.ends_with("！") or note.ends_with("!"),
			"%s origin_note should be tease-style" % str(helper.id)
		)


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
