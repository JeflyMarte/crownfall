extends GutTest
## 状態異常横断点検（P3-FIX-STATUS-AUDIT-001）— 味方防御DOWN／鈍化二重ロール。

const _StatusResolver := preload("res://scripts/combat/StatusResolver.gd")


func test_slow_uses_interval_proxy_only() -> void:
	var slow: Resource = DataRegistry.get_status_effect("slow")
	assert_not_null(slow)
	assert_eq(float(slow.skip_action_chance), 0.0, "slow must not stack skip_action_chance")
	assert_gt(float(slow.interval_multiplier), 1.0)


func test_member_armor_break_defense_reduction() -> void:
	var resolver = _StatusResolver.new()
	assert_eq(resolver.get_defense_reduction("party_0"), 0.0)
	assert_true(resolver.apply_status("party_0", "armor_break", 1, 0))
	assert_almost_eq(resolver.get_defense_reduction("party_0"), 0.5, 0.001)


func test_status_multipliers_party_and_enemy() -> void:
	var resolver = _StatusResolver.new()
	assert_true(resolver.apply_status("party_0", "vulnerable", 1, 0))
	assert_true(resolver.apply_status("party_0", "curse", 1, 0))
	assert_almost_eq(resolver.get_incoming_damage_multiplier("party_0"), 1.25, 0.001)
	assert_almost_eq(resolver.get_outgoing_damage_multiplier("party_0"), 0.75, 0.001)

	assert_true(resolver.apply_status("enemy_0", "mark", 1, 0))
	assert_true(resolver.apply_status("enemy_0", "guard", 1, 0))
	assert_almost_eq(resolver.get_incoming_damage_multiplier("enemy_0"), 1.15 * 0.5, 0.001)


func test_ignite_ticks_flat() -> void:
	var resolver = _StatusResolver.new()
	assert_true(resolver.apply_status("enemy_0", "ignite", 1, 0))
	var ticks: Array = resolver.tick_unit("enemy_0")
	assert_eq(ticks.size(), 1)
	## source_attack=0 でも固定分は入る（P3-BAL-DOT-IDENTITY-001）。
	assert_eq(int(ticks[0].get("damage", 0)), BalanceConfig.DOT_FLAT_IGNITE)


func test_stun_and_fear_skip_chance_fields() -> void:
	var stun: Resource = DataRegistry.get_status_effect("stun")
	var fear: Resource = DataRegistry.get_status_effect("fear")
	var chill: Resource = DataRegistry.get_status_effect("chill")
	assert_not_null(stun)
	assert_not_null(fear)
	assert_not_null(chill)
	assert_eq(float(stun.skip_action_chance), 1.0)
	assert_eq(float(fear.skip_action_chance), 0.5)
	assert_eq(float(chill.skip_action_chance), 0.5)
	assert_eq(float(chill.interval_multiplier), 1.0)
