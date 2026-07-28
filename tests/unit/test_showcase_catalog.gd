extends GutTest

## P3-SHOWCASE-001: スタッフ作例ビルドとセーブ欄。

const ShowcaseCatalogScript = preload("res://scripts/showcase/ShowcaseCatalog.gd")

func test_staff_presets_build_members() -> void:
	var presets: Array = ShowcaseCatalogScript.staff_presets()
	assert_gt(presets.size(), 0, "staff presets exist")
	for raw: Variant in presets:
		assert_true(raw is Dictionary)
		var preset: Dictionary = raw
		var member: Resource = ShowcaseCatalogScript.build_member_from_preset(preset)
		assert_not_null(member, "member for %s" % str(preset.get("id", "")))
		assert_false(str(member.display_name).is_empty())
		assert_false(str(preset.get("player_name", "")).is_empty(), "player_name for %s" % str(preset.get("id", "")))
		assert_false(str(member.job_id).is_empty())
		assert_gt(int(member.level), 0)
		var stats: Dictionary = RosterUiHelper.compute_member_stats(member)
		assert_gt(int(stats.get("hp", 0)), 0)


func test_showcase_member_id_roundtrip_helpers() -> void:
	var prev: String = GameState.showcase_member_id
	GameState.set_showcase_member_id("  adventurer_0  ")
	assert_eq(GameState.showcase_member_id, "adventurer_0")
	GameState.set_showcase_member_id("")
	assert_eq(GameState.showcase_member_id, "")
	GameState.showcase_member_id = prev


func test_power_and_change_member_layout_rects() -> void:
	## 総合戦力＝旧キャラ変更帯、キャラ変更＝装備とステのあいだ。
	var power: Rect2 = ShowcaseUiTokens.POWER_RECT
	var change: Rect2 = ShowcaseUiTokens.CHANGE_MEMBER_RECT
	var equip: Rect2 = ShowcaseUiTokens.EQUIP_RECT
	var stats: Rect2 = ShowcaseUiTokens.STATS_RECT
	assert_gt(power.position.y, change.position.y)
	assert_gt(change.position.x, equip.position.x + equip.size.x - 8.0)
	assert_lt(change.position.x + change.size.x, stats.position.x + 8.0)


func test_name_frame_top_rule_sits_above_footer_name() -> void:
	var rule: Rect2 = ShowcaseUiTokens.NAME_FRAME_TOP_RULE
	var footer: Rect2 = ShowcaseUiTokens.FOOTER_RECT
	assert_gte(rule.position.y, footer.position.y - 2.0)
	assert_lt(rule.position.y, footer.position.y + 20.0)
	assert_gt(rule.size.x, 100.0)
