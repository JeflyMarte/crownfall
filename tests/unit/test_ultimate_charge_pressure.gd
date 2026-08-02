extends GutTest
## P3-BAL-ULTIMATE-PRESSURE-001 — ELITE／BOSS 必殺チャージ圧力。


func test_pressure_constants() -> void:
	assert_almost_eq(BalanceConfig.ULTIMATE_CHARGE_PRESSURE_MULT, 0.5, 0.001)
	assert_almost_eq(BalanceConfig.ULTIMATE_CHARGE_PRESSURE_ENTER_MULT, 0.5, 0.001)


func test_enter_halves_existing_charge() -> void:
	var ctrl := CombatController.new()
	add_child_autofree(ctrl)
	ctrl.party_combat_hp = [100, 100]
	ctrl.party_max_hp = [100, 100]
	ctrl._init_member_ultimate_charge()
	ctrl.add_ultimate_charge(0, 80.0)
	ctrl.scale_member_ultimate_charge(BalanceConfig.ULTIMATE_CHARGE_PRESSURE_ENTER_MULT)
	assert_almost_eq(ctrl.get_ultimate_charge(0), 40.0, 0.01)


func test_pressure_mult_slows_dealt_and_taken() -> void:
	var ctrl := CombatController.new()
	add_child_autofree(ctrl)
	ctrl.party_combat_hp = [100, 100]
	ctrl.party_max_hp = [100, 100]
	ctrl._init_member_ultimate_charge()
	ctrl.set_ultimate_charge_gain_mult(BalanceConfig.ULTIMATE_CHARGE_PRESSURE_MULT)
	ctrl.add_ultimate_charge_from_damage_dealt(0, 100)
	assert_almost_eq(
		ctrl.get_ultimate_charge(0),
		100.0 * Constants.ULTIMATE_CHARGE_DEALT_K * 0.5,
		0.01
	)
	ctrl.add_ultimate_charge_from_damage_taken(0, 50)
	assert_almost_eq(
		ctrl.get_ultimate_charge(0),
		100.0 * Constants.ULTIMATE_CHARGE_DEALT_K * 0.5
		+ 50.0 * Constants.ULTIMATE_CHARGE_TAKEN_K * 0.5,
		0.01
	)


func test_normal_mult_unchanged_without_pressure() -> void:
	var ctrl := CombatController.new()
	add_child_autofree(ctrl)
	ctrl.party_combat_hp = [100]
	ctrl.party_max_hp = [100]
	ctrl._init_member_ultimate_charge()
	assert_almost_eq(ctrl.ultimate_charge_gain_mult, 1.0, 0.001)
	ctrl.add_ultimate_charge_from_damage_dealt(0, 100)
	assert_almost_eq(
		ctrl.get_ultimate_charge(0),
		100.0 * Constants.ULTIMATE_CHARGE_DEALT_K,
		0.01
	)


func test_end_combat_clears_pressure_mult() -> void:
	var ctrl := CombatController.new()
	add_child_autofree(ctrl)
	ctrl.party_combat_hp = [100]
	ctrl.party_max_hp = [100]
	ctrl.start_combat_group([], 1, false)
	ctrl.set_ultimate_charge_gain_mult(0.5)
	ctrl.end_combat()
	assert_almost_eq(ctrl.ultimate_charge_gain_mult, 1.0, 0.001)
