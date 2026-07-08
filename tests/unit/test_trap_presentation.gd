extends GutTest
## P3-UX-TRAP-001 — 罠ヒット演出パラメータ。

const _TrapPresentation = preload("res://scripts/dungeon/TrapPresentation.gd")


func test_trap_room_has_more_pulses_than_explore() -> void:
	assert_eq(_TrapPresentation.pulse_count(true, false), 3)
	assert_eq(_TrapPresentation.pulse_count(false, false), 2)


func test_fast_run_reduces_pulses() -> void:
	assert_eq(_TrapPresentation.pulse_count(true, true), 2)
	assert_eq(_TrapPresentation.pulse_count(false, true), 2)


func test_damage_scale_room_larger_than_explore() -> void:
	assert_gt(_TrapPresentation.damage_scale(true), _TrapPresentation.damage_scale(false))


func test_peak_alphas_match_pulse_count() -> void:
	var room: Array[float] = _TrapPresentation.peak_alphas(true, false)
	assert_eq(room.size(), 3)
	var explore: Array[float] = _TrapPresentation.peak_alphas(false, false)
	assert_eq(explore.size(), 2)
