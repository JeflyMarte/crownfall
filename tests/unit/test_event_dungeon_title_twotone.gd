extends GutTest

const _Helper = preload("res://scripts/ui/EventDungeonTitleHelper.gd")


func test_split_descent_titles() -> void:
	var chronos: Dictionary = _Helper.split_title("時環の共鳴龍　降臨")
	assert_eq(str(chronos.get("body", "")), "時環の共鳴龍　")
	assert_eq(str(chronos.get("suffix", "")), "降臨")
	var valgard: Dictionary = _Helper.split_title("境界の番　降臨")
	assert_eq(str(valgard.get("body", "")), "境界の番　")
	assert_eq(str(valgard.get("suffix", "")), "降臨")
	var weekday: Dictionary = _Helper.split_title("コズミックダックの裂け目")
	assert_eq(str(weekday.get("suffix", "")), "")
	assert_eq(str(weekday.get("body", "")), "コズミックダックの裂け目")


func test_descent_body_theme_colors_differ() -> void:
	assert_true(_Helper.is_descent_twotone("時環の共鳴龍　降臨"))
	assert_false(_Helper.is_descent_twotone("砂金の巣穴"))
	var chronos_c: Color = _Helper.body_color("chronos_mausoleum")
	var valgard_c: Color = _Helper.body_color("valgard_boundary")
	assert_false(is_equal_approx(chronos_c.r, valgard_c.r) and is_equal_approx(chronos_c.g, valgard_c.g))
	assert_eq(_Helper.suffix_color(), _Helper.COLOR_DESCENT_MARK)


func test_title_bbcode_twotone_and_plain() -> void:
	var bb: String = _Helper.title_bbcode(
		"chronos_mausoleum", "時環の共鳴龍　降臨", true
	)
	assert_true("降臨" in bb)
	assert_true("[color=#" in bb)
	var plain: String = _Helper.title_bbcode(
		"cosmic_rift", "コズミックダックの裂け目", true
	)
	assert_true("コズミックダックの裂け目" in plain)
	assert_false("]降臨" in plain)
