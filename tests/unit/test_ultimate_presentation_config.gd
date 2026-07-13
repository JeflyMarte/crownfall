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
