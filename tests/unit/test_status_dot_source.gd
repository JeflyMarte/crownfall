extends GutTest
## 出血／毒 DoT — source_attack と tick ダメージ（P3-FIX-DOT-SOURCE-001）。

const _StatusResolver := preload("res://scripts/combat/StatusResolver.gd")


func test_poison_ticks_without_source_attack() -> void:
	var resolver = _StatusResolver.new()
	assert_true(resolver.apply_status("party_0", "poison", 1, 0))
	var ticks: Array = resolver.tick_unit("party_0")
	assert_eq(ticks.size(), 1)
	assert_eq(str(ticks[0].get("effect_id", "")), "poison")
	assert_gt(int(ticks[0].get("damage", 0)), 0)


func test_bleed_needs_source_attack() -> void:
	var resolver = _StatusResolver.new()
	assert_true(resolver.apply_status("enemy_0", "bleed", 1, 0))
	var zero_ticks: Array = resolver.tick_unit("enemy_0")
	assert_eq(zero_ticks.size(), 0, "bleed with source_attack=0 must deal no DoT")

	assert_true(resolver.apply_status("enemy_1", "bleed", 1, 100))
	var ticks: Array = resolver.tick_unit("enemy_1")
	assert_eq(ticks.size(), 1)
	assert_eq(str(ticks[0].get("effect_id", "")), "bleed")
	## 100 * 0.2 * 1 stack
	assert_eq(int(ticks[0].get("damage", 0)), 20)


func test_bleed_scales_with_stacks() -> void:
	var resolver = _StatusResolver.new()
	assert_true(resolver.apply_status("enemy_0", "bleed", 2, 100))
	var ticks: Array = resolver.tick_unit("enemy_0")
	assert_eq(ticks.size(), 1)
	assert_eq(int(ticks[0].get("damage", 0)), 40)
