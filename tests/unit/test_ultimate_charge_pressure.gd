extends GutTest
## P3-BAL-ULTIMATE-UNIFY-100-001 — 必殺チャージは部屋種別によらず同一速度。


func test_pressure_constants_are_unity() -> void:
	assert_almost_eq(BalanceConfig.ULTIMATE_CHARGE_PRESSURE_MULT, 1.0, 0.001)
	assert_almost_eq(BalanceConfig.ULTIMATE_CHARGE_PRESSURE_ENTER_MULT, 1.0, 0.001)
	assert_almost_eq(Constants.ULTIMATE_CHARGE_FILL_SECONDS, 100.0, 0.001)


func test_enter_no_longer_halves_existing_charge() -> void:
	var ctrl := CombatController.new()
	add_child_autofree(ctrl)
	ctrl.party_combat_hp = [100, 100]
	ctrl.party_max_hp = [100, 100]
	ctrl._init_member_ultimate_charge()
	ctrl.add_ultimate_charge(0, 80.0)
	ctrl.scale_member_ultimate_charge(BalanceConfig.ULTIMATE_CHARGE_PRESSURE_ENTER_MULT)
	assert_almost_eq(ctrl.get_ultimate_charge(0), 80.0, 0.01)


func test_elite_boss_gain_mult_matches_normal_fill() -> void:
	var ctrl := CombatController.new()
	add_child_autofree(ctrl)
	ctrl.party_combat_hp = [100, 100]
	ctrl.party_max_hp = [100, 100]
	ctrl._init_member_ultimate_charge()
	ctrl.is_in_combat = true
	ctrl.set_ultimate_charge_gain_mult(BalanceConfig.ULTIMATE_CHARGE_PRESSURE_MULT)
	ctrl.tick_ultimate_charge_over_time(Constants.ULTIMATE_CHARGE_FILL_SECONDS)
	assert_true(ctrl.is_ultimate_charge_ready(0))


func test_normal_time_charge_without_pressure() -> void:
	var ctrl := CombatController.new()
	add_child_autofree(ctrl)
	ctrl.party_combat_hp = [100]
	ctrl.party_max_hp = [100]
	ctrl._init_member_ultimate_charge()
	ctrl.is_in_combat = true
	assert_almost_eq(ctrl.ultimate_charge_gain_mult, 1.0, 0.001)
	ctrl.tick_ultimate_charge_over_time(Constants.ULTIMATE_CHARGE_FILL_SECONDS)
	assert_true(ctrl.is_ultimate_charge_ready(0))


func test_end_combat_clears_pressure_mult() -> void:
	var ctrl := CombatController.new()
	add_child_autofree(ctrl)
	ctrl.party_combat_hp = [100]
	ctrl.party_max_hp = [100]
	ctrl.start_combat_group([], 1, false)
	ctrl.set_ultimate_charge_gain_mult(0.5)
	ctrl.end_combat()
	assert_almost_eq(ctrl.ultimate_charge_gain_mult, 1.0, 0.001)
