extends GutTest
## P3-BAL-HEAL-MAXHP-001 — 味方回復は対象 maxHP 割合。
## P3-BAL-BT-RG-KIT-TUNE-001 — 獣医ドレイン／野営全体／つつき自己除外。


func test_heal_frac_constants_match_skills() -> void:
	assert_almost_eq(
		float(DataRegistry.get_skill_data("mend").power_multiplier),
		BalanceConfig.HEAL_FRAC_MEND,
		0.001
	)
	assert_almost_eq(
		float(DataRegistry.get_skill_data("salve_burst").power_multiplier),
		BalanceConfig.HEAL_FRAC_SALVE_BURST,
		0.001
	)
	assert_eq(str(DataRegistry.get_skill_data("salve_burst").target_type), "all_party")
	assert_almost_eq(float(DataRegistry.get_skill_data("mend").cooldown), 8.0, 0.001)
	assert_almost_eq(float(DataRegistry.get_skill_data("salve_burst").cooldown), 12.0, 0.001)
	assert_almost_eq(
		float(DataRegistry.get_skill_data("grand_elixir").power_multiplier),
		BalanceConfig.HEAL_FRAC_GRAND_ELIXIR,
		0.001
	)
	assert_almost_eq(
		float(DataRegistry.get_skill_data("camp_draught").power_multiplier),
		BalanceConfig.HEAL_FRAC_CAMP_DRAUGHT,
		0.001
	)
	assert_eq(str(DataRegistry.get_skill_data("camp_draught").target_type), "all_party")
	var vet: Resource = DataRegistry.get_skill_data("beast_vet_care")
	assert_eq(str(vet.effect_type), "damage")
	assert_eq(str(vet.display_name), "血還の矢")
	assert_almost_eq(float(vet.power_multiplier), 1.1, 0.001)
	assert_true(vet.tags.has("drain"))
	assert_lte(float(vet.cast_time), 0.0, "drain attack must be instant (no cast)")
	assert_almost_eq(BalanceConfig.SKILL_DRAIN_HEAL_RATIO, 0.5, 0.001)


func test_heal_frac_examples() -> void:
	## 戦闘式: round(maxHP × power)。ボーナスなし時。
	assert_eq(int(round(1000.0 * BalanceConfig.HEAL_FRAC_MEND)), 200)
	assert_eq(int(round(2000.0 * BalanceConfig.HEAL_FRAC_SALVE_BURST)), 240)
	assert_eq(int(round(2000.0 * BalanceConfig.HEAL_FRAC_GRAND_ELIXIR)), 400)
	assert_eq(int(round(1000.0 * BalanceConfig.HEAL_FRAC_CAMP_DRAUGHT)), 80)
	assert_eq(int(round(1000.0 * BalanceConfig.HEAL_FRAC_PET_POUNCE)), 80)
	assert_eq(int(round(1000.0 * BalanceConfig.HEAL_FRAC_PET_BOND_RALLY)), 100)


func test_heal_hierarchy_mend_is_best_character_single() -> void:
	## P3-BAL-HEAL-HIERARCHY-001: 治癒がキャラ単体回復の頂点。獣医はドレイン攻撃へ分離。
	var mend: Resource = DataRegistry.get_skill_data("mend")
	var camp: Resource = DataRegistry.get_skill_data("camp_draught")
	var pounce: Resource = DataRegistry.get_skill_data("pet_pounce")
	var savage: Resource = DataRegistry.get_skill_data("pet_jack_savage")
	assert_gt(float(mend.power_multiplier), float(camp.power_multiplier))
	assert_gt(float(mend.power_multiplier), float(pounce.power_multiplier))
	assert_gt(float(mend.power_multiplier), float(savage.power_multiplier))
	assert_lt(float(mend.cooldown), float(camp.cooldown))
	assert_lt(float(mend.cooldown), float(pounce.cooldown))
	assert_lt(float(mend.cooldown), float(savage.cooldown))
	## つつきは旧CD5.5から伸ばす。自己非対象。
	assert_gte(float(pounce.cooldown), 9.5)
	assert_true(pounce.tags.has("exclude_self"))
	assert_almost_eq(float(pounce.power_multiplier), BalanceConfig.HEAL_FRAC_PET_POUNCE, 0.001)
	assert_almost_eq(float(savage.power_multiplier), BalanceConfig.HEAL_FRAC_PET_JACK_SAVAGE, 0.001)


func test_get_member_max_hp() -> void:
	var ctrl := CombatController.new()
	add_child_autofree(ctrl)
	ctrl.party_combat_hp = [1, 1]
	ctrl.party_max_hp = [1000, 2500]
	assert_eq(ctrl.get_member_max_hp(0), 1000)
	assert_eq(ctrl.get_member_max_hp(1), 2500)
	assert_eq(ctrl.get_member_max_hp(9), 0)


func test_most_injured_exclude_self() -> void:
	var ctrl := CombatController.new()
	add_child_autofree(ctrl)
	ctrl.party_combat_hp = [500, 900]
	ctrl.party_max_hp = [1000, 1000]
	assert_eq(ctrl.get_most_injured_member_index(), 0)
	assert_eq(ctrl.get_most_injured_member_index(0), 1)
	assert_eq(ctrl.get_most_injured_member_index(1), 0)
	ctrl.party_combat_hp = [1000, 1000]
	assert_eq(ctrl.get_most_injured_member_index(0), -1)
