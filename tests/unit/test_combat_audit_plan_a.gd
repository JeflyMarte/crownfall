extends GutTest
## P3-FIX-COMBAT-AUDIT-A-001 — スキル会心／aimed_shot 据置確認。


func test_skill_critical_multiplier_uses_weapon_crit_damage() -> void:
	var inst := WeaponInstance.new()
	inst.critical_damage = 2.0
	assert_almost_eq(WeaponStatResolver.resolve_critical_damage(inst), 2.0, 0.001)
	assert_almost_eq(
		WeaponStatResolver.resolve_critical_damage(null),
		BalanceConfig.DEFAULT_WEAPON_CRITICAL_DAMAGE,
		0.001
	)


func test_aimed_shot_remains_armor_break_only_per_audit() -> void:
	## P3-BAL-COMBAT-AUDIT-001: スナイプは甲砕のみ（標的は外したまま）。
	var aimed: Resource = DataRegistry.get_skill_data("aimed_shot")
	assert_eq(str(aimed.apply_status_id), "armor_break")
	assert_true(str(aimed.apply_status_id2).is_empty())
