extends GutTest
## P3-UX-ULTIMATE-001 — 必殺 resolve 演出タイミング。

const _UltimatePresentationConfig = preload("res://scripts/combat/UltimatePresentationConfig.gd")


func test_total_resolve_is_about_two_seconds() -> void:
	assert_almost_eq(_UltimatePresentationConfig.total_resolve_sec(), 1.9, 0.001)


func test_scaled_normal_speed() -> void:
	var t: Dictionary = _UltimatePresentationConfig.scaled(0.75)
	assert_almost_eq(float(t["total"]), 1.9 / 0.75, 0.001)
	assert_almost_eq(float(t["announce"]), 1.0 / 0.75, 0.001)


func test_scaled_fast_speed() -> void:
	var t: Dictionary = _UltimatePresentationConfig.scaled(1.5)
	assert_almost_eq(float(t["total"]), 1.9 / 1.5, 0.001)


func test_scaled_zero_mult_uses_neutral_pace() -> void:
	var t: Dictionary = _UltimatePresentationConfig.scaled(0.0)
	assert_almost_eq(float(t["total"]), 1.9, 0.001)


func test_boss_cutin_hold_matches_ally_banner_visible() -> void:
	## P3-UX-BOSS-ULTIMATE-001: ボス必殺バナー可視尺 = 味方 announce+windup
	var t: Dictionary = _UltimatePresentationConfig.scaled(1.0)
	var hold: float = float(t["announce"]) + float(t["windup"])
	assert_almost_eq(hold, 1.65, 0.001)
	var t_fast: Dictionary = _UltimatePresentationConfig.scaled(2.0)
	assert_almost_eq(float(t_fast["announce"]) + float(t_fast["windup"]), 1.65 / 2.0, 0.001)
